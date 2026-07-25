import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String establishmentId;
  final String label;
  final String category;
  final String accountType;
  final double amount;
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;

  const ExpenseModel({
    required this.id,
    required this.establishmentId,
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
      establishmentId: (map['establishmentId'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      accountType: (map['accountType'] ?? 'cash').toString(),
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
      'label': label,
      'category': category,
      'accountType': accountType,
      'amount': amount,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? establishmentId,
    String? label,
    String? category,
    String? accountType,
    double? amount,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      label: label ?? this.label,
      category: category ?? this.category,
      accountType: accountType ?? this.accountType,
      amount: amount ?? this.amount,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
