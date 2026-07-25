import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovementModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Stock concerné
  final String store;

  /// Produit
  final String itemId;
  final String itemName;
  final String unit;

  /// Quantité
  final double quantity;

  /// in | out | transfer | adjustment | cancellation_restore
  final String movementType;

  /// Raison mouvement
  final String reason;

  /// Références métier
  final String orderId;
  final String paymentId;
  final String sourceRequestId;

  /// Utilisateur ayant effectué le mouvement
  final String performedBy;
  final String performedByName;

  /// Validation
  final String validatedBy;
  final String validatedByName;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  /// Audit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockMovementModel({
    required this.id,
    required this.establishmentId,

    required this.store,

    required this.itemId,
    required this.itemName,
    required this.unit,

    required this.quantity,

    required this.movementType,
    required this.reason,

    required this.orderId,
    required this.paymentId,
    required this.sourceRequestId,

    required this.performedBy,
    required this.performedByName,

    required this.validatedBy,
    required this.validatedByName,

    required this.pendingSync,
    required this.syncError,

    required this.createdAt,
    required this.updatedAt,
  });

  factory StockMovementModel.fromMap(String id, Map<String, dynamic> map) {
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

    return StockMovementModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Stock
      store: map['store']?.toString() ?? '',

      /// Produit
      itemId: map['itemId']?.toString() ?? '',

      itemName: map['itemName']?.toString() ?? '',

      unit: map['unit']?.toString() ?? '',

      /// Quantité
      quantity: toDouble(map['quantity']),

      /// Mouvement
      movementType: map['movementType']?.toString() ?? '',

      reason: map['reason']?.toString() ?? '',

      /// Références métier
      orderId: map['orderId']?.toString() ?? '',

      paymentId: map['paymentId']?.toString() ?? '',

      sourceRequestId: map['sourceRequestId']?.toString() ?? '',

      /// Exécutant
      performedBy: map['performedBy']?.toString() ?? '',

      performedByName: map['performedByName']?.toString() ?? '',

      /// Validation
      validatedBy: map['validatedBy']?.toString() ?? '',

      validatedByName: map['validatedByName']?.toString() ?? '',

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

      /// Stock
      'store': store,

      /// Produit
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,

      /// Quantité
      'quantity': quantity,

      /// Mouvement
      'movementType': movementType,
      'reason': reason,

      /// Références métier
      'orderId': orderId,
      'paymentId': paymentId,
      'sourceRequestId': sourceRequestId,

      /// Exécutant
      'performedBy': performedBy,
      'performedByName': performedByName,

      /// Validation
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,

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

  StockMovementModel copyWith({
    String? id,
    String? establishmentId,

    String? store,

    String? itemId,
    String? itemName,
    String? unit,

    double? quantity,

    String? movementType,
    String? reason,

    String? orderId,
    String? paymentId,
    String? sourceRequestId,

    String? performedBy,
    String? performedByName,

    String? validatedBy,
    String? validatedByName,

    bool? pendingSync,
    bool? syncError,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockMovementModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      store: store ?? this.store,

      itemId: itemId ?? this.itemId,

      itemName: itemName ?? this.itemName,

      unit: unit ?? this.unit,

      quantity: quantity ?? this.quantity,

      movementType: movementType ?? this.movementType,

      reason: reason ?? this.reason,

      orderId: orderId ?? this.orderId,

      paymentId: paymentId ?? this.paymentId,

      sourceRequestId: sourceRequestId ?? this.sourceRequestId,

      performedBy: performedBy ?? this.performedBy,

      performedByName: performedByName ?? this.performedByName,

      validatedBy: validatedBy ?? this.validatedBy,

      validatedByName: validatedByName ?? this.validatedByName,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
