import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/services/store_stock_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreStockService _storeStockService = StoreStockService();

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

  Future<void> createOrder({
    required String establishmentId,
    required String clientType,
    required String? tableNumber,
    required String? roomNumber,

    /// Fiche client rattachée. Optionnel : chaîne vide = non rattachée.
    String clientId = '',
    required String createdBy,
    required String createdByName,
    required double subtotal,
    required double tax,
    required double total,
    required List<OrderItemModel> items,
  }) async {
    final now = DateTime.now();

    final orderNumber =
        'CMD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch}';

    final docRef = _ordersRef(establishmentId).doc();
    final batch = _firestore.batch();

    bool isForKitchen = false;
    bool isForBar = false;

    final Map<String, Map<String, dynamic>> aggregatedDeductions = {};

    for (final item in items) {
      final itemMap = item.toMap();

      final targetDepartment = (itemMap['targetDepartment'] ?? '')
          .toString()
          .toLowerCase();

      final isItemForKitchen =
          targetDepartment == 'kitchen' || targetDepartment == 'cuisine';

      final isItemForBar = targetDepartment == 'bar';

      if (isItemForKitchen) isForKitchen = true;
      if (isItemForBar) isForBar = true;

      final menuItemId = (itemMap['menuItemId'] ?? '').toString();

      if (menuItemId.isEmpty) {
        throw Exception(
          'Chaque article commandé doit contenir menuItemId pour permettre la déduction du stock.',
        );
      }

      final menuSnap = await _menuItemsRef(
        establishmentId,
      ).doc(menuItemId).get();

      if (!menuSnap.exists || menuSnap.data() == null) {
        throw Exception('Article menu introuvable : $menuItemId');
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      if (menuItem.ingredients.isEmpty) {
        throw Exception(
          'L’article "${menuItem.name}" n’a pas de recette définie.',
        );
      }

      final orderedQuantity = (itemMap['quantity'] as num?)?.toDouble() ?? 0;

      if (orderedQuantity <= 0) {
        throw Exception('Quantité invalide pour l’article "${menuItem.name}".');
      }

      for (final ingredient in menuItem.ingredients) {
        final key =
            '${ingredient.store}_${ingredient.itemId}_${ingredient.unit}';

        if (!aggregatedDeductions.containsKey(key)) {
          aggregatedDeductions[key] = {
            'establishmentId': establishmentId,
            'store': ingredient.store,
            'itemId': ingredient.itemId,
            'itemName': ingredient.itemName,
            'unit': ingredient.unit,
            'quantity': 0.0,
          };
        }

        aggregatedDeductions[key]!['quantity'] =
            ((aggregatedDeductions[key]!['quantity'] as num).toDouble()) +
            (ingredient.quantity * orderedQuantity);
      }
    }

    batch.set(docRef, {
      'establishmentId': establishmentId,
      'orderNumber': orderNumber,
      'clientType': clientType,
      'tableNumber': tableNumber,
      'roomNumber': roomNumber,
      'clientId': clientId.trim(),
      'createdBy': createdBy,
      'createdByName': createdByName,
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
      'stockDeducted': false,
      'stockRestored': false,
      'hasCancelledItems': false,
      'pendingSync': false,
      'syncError': false,
    });

    for (final item in items) {
      final itemRef = docRef.collection('items').doc(item.id);
      batch.set(
        itemRef,
        item.copyWith(establishmentId: establishmentId).toMap(),
      );
    }

    await batch.commit();

    try {
      await _storeStockService.removeStockForOrder(
        establishmentId: establishmentId,
        orderId: docRef.id,
        orderNumber: orderNumber,
        performedBy: createdBy,
        performedByName: createdByName,
        deductions: aggregatedDeductions.values.toList(),
      );

      await docRef.update({
        'stockDeducted': true,
        'stockDeductedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await docRef.update({
        'status': 'stock_error',
        'stockDeducted': false,
        'stockError': e.toString(),
        'stockErrorStack': stack.toString(),
        'syncError': true,
      });

      rethrow;
    }
  }

  Future<void> cancelOrderItems({
    required String establishmentId,
    required String orderId,
    required List<String> orderItemIds,
    required String cancelledBy,
    required String cancelledByName,
    String cancellationReason = '',
  }) async {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final orderRef = _ordersRef(establishmentId).doc(orderId);
    final orderSnap = await orderRef.get();

    if (!orderSnap.exists || orderSnap.data() == null) {
      throw Exception('Commande introuvable.');
    }

    final orderData = Map<String, dynamic>.from(orderSnap.data()!);

    final paymentStatus = (orderData['paymentStatus'] ?? '')
        .toString()
        .toLowerCase();

    if (paymentStatus == 'paid') {
      throw Exception(
        'Impossible d’annuler des articles d’une commande déjà encaissée.',
      );
    }

    final itemsSnap = await orderRef.collection('items').get();

    if (itemsSnap.docs.isEmpty) {
      throw Exception('Aucun article trouvé dans cette commande.');
    }

    final orderItems = itemsSnap.docs.map((doc) {
      return OrderItemModel.fromMap(doc.data(), id: doc.id);
    }).toList();

    final selectedItems = orderItems
        .where((item) => orderItemIds.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) {
      throw Exception('Aucun article sélectionné pour annulation.');
    }

    final kitchenStatus = (orderData['kitchenStatus'] ?? '').toString();
    final barStatus = (orderData['barStatus'] ?? '').toString();

    final Map<String, Map<String, dynamic>> aggregatedRestitutions = {};

    for (final item in selectedItems) {
      if (item.isCancelled) {
        throw Exception('L’article "${item.name}" est déjà annulé.');
      }

      final target = item.targetDepartment.toLowerCase();

      final isKitchenItem = target == 'kitchen' || target == 'cuisine';
      final isBarItem = target == 'bar';

      if (isKitchenItem &&
          (kitchenStatus == 'ready' || kitchenStatus == 'served')) {
        throw Exception(
          'Impossible d’annuler "${item.name}" : la cuisine est déjà prête ou servie.',
        );
      }

      if (isBarItem && (barStatus == 'ready' || barStatus == 'served')) {
        throw Exception(
          'Impossible d’annuler "${item.name}" : le bar est déjà prêt ou servi.',
        );
      }

      final menuSnap = await _menuItemsRef(
        establishmentId,
      ).doc(item.menuItemId).get();

      if (!menuSnap.exists || menuSnap.data() == null) {
        throw Exception(
          'Article menu introuvable pour annulation : ${item.menuItemId}',
        );
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      if (menuItem.ingredients.isEmpty) {
        throw Exception(
          'Impossible d’annuler : l’article "${menuItem.name}" n’a pas de recette définie.',
        );
      }

      final orderedQuantity = item.quantity.toDouble();

      for (final ingredient in menuItem.ingredients) {
        final key =
            '${ingredient.store}_${ingredient.itemId}_${ingredient.unit}';

        if (!aggregatedRestitutions.containsKey(key)) {
          aggregatedRestitutions[key] = {
            'establishmentId': establishmentId,
            'store': ingredient.store,
            'itemId': ingredient.itemId,
            'itemName': ingredient.itemName,
            'unit': ingredient.unit,
            'quantity': 0.0,
          };
        }

        aggregatedRestitutions[key]!['quantity'] =
            toDouble(aggregatedRestitutions[key]!['quantity']) +
            (ingredient.quantity * orderedQuantity);
      }
    }

    final stockDeducted = orderData['stockDeducted'] == true;

    if (stockDeducted) {
      await _storeStockService.restoreStockForCancelledOrder(
        establishmentId: establishmentId,
        orderId: orderId,
        orderNumber: (orderData['orderNumber'] ?? '').toString(),
        performedBy: cancelledBy,
        performedByName: cancelledByName,
        restitutions: aggregatedRestitutions.values.toList(),
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
      'stockRestored': refreshedItems.any((item) => item.isCancelled),
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
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final orderRef = _ordersRef(establishmentId).doc(orderId);
    final orderSnap = await orderRef.get();

    if (!orderSnap.exists || orderSnap.data() == null) {
      throw Exception('Commande introuvable.');
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
      throw Exception('Cette commande est déjà annulée.');
    }

    if (stockRestored) {
      throw Exception('Le stock de cette commande a déjà été restitué.');
    }

    if (paymentStatus.toLowerCase() == 'paid') {
      throw Exception('Impossible d’annuler une commande déjà encaissée.');
    }

    if (isForKitchen &&
        (kitchenStatus == 'ready' || kitchenStatus == 'served')) {
      throw Exception(
        'Impossible d’annuler : la partie cuisine est déjà prête ou servie.',
      );
    }

    if (isForBar && (barStatus == 'ready' || barStatus == 'served')) {
      throw Exception(
        'Impossible d’annuler : la partie bar est déjà prête ou servie.',
      );
    }

    final itemsSnap = await orderRef.collection('items').get();

    if (itemsSnap.docs.isEmpty) {
      throw Exception('Cette commande ne contient aucun article.');
    }

    final items = itemsSnap.docs
        .map((doc) => OrderItemModel.fromMap(doc.data(), id: doc.id))
        .toList();

    final Map<String, Map<String, dynamic>> aggregatedRestitutions = {};

    for (final item in items) {
      final menuItemId = item.menuItemId;

      if (menuItemId.isEmpty) {
        throw Exception(
          'Impossible d’annuler : menuItemId manquant pour un article.',
        );
      }

      final menuSnap = await _menuItemsRef(
        establishmentId,
      ).doc(menuItemId).get();

      if (!menuSnap.exists || menuSnap.data() == null) {
        throw Exception(
          'Article menu introuvable pour annulation : $menuItemId',
        );
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      if (menuItem.ingredients.isEmpty) {
        throw Exception(
          'Impossible d’annuler : l’article "${menuItem.name}" n’a pas de recette définie.',
        );
      }

      final orderedQuantity = toDouble(item.quantity);

      if (orderedQuantity <= 0) {
        throw Exception(
          'Quantité invalide dans la commande pour "${menuItem.name}".',
        );
      }

      for (final ingredient in menuItem.ingredients) {
        final key =
            '${ingredient.store}_${ingredient.itemId}_${ingredient.unit}';

        if (!aggregatedRestitutions.containsKey(key)) {
          aggregatedRestitutions[key] = {
            'establishmentId': establishmentId,
            'store': ingredient.store,
            'itemId': ingredient.itemId,
            'itemName': ingredient.itemName,
            'unit': ingredient.unit,
            'quantity': 0.0,
          };
        }

        aggregatedRestitutions[key]!['quantity'] =
            toDouble(aggregatedRestitutions[key]!['quantity']) +
            (ingredient.quantity * orderedQuantity);
      }
    }

    if (stockDeducted) {
      await _storeStockService.restoreStockForCancelledOrder(
        establishmentId: establishmentId,
        orderId: orderId,
        orderNumber: orderNumber,
        performedBy: cancelledBy,
        performedByName: cancelledByName,
        restitutions: aggregatedRestitutions.values.toList(),
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
      throw Exception('Établissement introuvable.');
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
