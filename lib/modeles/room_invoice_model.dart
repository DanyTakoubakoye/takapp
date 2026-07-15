import 'package:cloud_firestore/cloud_firestore.dart';

class RoomInvoiceModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Client
  final String clientName;
  final String clientIfu;
  final String clientAddress;
  final String clientPhone;

  /// Chambre
  final String roomNumber;

  /// Séjour
  final int nights;

  final double pricePerNight;
  final double roomTotal;

  /// Extras / consommations
  final double extrasTotal;
  final double servicesTotal;

  /// Total général
  final double total;

  /// unpaid | partially_paid | paid | cancelled
  final String status;

  /// cash | mobile_money | card | transfer
  final String paymentMethod;

  /// none | A | B
  final String aibType;

  /// Fiscalisation
  final bool isFiscalized;

  /// pending | success | failed
  final String fiscalStatus;

  final String fiscalError;

  final DateTime? fiscalizedAt;

  /// FV / EV / AV
  final String fiscalInvoiceType;

  final String fiscalEmcfUid;
  final String fiscalMecefCode;
  final String fiscalNim;
  final String fiscalCounter;
  final String fiscalMachineDateTime;
  final String fiscalQrCode;

  final String fiscalRawCreateResponse;
  final String fiscalRawConfirmResponse;

  final Map<String, dynamic>? fiscalRequestSnapshot;

  /// Période séjour
  final DateTime? startDate;
  final DateTime? endDate;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  /// Audit
  final String createdBy;
  final String createdByName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomInvoiceModel({
    required this.id,

    required this.establishmentId,

    required this.clientName,
    required this.clientIfu,
    required this.clientAddress,
    required this.clientPhone,

    required this.roomNumber,

    required this.nights,

    required this.pricePerNight,
    required this.roomTotal,

    required this.extrasTotal,
    required this.servicesTotal,

    required this.total,

    required this.status,

    required this.paymentMethod,

    required this.aibType,

    required this.isFiscalized,
    required this.fiscalStatus,
    required this.fiscalError,
    required this.fiscalizedAt,
    required this.fiscalInvoiceType,
    required this.fiscalEmcfUid,
    required this.fiscalMecefCode,
    required this.fiscalNim,
    required this.fiscalCounter,
    required this.fiscalMachineDateTime,
    required this.fiscalQrCode,
    required this.fiscalRawCreateResponse,
    required this.fiscalRawConfirmResponse,
    required this.fiscalRequestSnapshot,

    required this.startDate,
    required this.endDate,

    required this.pendingSync,
    required this.syncError,

    required this.createdBy,
    required this.createdByName,

    required this.createdAt,
    required this.updatedAt,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Client
      'clientName': clientName,
      'clientIfu': clientIfu,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,

      /// Chambre
      'roomNumber': roomNumber,

      /// Séjour
      'nights': nights,

      'pricePerNight': pricePerNight,
      'roomTotal': roomTotal,

      /// Extras
      'extrasTotal': extrasTotal,
      'servicesTotal': servicesTotal,

      /// Total
      'total': total,

      /// Paiement
      'status': status,
      'paymentMethod': paymentMethod,
      'aibType': aibType,

      /// Fiscalisation
      'isFiscalized': isFiscalized,
      'fiscalStatus': fiscalStatus,
      'fiscalError': fiscalError,

      'fiscalizedAt': fiscalizedAt == null
          ? null
          : Timestamp.fromDate(fiscalizedAt!),

      'fiscalInvoiceType': fiscalInvoiceType,
      'fiscalEmcfUid': fiscalEmcfUid,
      'fiscalMecefCode': fiscalMecefCode,
      'fiscalNim': fiscalNim,
      'fiscalCounter': fiscalCounter,
      'fiscalMachineDateTime': fiscalMachineDateTime,
      'fiscalQrCode': fiscalQrCode,

      'fiscalRawCreateResponse': fiscalRawCreateResponse,

      'fiscalRawConfirmResponse': fiscalRawConfirmResponse,

      'fiscalRequestSnapshot': fiscalRequestSnapshot,

      /// Séjour
      'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),

      'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),

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

  factory RoomInvoiceModel.fromMap(String id, Map<String, dynamic> map) {
    return RoomInvoiceModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Client
      clientName: map['clientName']?.toString() ?? '',

      clientIfu: map['clientIfu']?.toString() ?? '',

      clientAddress: map['clientAddress']?.toString() ?? '',

      clientPhone: map['clientPhone']?.toString() ?? '',

      /// Chambre
      roomNumber: map['roomNumber']?.toString() ?? '',

      /// Séjour
      nights: _toInt(map['nights']),

      pricePerNight: _toDouble(map['pricePerNight']),

      roomTotal: _toDouble(map['roomTotal']),

      /// Extras
      extrasTotal: _toDouble(map['extrasTotal']),

      servicesTotal: _toDouble(map['servicesTotal']),

      /// Total
      total: _toDouble(map['total']),

      /// Paiement
      status: map['status']?.toString() ?? 'unpaid',

      paymentMethod: map['paymentMethod']?.toString() ?? 'cash',

      aibType: map['aibType']?.toString() ?? 'none',

      /// Fiscalisation
      isFiscalized: map['isFiscalized'] == true,

      fiscalStatus: map['fiscalStatus']?.toString() ?? 'pending',

      fiscalError: map['fiscalError']?.toString() ?? '',

      fiscalizedAt: _toDate(map['fiscalizedAt']),

      fiscalInvoiceType: map['fiscalInvoiceType']?.toString() ?? 'FV',

      fiscalEmcfUid: map['fiscalEmcfUid']?.toString() ?? '',

      fiscalMecefCode: map['fiscalMecefCode']?.toString() ?? '',

      fiscalNim: map['fiscalNim']?.toString() ?? '',

      fiscalCounter: map['fiscalCounter']?.toString() ?? '',

      fiscalMachineDateTime: map['fiscalMachineDateTime']?.toString() ?? '',

      fiscalQrCode: map['fiscalQrCode']?.toString() ?? '',

      fiscalRawCreateResponse: map['fiscalRawCreateResponse']?.toString() ?? '',

      fiscalRawConfirmResponse:
          map['fiscalRawConfirmResponse']?.toString() ?? '',

      fiscalRequestSnapshot:
          map['fiscalRequestSnapshot'] is Map<String, dynamic>
          ? map['fiscalRequestSnapshot'] as Map<String, dynamic>
          : null,

      /// Séjour
      startDate: _toDate(map['startDate']),

      endDate: _toDate(map['endDate']),

      /// Offline
      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,

      /// Audit
      createdBy: map['createdBy']?.toString() ?? '',

      createdByName: map['createdByName']?.toString() ?? '',

      createdAt: _toDate(map['createdAt']),

      updatedAt: _toDate(map['updatedAt']),
    );
  }

  RoomInvoiceModel copyWith({
    String? id,
    String? establishmentId,

    String? clientName,
    String? clientIfu,
    String? clientAddress,
    String? clientPhone,

    String? roomNumber,

    int? nights,

    double? pricePerNight,
    double? roomTotal,

    double? extrasTotal,
    double? servicesTotal,

    double? total,

    String? status,

    String? paymentMethod,

    String? aibType,

    bool? isFiscalized,
    String? fiscalStatus,
    String? fiscalError,
    DateTime? fiscalizedAt,
    String? fiscalInvoiceType,
    String? fiscalEmcfUid,
    String? fiscalMecefCode,
    String? fiscalNim,
    String? fiscalCounter,
    String? fiscalMachineDateTime,
    String? fiscalQrCode,
    String? fiscalRawCreateResponse,
    String? fiscalRawConfirmResponse,
    Map<String, dynamic>? fiscalRequestSnapshot,

    DateTime? startDate,
    DateTime? endDate,

    bool? pendingSync,
    bool? syncError,

    String? createdBy,
    String? createdByName,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomInvoiceModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      clientName: clientName ?? this.clientName,

      clientIfu: clientIfu ?? this.clientIfu,

      clientAddress: clientAddress ?? this.clientAddress,

      clientPhone: clientPhone ?? this.clientPhone,

      roomNumber: roomNumber ?? this.roomNumber,

      nights: nights ?? this.nights,

      pricePerNight: pricePerNight ?? this.pricePerNight,

      roomTotal: roomTotal ?? this.roomTotal,

      extrasTotal: extrasTotal ?? this.extrasTotal,

      servicesTotal: servicesTotal ?? this.servicesTotal,

      total: total ?? this.total,

      status: status ?? this.status,

      paymentMethod: paymentMethod ?? this.paymentMethod,

      aibType: aibType ?? this.aibType,

      isFiscalized: isFiscalized ?? this.isFiscalized,

      fiscalStatus: fiscalStatus ?? this.fiscalStatus,

      fiscalError: fiscalError ?? this.fiscalError,

      fiscalizedAt: fiscalizedAt ?? this.fiscalizedAt,

      fiscalInvoiceType: fiscalInvoiceType ?? this.fiscalInvoiceType,

      fiscalEmcfUid: fiscalEmcfUid ?? this.fiscalEmcfUid,

      fiscalMecefCode: fiscalMecefCode ?? this.fiscalMecefCode,

      fiscalNim: fiscalNim ?? this.fiscalNim,

      fiscalCounter: fiscalCounter ?? this.fiscalCounter,

      fiscalMachineDateTime:
          fiscalMachineDateTime ?? this.fiscalMachineDateTime,

      fiscalQrCode: fiscalQrCode ?? this.fiscalQrCode,

      fiscalRawCreateResponse:
          fiscalRawCreateResponse ?? this.fiscalRawCreateResponse,

      fiscalRawConfirmResponse:
          fiscalRawConfirmResponse ?? this.fiscalRawConfirmResponse,

      fiscalRequestSnapshot:
          fiscalRequestSnapshot ?? this.fiscalRequestSnapshot,

      startDate: startDate ?? this.startDate,

      endDate: endDate ?? this.endDate,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,

      createdBy: createdBy ?? this.createdBy,

      createdByName: createdByName ?? this.createdByName,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
