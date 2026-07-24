import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/room_invoice_model.dart';

class RoomInvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentReference> createInvoice(RoomInvoiceModel invoice) async {
    return await _firestore.collection('roomInvoices').add(invoice.toMap());
  }

  Stream<List<RoomInvoiceModel>> streamInvoices() {
    return _firestore
        .collection('roomInvoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoomInvoiceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> markAsPaid(String id) async {
    await _firestore.collection('roomInvoices').doc(id).update({
      'status': 'paid',
    });
  }

  Future<void> payInvoice({
    required String invoiceId,
    required double amount,
    required String method,
    required String receivedBy,
    required String receivedByName,
  }) async {
    final invoiceRef = _firestore.collection('roomInvoices').doc(invoiceId);
    final paymentRef = _firestore.collection('payments').doc();

    final batch = _firestore.batch();

    batch.set(paymentRef, {
      'type': 'room',
      'invoiceId': invoiceId,
      'amount': amount,
      'method': method,
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,
      'handoverStatus': 'pending',
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(invoiceRef, {
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
