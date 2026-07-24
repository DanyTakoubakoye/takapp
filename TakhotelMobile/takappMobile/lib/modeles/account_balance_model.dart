import 'package:cloud_firestore/cloud_firestore.dart';

class AccountBalanceModel {
  final String id;
  final String type;
  final double amount;
  final DateTime? date;
  final String createdBy;
  final String createdByName;

  const AccountBalanceModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdBy,
    required this.createdByName,
  });

  factory AccountBalanceModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final ts = map['date'];

    return AccountBalanceModel(
      id: documentId,
      type: (map['type'] ?? '').toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      date: ts is Timestamp ? ts.toDate() : null,
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'date': date == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(date!),
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }
}
