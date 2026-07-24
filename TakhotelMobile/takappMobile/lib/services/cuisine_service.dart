import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:takapp/modeles/kitchen_order_model.dart';
import 'package:takapp/modeles/order_item_model.dart';

class CuisineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Stream<List<KitchenOrderModel>> streamKitchenOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => KitchenOrderModel.fromMap(doc.data(), doc.id))
              .where((order) => order.isForKitchen)
              .toList();
        });
  }

  Future<List<OrderItemModel>> getKitchenItemsForOrder(String orderId) async {
    final snapshot = await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .where('targetDepartment', isEqualTo: 'kitchen')
        .get();

    return snapshot.docs
        .map((doc) => OrderItemModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateKitchenStatus({
    required String orderId,
    required String newKitchenStatus,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    final updates = <String, dynamic>{'kitchenStatus': newKitchenStatus};

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

    if (newKitchenStatus == 'ready') {
      print('APPEL notifyKitchenReady pour orderId=$orderId');
      final callable = _functions.httpsCallable('notifyKitchenReady');
      await callable.call({'orderId': orderId});
    }
  }
}
