import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovementModel {
  final String id;
  final String store;
  final String itemId;
  final String itemName;
  final String unit;
  final double quantity;
  final String movementType;
  final String reason;
  final String performedBy;
  final String performedByName;
  final String validatedBy;
  final String validatedByName;
  final String sourceRequestId;
  final DateTime? createdAt;

  StockMovementModel({
    required this.id,
    required this.store,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.movementType,
    required this.reason,
    required this.performedBy,
    required this.performedByName,
    required this.validatedBy,
    required this.validatedByName,
    required this.sourceRequestId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'store': store,
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'movementType': movementType,
      'reason': reason,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'sourceRequestId': sourceRequestId,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory StockMovementModel.fromMap(String id, Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StockMovementModel(
      id: id,
      store: map['store']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? '',
      itemName: map['itemName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      quantity: toDouble(map['quantity']),
      movementType: map['movementType']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      performedBy: map['performedBy']?.toString() ?? '',
      performedByName: map['performedByName']?.toString() ?? '',
      validatedBy: map['validatedBy']?.toString() ?? '',
      validatedByName: map['validatedByName']?.toString() ?? '',
      sourceRequestId: map['sourceRequestId']?.toString() ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
