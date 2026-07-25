class EmcfInvoiceCreateResponseModel {
  final String uid;
  final int ta;
  final int tb;
  final int tc;
  final int td;
  final int taa;
  final int tab;
  final int tac;
  final int tad;
  final int tae;
  final int taf;
  final int hab;
  final int had;
  final int vab;
  final int vad;
  final int aib;
  final int ts;
  final int total;
  final String errorCode;
  final String errorDesc;
  final Map<String, dynamic> raw;

  const EmcfInvoiceCreateResponseModel({
    required this.uid,
    required this.ta,
    required this.tb,
    required this.tc,
    required this.td,
    required this.taa,
    required this.tab,
    required this.tac,
    required this.tad,
    required this.tae,
    required this.taf,
    required this.hab,
    required this.had,
    required this.vab,
    required this.vad,
    required this.aib,
    required this.ts,
    required this.total,
    required this.errorCode,
    required this.errorDesc,
    required this.raw,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  factory EmcfInvoiceCreateResponseModel.fromMap(Map<String, dynamic> map) {
    return EmcfInvoiceCreateResponseModel(
      uid: map['uid']?.toString() ?? '',
      ta: _toInt(map['ta']),
      tb: _toInt(map['tb']),
      tc: _toInt(map['tc']),
      td: _toInt(map['td']),
      taa: _toInt(map['taa']),
      tab: _toInt(map['tab']),
      tac: _toInt(map['tac']),
      tad: _toInt(map['tad']),
      tae: _toInt(map['tae']),
      taf: _toInt(map['taf']),
      hab: _toInt(map['hab']),
      had: _toInt(map['had']),
      vab: _toInt(map['vab']),
      vad: _toInt(map['vad']),
      aib: _toInt(map['aib']),
      ts: _toInt(map['ts']),
      total: _toInt(map['total']),
      errorCode: map['errorCode']?.toString() ?? '',
      errorDesc: map['errorDesc']?.toString() ?? '',
      raw: map,
    );
  }

  bool get hasError => errorCode.trim().isNotEmpty || uid.trim().isEmpty;
}
