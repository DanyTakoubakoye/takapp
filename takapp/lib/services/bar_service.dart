import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  /// Helper : référence vers la sous-collection orders du tenant
  CollectionReference<Map<String, dynamic>> _ordersRef(String establishmentId) {
    if (establishmentId.isEmpty) {
      throw Exception('Établissement introuvable.');
    }
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBarOrders({
    required String establishmentId,
  }) {
    return _ordersRef(establishmentId)
        .where('isForBar', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getBarItemsForOrder({
    required String establishmentId,
    required String orderId,
  }) async {
    final orderDoc = await _ordersRef(establishmentId).doc(orderId).get();

    if (!orderDoc.exists) {
      return [];
    }

    final snapshot = await _ordersRef(establishmentId)
        .doc(orderId)
        .collection('items')
        .where('targetDepartment', isEqualTo: 'bar')
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((item) => item['isCancelled'] != true)
        .toList();
  }

  Future<void> updateBarStatus({
    required String establishmentId,
    required String orderId,
    required String newBarStatus,
  }) async {
    final orderRef = _ordersRef(establishmentId).doc(orderId);
    final orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      throw Exception('Commande introuvable.');
    }

    final updates = <String, dynamic>{
      'barStatus': newBarStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newBarStatus == 'ready') {
      updates['status'] = 'ready';
    } else if (newBarStatus == 'preparing') {
      updates['status'] = 'preparing';
    } else if (newBarStatus == 'pending') {
      updates['status'] = 'sent';
    } else if (newBarStatus == 'served') {
      updates['status'] = 'served';
    }

    await orderRef.update(updates);

    if (newBarStatus == 'ready') {
      final callable = _functions.httpsCallable('notifyBarReady');
      await callable.call({
        'establishmentId': establishmentId,
        'orderId': orderId,
      });
    }
  }
}
