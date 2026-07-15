class FiscalizationResultModel {
  /// =========================
  /// SAAS
  /// =========================

  final String? establishmentId;

  final String? establishmentName;

  /// =========================
  /// RESULTAT
  /// =========================

  final bool success;

  final String message;

  final String mecefCode;

  final String nim;

  final String counter;

  final DateTime? machineDateTime;

  final String rawResponse;

  const FiscalizationResultModel({
    this.establishmentId,
    this.establishmentName,

    required this.success,
    required this.message,
    required this.mecefCode,
    required this.nim,
    required this.counter,
    required this.machineDateTime,
    required this.rawResponse,
  });

  factory FiscalizationResultModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }

      return DateTime.tryParse(value.toString());
    }

    return FiscalizationResultModel(
      /// =========================
      /// SAAS
      /// =========================
      establishmentId: map['establishmentId']?.toString(),

      establishmentName: map['establishmentName']?.toString(),

      /// =========================
      /// RESULTAT
      /// =========================
      success: map['success'] == true,

      message: map['message']?.toString() ?? '',

      mecefCode: map['mecefCode']?.toString() ?? '',

      nim: map['nim']?.toString() ?? '',

      counter: map['counter']?.toString() ?? '',

      machineDateTime: parseDate(map['machineDateTime']),

      rawResponse: map['rawResponse']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// =========================
      /// SAAS
      /// =========================
      'establishmentId': establishmentId,

      'establishmentName': establishmentName,

      /// =========================
      /// RESULTAT
      /// =========================
      'success': success,

      'message': message,

      'mecefCode': mecefCode,

      'nim': nim,

      'counter': counter,

      'machineDateTime': machineDateTime?.toIso8601String(),

      'rawResponse': rawResponse,
    };
  }
}
