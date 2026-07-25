import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Identifiant chambre (libre : "101", "Jasmin", "A2"...)
  final String number;

  /// Référence au type de chambre
  final String roomTypeId;

  /// Nom du type au moment de la création (dénormalisé pour affichage rapide)
  final String roomTypeName;

  /// Prix par nuit spécifique à cette chambre.
  /// Si null ou <= 0, on utilise le basePrice du type.
  final double? priceOverride;

  /// État : available | occupied | cleaning | maintenance
  final String status;

  /// Étage (optionnel, libre)
  final String floor;

  /// Actif / supprimé logiquement
  final bool isActive;

  /// Audit
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomModel({
    required this.id,
    required this.establishmentId,
    required this.number,
    required this.roomTypeId,
    required this.roomTypeName,
    required this.priceOverride,
    required this.status,
    required this.floor,
    required this.isActive,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    }

    double? toDoubleOrNull(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return RoomModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Chambre
      number: map['number']?.toString() ?? '',
      roomTypeId: map['roomTypeId']?.toString() ?? '',
      roomTypeName: map['roomTypeName']?.toString() ?? '',
      priceOverride: toDoubleOrNull(map['priceOverride']),
      status: map['status']?.toString() ?? 'available',
      floor: map['floor']?.toString() ?? '',

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

      /// Chambre
      'number': number,
      'roomTypeId': roomTypeId,
      'roomTypeName': roomTypeName,
      'priceOverride': priceOverride,
      'status': status,
      'floor': floor,

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

  RoomModel copyWith({
    String? id,
    String? establishmentId,
    String? number,
    String? roomTypeId,
    String? roomTypeName,
    double? priceOverride,
    String? status,
    String? floor,
    bool? isActive,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      number: number ?? this.number,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      roomTypeName: roomTypeName ?? this.roomTypeName,
      priceOverride: priceOverride ?? this.priceOverride,
      status: status ?? this.status,
      floor: floor ?? this.floor,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
