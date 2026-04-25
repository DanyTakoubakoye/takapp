class FiscalizationResultModel {
  final bool success;
  final String message;
  final String mecefCode;
  final String nim;
  final String counter;
  final DateTime? machineDateTime;
  final String rawResponse;

  const FiscalizationResultModel({
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
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return FiscalizationResultModel(
      success: map['success'] == true,
      message: map['message']?.toString() ?? '',
      mecefCode: map['mecefCode']?.toString() ?? '',
      nim: map['nim']?.toString() ?? '',
      counter: map['counter']?.toString() ?? '',
      machineDateTime: parseDate(map['machineDateTime']),
      rawResponse: map['rawResponse']?.toString() ?? '',
    );
  }
}
