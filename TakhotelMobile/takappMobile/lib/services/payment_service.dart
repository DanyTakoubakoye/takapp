import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/order_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> streamUnpaidOrdersForServer(String serveurId) {
    return _firestore
        .collection('orders')
        .where('createdBy', isEqualTo: serveurId)
        .where('paymentStatus', isEqualTo: 'unpaid')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> registerPayment({
    required String orderId,
    required String orderNumber,
    required String receivedBy,
    required String receivedByName,
    required String method,
    required double amount,
    double? roomNumber,
  }) async {
    /// 🔥 VERIFICATION CUISINE (À AJOUTER ICI)
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();

    if (method == 'room') {
      await _firestore.collection('roomExtras').add({
        'roomNumber': roomNumber,
        'amount': amount,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (!orderDoc.exists || orderDoc.data() == null) {
      throw Exception("Commande introuvable");
    }

    final orderData = orderDoc.data()!;

    if (orderData['isForKitchen'] == true &&
        orderData['kitchenStatus'] != 'ready' &&
        orderData['kitchenStatus'] != 'served') {
      throw Exception("Commande cuisine non prête");
    }

    /// 🔽 SUITE NORMALE
    final paymentRef = _firestore.collection('payments').doc();
    final orderRef = _firestore.collection('orders').doc(orderId);

    final batch = _firestore.batch();

    batch.set(paymentRef, {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,
      'method': method,
      'amount': amount,
      'status': 'confirmed',
      'handoverStatus': 'pending',
      'handoverId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(orderRef, {
      'paymentStatus': 'paid',
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
