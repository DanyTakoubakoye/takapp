import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/stock_mode.dart';
import 'package:takapp/services/order_actor_verifier.dart';
import 'package:takapp/services/order_stock_policy.dart';
import 'package:takapp/services/store_stock_service.dart';

/// Commande réellement acceptée et écrite.
class OrderCreationResult {
  final String orderId;
  final String orderNumber;
  final StockMode stockMode;

  /// Anomalies acceptées en warningOnly (vide sinon) : l'UI doit les montrer.
  final List<StockAnomaly> stockWarnings;

  const OrderCreationResult({
    required this.orderId,
    required this.orderNumber,
    required this.stockMode,
    this.stockWarnings = const [],
  });

  bool get hasStockWarnings => stockWarnings.isNotEmpty;
}

/// Résultat du rattachement d'une commande à une addition.
class _TicketResolution {
  final String ticketId;

  /// Commandes ouvertes de la même table / chambre créées avant l'introduction
  /// des additions : elles doivent être rattachées au même ticket.
  final List<String> orphanOrderIds;

  const _TicketResolution({
    required this.ticketId,
    required this.orphanOrderIds,
  });
}

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreStockService _storeStockService = StoreStockService();

  /// UID Firebase Auth de la session : seule source de l'auteur réel.
  final String? Function() _currentUserId;

  OrderService({String? Function()? currentUserId})
    : _currentUserId =
          currentUserId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  CollectionReference<Map<String, dynamic>> _ordersRef(String establishmentId) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders');
  }

  CollectionReference<Map<String, dynamic>> _menuItemsRef(
    String establishmentId,
  ) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('menuItems');
  }

  /// =========================
  /// ADDITIONS (TICKETS)
  /// =========================

  /// Référence de l'addition : la chambre pour l'hôtel, la table pour le
  /// restaurant. Vide pour le bar : chaque commande y reste une facture à part.
  String _ticketReference({
    required String clientType,
    String? tableNumber,
    String? roomNumber,
  }) {
    final type = clientType.trim().toLowerCase();

    if (type == 'hotel') return (roomNumber ?? '').trim();

    if (type == 'restaurant') return (tableNumber ?? '').trim();

    return '';
  }

  String _newTicketId({
    required String clientType,
    required String reference,
    required String fallbackId,
  }) {
    final slug = reference.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

    if (slug.isEmpty) return 'TCK-$fallbackId';

    return 'TCK-${clientType.trim().toUpperCase()}-$slug-$fallbackId';
  }

  /// Détermine l'addition à laquelle rattacher une nouvelle commande.
  ///
  /// Si la table / la chambre a déjà une commande non encaissée, la nouvelle
  /// commande rejoint la même addition. Sinon une nouvelle addition est ouverte.
  ///
  /// Requête sur un seul champ + filtrage côté client : aucun index composite
  /// Firestore requis (convention du projet).
  Future<_TicketResolution> _resolveTicket({
    required String establishmentId,
    required String clientType,
    required String? tableNumber,
    required String? roomNumber,
    required String fallbackId,
  }) async {
    final type = clientType.trim().toLowerCase();

    final reference = _ticketReference(
      clientType: type,
      tableNumber: tableNumber,
      roomNumber: roomNumber,
    );

    if (reference.isEmpty) {
      return _TicketResolution(
        ticketId: _newTicketId(
          clientType: type,
          reference: reference,
          fallbackId: fallbackId,
        ),
        orphanOrderIds: const [],
      );
    }

    final snapshot = await _ordersRef(
      establishmentId,
    ).where('paymentStatus', isEqualTo: 'unpaid').get();

    final openOrders =
        snapshot.docs.where((doc) {
          final data = doc.data();

          if ((data['status'] ?? '').toString().toLowerCase() == 'cancelled') {
            return false;
          }

          if ((data['clientType'] ?? '').toString().trim().toLowerCase() !=
              type) {
            return false;
          }

          return _ticketReference(
                clientType: type,
                tableNumber: data['tableNumber']?.toString(),
                roomNumber: data['roomNumber']?.toString(),
              ) ==
              reference;
        }).toList()..sort((a, b) {
          final aDate = a.data()['createdAt'];
          final bDate = b.data()['createdAt'];

          final aMillis = aDate is Timestamp
              ? aDate.millisecondsSinceEpoch
              : 1 << 62;

          final bMillis = bDate is Timestamp
              ? bDate.millisecondsSinceEpoch
              : 1 << 62;

          return bMillis.compareTo(aMillis);
        });

    final existingTicketId = openOrders
        .map((doc) => (doc.data()['ticketId'] ?? '').toString().trim())
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');

    // Commandes ouvertes antérieures aux additions : on les rattache au ticket.
    final orphanOrderIds = openOrders
        .where(
          (doc) => (doc.data()['ticketId'] ?? '').toString().trim().isEmpty,
        )
        .map((doc) => doc.id)
        .toList();

    return _TicketResolution(
      ticketId: existingTicketId.isNotEmpty
          ? existingTicketId
          : _newTicketId(
              clientType: type,
              reference: reference,
              fallbackId: fallbackId,
            ),
      orphanOrderIds: orphanOrderIds,
    );
  }

  Future<StockMode> _fetchStockMode(String establishmentId) async {
    final snapshot = await _firestore
        .collection('establishments')
        .doc(establishmentId)
        .get();

    return StockMode.fromValue(snapshot.data()?['stockMode']);
  }

  /// =========================
  /// CRÉATION DE COMMANDE
  /// =========================
  ///
  /// Moteur unique de création de commande. Le `stockMode` de l'établissement
  /// est lu ici (couche métier) et appliqué par [OrderStockPolicy] ; aucun
  /// widget n'a à le connaître.
  ///
  /// Garanties côté client :
  /// - la commande, ses lignes, les déductions et les mouvements de stock
  ///   sont écrits dans UNE transaction : plus de commande `stock_error`
  ///   créée puis laissée en plan ;
  /// - un refus (strict) n'écrit RIEN : aucune commande n'existe, donc la
  ///   Cloud Function `notifyDepartmentsNewOrder` (onDocumentCreated) ne
  ///   notifie ni la cuisine ni le bar ;
  /// - le stock est relu dans la transaction : deux commandes concurrentes ne
  ///   peuvent pas consommer deux fois la même quantité.
  ///
  /// Limites connues (client, pas de backend autoritaire) :
  /// - `stockMode`, les recettes et les références de stock sont lus juste
  ///   AVANT la transaction (les requêtes y sont interdites côté client) ;
  ///   un changement de mode ou de recette pendant ces quelques ms n'est pas
  ///   détecté ;
  /// - les règles Firestore ne vérifient pas la cohérence commande / stock.
  ///
  /// TODO(cloud-functions): déplacer ce flux dans `createOrderAndDeductStock`
  /// (callable, Admin SDK) : lecture de `stockMode` et des recettes côté
  /// serveur, transaction unique, puis interdire `create` sur `orders` et
  /// `update` sur `store_stocks` depuis le client pour les serveurs.
  Future<OrderCreationResult> createOrder({
    required String establishmentId,
    required String clientType,
    required String? tableNumber,
    required String? roomNumber,

    /// Fiche client rattachée. Optionnel : chaîne vide = non rattachée.
    String clientId = '',

    /// Qui saisit, et pour quel serveur (voir [OrderActorContext]).
    required OrderActorContext actor,
    required double subtotal,
    required double tax,
    required double total,
    required List<OrderItemModel> items,
  }) async {
    // 0. L'acteur avant tout : rien n'est lu ni écrit pour un acteur refusé.
    await _validateActor(establishmentId, actor);

    final now = DateTime.now();

    final orderNumber =
        'CMD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch}';

    final docRef = _ordersRef(establishmentId).doc();

    bool isForKitchen = false;
    bool isForBar = false;

    // 1. Lignes de commande + recettes en vigueur.
    final List<OrderLineRecipe> lines = [];

    for (final item in items) {
      final targetDepartment = item.targetDepartment.toLowerCase();

      if (targetDepartment == 'kitchen' || targetDepartment == 'cuisine') {
        isForKitchen = true;
      }

      if (targetDepartment == 'bar') isForBar = true;

      if (item.menuItemId.isEmpty) {
        throw const AppError(AppErrorCode.menuItemIdRequired);
      }

      final menuSnap = await _menuItemsRef(
        establishmentId,
      ).doc(item.menuItemId).get();

      if (!menuSnap.exists || menuSnap.data() == null) {
        throw AppError(AppErrorCode.menuItemNotFound, name: item.menuItemId);
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      final orderedQuantity = item.quantity.toDouble();

      if (orderedQuantity <= 0) {
        throw AppError(
          AppErrorCode.invalidQuantityForItem,
          name: menuItem.name,
        );
      }

      lines.add(
        OrderLineRecipe(
          menuItemName: menuItem.name,
          orderedQuantity: orderedQuantity,
          ingredients: menuItem.ingredients,
        ),
      );
    }

    // 2. Besoins en stock selon le mode (aucun en mode désactivé).
    final stockMode = await _fetchStockMode(establishmentId);

    final requirements = stockMode == StockMode.disabled
        ? const StockRequirements(requirements: [], recipeAnomalies: [])
        : OrderStockPolicy.computeRequirements(lines);

    final Map<String, DocumentReference<Map<String, dynamic>>> stockRefs = {};

    for (final requirement in requirements.requirements) {
      final ref = await _storeStockService.findStockRef(
        establishmentId: establishmentId,
        store: requirement.store,
        itemId: requirement.itemId,
      );

      if (ref != null) stockRefs[requirement.key] = ref;
    }

    final ticket = await _resolveTicket(
      establishmentId: establishmentId,
      clientType: clientType,
      tableNumber: tableNumber,
      roomNumber: roomNumber,
      fallbackId: docRef.id,
    );

    // 3. Décision + écritures, atomiquement.
    //
    // Sur Flutter web, un `throw` dans runTransaction est "boxé" (message
    // perdu) : on capture le plan et on lève le refus APRÈS la transaction.
    OrderStockPlan? decidedPlan;

    await _firestore.runTransaction((transaction) async {
      final Map<String, StockLevel?> levels = {};

      for (final entry in stockRefs.entries) {
        levels[entry.key] = await _storeStockService.readStockLevel(
          transaction,
          entry.value,
        );
      }

      final plan = OrderStockPolicy.evaluate(
        mode: stockMode,
        requirements: requirements,
        levels: levels,
      );

      decidedPlan = plan;

      // Refus : rien n'est écrit, aucune commande n'existe.
      if (!plan.isAccepted) return;

      final stockDeducted = plan.deductions.isNotEmpty;

      transaction.set(docRef, {
        'establishmentId': establishmentId,
        'orderNumber': orderNumber,
        'ticketId': ticket.ticketId,
        'clientType': clientType,
        'tableNumber': tableNumber,
        'roomNumber': roomNumber,
        'clientId': clientId.trim(),
        // createdBy (= serveur responsable pendant la transition),
        // performedBy*, assignedServer*, shiftId.
        ...actor.toOrderFields(),
        'status': 'sent',
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'isForKitchen': isForKitchen,
        'kitchenStatus': isForKitchen ? 'pending' : 'ready',
        'isForBar': isForBar,
        'barStatus': isForBar ? 'pending' : 'ready',
        'stockMode': stockMode.value,
        'stockStatus': plan.stockStatus,
        'stockDeducted': stockDeducted,
        if (stockDeducted) 'stockDeductedAt': FieldValue.serverTimestamp(),
        'stockDeductedKeys': plan.deductedKeys,
        'stockAnomalies': plan.anomalies.map((a) => a.toMap()).toList(),
        'hasStockAnomaly': plan.anomalies.isNotEmpty,
        'stockRestored': false,
        'hasCancelledItems': false,
        'pendingSync': false,
        'syncError': false,
      });

      for (final item in items) {
        transaction.set(
          docRef.collection('items').doc(item.id),
          item.copyWith(establishmentId: establishmentId).toMap(),
        );
      }

      for (final orphanOrderId in ticket.orphanOrderIds) {
        transaction.update(_ordersRef(establishmentId).doc(orphanOrderId), {
          'ticketId': ticket.ticketId,
        });
      }

      _storeStockService.writeOrderDeductions(
        transaction,
        establishmentId: establishmentId,
        orderId: docRef.id,
        orderNumber: orderNumber,
        // Audit du stock : l'auteur RÉEL de la saisie.
        performedBy: actor.performedByUserId,
        performedByName: actor.performedByUserName,
        deductions: plan.deductions,
        stockRefs: stockRefs,
      );
    });

    final plan = decidedPlan;

    if (plan == null) throw const AppError(AppErrorCode.unknown);

    final refusal = plan.refusal;

    if (refusal != null) throw refusal;

    return OrderCreationResult(
      orderId: docRef.id,
      orderNumber: orderNumber,
      stockMode: stockMode,
      stockWarnings: plan.anomalies,
    );
  }

  /// Défense côté client de l'acteur (voir [OrderActorVerifier]) : l'auteur
  /// réel doit être l'UID authentifié, et un Floor Manager ne peut saisir
  /// que dans SON service ouvert, pour lui-même ou pour un serveur présent.
  /// L'autorité reste firestore.rules (`validOrderActor`).
  Future<void> _validateActor(
    String establishmentId,
    OrderActorContext actor,
  ) async {
    await OrderActorVerifier(
      _firestore,
      _currentUserId,
    ).verify(establishmentId, actor);
  }

  /// =========================
  /// RESTITUTION A L'ANNULATION
  /// =========================
  ///
  /// Quantités à remettre en stock pour des lignes annulées :
  /// - commande sans déduction (mode désactivé, ancienne `stock_error`,
  ///   warningOnly sans rien de déductible) : rien, et la recette n'est même
  ///   pas relue — une recette absente ne bloque donc pas l'annulation ;
  /// - commande récente : seules les clés de `stockDeductedKeys` sont
  ///   restituées (en warningOnly, un ingrédient manquant n'a jamais été
  ///   retiré, il ne doit pas être « rendu ») ;
  /// - ancienne commande (champ absent) : comportement historique, toute la
  ///   recette est restituée.
  ///
  /// La recette relue est celle du moment de l'annulation (limite
  /// historique). TODO(cloud-functions): restituer à partir des mouvements
  /// `stock_movements` liés à `orderId` plutôt que de la recette courante.
  Future<List<Map<String, dynamic>>> _restitutionsFor({
    required String establishmentId,
    required Map<String, dynamic> orderData,
    required List<OrderItemModel> items,
  }) async {
    if (orderData['stockDeducted'] != true) return const [];

    final rawKeys = orderData['stockDeductedKeys'];

    final Set<String>? deductedKeys = rawKeys is List
        ? rawKeys.map((key) => key.toString()).toSet()
        : null;

    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final item in items) {
      if (item.menuItemId.isEmpty) {
        throw const AppError(AppErrorCode.menuItemIdMissingForCancel);
      }

      final menuSnap = await _menuItemsRef(
        establishmentId,
      ).doc(item.menuItemId).get();

      if (!menuSnap.exists || menuSnap.data() == null) {
        throw AppError(AppErrorCode.menuItemNotFound, name: item.menuItemId);
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      if (menuItem.ingredients.isEmpty) {
        // Commande récente : plat accepté sans recette en warningOnly.
        if (deductedKeys != null) continue;
        throw AppError(AppErrorCode.noRecipeDefined, name: menuItem.name);
      }

      final orderedQuantity = item.quantity.toDouble();

      if (orderedQuantity <= 0) {
        throw AppError(
          AppErrorCode.invalidQuantityInOrder,
          name: menuItem.name,
        );
      }

      for (final ingredient in menuItem.ingredients) {
        final key = OrderStockPolicy.ingredientKey(
          store: ingredient.store,
          itemId: ingredient.itemId,
          unit: ingredient.unit,
        );

        if (deductedKeys != null && !deductedKeys.contains(key)) continue;

        final entry = aggregated.putIfAbsent(
          key,
          () => {
            'establishmentId': establishmentId,
            'store': ingredient.store,
            'itemId': ingredient.itemId,
            'itemName': ingredient.itemName,
            'unit': ingredient.unit,
            'quantity': 0.0,
          },
        );

        entry['quantity'] =
            (entry['quantity'] as double) +
            (ingredient.quantity * orderedQuantity);
      }
    }

    return aggregated.values.toList();
  }

  Future<void> cancelOrderItems({
    required String establishmentId,
    required String orderId,
    required List<String> orderItemIds,
    required String cancelledBy,
    required String cancelledByName,
    String cancellationReason = '',
  }) async {
    final orderRef = _ordersRef(establishmentId).doc(orderId);
    final orderSnap = await orderRef.get();

    if (!orderSnap.exists || orderSnap.data() == null) {
      throw const AppError(AppErrorCode.orderNotFound);
    }

    final orderData = Map<String, dynamic>.from(orderSnap.data()!);

    final paymentStatus = (orderData['paymentStatus'] ?? '')
        .toString()
        .toLowerCase();

    if (paymentStatus == 'paid') {
      throw const AppError(AppErrorCode.cannotCancelPaidOrderItems);
    }

    final itemsSnap = await orderRef.collection('items').get();

    if (itemsSnap.docs.isEmpty) {
      throw const AppError(AppErrorCode.noItemsFoundInOrder);
    }

    final orderItems = itemsSnap.docs.map((doc) {
      return OrderItemModel.fromMap(doc.data(), id: doc.id);
    }).toList();

    final selectedItems = orderItems
        .where((item) => orderItemIds.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) {
      throw const AppError(AppErrorCode.noItemSelectedForCancellation);
    }

    final kitchenStatus = (orderData['kitchenStatus'] ?? '').toString();
    final barStatus = (orderData['barStatus'] ?? '').toString();

    for (final item in selectedItems) {
      if (item.isCancelled) {
        throw AppError(AppErrorCode.itemAlreadyCancelled, name: item.name);
      }

      final target = item.targetDepartment.toLowerCase();

      final isKitchenItem = target == 'kitchen' || target == 'cuisine';
      final isBarItem = target == 'bar';

      if (isKitchenItem &&
          (kitchenStatus == 'ready' || kitchenStatus == 'served')) {
        throw AppError(
          AppErrorCode.cannotCancelItemKitchenReady,
          name: item.name,
        );
      }

      if (isBarItem && (barStatus == 'ready' || barStatus == 'served')) {
        throw AppError(AppErrorCode.cannotCancelItemBarReady, name: item.name);
      }
    }

    final stockDeducted = orderData['stockDeducted'] == true;

    final restitutions = await _restitutionsFor(
      establishmentId: establishmentId,
      orderData: orderData,
      items: selectedItems,
    );

    if (restitutions.isNotEmpty) {
      await _storeStockService.restoreStockForCancelledOrder(
        establishmentId: establishmentId,
        orderId: orderId,
        orderNumber: (orderData['orderNumber'] ?? '').toString(),
        performedBy: cancelledBy,
        performedByName: cancelledByName,
        restitutions: restitutions,
      );
    }

    final batch = _firestore.batch();

    for (final item in selectedItems) {
      final itemRef = orderRef.collection('items').doc(item.id);

      batch.update(itemRef, {
        'isCancelled': true,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': cancelledBy,
        'cancelledByName': cancelledByName,
        'cancellationReason': cancellationReason,
      });
    }

    await batch.commit();

    final refreshedItemsSnap = await orderRef.collection('items').get();

    final refreshedItems = refreshedItemsSnap.docs
        .map((doc) => OrderItemModel.fromMap(doc.data(), id: doc.id))
        .toList();

    final activeItems = refreshedItems
        .where((item) => !item.isCancelled)
        .toList();

    final activeKitchenItems = activeItems.where((item) {
      final target = item.targetDepartment.toLowerCase();
      return target == 'kitchen' || target == 'cuisine';
    }).toList();

    final activeBarItems = activeItems.where((item) {
      final target = item.targetDepartment.toLowerCase();
      return target == 'bar';
    }).toList();

    final newSubtotal = activeItems.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );

    final newTax = 0.0;
    final newTotal = newSubtotal + newTax;

    String newStatus;

    if (activeItems.isEmpty) {
      newStatus = 'cancelled';
    } else if (activeItems.length < refreshedItems.length) {
      newStatus = 'partially_cancelled';
    } else {
      newStatus = (orderData['status'] ?? 'sent').toString();
    }

    final Map<String, dynamic> orderUpdate = {
      'subtotal': newSubtotal,
      'tax': newTax,
      'total': newTotal,
      'status': newStatus,
      'hasCancelledItems': refreshedItems.any((item) => item.isCancelled),
      // Sans déduction initiale, rien n'a été restitué : ne pas bloquer une
      // annulation complète ultérieure avec « stock déjà restitué ».
      'stockRestored':
          stockDeducted && refreshedItems.any((item) => item.isCancelled),
      'isForKitchen': activeKitchenItems.isNotEmpty,
      'isForBar': activeBarItems.isNotEmpty,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (activeKitchenItems.isEmpty) {
      orderUpdate['kitchenStatus'] = 'cancelled';
    }

    if (activeBarItems.isEmpty) {
      orderUpdate['barStatus'] = 'cancelled';
    }

    await orderRef.update(orderUpdate);
  }

  Future<void> cancelOrder({
    required String establishmentId,
    required String orderId,
    required String cancelledBy,
    required String cancelledByName,
    String cancellationReason = '',
  }) async {
    final orderRef = _ordersRef(establishmentId).doc(orderId);
    final orderSnap = await orderRef.get();

    if (!orderSnap.exists || orderSnap.data() == null) {
      throw const AppError(AppErrorCode.orderNotFound);
    }

    final orderData = Map<String, dynamic>.from(orderSnap.data()!);

    final orderNumber = (orderData['orderNumber'] ?? '').toString();
    final paymentStatus = (orderData['paymentStatus'] ?? '').toString();
    final status = (orderData['status'] ?? '').toString();

    final stockDeducted = orderData['stockDeducted'] == true;
    final stockRestored = orderData['stockRestored'] == true;

    final isForKitchen = orderData['isForKitchen'] == true;
    final isForBar = orderData['isForBar'] == true;

    final kitchenStatus = (orderData['kitchenStatus'] ?? '').toString();
    final barStatus = (orderData['barStatus'] ?? '').toString();

    if (status == 'cancelled') {
      throw const AppError(AppErrorCode.orderAlreadyCancelled);
    }

    if (stockRestored) {
      throw const AppError(AppErrorCode.stockAlreadyRestored);
    }

    if (paymentStatus.toLowerCase() == 'paid') {
      throw const AppError(AppErrorCode.cannotCancelPaidOrder);
    }

    if (isForKitchen &&
        (kitchenStatus == 'ready' || kitchenStatus == 'served')) {
      throw const AppError(AppErrorCode.cannotCancelKitchenReady);
    }

    if (isForBar && (barStatus == 'ready' || barStatus == 'served')) {
      throw const AppError(AppErrorCode.cannotCancelBarReady);
    }

    final itemsSnap = await orderRef.collection('items').get();

    if (itemsSnap.docs.isEmpty) {
      throw const AppError(AppErrorCode.orderHasNoItems);
    }

    final items = itemsSnap.docs
        .map((doc) => OrderItemModel.fromMap(doc.data(), id: doc.id))
        .toList();

    final restitutions = await _restitutionsFor(
      establishmentId: establishmentId,
      orderData: orderData,
      items: items,
    );

    if (restitutions.isNotEmpty) {
      await _storeStockService.restoreStockForCancelledOrder(
        establishmentId: establishmentId,
        orderId: orderId,
        orderNumber: orderNumber,
        performedBy: cancelledBy,
        performedByName: cancelledByName,
        restitutions: restitutions,
      );
    }

    await orderRef.update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': cancelledBy,
      'cancelledByName': cancelledByName,
      'cancellationReason': cancellationReason,
      'stockRestored': stockDeducted,
      'stockRestoredAt': stockDeducted ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isForKitchen) 'kitchenStatus': 'cancelled',
      if (isForBar) 'barStatus': 'cancelled',
    });
  }

  /// =========================
  /// ORDERS FOR CLIENT
  /// =========================

  /// Commandes rattachées à une fiche client.
  ///
  /// Requête simple `where('clientId')` + tri côté client : aucun index
  /// composite Firestore requis (convention du projet).
  Future<List<OrderModel>> ordersForClient({
    String? establishmentId,
    required String clientId,
  }) async {
    final resolvedEstablishmentId = (establishmentId ?? '').trim();

    if (resolvedEstablishmentId.isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    final cleanClientId = clientId.trim();

    if (cleanClientId.isEmpty) {
      return <OrderModel>[];
    }

    final snapshot = await _ordersRef(
      resolvedEstablishmentId,
    ).where('clientId', isEqualTo: cleanClientId).get();

    final orders = snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .toList();

    // Commande la plus récente en premier.
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }
}
