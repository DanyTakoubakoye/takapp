import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';

class HandoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _paymentsRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('payments');
  }

  CollectionReference<Map<String, dynamic>> _handoversRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('serverHandovers');
  }

  /// =========================
  /// PAIEMENTS NON VERSES
  /// =========================

  Stream<List<PaymentModel>> streamUnhandedPaymentsForServer({
    required String establishmentId,
    required String serveurId,
  }) {
    return _paymentsRef(establishmentId: establishmentId)
        .where('receivedBy', isEqualTo: serveurId)
        .where('status', isEqualTo: 'confirmed')
        .where('handoverStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// =========================
  /// VERSEMENTS DU SERVEUR
  /// =========================

  Stream<List<ServerHandoverModel>> streamServerHandovers({
    required String establishmentId,
    required String serveurId,
  }) {
    return _handoversRef(establishmentId: establishmentId)
        .where('serveurId', isEqualTo: serveurId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServerHandoverModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// =========================
  /// CREATION VERSEMENT
  /// =========================

  Future<void> createHandover({
    required String establishmentId,
    required String serveurId,
    required String serveurName,
    required double declaredAmount,
    required List<String> paymentIds,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    if (paymentIds.isEmpty) {
      throw const AppError(AppErrorCode.noPaymentSelectedForHandover);
    }

    final handoverRef = _handoversRef(establishmentId: establishmentId).doc();

    final batch = _firestore.batch();

    batch.set(handoverRef, {
      'establishmentId': establishmentId,
      'serveurId': serveurId,
      'serveurName': serveurName,
      'declaredAmount': declaredAmount,
      'validatedAmount': null,
      'status': 'pending',
      'receivedByManagerId': null,
      'receivedByManagerName': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'validatedAt': null,
      'paymentIds': paymentIds,
      'validatedPaymentIds': <String>[],
      'rejectedPaymentIds': <String>[],
      'pendingSync': false,
      'syncError': false,
    });

    for (final paymentId in paymentIds) {
      final paymentRef = _paymentsRef(
        establishmentId: establishmentId,
      ).doc(paymentId);

      batch.update(paymentRef, {
        'handoverStatus': 'declared',
        'handoverId': handoverRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
        'pendingSync': false,
        'syncError': false,
      });
    }

    await batch.commit();
  }

  /// =========================
  /// GET PAYMENTS BY IDS
  /// =========================

  Future<List<PaymentModel>> getPaymentsByIds({
    required String establishmentId,
    required List<String> paymentIds,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

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
}
