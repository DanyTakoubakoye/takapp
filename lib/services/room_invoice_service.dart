import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/room_invoice_model.dart';

class RoomInvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('roomInvoices');

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime _normalizeStart(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  DateTime _normalizeEnd(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  Future<DocumentReference<Map<String, dynamic>>> createInvoice(
    RoomInvoiceModel invoice,
  ) async {
    return await _col.add(invoice.toMap());
  }

  Future<RoomInvoiceModel?> getInvoiceById(String invoiceId) async {
    final doc = await _col.doc(invoiceId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return RoomInvoiceModel.fromMap(doc.id, doc.data()!);
  }

  Stream<RoomInvoiceModel?> watchInvoice(String invoiceId) {
    return _col.doc(invoiceId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RoomInvoiceModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<bool> invoiceExists({
    required String roomNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _col
        .where('roomNumber', isEqualTo: roomNumber.trim())
        .where(
          'startDate',
          isEqualTo: Timestamp.fromDate(_normalizeStart(startDate)),
        )
        .where('endDate', isEqualTo: Timestamp.fromDate(_normalizeEnd(endDate)))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<RoomInvoiceModel?> findInvoiceByRoomAndDates({
    required String roomNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _col
        .where('roomNumber', isEqualTo: roomNumber.trim())
        .where(
          'startDate',
          isEqualTo: Timestamp.fromDate(_normalizeStart(startDate)),
        )
        .where('endDate', isEqualTo: Timestamp.fromDate(_normalizeEnd(endDate)))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return RoomInvoiceModel.fromMap(doc.id, doc.data());
  }

  Stream<List<RoomInvoiceModel>> streamInvoices() {
    return _col.orderBy('startDate', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => RoomInvoiceModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<RoomInvoiceModel>> searchInvoicesByClient(
    String clientName,
  ) async {
    final query = clientName.trim().toLowerCase();
    if (query.isEmpty) return [];

    final snapshot = await _col.get();

    final invoices = snapshot.docs
        .map((doc) => RoomInvoiceModel.fromMap(doc.id, doc.data()))
        .where((invoice) => invoice.clientName.toLowerCase().contains(query))
        .toList();

    invoices.sort((a, b) {
      final aDate = a.startDate ?? DateTime(2000);
      final bDate = b.startDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return invoices;
  }

  Future<List<RoomInvoiceModel>> searchInvoicesByRoom(String roomNumber) async {
    final query = roomNumber.trim().toLowerCase();
    if (query.isEmpty) return [];

    final snapshot = await _col.get();

    final invoices = snapshot.docs
        .map((doc) => RoomInvoiceModel.fromMap(doc.id, doc.data()))
        .where((invoice) => invoice.roomNumber.toLowerCase().contains(query))
        .toList();

    invoices.sort((a, b) {
      final aDate = a.startDate ?? DateTime(2000);
      final bDate = b.startDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return invoices;
  }

  Future<void> payInvoice({
    required String invoiceId,
    required double amount,
    required String method,
    required String receivedBy,
    required String receivedByName,
  }) async {
    final docRef = _col.doc(invoiceId);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Facture introuvable.');
    }

    final data = snapshot.data()!;
    final invoiceTotal = _toDouble(data['total']);

    if (invoiceTotal <= 0) {
      throw Exception('Montant total de facture invalide.');
    }

    if (amount <= 0) {
      throw Exception('Montant de paiement invalide.');
    }

    await docRef.update({
      'status': 'paid',
      'paidAmount': amount,
      'paidAt': FieldValue.serverTimestamp(),
      'paymentMethod': method,
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,
    });
  }

  Future<void> markAsPaid(String invoiceId) async {
    final docRef = _col.doc(invoiceId);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Facture introuvable.');
    }

    final data = snapshot.data()!;
    final invoiceTotal = _toDouble(data['total']);

    await docRef.update({
      'status': 'paid',
      'paidAmount': invoiceTotal,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markInvoiceUnpaid(String invoiceId) async {
    await _col.doc(invoiceId).update({
      'status': 'unpaid',
      'paidAmount': 0,
      'paidAt': null,
      'receivedBy': '',
      'receivedByName': '',
    });
  }

  Future<void> markFiscalizationPending({
    required String invoiceId,
    required Map<String, dynamic> requestSnapshot,
  }) async {
    await _col.doc(invoiceId).update({
      'fiscalStatus': 'pending',
      'fiscalError': '',
      'fiscalRequestSnapshot': requestSnapshot,
    });
  }

  Future<void> markFiscalizationSuccess({
    required String invoiceId,
    required String emcfUid,
    required String mecefCode,
    required String nim,
    required String counter,
    required String machineDateTime,
    required String qrCode,
    required String rawCreateResponse,
    required String rawConfirmResponse,
  }) async {
    await _col.doc(invoiceId).update({
      'isFiscalized': true,
      'fiscalStatus': 'success',
      'fiscalError': '',
      'fiscalizedAt': FieldValue.serverTimestamp(),
      'fiscalEmcfUid': emcfUid,
      'fiscalMecefCode': mecefCode,
      'fiscalNim': nim,
      'fiscalCounter': counter,
      'fiscalMachineDateTime': machineDateTime,
      'fiscalQrCode': qrCode,
      'fiscalRawCreateResponse': rawCreateResponse,
      'fiscalRawConfirmResponse': rawConfirmResponse,
    });
  }

  Future<void> markFiscalizationFailed({
    required String invoiceId,
    required String error,
    required String rawResponse,
  }) async {
    await _col.doc(invoiceId).update({
      'isFiscalized': false,
      'fiscalStatus': 'failed',
      'fiscalError': error,
      'fiscalRawConfirmResponse': rawResponse,
    });
  }

  Future<void> clearFiscalization(String invoiceId) async {
    await _col.doc(invoiceId).update({
      'isFiscalized': false,
      'fiscalStatus': 'pending',
      'fiscalError': '',
      'fiscalizedAt': null,
      'fiscalEmcfUid': '',
      'fiscalMecefCode': '',
      'fiscalNim': '',
      'fiscalCounter': '',
      'fiscalMachineDateTime': '',
      'fiscalQrCode': '',
      'fiscalRawCreateResponse': '',
      'fiscalRawConfirmResponse': '',
      'fiscalRequestSnapshot': null,
    });
  }
}
