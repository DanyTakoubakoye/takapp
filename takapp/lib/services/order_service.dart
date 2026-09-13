import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/services/store_stock_service.dart';

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

    final ticket = await _resolveTicket(
      establishmentId: establishmentId,
      clientType: clientType,
      tableNumber: tableNumber,
      roomNumber: roomNumber,
      fallbackId: docRef.id,
    );

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
        throw AppError(AppErrorCode.menuItemNotFound, name: menuItemId);
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      if (menuItem.ingredients.isEmpty) {
        throw AppError(AppErrorCode.noRecipeDefined, name: menuItem.name);
      }

      final orderedQuantity = (itemMap['quantity'] as num?)?.toDouble() ?? 0;

      if (orderedQuantity <= 0) {
        throw AppError(
          AppErrorCode.invalidQuantityForItem,
          name: menuItem.name,
        );
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
      'ticketId': ticket.ticketId,
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

    for (final orphanOrderId in ticket.orphanOrderIds) {
      batch.update(_ordersRef(establishmentId).doc(orphanOrderId), {
        'ticketId': ticket.ticketId,
      });
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

    final Map<String, Map<String, dynamic>> aggregatedRestitutions = {};

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
        throw AppError(
          AppErrorCode.cannotCancelItemBarReady,
          name: item.name,
        );
      }

      final menuSnap = await _menuItemsRef(
        establishmentId,
      ).doc(item.menuItemId).get();

      if (!menuSnap.exists || menuSnap.data() == null) {
        throw AppError(
          AppErrorCode.menuItemNotFound,
          name: item.menuItemId,
        );
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      if (menuItem.ingredients.isEmpty) {
        throw AppError(AppErrorCode.noRecipeDefined, name: menuItem.name);
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
        throw AppError(AppErrorCode.menuItemNotFound, name: menuItemId);
      }

      final menuItem = MenuItemModel.fromMap(menuSnap.data()!, menuSnap.id);

      if (menuItem.ingredients.isEmpty) {
        throw AppError(AppErrorCode.noRecipeDefined, name: menuItem.name);
      }

      final orderedQuantity = toDouble(item.quantity);

      if (orderedQuantity <= 0) {
        throw AppError(
          AppErrorCode.invalidQuantityInOrder,
          name: menuItem.name,
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
