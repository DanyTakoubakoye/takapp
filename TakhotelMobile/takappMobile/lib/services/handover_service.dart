import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';

class HandoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PaymentModel>> streamUnhandedPaymentsForServer(String serveurId) {
    return _firestore
        .collection('payments')
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

  Stream<List<ServerHandoverModel>> streamServerHandovers(String serveurId) {
    return _firestore
        .collection('serverHandovers')
        .where('serveurId', isEqualTo: serveurId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServerHandoverModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> createHandover({
    required String serveurId,
    required String serveurName,
    required double declaredAmount,
    required List<String> paymentIds,
  }) async {
    if (paymentIds.isEmpty) {
      throw Exception('Aucun paiement sélectionné pour le versement.');
    }

    final handoverRef = _firestore.collection('serverHandovers').doc();
    final batch = _firestore.batch();

    batch.set(handoverRef, {
      'serveurId': serveurId,
      'serveurName': serveurName,
      'declaredAmount': declaredAmount,
      'validatedAmount': null,
      'status': 'pending',
      'receivedByManagerId': null,
      'receivedByManagerName': null,
      'createdAt': FieldValue.serverTimestamp(),
      'validatedAt': null,
      'paymentIds': paymentIds,
    });

    for (final paymentId in paymentIds) {
      final paymentRef = _firestore.collection('payments').doc(paymentId);
      batch.update(paymentRef, {
        'handoverStatus': 'declared',
        'handoverId': handoverRef.id,
      });
    }

    await batch.commit();
  }

  Future<List<PaymentModel>> getPaymentsByIds(List<String> paymentIds) async {
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
}
