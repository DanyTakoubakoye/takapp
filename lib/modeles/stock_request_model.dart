import 'package:cloud_firestore/cloud_firestore.dart';

class StockRequestModel {
  final String id;
  final String store;
  final String requestedBy;
  final String requestedByName;
  final String requestedByRole;
  final String status;
  final String note;
  final bool validatedByManager;
  final bool validatedByReceiver;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? receivedAt;

  StockRequestModel({
    required this.id,
    required this.store,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedByRole,
    required this.status,
    required this.note,
    required this.validatedByManager,
    required this.validatedByReceiver,
    required this.createdAt,
    required this.deliveredAt,
    required this.receivedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'store': store,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedByRole': requestedByRole,
      'status': status,
      'note': note,
      'validatedByManager': validatedByManager,
      'validatedByReceiver': validatedByReceiver,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'deliveredAt': deliveredAt == null
          ? null
          : Timestamp.fromDate(deliveredAt!),
      'receivedAt': receivedAt == null ? null : Timestamp.fromDate(receivedAt!),
    };
  }

  factory StockRequestModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return StockRequestModel(
      id: id,
      store: map['store']?.toString() ?? '',
      requestedBy: map['requestedBy']?.toString() ?? '',
      requestedByName: map['requestedByName']?.toString() ?? '',
      requestedByRole: map['requestedByRole']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      note: map['note']?.toString() ?? '',
      validatedByManager: map['validatedByManager'] == true,
      validatedByReceiver: map['validatedByReceiver'] == true,
      createdAt: toDate(map['createdAt']),
      deliveredAt: toDate(map['deliveredAt']),
      receivedAt: toDate(map['receivedAt']),
    );
  }
}
