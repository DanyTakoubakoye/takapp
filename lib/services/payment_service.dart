import 'package:cloud_firestore/cloud_firestore.dart';

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
      throw Exception('Établissement introuvable.');
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
  /// REGISTER PAYMENT
  /// =========================

  Future<void> registerPayment({
    required String establishmentId,
    required String orderId,
    required String orderNumber,
    required String receivedBy,
    required String receivedByName,
    required String method,
    required double amount,
    double? roomNumber,
  }) async {
    _validateEstablishmentId(establishmentId);

    if (orderId.trim().isEmpty) {
      throw Exception('Commande introuvable.');
    }

    if (amount <= 0) {
      throw Exception('Le montant doit être supérieur à 0.');
    }

    final orderRef = _ordersRef(establishmentId: establishmentId).doc(orderId);
    final orderDoc = await orderRef.get();

    if (!orderDoc.exists || orderDoc.data() == null) {
      throw Exception('Commande introuvable.');
    }

    final orderData = orderDoc.data()!;

    if (orderData['isForKitchen'] == true &&
        orderData['kitchenStatus'] != 'ready' &&
        orderData['kitchenStatus'] != 'served') {
      throw Exception('Commande cuisine non prête.');
    }

    if (orderData['isForBar'] == true &&
        orderData['barStatus'] != 'ready' &&
        orderData['barStatus'] != 'served') {
      throw Exception('Commande bar non prête.');
    }

    final paymentRef = _paymentsRef(establishmentId: establishmentId).doc();

    final batch = _firestore.batch();

    if (method == 'room') {
      final roomExtraRef = _roomExtrasRef(
        establishmentId: establishmentId,
      ).doc();

      batch.set(roomExtraRef, {
        'establishmentId': establishmentId,
        'roomNumber': roomNumber,
        'amount': amount,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'createdBy': receivedBy,
        'createdByName': receivedByName,
        'createdAt': FieldValue.serverTimestamp(),
        'pendingSync': false,
        'syncError': false,
      });
    }

    batch.set(paymentRef, {
      'establishmentId': establishmentId,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'clientType': (orderData['clientType'] ?? '').toString(),
      'type': method == 'room'
          ? 'room'
          : (orderData['clientType'] ?? '').toString(),
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

    batch.update(orderRef, {
      'paymentStatus': 'paid',
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });

    await batch.commit();
  }
}
