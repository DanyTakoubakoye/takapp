import 'package:cloud_firestore/cloud_firestore.dart';

class ServerHandoverModel {
  final String id;
  final String serveurId;
  final String serveurName;
  final double declaredAmount;
  final double? validatedAmount;
  final String status;
  final String? receivedByManagerId;
  final String? receivedByManagerName;
  final DateTime? createdAt;
  final DateTime? validatedAt;
  final List<String> paymentIds;
  final List<String> validatedPaymentIds;
  final List<String> rejectedPaymentIds;

  const ServerHandoverModel({
    required this.id,
    required this.serveurId,
    required this.serveurName,
    required this.declaredAmount,
    required this.validatedAmount,
    required this.status,
    required this.receivedByManagerId,
    required this.receivedByManagerName,
    required this.createdAt,
    required this.validatedAt,
    required this.paymentIds,
    required this.validatedPaymentIds,
    required this.rejectedPaymentIds,
  });

  factory ServerHandoverModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final createdTs = map['createdAt'];
    final validatedTs = map['validatedAt'];

    return ServerHandoverModel(
      id: documentId,
      serveurId: (map['serveurId'] ?? '').toString(),
      serveurName: (map['serveurName'] ?? '').toString(),
      declaredAmount: (map['declaredAmount'] ?? 0).toDouble(),
      validatedAmount: map['validatedAmount'] == null
          ? null
          : (map['validatedAmount'] as num).toDouble(),
      status: (map['status'] ?? '').toString(),
      receivedByManagerId: map['receivedByManagerId']?.toString(),
      receivedByManagerName: map['receivedByManagerName']?.toString(),
      createdAt: createdTs is Timestamp ? createdTs.toDate() : null,
      validatedAt: validatedTs is Timestamp ? validatedTs.toDate() : null,
      paymentIds: (map['paymentIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      validatedPaymentIds: (map['validatedPaymentIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      rejectedPaymentIds: (map['rejectedPaymentIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serveurId': serveurId,
      'serveurName': serveurName,
      'declaredAmount': declaredAmount,
      'validatedAmount': validatedAmount,
      'status': status,
      'receivedByManagerId': receivedByManagerId,
      'receivedByManagerName': receivedByManagerName,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'validatedAt': validatedAt == null
          ? null
          : Timestamp.fromDate(validatedAt!),
      'paymentIds': paymentIds,
      'validatedPaymentIds': validatedPaymentIds,
      'rejectedPaymentIds': rejectedPaymentIds,
    };
  }
}
