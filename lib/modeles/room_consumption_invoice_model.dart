import 'room_consumption_line_model.dart';

class RoomConsumptionInvoiceModel {
  /// SaaS
  final String establishmentId;

  /// Chambre concernée
  final String roomNumber;

  /// Période de facturation
  final DateTime startDate;
  final DateTime endDate;

  /// Lignes de consommation
  final List<RoomConsumptionLineModel> lines;

  /// Total facture
  final double total;

  /// Fiscalisation
  final bool isFiscalized;
  final String fiscalUid;
  final String qrCode;
  final String nim;

  /// Statut
  final String status;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  const RoomConsumptionInvoiceModel({
    required this.establishmentId,
    required this.roomNumber,
    required this.startDate,
    required this.endDate,
    required this.lines,
    required this.total,

    required this.isFiscalized,
    required this.fiscalUid,
    required this.qrCode,
    required this.nim,

    required this.status,

    required this.pendingSync,
    required this.syncError,
  });

  factory RoomConsumptionInvoiceModel.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime toDate(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }

      return DateTime.now();
    }

    final rawLines = (map['lines'] as List?) ?? const [];

    return RoomConsumptionInvoiceModel(
      /// SaaS
      establishmentId: (map['establishmentId'] ?? '').toString(),

      /// Chambre
      roomNumber: (map['roomNumber'] ?? '').toString(),

      /// Dates
      startDate: toDate(map['startDate']),

      endDate: toDate(map['endDate']),

      /// Lignes
      lines: rawLines
          .whereType<Map>()
          .map(
            (e) =>
                RoomConsumptionLineModel.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),

      /// Total
      total: toDouble(map['total']),

      /// Fiscalisation
      isFiscalized: map['isFiscalized'] == true,

      fiscalUid: (map['fiscalUid'] ?? '').toString(),

      qrCode: (map['qrCode'] ?? '').toString(),

      nim: (map['nim'] ?? '').toString(),

      /// Statut
      status: (map['status'] ?? 'pending').toString(),

      /// Offline
      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Chambre
      'roomNumber': roomNumber,

      /// Dates
      'startDate': startDate.toIso8601String(),

      'endDate': endDate.toIso8601String(),

      /// Lignes
      'lines': lines.map((e) => e.toMap()).toList(),

      /// Total
      'total': total,

      /// Fiscalisation
      'isFiscalized': isFiscalized,
      'fiscalUid': fiscalUid,
      'qrCode': qrCode,
      'nim': nim,

      /// Statut
      'status': status,

      /// Offline
      'pendingSync': pendingSync,
      'syncError': syncError,
    };
  }

  RoomConsumptionInvoiceModel copyWith({
    String? establishmentId,
    String? roomNumber,
    DateTime? startDate,
    DateTime? endDate,
    List<RoomConsumptionLineModel>? lines,
    double? total,

    bool? isFiscalized,
    String? fiscalUid,
    String? qrCode,
    String? nim,

    String? status,

    bool? pendingSync,
    bool? syncError,
  }) {
    return RoomConsumptionInvoiceModel(
      establishmentId: establishmentId ?? this.establishmentId,

      roomNumber: roomNumber ?? this.roomNumber,

      startDate: startDate ?? this.startDate,

      endDate: endDate ?? this.endDate,

      lines: lines ?? this.lines,

      total: total ?? this.total,

      isFiscalized: isFiscalized ?? this.isFiscalized,

      fiscalUid: fiscalUid ?? this.fiscalUid,

      qrCode: qrCode ?? this.qrCode,

      nim: nim ?? this.nim,

      status: status ?? this.status,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,
    );
  }
}
