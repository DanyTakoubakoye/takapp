import 'package:cloud_firestore/cloud_firestore.dart';

class AccountBalanceModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// cash | mobile_money | bank | card
  final String type;

  /// Solde
  final double amount;

  /// Date comptable
  final DateTime? date;

  /// Créateur
  final String createdBy;
  final String createdByName;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  /// Audit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountBalanceModel({
    required this.id,
    required this.establishmentId,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdBy,
    required this.createdByName,
    required this.pendingSync,
    required this.syncError,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountBalanceModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime? toDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      return null;
    }

    return AccountBalanceModel(
      id: documentId,

      /// SaaS
      establishmentId: (map['establishmentId'] ?? '').toString(),

      /// Type compte
      type: (map['type'] ?? '').toString(),

      /// Solde
      amount: toDouble(map['amount']),

      /// Date
      date: toDate(map['date']),

      /// Créateur
      createdBy: (map['createdBy'] ?? '').toString(),

      createdByName: (map['createdByName'] ?? '').toString(),

      /// Offline
      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,

      /// Audit
      createdAt: toDate(map['createdAt']),

      updatedAt: toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Type compte
      'type': type,

      /// Solde
      'amount': amount,

      /// Date comptable
      'date': date == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(date!),

      /// Créateur
      'createdBy': createdBy,
      'createdByName': createdByName,

      /// Offline
      'pendingSync': pendingSync,
      'syncError': syncError,

      /// Audit
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),

      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AccountBalanceModel copyWith({
    String? id,
    String? establishmentId,

    String? type,
    double? amount,

    DateTime? date,

    String? createdBy,
    String? createdByName,

    bool? pendingSync,
    bool? syncError,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountBalanceModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      type: type ?? this.type,

      amount: amount ?? this.amount,

      date: date ?? this.date,

      createdBy: createdBy ?? this.createdBy,

      createdByName: createdByName ?? this.createdByName,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
