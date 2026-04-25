import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String label;
  final String category;
  final String accountType;
  final double amount;
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;

  const ExpenseModel({
    required this.id,
    required this.label,
    required this.category,
    required this.accountType,
    required this.amount,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    final ts = map['createdAt'];

    return ExpenseModel(
      id: documentId,
      label: (map['label'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      accountType: (map['accountType'] ?? 'cash').toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'category': category,
      'accountType': accountType,
      'amount': amount,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
