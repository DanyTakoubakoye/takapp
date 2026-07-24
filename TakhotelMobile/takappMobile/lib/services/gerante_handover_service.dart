import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';

class GeranteHandoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ServerHandoverModel>> streamPendingHandovers() {
    return _firestore
        .collection('serverHandovers')
        .where('status', whereIn: ['pending', 'partially_validated'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServerHandoverModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<QueryDocumentSnapshot>> getUnpaidServerPayments() {
    return _firestore
        .collection('payments')
        .where('handoverStatus', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs);
  }

  Stream<List<Map<String, dynamic>>> streamServerPaymentsNonVerses() {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('handoverStatus', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .where((data) => (data['type'] ?? '') != 'room') // EXCLURE HOTEL
              .toList(),
        );
  }

  Future<List<PaymentModel>> getPaymentsForHandover(
    List<String> paymentIds,
  ) async {
    if (paymentIds.isEmpty) return [];

    final futures = paymentIds.map(
      (id) => _firestore.collection('payments').doc(id).get(),
    );

    final docs = await Future.wait(futures);

    return docs
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) => PaymentModel.fromMap(doc.data()!, doc.id))
        .toList();
  }

  Future<void> validateSelectedPayments({
    required String handoverId,
    required List<String> selectedPaymentIds,
    required double validatedAmount,
    required String managerId,
    required String managerName,
  }) async {
    if (selectedPaymentIds.isEmpty) {
      throw Exception('Aucune commande sélectionnée.');
    }

    final handoverRef = _firestore
        .collection('serverHandovers')
        .doc(handoverId);
    final handoverSnap = await handoverRef.get();

    if (!handoverSnap.exists || handoverSnap.data() == null) {
      throw Exception('Versement introuvable.');
    }

    final data = handoverSnap.data()!;
    final paymentIds = List<String>.from(data['paymentIds'] ?? []);
    final validatedIds = List<String>.from(data['validatedPaymentIds'] ?? []);
    final rejectedIds = List<String>.from(data['rejectedPaymentIds'] ?? []);

    final newValidatedIds = {...validatedIds, ...selectedPaymentIds}.toList();

    String newStatus = 'partially_validated';
    if ((newValidatedIds.length + rejectedIds.length) >= paymentIds.length) {
      newStatus = 'validated';
    }

    final batch = _firestore.batch();

    batch.update(handoverRef, {
      'validatedPaymentIds': newValidatedIds,
      'validatedAmount': validatedAmount,
      'status': newStatus,
      'receivedByManagerId': managerId,
      'receivedByManagerName': managerName,
      'validatedAt': FieldValue.serverTimestamp(),
    });

    for (final paymentId in selectedPaymentIds) {
      final paymentRef = _firestore.collection('payments').doc(paymentId);
      batch.update(paymentRef, {'handoverStatus': 'validated'});
    }

    await batch.commit();
  }

  Future<void> rejectSelectedPayments({
    required String handoverId,
    required List<String> selectedPaymentIds,
    required double validatedAmount,
    required String managerId,
    required String managerName,
  }) async {
    if (selectedPaymentIds.isEmpty) {
      throw Exception('Aucune commande sélectionnée.');
    }

    final handoverRef = _firestore
        .collection('serverHandovers')
        .doc(handoverId);
    final handoverSnap = await handoverRef.get();

    if (!handoverSnap.exists || handoverSnap.data() == null) {
      throw Exception('Versement introuvable.');
    }

    final data = handoverSnap.data()!;
    final paymentIds = List<String>.from(data['paymentIds'] ?? []);
    final validatedIds = List<String>.from(data['validatedPaymentIds'] ?? []);
    final rejectedIds = List<String>.from(data['rejectedPaymentIds'] ?? []);

    final newRejectedIds = {...rejectedIds, ...selectedPaymentIds}.toList();

    String newStatus = 'partially_validated';
    if ((validatedIds.length + newRejectedIds.length) >= paymentIds.length) {
      newStatus = 'validated';
    }

    final batch = _firestore.batch();

    batch.update(handoverRef, {
      'rejectedPaymentIds': newRejectedIds,
      'validatedAmount': validatedAmount,
      'status': newStatus,
      'receivedByManagerId': managerId,
      'receivedByManagerName': managerName,
      'validatedAt': FieldValue.serverTimestamp(),
    });

    for (final paymentId in selectedPaymentIds) {
      final paymentRef = _firestore.collection('payments').doc(paymentId);
      batch.update(paymentRef, {
        'handoverStatus': 'pending',
        'handoverId': null,
      });
    }

    await batch.commit();
  }
}
