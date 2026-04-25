import 'package:cloud_firestore/cloud_firestore.dart';

class StoreStockModel {
  final String id;
  final String store;
  final String itemId;
  final String itemName;
  final String unit;
  final double quantity;
  final double minimumQuantity;
  final bool isLowStock;
  final DateTime? updatedAt;

  StoreStockModel({
    required this.id,
    required this.store,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.minimumQuantity,
    required this.isLowStock,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'store': store,
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'minimumQuantity': minimumQuantity,
      'isLowStock': isLowStock,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory StoreStockModel.fromMap(String id, Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final quantity = toDouble(map['quantity']);
    final minimumQuantity = toDouble(map['minimumQuantity']);

    return StoreStockModel(
      id: id,
      store: map['store']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? '',
      itemName: map['itemName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      quantity: quantity,
      minimumQuantity: minimumQuantity,
      isLowStock: map['isLowStock'] == true || quantity <= minimumQuantity,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
