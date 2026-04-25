import 'package:cloud_firestore/cloud_firestore.dart';

class BarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBarOrders() {
    return _firestore
        .collection('orders')
        .where('isForBar', isEqualTo: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getBarItemsForOrder(String orderId) async {
    final snapshot = await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).where((
      item,
    ) {
      final targetDepartment = (item['targetDepartment'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final isCancelled = item['isCancelled'] == true;

      return targetDepartment == 'bar' && !isCancelled;
    }).toList();
  }

  Future<void> updateBarStatus({
    required String orderId,
    required String newBarStatus,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'barStatus': newBarStatus,
    });
  }
}
