import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';

class GeranteHandoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS
  /// =========================

  CollectionReference<Map<String, dynamic>> _handoversRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('serverHandovers');
  }

  CollectionReference<Map<String, dynamic>> _paymentsRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('payments');
  }

  /// =========================
  /// STREAM VERSEMENTS
  /// =========================

  Stream<List<ServerHandoverModel>> streamPendingHandovers({
    required String establishmentId,
  }) {
    return _handoversRef(establishmentId: establishmentId)
        .where('status', whereIn: ['pending', 'partially_validated'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServerHandoverModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// =========================
  /// PAIEMENTS NON VERSES
  /// =========================

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getUnpaidServerPayments({required String establishmentId}) {
    return _paymentsRef(establishmentId: establishmentId)
        .where('handoverStatus', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs);
  }

  /// =========================
  /// STREAM PAIEMENTS SERVEURS
  /// =========================

  Stream<List<Map<String, dynamic>>> streamServerPaymentsNonVerses({
    required String establishmentId,
  }) {
    return _paymentsRef(establishmentId: establishmentId)
        .where('handoverStatus', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .where((data) => (data['type'] ?? '') != 'room')
              .toList(),
        );
  }

  /// =========================
  /// GET PAYMENTS FOR HANDOVER
  /// =========================

  Future<List<PaymentModel>> getPaymentsForHandover({
    required String establishmentId,
    required List<String> paymentIds,
  }) async {
    if (paymentIds.isEmpty) {
      return [];
    }

    final futures = paymentIds.map(
      (id) => _paymentsRef(establishmentId: establishmentId).doc(id).get(),
    );

    final docs = await Future.wait(futures);

    return docs
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) => PaymentModel.fromMap(doc.data()!, doc.id))
        .toList();
  }

  /// =========================
  /// VALIDATE PAYMENTS
  /// =========================

  Future<void> validateSelectedPayments({
    required String establishmentId,
    required String handoverId,
    required List<String> selectedPaymentIds,
    required double validatedAmount,
    required String managerId,
    required String managerName,
  }) async {
    if (selectedPaymentIds.isEmpty) {
      throw const AppError(AppErrorCode.noOrderSelected);
    }

    final handoverRef = _handoversRef(
      establishmentId: establishmentId,
    ).doc(handoverId);

    final handoverSnap = await handoverRef.get();

    if (!handoverSnap.exists || handoverSnap.data() == null) {
      throw const AppError(AppErrorCode.handoverNotFound);
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

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });

    for (final paymentId in selectedPaymentIds) {
      final paymentRef = _paymentsRef(
        establishmentId: establishmentId,
      ).doc(paymentId);

      batch.update(paymentRef, {
        'handoverStatus': 'validated',

        'updatedAt': FieldValue.serverTimestamp(),

        'pendingSync': false,

        'syncError': false,
      });
    }

    await batch.commit();
  }

  /// =========================
  /// REJECT PAYMENTS
  /// =========================

  Future<void> rejectSelectedPayments({
    required String establishmentId,
    required String handoverId,
    required List<String> selectedPaymentIds,
    required double validatedAmount,
    required String managerId,
    required String managerName,
  }) async {
    if (selectedPaymentIds.isEmpty) {
      throw const AppError(AppErrorCode.noOrderSelected);
    }

    final handoverRef = _handoversRef(
      establishmentId: establishmentId,
    ).doc(handoverId);

    final handoverSnap = await handoverRef.get();

    if (!handoverSnap.exists || handoverSnap.data() == null) {
      throw const AppError(AppErrorCode.handoverNotFound);
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

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });

    for (final paymentId in selectedPaymentIds) {
      final paymentRef = _paymentsRef(
        establishmentId: establishmentId,
      ).doc(paymentId);

      batch.update(paymentRef, {
        'handoverStatus': 'pending',

        'handoverId': null,

        'updatedAt': FieldValue.serverTimestamp(),

        'pendingSync': false,

        'syncError': false,
      });
    }

    await batch.commit();
  }
}
