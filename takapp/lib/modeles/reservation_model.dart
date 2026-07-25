import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Client
  /// Référence vers la fiche client (`establishments/{eid}/clients`).
  /// Vide si la réservation n'est pas rattachée à une fiche (walk-in,
  /// saisie rapide) : le rattachement est une commodité, pas une obligation.
  final String clientId;

  /// Données client figées à la réservation. On les conserve EN PLUS du
  /// clientId : la facture est un document légal (fiscalisation CertiLink)
  /// qui ne doit pas changer rétroactivement si la fiche client est modifiée.
  final String clientName;
  final String clientPhone;
  final String clientIfu;
  final String clientAddress;

  /// Type réservé (la chambre précise est assignée au check-in)
  final String roomTypeId;
  final String roomTypeName;

  /// Chambre assignée (vide tant que pas de check-in)
  final String assignedRoomId;
  final String assignedRoomNumber;

  /// Séjour
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int numberOfGuests;

  /// Tarif (figé à la réservation, hérité du type mais modifiable)
  final double pricePerNight;
  final int numberOfNights;
  final double roomTotal;

  /// Statut : confirmed | checked_in | checked_out | cancelled
  final String status;

  /// Note interne (optionnel)
  final String note;

  /// Audit
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReservationModel({
    required this.id,
    required this.establishmentId,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientIfu,
    required this.clientAddress,
    required this.roomTypeId,
    required this.roomTypeName,
    required this.assignedRoomId,
    required this.assignedRoomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.pricePerNight,
    required this.numberOfNights,
    required this.roomTotal,
    required this.status,
    required this.note,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReservationModel.fromMap(String id, Map<String, dynamic> map) {
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

    return ReservationModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Client
      clientId: map['clientId']?.toString() ?? '',
      clientName: map['clientName']?.toString() ?? '',
      clientPhone: map['clientPhone']?.toString() ?? '',
      clientIfu: map['clientIfu']?.toString() ?? '',
      clientAddress: map['clientAddress']?.toString() ?? '',

      /// Type
      roomTypeId: map['roomTypeId']?.toString() ?? '',
      roomTypeName: map['roomTypeName']?.toString() ?? '',

      /// Chambre assignée
      assignedRoomId: map['assignedRoomId']?.toString() ?? '',
      assignedRoomNumber: map['assignedRoomNumber']?.toString() ?? '',

      /// Séjour
      checkInDate: toDate(map['checkInDate']),
      checkOutDate: toDate(map['checkOutDate']),
      numberOfGuests: toInt(map['numberOfGuests']),

      /// Tarif
      pricePerNight: toDouble(map['pricePerNight']),
      numberOfNights: toInt(map['numberOfNights']),
      roomTotal: toDouble(map['roomTotal']),

      /// Statut
      status: map['status']?.toString() ?? 'confirmed',

      /// Note
      note: map['note']?.toString() ?? '',

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
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientIfu': clientIfu,
      'clientAddress': clientAddress,

      /// Type
      'roomTypeId': roomTypeId,
      'roomTypeName': roomTypeName,

      /// Chambre assignée
      'assignedRoomId': assignedRoomId,
      'assignedRoomNumber': assignedRoomNumber,

      /// Séjour
      'checkInDate': checkInDate == null
          ? null
          : Timestamp.fromDate(checkInDate!),
      'checkOutDate': checkOutDate == null
          ? null
          : Timestamp.fromDate(checkOutDate!),
      'numberOfGuests': numberOfGuests,

      /// Tarif
      'pricePerNight': pricePerNight,
      'numberOfNights': numberOfNights,
      'roomTotal': roomTotal,

      /// Statut
      'status': status,

      /// Note
      'note': note,

      /// Audit
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ReservationModel copyWith({
    String? id,
    String? establishmentId,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? clientIfu,
    String? clientAddress,
    String? roomTypeId,
    String? roomTypeName,
    String? assignedRoomId,
    String? assignedRoomNumber,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numberOfGuests,
    double? pricePerNight,
    int? numberOfNights,
    double? roomTotal,
    String? status,
    String? note,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientIfu: clientIfu ?? this.clientIfu,
      clientAddress: clientAddress ?? this.clientAddress,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      roomTypeName: roomTypeName ?? this.roomTypeName,
      assignedRoomId: assignedRoomId ?? this.assignedRoomId,
      assignedRoomNumber: assignedRoomNumber ?? this.assignedRoomNumber,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      numberOfNights: numberOfNights ?? this.numberOfNights,
      roomTotal: roomTotal ?? this.roomTotal,
      status: status ?? this.status,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
