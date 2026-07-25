import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/account_balance_model.dart';
import 'package:takapp/modeles/expense_model.dart';
import 'package:takapp/modeles/manager_transfer_model.dart';

class ComptabiliteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collectionRef({
    required String establishmentId,
    required String collectionName,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection(collectionName);
  }

  Stream<List<ManagerTransferModel>> streamPendingTransfers({
    required String establishmentId,
  }) {
    return _collectionRef(
          establishmentId: establishmentId,
          collectionName: 'managerToAccountingTransfers',
        )
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerTransferModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ManagerTransferModel>> streamReceivedTransfers({
    required String establishmentId,
  }) {
    return _collectionRef(
          establishmentId: establishmentId,
          collectionName: 'managerToAccountingTransfers',
        )
        .where('status', isEqualTo: 'received')
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerTransferModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ExpenseModel>> streamExpenses({required String establishmentId}) {
    return _collectionRef(
          establishmentId: establishmentId,
          collectionName: 'expenses',
        )
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<AccountBalanceModel>> streamOpeningBalances({
    required String establishmentId,
  }) {
    return _collectionRef(
          establishmentId: establishmentId,
          collectionName: 'accountOpeningBalances',
        )
        .orderBy('type')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AccountBalanceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamManagerTransfers({
    required String establishmentId,
  }) {
    return _collectionRef(
      establishmentId: establishmentId,
      collectionName: 'managerToAccountingTransfers',
    ).where('status', isEqualTo: 'pending').snapshots();
  }

  Future<void> confirmManagerTransfer({
    required String establishmentId,
    required String id,
  }) async {
    await _collectionRef(
      establishmentId: establishmentId,
      collectionName: 'managerToAccountingTransfers',
    ).doc(id).update({
      'status': 'received',
      'receivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmTransferReception({
    required String establishmentId,
    required String transferId,
    required String accountingId,
    required String accountingName,
  }) async {
    await _collectionRef(
      establishmentId: establishmentId,
      collectionName: 'managerToAccountingTransfers',
    ).doc(transferId).update({
      'status': 'received',
      'receivedByAccountingId': accountingId,
      'receivedByAccountingName': accountingName,
      'receivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createExpense({
    required String establishmentId,
    required String label,
    required String category,
    required String accountType,
    required double amount,
    required String createdBy,
    required String createdByName,
  }) async {
    await _collectionRef(
      establishmentId: establishmentId,
      collectionName: 'expenses',
    ).add({
      'establishmentId': establishmentId,
      'label': label,
      'category': category,
      'accountType': accountType,
      'amount': amount,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'pendingSync': false,
      'syncError': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setOpeningBalance({
    required String establishmentId,
    required String type,
    required double amount,
    required DateTime date,
    required String createdBy,
    required String createdByName,
  }) async {
    await _collectionRef(
      establishmentId: establishmentId,
      collectionName: 'accountOpeningBalances',
    ).doc(type).set({
      'establishmentId': establishmentId,
      'type': type,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'pendingSync': false,
      'syncError': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getWeeklySummary({
    required String establishmentId,
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

    final managerTransfersSnapshot =
        await _collectionRef(
              establishmentId: establishmentId,
              collectionName: 'managerToAccountingTransfers',
            )
            .where('status', isEqualTo: 'received')
            .where(
              'receivedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('receivedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

    final expensesSnapshot =
        await _collectionRef(
              establishmentId: establishmentId,
              collectionName: 'expenses',
            )
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

    final balancesSnapshot = await _collectionRef(
      establishmentId: establishmentId,
      collectionName: 'accountOpeningBalances',
    ).get();

    final double totalEntries = managerTransfersSnapshot.docs.fold<double>(0, (
      total,
      doc,
    ) {
      final data = doc.data();
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      return total + amount;
    });

    final double totalExpenses = expensesSnapshot.docs.fold<double>(0, (
      total,
      doc,
    ) {
      final data = doc.data();
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      return total + amount;
    });

    final double totalOpeningBalances = balancesSnapshot.docs.fold<double>(0, (
      total,
      doc,
    ) {
      final data = doc.data();
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      return total + amount;
    });

    return {
      'establishmentId': establishmentId,
      'entries': totalEntries,
      'expenses': totalExpenses,
      'openingBalances': totalOpeningBalances,
      'balance': totalEntries - totalExpenses + totalOpeningBalances,
    };
  }
}
