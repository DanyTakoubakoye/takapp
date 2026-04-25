class EmcfSecurityElementModel {
  final String dateTime;
  final String qrCode;
  final String codeMECeFDGI;
  final String counters;
  final String nim;
  final String errorCode;
  final String errorDesc;
  final Map<String, dynamic> raw;

  const EmcfSecurityElementModel({
    required this.dateTime,
    required this.qrCode,
    required this.codeMECeFDGI,
    required this.counters,
    required this.nim,
    required this.errorCode,
    required this.errorDesc,
    required this.raw,
  });

  factory EmcfSecurityElementModel.fromMap(Map<String, dynamic> map) {
    return EmcfSecurityElementModel(
      dateTime: map['dateTime']?.toString() ?? '',
      qrCode: map['qrCode']?.toString() ?? '',
      codeMECeFDGI: map['codeMECeFDGI']?.toString() ?? '',
      counters: map['counters']?.toString() ?? '',
      nim: map['nim']?.toString() ?? '',
      errorCode: map['errorCode']?.toString() ?? '',
      errorDesc: map['errorDesc']?.toString() ?? '',
      raw: map,
    );
  }

  bool get hasError =>
      errorCode.trim().isNotEmpty || codeMECeFDGI.trim().isEmpty;
}
