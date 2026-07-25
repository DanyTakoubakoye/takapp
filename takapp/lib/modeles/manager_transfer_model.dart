import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerTransferModel {
  final String id;
  final String establishmentId;
  final String handoverId;
  final String serveurId;
  final String serveurName;
  final double amount;
  final String status;
  final String? receivedByAccountingId;
  final String? receivedByAccountingName;
  final DateTime? createdAt;
  final DateTime? receivedAt;

  const ManagerTransferModel({
    required this.id,
    required this.establishmentId,
    required this.handoverId,
    required this.serveurId,
    required this.serveurName,
    required this.amount,
    required this.status,
    required this.receivedByAccountingId,
    required this.receivedByAccountingName,
    required this.createdAt,
    required this.receivedAt,
  });

  factory ManagerTransferModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final createdTs = map['createdAt'];
    final receivedTs = map['receivedAt'];

    return ManagerTransferModel(
      id: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString(),
      handoverId: (map['handoverId'] ?? '').toString(),
      serveurId: (map['serveurId'] ?? '').toString(),
      serveurName: (map['serveurName'] ?? '').toString(),
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      status: (map['status'] ?? '').toString(),
      receivedByAccountingId: map['receivedByAccountingId']?.toString(),
      receivedByAccountingName: map['receivedByAccountingName']?.toString(),
      createdAt: createdTs is Timestamp ? createdTs.toDate() : null,
      receivedAt: receivedTs is Timestamp ? receivedTs.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
      'handoverId': handoverId,
      'serveurId': serveurId,
      'serveurName': serveurName,
      'amount': amount,
      'status': status,
      'receivedByAccountingId': receivedByAccountingId,
      'receivedByAccountingName': receivedByAccountingName,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'receivedAt': receivedAt == null ? null : Timestamp.fromDate(receivedAt!),
    };
  }

  ManagerTransferModel copyWith({
    String? id,
    String? establishmentId,
    String? handoverId,
    String? serveurId,
    String? serveurName,
    double? amount,
    String? status,
    String? receivedByAccountingId,
    String? receivedByAccountingName,
    DateTime? createdAt,
    DateTime? receivedAt,
  }) {
    return ManagerTransferModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      handoverId: handoverId ?? this.handoverId,
      serveurId: serveurId ?? this.serveurId,
      serveurName: serveurName ?? this.serveurName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      receivedByAccountingId:
          receivedByAccountingId ?? this.receivedByAccountingId,
      receivedByAccountingName:
          receivedByAccountingName ?? this.receivedByAccountingName,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}
