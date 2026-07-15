import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/room_invoice_model.dart';

class RoomInvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// SAAS HELPERS
  /// =========================

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('roomInvoices');
  }

  void _validateEstablishmentId(String establishmentId) {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime _normalizeStart(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  DateTime _normalizeEnd(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// =========================
  /// CREATE INVOICE
  /// =========================

  Future<DocumentReference<Map<String, dynamic>>> createInvoice({
    required String establishmentId,
    required RoomInvoiceModel invoice,
  }) async {
    _validateEstablishmentId(establishmentId);

    return await _col(establishmentId: establishmentId).add({
      ...invoice.toMap(),

      'establishmentId': establishmentId,

      'createdAt': FieldValue.serverTimestamp(),

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });
  }

  /// =========================
  /// GET INVOICE
  /// =========================

  Future<RoomInvoiceModel?> getInvoiceById({
    required String establishmentId,
    required String invoiceId,
  }) async {
    _validateEstablishmentId(establishmentId);

    final doc = await _col(
      establishmentId: establishmentId,
    ).doc(invoiceId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return RoomInvoiceModel.fromMap(doc.id, doc.data()!);
  }

  /// =========================
  /// WATCH INVOICE
  /// =========================

  Stream<RoomInvoiceModel?> watchInvoice({
    required String establishmentId,
    required String invoiceId,
  }) {
    _validateEstablishmentId(establishmentId);

    return _col(
      establishmentId: establishmentId,
    ).doc(invoiceId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return RoomInvoiceModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// =========================
  /// INVOICE EXISTS
  /// =========================

  Future<bool> invoiceExists({
    required String establishmentId,
    required String roomNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _validateEstablishmentId(establishmentId);

    final snapshot = await _col(establishmentId: establishmentId)
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

  /// =========================
  /// FIND INVOICE
  /// =========================

  Future<RoomInvoiceModel?> findInvoiceByRoomAndDates({
    required String establishmentId,
    required String roomNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _validateEstablishmentId(establishmentId);

    final snapshot = await _col(establishmentId: establishmentId)
        .where('roomNumber', isEqualTo: roomNumber.trim())
        .where(
          'startDate',
          isEqualTo: Timestamp.fromDate(_normalizeStart(startDate)),
        )
        .where('endDate', isEqualTo: Timestamp.fromDate(_normalizeEnd(endDate)))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return RoomInvoiceModel.fromMap(doc.id, doc.data());
  }

  /// =========================
  /// STREAM INVOICES
  /// =========================

  Stream<List<RoomInvoiceModel>> streamInvoices({
    required String establishmentId,
  }) {
    _validateEstablishmentId(establishmentId);

    return _col(
      establishmentId: establishmentId,
    ).orderBy('startDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomInvoiceModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// =========================
  /// SEARCH CLIENT
  /// =========================

  Future<List<RoomInvoiceModel>> searchInvoicesByClient({
    required String establishmentId,
    required String clientName,
  }) async {
    _validateEstablishmentId(establishmentId);

    final query = clientName.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    final snapshot = await _col(establishmentId: establishmentId).get();

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

  /// =========================
  /// SEARCH ROOM
  /// =========================

  Future<List<RoomInvoiceModel>> searchInvoicesByRoom({
    required String establishmentId,
    required String roomNumber,
  }) async {
    _validateEstablishmentId(establishmentId);

    final query = roomNumber.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    final snapshot = await _col(establishmentId: establishmentId).get();

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

  /// =========================
  /// PAY INVOICE
  /// =========================

  Future<void> payInvoice({
    required String establishmentId,
    required String invoiceId,
    required double amount,
    required String method,
    required String receivedBy,
    required String receivedByName,
  }) async {
    _validateEstablishmentId(establishmentId);

    final docRef = _col(establishmentId: establishmentId).doc(invoiceId);

    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Facture introuvable.');
    }

    final data = snapshot.data()!;

    final invoiceTotal = _toDouble(data['total']);

    if (invoiceTotal <= 0) {
      throw Exception('Montant total invalide.');
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

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });
  }

  /// =========================
  /// MARK AS PAID
  /// =========================

  Future<void> markAsPaid({
    required String establishmentId,
    required String invoiceId,
  }) async {
    _validateEstablishmentId(establishmentId);

    final docRef = _col(establishmentId: establishmentId).doc(invoiceId);

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

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// MARK UNPAID
  /// =========================

  Future<void> markInvoiceUnpaid({
    required String establishmentId,
    required String invoiceId,
  }) async {
    _validateEstablishmentId(establishmentId);

    await _col(establishmentId: establishmentId).doc(invoiceId).update({
      'status': 'unpaid',

      'paidAmount': 0,

      'paidAt': null,

      'receivedBy': '',

      'receivedByName': '',

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// FISCALIZATION PENDING
  /// =========================

  Future<void> markFiscalizationPending({
    required String establishmentId,
    required String invoiceId,
    required Map<String, dynamic> requestSnapshot,
  }) async {
    _validateEstablishmentId(establishmentId);

    await _col(establishmentId: establishmentId).doc(invoiceId).update({
      'fiscalStatus': 'pending',

      'fiscalError': '',

      'fiscalRequestSnapshot': requestSnapshot,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// FISCALIZATION SUCCESS
  /// =========================

  Future<void> markFiscalizationSuccess({
    required String establishmentId,
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
    _validateEstablishmentId(establishmentId);

    await _col(establishmentId: establishmentId).doc(invoiceId).update({
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

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// FISCALIZATION FAILED
  /// =========================

  Future<void> markFiscalizationFailed({
    required String establishmentId,
    required String invoiceId,
    required String error,
    required String rawResponse,
  }) async {
    _validateEstablishmentId(establishmentId);

    await _col(establishmentId: establishmentId).doc(invoiceId).update({
      'isFiscalized': false,

      'fiscalStatus': 'failed',

      'fiscalError': error,

      'fiscalRawConfirmResponse': rawResponse,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// CLEAR FISCALIZATION
  /// =========================

  Future<void> clearFiscalization({
    required String establishmentId,
    required String invoiceId,
  }) async {
    _validateEstablishmentId(establishmentId);

    await _col(establishmentId: establishmentId).doc(invoiceId).update({
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

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
