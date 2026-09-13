import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';

class ManagerTransferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('managerToAccountingTransfers');
  }

  /// =========================
  /// CREATE TRANSFER
  /// =========================

  Future<void> sendToAccounting({
    required String establishmentId,
    required double amount,
    required String managerId,
    required String managerName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    if (amount <= 0) {
      throw const AppError(AppErrorCode.amountMustBePositive);
    }

    await _col(establishmentId: establishmentId).add({
      'establishmentId': establishmentId,

      'amount': amount,

      'status': 'pending',

      'managerId': managerId,

      'managerName': managerName,

      'receivedByAccountingId': '',

      'receivedByAccountingName': '',

      'createdAt': FieldValue.serverTimestamp(),

      'receivedAt': null,

      'pendingSync': false,

      'syncError': false,
    });
  }

  /// =========================
  /// STREAM TRANSFERS
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTransfers({
    required String establishmentId,
  }) {
    return _col(
      establishmentId: establishmentId,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  /// =========================
  /// STREAM PENDING TRANSFERS
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingTransfers({
    required String establishmentId,
  }) {
    return _col(establishmentId: establishmentId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// =========================
  /// CONFIRM RECEPTION
  /// =========================

  Future<void> confirmReception({
    required String establishmentId,
    required String transferId,
    required String accountingId,
    required String accountingName,
  }) async {
    await _col(establishmentId: establishmentId).doc(transferId).update({
      'status': 'received',

      'receivedByAccountingId': accountingId,

      'receivedByAccountingName': accountingName,

      'receivedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });
  }
}
