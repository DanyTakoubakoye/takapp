import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerTransferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendToAccounting(double amount) async {
    await _firestore.collection('managerToAccountingTransfers').add({
      'amount': amount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamTransfers() {
    return _firestore.collection('managerToAccountingTransfers').snapshots();
  }
}
