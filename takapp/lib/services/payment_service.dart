import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:takapp/core/errors/app_error.dart';

import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/services/order_actor_verifier.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// UID Firebase Auth de la session : seule source de l'encaisseur réel.
  final String? Function() _currentUserId;

  PaymentService({String? Function()? currentUserId})
    : _currentUserId =
          currentUserId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _ordersRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders');
  }

  CollectionReference<Map<String, dynamic>> _paymentsRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('payments');
  }

  CollectionReference<Map<String, dynamic>> _roomExtrasRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('roomExtras');
  }

  void _validateEstablishmentId(String establishmentId) {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }
  }

  /// =========================
  /// STREAM UNPAID ORDERS
  /// =========================

  Stream<List<OrderModel>> streamUnpaidOrdersForServer({
    required String establishmentId,
    required String serveurId,
  }) {
    _validateEstablishmentId(establishmentId);

    // Serveur RESPONSABLE : pendant la transition, createdBy vaut
    // assignedServerId pour toutes les commandes, anciennes comprises.
    // Filtrer sur assignedServerId ferait disparaître les anciennes.
    return _ordersRef(establishmentId: establishmentId)
        .where('createdBy', isEqualTo: serveurId)
        .where('paymentStatus', isEqualTo: 'unpaid')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Toutes les commandes non encaissées de l'établissement.
  ///
  /// Les commandes annulées sont filtrées après lecture afin de conserver une
  /// requête Firestore simple et sans index composite supplémentaire.
  Stream<List<OrderModel>> streamUnpaidOrdersForEstablishment({
    required String establishmentId,
  }) {
    _validateEstablishmentId(establishmentId);

    return _ordersRef(establishmentId: establishmentId)
        .where('paymentStatus', isEqualTo: 'unpaid')
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .where((doc) {
                return (doc.data()['status'] ?? '').toString() != 'cancelled';
              })
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();

          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// =========================
  /// STREAM ALL ORDERS FOR SERVER (par jour)
  /// =========================
  /// Toutes les commandes créées par ce serveur pour un jour donné,
  /// payées ou non, fiscalisées ou non. Triées du plus récent au plus ancien.
  Stream<List<OrderModel>> streamOrdersForServerByDay({
    required String establishmentId,
    required String serveurId,
    required DateTime day,
  }) {
    _validateEstablishmentId(establishmentId);

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Serveur RESPONSABLE (createdBy = assignedServerId, anciennes incluses).
    return _ordersRef(establishmentId: establishmentId)
        .where('createdBy', isEqualTo: serveurId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// =========================
  /// ACTEURS D'UN PAIEMENT
  /// =========================

  /// Champs d'acteur écrits sur un paiement.
  ///
  /// - `receivedBy*` : ENCAISSEUR RÉEL, l'auteur du contexte (utilisateur
  ///   authentifié, vérifié avant l'écriture). Les remises d'argent le
  ///   suivent : c'est lui qui a l'argent.
  /// - `responsibleServer*` : SERVEUR RESPONSABLE de la vente. Floor Manager :
  ///   le serveur du contexte (lui-même en direct, Jean pour Jean). Autres
  ///   rôles : le serveur responsable de la commande principale.
  /// - `shiftId` : service de l'encaissement (Floor Manager), sinon null.
  static Map<String, dynamic> paymentActorFields({
    required OrderActorContext actor,
    required OrderModel primaryOrder,
  }) {
    return {
      'receivedBy': actor.performedByUserId,
      'receivedByName': actor.performedByUserName,
      'responsibleServerId': actor.isFloorManager
          ? actor.assignedServerId
          : primaryOrder.effectiveAssignedServerId,
      'responsibleServerName': actor.isFloorManager
          ? actor.assignedServerName
          : primaryOrder.effectiveAssignedServerName,
      'shiftId': actor.shiftId,
    };
  }

  /// =========================
  /// REGISTER PAYMENT
  /// =========================

  /// Encaisse une addition en un seul règlement.
  ///
  /// Toutes les commandes du ticket (table ou chambre) sont soldées ensemble et
  /// donnent lieu à un unique document `payments` : le montant remis en caisse
  /// correspond exactement à la facture présentée au client.
  ///
  /// ACTEURS (10B) — deux notions distinctes, jamais confondues :
  /// - ENCAISSEUR RÉEL : `receivedBy` = [OrderActorContext.performedByUserId],
  ///   toujours l'utilisateur authentifié (vérifié). Les remises d'argent
  ///   suivent ce champ : c'est lui qui a l'argent.
  /// - SERVEUR RESPONSABLE de la vente : `responsibleServerId`. Floor Manager :
  ///   le serveur choisi (lui-même en direct, Jean pour Jean). Autres rôles :
  ///   le serveur responsable de la commande principale de l'addition.
  ///
  /// DOUBLE ENCAISSEMENT : tout se passe dans UNE transaction qui relit les
  /// commandes ; une commande déjà payée fait échouer l'opération, et deux
  /// validations simultanées ne peuvent pas réussir toutes les deux (la
  /// seconde est rejouée puis refusée). Les règles Firestore interdisent en
  /// outre de repasser une commande payée à « payée ».
  Future<void> registerTicketPayment({
    required String establishmentId,
    required String ticketId,
    required List<String> orderIds,
    required OrderActorContext actor,
    required String method,
    required double amount,
  }) async {
    _validateEstablishmentId(establishmentId);

    final ids = orderIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) {
      throw const AppError(AppErrorCode.orderNotFound);
    }

    if (amount <= 0) {
      throw const AppError(AppErrorCode.amountMustBePositive);
    }

    // Floor Manager : service ouvert, serveur présent (mêmes contrôles que
    // pour la prise de commande). Autres rôles : l'encaisseur est bien
    // l'utilisateur authentifié.
    final verified = await OrderActorVerifier(
      _firestore,
      _currentUserId,
    ).verify(establishmentId, actor);

    if (actor.isFloorManager && method == 'room') {
      throw const AppError(AppErrorCode.orderAssignmentForbidden);
    }

    final orderRefs = ids
        .map((id) => _ordersRef(establishmentId: establishmentId).doc(id))
        .toList();

    final paymentRef = _paymentsRef(establishmentId: establishmentId).doc();

    // Sur le web, une exception levée DANS la transaction perd son message :
    // on la capture et on la relance après.
    AppError? failure;

    await _firestore.runTransaction((transaction) async {
      failure = null; // la transaction peut être rejouée

      final List<OrderModel> orders = [];

      for (final orderRef in orderRefs) {
        final orderDoc = await transaction.get(orderRef);
        final orderData = orderDoc.data();

        if (!orderDoc.exists || orderData == null) {
          failure = const AppError(AppErrorCode.orderNotFound);
          return;
        }

        final order = OrderModel.fromMap(orderData, orderDoc.id);

        // Relu dans la transaction : un second encaissement concurrent voit
        // la commande déjà payée et échoue.
        if (order.paymentStatus == 'paid') {
          failure = AppError(
            AppErrorCode.orderAlreadyPaid,
            name: order.orderNumber,
          );
          return;
        }

        if (order.status == 'cancelled') {
          failure = AppError(
            AppErrorCode.orderNotPayable,
            name: order.orderNumber,
          );
          return;
        }

        if (orderData['isForKitchen'] == true &&
            orderData['kitchenStatus'] != 'ready' &&
            orderData['kitchenStatus'] != 'served') {
          failure = AppError(
            AppErrorCode.kitchenNotReady,
            name: order.orderNumber,
          );
          return;
        }

        if (orderData['isForBar'] == true &&
            orderData['barStatus'] != 'ready' &&
            orderData['barStatus'] != 'served') {
          failure = AppError(
            AppErrorCode.barNotReady,
            name: order.orderNumber,
          );
          return;
        }

        // Floor Manager : chaque commande doit appartenir à lui-même ou à un
        // serveur de SON service (jamais à un autre serveur / Floor Manager).
        final shift = verified.shift;
        if (actor.isFloorManager) {
          final owner = order.effectiveAssignedServerId;
          final allowed =
              owner == actor.performedByUserId ||
              (shift != null && shift.serverIds.contains(owner));
          if (!allowed) {
            failure = AppError(
              AppErrorCode.orderServerNotInShift,
              name: order.effectiveAssignedServerName,
            );
            return;
          }
        }

        orders.add(order);
      }

      // Floor Manager : le montant (non modifiable dans son écran) doit
      // correspondre aux commandes relues, sinon l'addition a changé depuis
      // son affichage. Les autres rôles gardent le montant saisi librement
      // (comportement historique de l'écran d'encaissement du serveur).
      final expected = orders.fold<double>(0, (running, o) => running + o.total);
      if (actor.isFloorManager && (expected - amount).abs() > 0.01) {
        failure = const AppError(AppErrorCode.ticketChanged);
        return;
      }

      final primary = orders.first;
      final orderNumbers = orders.map((o) => o.orderNumber).toList();
      final clientType = primary.clientType;

      final actorFields = paymentActorFields(
        actor: actor,
        primaryOrder: primary,
      );

      if (method == 'room') {
        final roomExtraRef = _roomExtrasRef(
          establishmentId: establishmentId,
        ).doc();

        transaction.set(roomExtraRef, {
          'establishmentId': establishmentId,
          'roomNumber': primary.roomNumber ?? '',
          'amount': amount,
          'ticketId': ticketId,
          'orderId': ids.first,
          'orderNumber': orderNumbers.first,
          'orderIds': ids,
          'orderNumbers': orderNumbers,
          'createdBy': actor.performedByUserId,
          'createdByName': actor.performedByUserName,
          'createdAt': FieldValue.serverTimestamp(),
          'pendingSync': false,
          'syncError': false,
        });
      }

      transaction.set(paymentRef, {
        'establishmentId': establishmentId,
        'ticketId': ticketId,

        /// Commande principale de l'addition : conservée pour la compatibilité
        /// des écrans qui rattachent un paiement à une commande unique.
        'orderId': ids.first,
        'orderNumber': orderNumbers.first,

        'orderIds': ids,
        'orderNumbers': orderNumbers,
        'orderCount': ids.length,

        'clientType': clientType,
        'type': method == 'room' ? 'room' : clientType,

        // receivedBy* (encaisseur réel), responsibleServer* (serveur
        // responsable de la vente), shiftId.
        ...actorFields,

        'method': method,
        'amount': amount,
        'status': 'confirmed',
        'handoverStatus': method == 'room' ? 'none' : 'pending',
        'handoverId': null,
        'isFiscalized': false,
        'fiscalUid': '',
        'pendingSync': false,
        'syncError': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final orderRef in orderRefs) {
        transaction.update(orderRef, {
          'paymentStatus': 'paid',
          'status': 'paid',
          'paymentId': paymentRef.id,
          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'pendingSync': false,
          'syncError': false,
        });
      }
    });

    final error = failure;
    if (error != null) throw error;
  }
}
