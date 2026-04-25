import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/account_balance_model.dart';
import 'package:takapp/modeles/expense_model.dart';
import 'package:takapp/modeles/manager_transfer_model.dart';

class ComptabiliteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ManagerTransferModel>> streamPendingTransfers() {
    return _firestore
        .collection('managerToAccountingTransfers')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerTransferModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ManagerTransferModel>> streamReceivedTransfers() {
    return _firestore
        .collection('managerToAccountingTransfers')
        .where('status', isEqualTo: 'received')
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerTransferModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ExpenseModel>> streamExpenses() {
    return _firestore
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<AccountBalanceModel>> streamOpeningBalances() {
    return _firestore
        .collection('accountOpeningBalances')
        .orderBy('type')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AccountBalanceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<QuerySnapshot> streamManagerTransfers() {
    return _firestore
        .collection('managerToAccountingTransfers')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> confirmManagerTransfer(String id) async {
    await _firestore.collection('managerToAccountingTransfers').doc(id).update({
      'status': 'received',
      'receivedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmTransferReception({
    required String transferId,
    required String accountingId,
    required String accountingName,
  }) async {
    await _firestore
        .collection('managerToAccountingTransfers')
        .doc(transferId)
        .update({
          'status': 'received',
          'receivedByAccountingId': accountingId,
          'receivedByAccountingName': accountingName,
          'receivedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> createExpense({
    required String label,
    required String category,
    required String accountType,
    required double amount,
    required String createdBy,
    required String createdByName,
  }) async {
    await _firestore.collection('expenses').add({
      'label': label,
      'category': category,
      'accountType': accountType,
      'amount': amount,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setOpeningBalance({
    required String type,
    required double amount,
    required DateTime date,
    required String createdBy,
    required String createdByName,
  }) async {
    await _firestore.collection('accountOpeningBalances').doc(type).set({
      'type': type,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
      'createdByName': createdByName,
    });
  }

  Future<Map<String, dynamic>> getWeeklySummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      0,
      0,
      0,
    );

    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final managerTransfersSnapshot = await _firestore
        .collection('managerToAccountingTransfers')
        .where('status', isEqualTo: 'received')
        .where('receivedAt', isGreaterThanOrEqualTo: start)
        .where('receivedAt', isLessThanOrEqualTo: end)
        .get();

    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();

    final balancesSnapshot = await _firestore
        .collection('accountOpeningBalances')
        .get();

    final double totalEntries = managerTransfersSnapshot.docs.fold<double>(0, (
      sum,
      doc,
    ) {
      final data = doc.data();
      if (data.isEmpty) return sum;
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      return sum + amount;
    });

    final double totalExpenses = expensesSnapshot.docs.fold<double>(0, (
      sum,
      doc,
    ) {
      final data = doc.data();
      if (data.isEmpty) return sum;
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      return sum + amount;
    });

    final double totalOpeningBalances = balancesSnapshot.docs.fold<double>(0, (
      sum,
      doc,
    ) {
      final data = doc.data();
      if (data.isEmpty) return sum;
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      return sum + amount;
    });

    return {
      'entries': totalEntries,
      'expenses': totalExpenses,
      'openingBalances': totalOpeningBalances,
      'balance': totalEntries - totalExpenses + totalOpeningBalances,
    };
  }
}
