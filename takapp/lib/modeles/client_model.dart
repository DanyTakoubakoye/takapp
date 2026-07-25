import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Client
  /// Nom complet (particulier) ou raison sociale (entreprise)
  final String name;

  final String phone;

  /// Identifiant fiscal unique (surtout pour les entreprises)
  final String ifu;

  final String address;
  final String email;

  /// Note libre
  final String note;

  /// particulier | entreprise
  final String clientType;

  /// Actif / supprimé logiquement
  final bool isActive;

  /// Audit
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClientModel({
    required this.id,
    required this.establishmentId,
    required this.name,
    required this.phone,
    required this.ifu,
    required this.address,
    required this.email,
    required this.note,
    required this.clientType,
    required this.isActive,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    }

    return ClientModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Client
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      ifu: map['ifu']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      clientType: map['clientType']?.toString() ?? '',

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

      /// Client
      'name': name,
      'phone': phone,
      'ifu': ifu,
      'address': address,
      'email': email,
      'note': note,
      'clientType': clientType,

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

  ClientModel copyWith({
    String? id,
    String? establishmentId,
    String? name,
    String? phone,
    String? ifu,
    String? address,
    String? email,
    String? note,
    String? clientType,
    bool? isActive,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      ifu: ifu ?? this.ifu,
      address: address ?? this.address,
      email: email ?? this.email,
      note: note ?? this.note,
      clientType: clientType ?? this.clientType,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
