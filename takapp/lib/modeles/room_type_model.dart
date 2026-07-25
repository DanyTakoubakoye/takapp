import 'package:cloud_firestore/cloud_firestore.dart';

class RoomTypeModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Type de chambre (libellé libre défini par l'établissement)
  /// ex: Simple, Double, Suite Junior, Bungalow, Appartement...
  final String name;

  /// Prix par nuit par défaut pour ce type (FCFA)
  final double basePrice;

  /// Nombre de personnes maximum
  final int capacity;

  /// Description optionnelle
  final String description;

  /// Équipements (liste libre : clim, wifi, TV, minibar...)
  final List<String> amenities;

  /// Actif / supprimé logiquement
  final bool isActive;

  /// Audit
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomTypeModel({
    required this.id,
    required this.establishmentId,
    required this.name,
    required this.basePrice,
    required this.capacity,
    required this.description,
    required this.amenities,
    required this.isActive,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomTypeModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '0') ?? 0;
    }

    int toInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    return RoomTypeModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Type
      name: map['name']?.toString() ?? '',
      basePrice: toDouble(map['basePrice']),
      capacity: toInt(map['capacity']),
      description: map['description']?.toString() ?? '',
      amenities: (map['amenities'] is List)
          ? List<String>.from(
              (map['amenities'] as List).map((e) => e.toString()),
            )
          : <String>[],

      /// Etat
      isActive: map['isActive'] != false,

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

      /// Type
      'name': name,
      'basePrice': basePrice,
      'capacity': capacity,
      'description': description,
      'amenities': amenities,

      /// Etat
      'isActive': isActive,

      /// Audit
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  RoomTypeModel copyWith({
    String? id,
    String? establishmentId,
    String? name,
    double? basePrice,
    int? capacity,
    String? description,
    List<String>? amenities,
    bool? isActive,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomTypeModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
