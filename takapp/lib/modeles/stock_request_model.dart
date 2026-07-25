import 'package:cloud_firestore/cloud_firestore.dart';

class StockRequestModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Magasin concerné : restaurant | bar | hotel | divers
  final String store;

  /// Demandeur
  final String requestedBy;
  final String requestedByName;
  final String requestedByRole;

  /// pending | approved | delivered | received | rejected | cancelled
  final String status;

  final String note;

  final bool validatedByManager;
  final bool validatedByReceiver;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  /// Dates
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? receivedAt;
  final DateTime? updatedAt;

  const StockRequestModel({
    required this.id,
    required this.establishmentId,
    required this.store,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedByRole,
    required this.status,
    required this.note,
    required this.validatedByManager,
    required this.validatedByReceiver,
    required this.pendingSync,
    required this.syncError,
    required this.createdAt,
    required this.deliveredAt,
    required this.receivedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
      'store': store,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedByRole': requestedByRole,
      'status': status,
      'note': note,
      'validatedByManager': validatedByManager,
      'validatedByReceiver': validatedByReceiver,
      'pendingSync': pendingSync,
      'syncError': syncError,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'deliveredAt': deliveredAt == null
          ? null
          : Timestamp.fromDate(deliveredAt!),
      'receivedAt': receivedAt == null ? null : Timestamp.fromDate(receivedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory StockRequestModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return StockRequestModel(
      id: id,
      establishmentId: map['establishmentId']?.toString() ?? '',
      store: map['store']?.toString() ?? '',
      requestedBy: map['requestedBy']?.toString() ?? '',
      requestedByName: map['requestedByName']?.toString() ?? '',
      requestedByRole: map['requestedByRole']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      note: map['note']?.toString() ?? '',
      validatedByManager: map['validatedByManager'] == true,
      validatedByReceiver: map['validatedByReceiver'] == true,
      pendingSync: map['pendingSync'] == true,
      syncError: map['syncError'] == true,
      createdAt: toDate(map['createdAt']),
      deliveredAt: toDate(map['deliveredAt']),
      receivedAt: toDate(map['receivedAt']),
      updatedAt: toDate(map['updatedAt']),
    );
  }

  StockRequestModel copyWith({
    String? id,
    String? establishmentId,
    String? store,
    String? requestedBy,
    String? requestedByName,
    String? requestedByRole,
    String? status,
    String? note,
    bool? validatedByManager,
    bool? validatedByReceiver,
    bool? pendingSync,
    bool? syncError,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? receivedAt,
    DateTime? updatedAt,
  }) {
    return StockRequestModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      store: store ?? this.store,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      requestedByRole: requestedByRole ?? this.requestedByRole,
      status: status ?? this.status,
      note: note ?? this.note,
      validatedByManager: validatedByManager ?? this.validatedByManager,
      validatedByReceiver: validatedByReceiver ?? this.validatedByReceiver,
      pendingSync: pendingSync ?? this.pendingSync,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      receivedAt: receivedAt ?? this.receivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
