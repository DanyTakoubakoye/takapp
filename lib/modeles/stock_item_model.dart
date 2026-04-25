import 'package:cloud_firestore/cloud_firestore.dart';

class StockItemModel {
  final String id;
  final String name;
  final String category;
  final String unit;
  final String store;
  final bool isActive;
  final DateTime? createdAt;

  StockItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.store,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'unit': unit,
      'store': store,
      'isActive': isActive,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory StockItemModel.fromMap(String id, Map<String, dynamic> map) {
    return StockItemModel(
      id: id,
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      store: map['store']?.toString() ?? '',
      isActive: map['isActive'] != false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
