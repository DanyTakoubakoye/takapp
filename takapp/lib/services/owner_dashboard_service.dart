import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';

class OwnerDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> accountTypes = [
    'cash',
    'banque',
    'mobile_money',
    'benin_resto',
    'credit',
  ];

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
    required String collectionName,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection(collectionName);
  }

  void _validateEstablishmentId(String establishmentId) {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }
  }

  String _normalizePaymentType(String method) {
    switch (method) {
      case 'cash':
        return 'cash';
      case 'card':
      case 'bank_transfer':
        return 'banque';
      case 'mobile_money':
        return 'mobile_money';
      case 'benin_resto':
        return 'benin_resto';
      case 'credit':
        return 'credit';
      default:
        return 'cash';
    }
  }

  /// =========================
  /// OPENING BALANCES
  /// =========================

  Future<Map<String, double>> getOpeningBalancesByType({
    required String establishmentId,
  }) async {
    _validateEstablishmentId(establishmentId);

    final snapshot = await _col(
      establishmentId: establishmentId,
      collectionName: 'accountOpeningBalances',
    ).get();

    final Map<String, double> result = {
      for (final type in accountTypes) type: 0,
    };

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = (data['type'] ?? '').toString();
      final amount = ((data['amount'] ?? 0) as num).toDouble();

      if (result.containsKey(type)) {
        result[type] = amount;
      }
    }

    return result;
  }

  /// =========================
  /// THEORETICAL BALANCES
  /// =========================

  Future<Map<String, double>> getTheoreticalBalancesByType({
    required String establishmentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _validateEstablishmentId(establishmentId);

    final opening = await getOpeningBalancesByType(
      establishmentId: establishmentId,
    );

    final paymentsSnapshot =
        await _col(establishmentId: establishmentId, collectionName: 'payments')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    final expensesSnapshot =
        await _col(establishmentId: establishmentId, collectionName: 'expenses')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    final result = Map<String, double>.from(opening);

    for (final doc in paymentsSnapshot.docs) {
      final data = doc.data();
      final method = (data['method'] ?? '').toString();
      final type = _normalizePaymentType(method);
      final amount = ((data['amount'] ?? 0) as num).toDouble();

      result[type] = (result[type] ?? 0) + amount;
    }

    for (final doc in expensesSnapshot.docs) {
      final data = doc.data();
      final type = (data['accountType'] ?? 'cash').toString();
      final amount = ((data['amount'] ?? 0) as num).toDouble();

      result[type] = (result[type] ?? 0) - amount;
    }

    return result;
  }

  /// =========================
  /// VALIDATE ACCOUNT BALANCE
  /// =========================

  Future<void> validateAccountBalance({
    required String establishmentId,
    required String accountType,
    required double theoreticalAmount,
    required double physicalAmount,
    required String validatedById,
    required String validatedByName,
  }) async {
    _validateEstablishmentId(establishmentId);

    await _col(
      establishmentId: establishmentId,
      collectionName: 'accountClosures',
    ).add({
      'establishmentId': establishmentId,
      'accountType': accountType,
      'theoreticalAmount': theoreticalAmount,
      'physicalAmount': physicalAmount,
      'difference': physicalAmount - theoreticalAmount,
      'validated': theoreticalAmount == physicalAmount,
      'validatedById': validatedById,
      'validatedByName': validatedByName,
      'date': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }
}
