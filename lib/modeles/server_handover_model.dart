import 'package:cloud_firestore/cloud_firestore.dart';

class ServerHandoverModel {
  final String id;

  /// SaaS
  final String establishmentId;

  final String serveurId;
  final String serveurName;

  final double declaredAmount;
  final double? validatedAmount;

  /// pending | partially_validated | validated | rejected
  final String status;

  final String? receivedByManagerId;
  final String? receivedByManagerName;

  final DateTime? createdAt;
  final DateTime? validatedAt;

  final List<String> paymentIds;
  final List<String> validatedPaymentIds;
  final List<String> rejectedPaymentIds;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  const ServerHandoverModel({
    required this.id,
    required this.establishmentId,
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
    required this.pendingSync,
    required this.syncError,
  });

  factory ServerHandoverModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    double? toNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    List<String> toStringList(dynamic value) {
      return (value as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    }

    return ServerHandoverModel(
      id: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString(),
      serveurId: (map['serveurId'] ?? '').toString(),
      serveurName: (map['serveurName'] ?? '').toString(),
      declaredAmount: toDouble(map['declaredAmount']),
      validatedAmount: toNullableDouble(map['validatedAmount']),
      status: (map['status'] ?? 'pending').toString(),
      receivedByManagerId: map['receivedByManagerId']?.toString(),
      receivedByManagerName: map['receivedByManagerName']?.toString(),
      createdAt: toDate(map['createdAt']),
      validatedAt: toDate(map['validatedAt']),
      paymentIds: toStringList(map['paymentIds']),
      validatedPaymentIds: toStringList(map['validatedPaymentIds']),
      rejectedPaymentIds: toStringList(map['rejectedPaymentIds']),
      pendingSync: map['pendingSync'] == true,
      syncError: map['syncError'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
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
      'pendingSync': pendingSync,
      'syncError': syncError,
    };
  }

  ServerHandoverModel copyWith({
    String? id,
    String? establishmentId,
    String? serveurId,
    String? serveurName,
    double? declaredAmount,
    double? validatedAmount,
    String? status,
    String? receivedByManagerId,
    String? receivedByManagerName,
    DateTime? createdAt,
    DateTime? validatedAt,
    List<String>? paymentIds,
    List<String>? validatedPaymentIds,
    List<String>? rejectedPaymentIds,
    bool? pendingSync,
    bool? syncError,
  }) {
    return ServerHandoverModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      serveurId: serveurId ?? this.serveurId,
      serveurName: serveurName ?? this.serveurName,
      declaredAmount: declaredAmount ?? this.declaredAmount,
      validatedAmount: validatedAmount ?? this.validatedAmount,
      status: status ?? this.status,
      receivedByManagerId: receivedByManagerId ?? this.receivedByManagerId,
      receivedByManagerName:
          receivedByManagerName ?? this.receivedByManagerName,
      createdAt: createdAt ?? this.createdAt,
      validatedAt: validatedAt ?? this.validatedAt,
      paymentIds: paymentIds ?? this.paymentIds,
      validatedPaymentIds: validatedPaymentIds ?? this.validatedPaymentIds,
      rejectedPaymentIds: rejectedPaymentIds ?? this.rejectedPaymentIds,
      pendingSync: pendingSync ?? this.pendingSync,
      syncError: syncError ?? this.syncError,
    );
  }
}
