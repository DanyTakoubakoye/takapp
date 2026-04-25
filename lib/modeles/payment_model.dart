import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String receivedBy;
  final String receivedByName;
  final String method;
  final double amount;
  final String status;
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.receivedBy,
    required this.receivedByName,
    required this.method,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    final ts = map['createdAt'];

    return PaymentModel(
      id: documentId,
      orderId: (map['orderId'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? '').toString(),
      receivedBy: (map['receivedBy'] ?? '').toString(),
      receivedByName: (map['receivedByName'] ?? '').toString(),
      method: (map['method'] ?? '').toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      status: (map['status'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,
      'method': method,
      'amount': amount,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
