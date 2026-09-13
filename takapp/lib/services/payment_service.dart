import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';

import 'package:takapp/modeles/order_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  /// REGISTER PAYMENT
  /// =========================

  /// Encaisse une addition en un seul règlement.
  ///
  /// Toutes les commandes du ticket (table ou chambre) sont soldées ensemble et
  /// donnent lieu à un unique document `payments` : le montant remis en caisse
  /// correspond exactement à la facture présentée au client.
  Future<void> registerTicketPayment({
    required String establishmentId,
    required String ticketId,
    required List<String> orderIds,
    required String receivedBy,
    required String receivedByName,
    required String method,
    required double amount,
  }) async {
    _validateEstablishmentId(establishmentId);

    final ids = orderIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (ids.isEmpty) {
      throw const AppError(AppErrorCode.orderNotFound);
    }

    if (amount <= 0) {
      throw const AppError(AppErrorCode.amountMustBePositive);
    }

    final orderRefs = ids
        .map((id) => _ordersRef(establishmentId: establishmentId).doc(id))
        .toList();

    final orderDocs = await Future.wait(orderRefs.map((ref) => ref.get()));

    final List<Map<String, dynamic>> ordersData = [];

    for (final orderDoc in orderDocs) {
      if (!orderDoc.exists || orderDoc.data() == null) {
        throw const AppError(AppErrorCode.orderNotFound);
      }

      final orderData = orderDoc.data()!;

      final orderNumber = (orderData['orderNumber'] ?? '').toString();

      if (orderData['isForKitchen'] == true &&
          orderData['kitchenStatus'] != 'ready' &&
          orderData['kitchenStatus'] != 'served') {
        throw AppError(AppErrorCode.kitchenNotReady, name: orderNumber);
      }

      if (orderData['isForBar'] == true &&
          orderData['barStatus'] != 'ready' &&
          orderData['barStatus'] != 'served') {
        throw AppError(AppErrorCode.barNotReady, name: orderNumber);
      }

      ordersData.add(orderData);
    }

    final primaryData = ordersData.first;

    final orderNumbers = ordersData
        .map((data) => (data['orderNumber'] ?? '').toString())
        .toList();

    final clientType = (primaryData['clientType'] ?? '').toString();

    final paymentRef = _paymentsRef(establishmentId: establishmentId).doc();

    final batch = _firestore.batch();

    if (method == 'room') {
      final roomExtraRef = _roomExtrasRef(
        establishmentId: establishmentId,
      ).doc();

      batch.set(roomExtraRef, {
        'establishmentId': establishmentId,
        'roomNumber': primaryData['roomNumber']?.toString() ?? '',
        'amount': amount,
        'ticketId': ticketId,
        'orderId': ids.first,
        'orderNumber': orderNumbers.first,
        'orderIds': ids,
        'orderNumbers': orderNumbers,
        'createdBy': receivedBy,
        'createdByName': receivedByName,
        'createdAt': FieldValue.serverTimestamp(),
        'pendingSync': false,
        'syncError': false,
      });
    }

    batch.set(paymentRef, {
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
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,
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
      batch.update(orderRef, {
        'paymentStatus': 'paid',
        'status': 'paid',
        'paymentId': paymentRef.id,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'pendingSync': false,
        'syncError': false,
      });
    }

    await batch.commit();
  }
}
