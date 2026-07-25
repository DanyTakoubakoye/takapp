import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:takapp/modeles/kitchen_order_model.dart';
import 'package:takapp/modeles/order_item_model.dart';

class CuisineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  /// =========================
  /// HELPERS
  /// =========================

  CollectionReference<Map<String, dynamic>> _ordersRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders');
  }

  /// =========================
  /// STREAM COMMANDES CUISINE
  /// =========================

  Stream<List<KitchenOrderModel>> streamKitchenOrders({
    required String establishmentId,
  }) {
    return _ordersRef(establishmentId: establishmentId)
        .where('isForKitchen', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => KitchenOrderModel.fromMap(doc.data(), doc.id))
              .where((order) {
                return order.kitchenStatus != 'cancelled' &&
                    order.kitchenStatus != 'served';
              })
              .toList();
        });
  }

  /// =========================
  /// ITEMS D’UNE COMMANDE
  /// =========================

  Future<List<OrderItemModel>> getKitchenItemsForOrder({
    required String establishmentId,
    required String orderId,
  }) async {
    final snapshot = await _ordersRef(establishmentId: establishmentId)
        .doc(orderId)
        .collection('items')
        .where('targetDepartment', whereIn: ['kitchen', 'cuisine'])
        .get();

    return snapshot.docs.map((doc) {
      return OrderItemModel.fromMap(doc.data(), id: doc.id);
    }).toList();
  }

  /// =========================
  /// UPDATE STATUS CUISINE
  /// =========================

  Future<void> updateKitchenStatus({
    required String establishmentId,
    required String orderId,
    required String newKitchenStatus,
  }) async {
    final orderRef = _ordersRef(establishmentId: establishmentId).doc(orderId);

    final updates = <String, dynamic>{
      'kitchenStatus': newKitchenStatus,

      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newKitchenStatus == 'ready') {
      updates['status'] = 'ready';
    } else if (newKitchenStatus == 'preparing') {
      updates['status'] = 'preparing';
    } else if (newKitchenStatus == 'pending') {
      updates['status'] = 'sent';
    } else if (newKitchenStatus == 'served') {
      updates['status'] = 'served';
    }

    await orderRef.update(updates);

    /// =========================
    /// NOTIFICATION CUISINE
    /// =========================

    if (newKitchenStatus == 'ready') {
      debugPrint(
        'APPEL notifyKitchenReady '
        'pour orderId=$orderId '
        'establishmentId=$establishmentId',
      );

      final callable = _functions.httpsCallable('notifyKitchenReady');

      await callable.call({
        'orderId': orderId,

        'establishmentId': establishmentId,
      });
    }
  }
}
