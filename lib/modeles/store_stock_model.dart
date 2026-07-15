import 'package:cloud_firestore/cloud_firestore.dart';

class StoreStockModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Magasin : restaurant | bar | hotel | divers
  final String store;

  /// Produit
  final String itemId;
  final String itemName;
  final String unit;

  /// Stock réel
  final double quantity;

  /// Stock réservé/offline
  final double reservedQuantity;

  /// Seuil minimum
  final double minimumQuantity;

  final bool isLowStock;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  /// Audit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoreStockModel({
    required this.id,
    required this.establishmentId,
    required this.store,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.reservedQuantity,
    required this.minimumQuantity,
    required this.isLowStock,
    required this.pendingSync,
    required this.syncError,
    required this.createdAt,
    required this.updatedAt,
  });

  double get availableQuantity => quantity - reservedQuantity;

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
      'store': store,
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'reservedQuantity': reservedQuantity,
      'minimumQuantity': minimumQuantity,
      'isLowStock': isLowStock || quantity <= minimumQuantity,
      'pendingSync': pendingSync,
      'syncError': syncError,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory StoreStockModel.fromMap(String id, Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    final quantity = toDouble(map['quantity']);
    final reservedQuantity = toDouble(map['reservedQuantity']);
    final minimumQuantity = toDouble(map['minimumQuantity']);

    return StoreStockModel(
      id: id,
      establishmentId: map['establishmentId']?.toString() ?? '',
      store: map['store']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? '',
      itemName: map['itemName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      quantity: quantity,
      reservedQuantity: reservedQuantity,
      minimumQuantity: minimumQuantity,
      isLowStock: map['isLowStock'] == true || quantity <= minimumQuantity,
      pendingSync: map['pendingSync'] == true,
      syncError: map['syncError'] == true,
      createdAt: toDate(map['createdAt']),
      updatedAt: toDate(map['updatedAt']),
    );
  }

  StoreStockModel copyWith({
    String? id,
    String? establishmentId,
    String? store,
    String? itemId,
    String? itemName,
    String? unit,
    double? quantity,
    double? reservedQuantity,
    double? minimumQuantity,
    bool? isLowStock,
    bool? pendingSync,
    bool? syncError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newQuantity = quantity ?? this.quantity;
    final newMinimumQuantity = minimumQuantity ?? this.minimumQuantity;

    return StoreStockModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      store: store ?? this.store,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      quantity: newQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      minimumQuantity: newMinimumQuantity,
      isLowStock: isLowStock ?? newQuantity <= newMinimumQuantity,
      pendingSync: pendingSync ?? this.pendingSync,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
