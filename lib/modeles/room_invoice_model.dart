import 'package:cloud_firestore/cloud_firestore.dart';

class RoomInvoiceModel {
  final String id;
  final String clientName;
  final String clientIfu;
  final String clientAddress;
  final String clientPhone;
  final String roomNumber;
  final int nights;
  final double pricePerNight;
  final double roomTotal;
  final double extrasTotal;
  final double servicesTotal;
  final double total;
  final String status;
  final String paymentMethod;
  final String aibType;

  final bool isFiscalized;
  final String fiscalStatus;
  final String fiscalError;
  final DateTime? fiscalizedAt;
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

  final DateTime? startDate;
  final DateTime? endDate;

  RoomInvoiceModel({
    required this.id,
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
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'clientIfu': clientIfu,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,
      'roomNumber': roomNumber,
      'nights': nights,
      'pricePerNight': pricePerNight,
      'roomTotal': roomTotal,
      'extrasTotal': extrasTotal,
      'servicesTotal': servicesTotal,
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'aibType': aibType,
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
      'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),
      'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
    };
  }

  factory RoomInvoiceModel.fromMap(String id, Map<String, dynamic> map) {
    return RoomInvoiceModel(
      id: id,
      clientName: map['clientName']?.toString() ?? '',
      clientIfu: map['clientIfu']?.toString() ?? '',
      clientAddress: map['clientAddress']?.toString() ?? '',
      clientPhone: map['clientPhone']?.toString() ?? '',
      roomNumber: map['roomNumber']?.toString() ?? '',
      nights: _toInt(map['nights']),
      pricePerNight: _toDouble(map['pricePerNight']),
      roomTotal: _toDouble(map['roomTotal']),
      extrasTotal: _toDouble(map['extrasTotal']),
      servicesTotal: _toDouble(map['servicesTotal']),
      total: _toDouble(map['total']),
      status: map['status']?.toString() ?? 'unpaid',
      paymentMethod: map['paymentMethod']?.toString() ?? 'cash',
      aibType: map['aibType']?.toString() ?? 'none',
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
      startDate: _toDate(map['startDate']),
      endDate: _toDate(map['endDate']),
    );
  }
}
