class EmcfStatusModel {
  final bool status;
  final String version;
  final String ifu;
  final String nim;
  final String tokenValid;
  final String serverDateTime;
  final int pendingRequestsCount;
  final List<Map<String, dynamic>> pendingRequestsList;

  const EmcfStatusModel({
    required this.status,
    required this.version,
    required this.ifu,
    required this.nim,
    required this.tokenValid,
    required this.serverDateTime,
    required this.pendingRequestsCount,
    required this.pendingRequestsList,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  factory EmcfStatusModel.fromMap(Map<String, dynamic> map) {
    final list = <Map<String, dynamic>>[];
    if (map['pendingRequestsList'] is List) {
      for (final item in map['pendingRequestsList']) {
        if (item is Map<String, dynamic>) {
          list.add(item);
        }
      }
    }

    return EmcfStatusModel(
      status: map['status'] == true,
      version: map['version']?.toString() ?? '',
      ifu: map['ifu']?.toString() ?? '',
      nim: map['nim']?.toString() ?? map['nime']?.toString() ?? '',
      tokenValid: map['tokenValid']?.toString() ?? '',
      serverDateTime: map['serverDateTime']?.toString() ?? '',
      pendingRequestsCount: _toInt(map['pendingRequestsCount']),
      pendingRequestsList: list,
    );
  }
}
