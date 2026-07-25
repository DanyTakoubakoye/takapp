import 'package:cloud_firestore/cloud_firestore.dart';

class StockItemModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Produit
  final String name;
  final String category;

  /// kg | litre | bouteille | sachet etc.
  final String unit;

  /// restaurant | bar | hotel | divers
  final String store;

  /// Actif / supprimé logiquement
  final bool isActive;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  /// Audit
  final String createdBy;
  final String createdByName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockItemModel({
    required this.id,
    required this.establishmentId,
    required this.name,
    required this.category,
    required this.unit,
    required this.store,
    required this.isActive,
    required this.pendingSync,
    required this.syncError,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockItemModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      return null;
    }

    return StockItemModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Produit
      name: map['name']?.toString() ?? '',

      category: map['category']?.toString() ?? '',

      unit: map['unit']?.toString() ?? '',

      store: map['store']?.toString() ?? '',

      /// Etat
      isActive: map['isActive'] != false,

      /// Offline
      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,

      /// Audit
      createdBy: map['createdBy']?.toString() ?? '',

      createdByName: map['createdByName']?.toString() ?? '',

      createdAt: toDate(map['createdAt']),

      updatedAt: toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Produit
      'name': name,
      'category': category,
      'unit': unit,
      'store': store,

      /// Etat
      'isActive': isActive,

      /// Offline
      'pendingSync': pendingSync,
      'syncError': syncError,

      /// Audit
      'createdBy': createdBy,
      'createdByName': createdByName,

      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),

      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StockItemModel copyWith({
    String? id,
    String? establishmentId,

    String? name,
    String? category,
    String? unit,
    String? store,

    bool? isActive,

    bool? pendingSync,
    bool? syncError,

    String? createdBy,
    String? createdByName,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItemModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      name: name ?? this.name,

      category: category ?? this.category,

      unit: unit ?? this.unit,

      store: store ?? this.store,

      isActive: isActive ?? this.isActive,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,

      createdBy: createdBy ?? this.createdBy,

      createdByName: createdByName ?? this.createdByName,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
