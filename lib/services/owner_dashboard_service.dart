import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> accountTypes = [
    'cash',
    'banque',
    'mobile_money',
    'benin_resto',
    'credit',
  ];

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

  Future<Map<String, double>> getOpeningBalancesByType() async {
    final snapshot = await _firestore
        .collection('accountOpeningBalances')
        .get();

    final Map<String, double> result = {
      for (final type in accountTypes) type: 0,
    };

    for (final doc in snapshot.docs) {
      final type = (doc.data()['type'] ?? '').toString();
      final amount = ((doc.data()['amount'] ?? 0) as num).toDouble();
      if (result.containsKey(type)) {
        result[type] = amount;
      }
    }

    return result;
  }

  Future<Map<String, double>> getTheoreticalBalancesByType({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final opening = await getOpeningBalancesByType();

    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final result = Map<String, double>.from(opening);

    for (final doc in paymentsSnapshot.docs) {
      final method = (doc.data()['method'] ?? '').toString();
      final type = _normalizePaymentType(method);
      final amount = ((doc.data()['amount'] ?? 0) as num).toDouble();
      result[type] = (result[type] ?? 0) + amount;
    }

    for (final doc in expensesSnapshot.docs) {
      final type = (doc.data()['accountType'] ?? 'cash').toString();
      final amount = ((doc.data()['amount'] ?? 0) as num).toDouble();
      result[type] = (result[type] ?? 0) - amount;
    }

    return result;
  }

  Future<void> validateAccountBalance({
    required String accountType,
    required double theoreticalAmount,
    required double physicalAmount,
    required String validatedById,
    required String validatedByName,
  }) async {
    await _firestore.collection('accountClosures').add({
      'accountType': accountType,
      'theoreticalAmount': theoreticalAmount,
      'physicalAmount': physicalAmount,
      'validated': theoreticalAmount == physicalAmount,
      'validatedById': validatedById,
      'validatedByName': validatedByName,
      'date': FieldValue.serverTimestamp(),
    });
  }
}
