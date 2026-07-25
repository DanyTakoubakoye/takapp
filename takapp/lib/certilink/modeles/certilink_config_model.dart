class CertilinkConfigModel {
  final bool enabled;
  final String tenantId;
  final String apiKey;
  final String softwareName;
  final String softwareVersion;

  const CertilinkConfigModel({
    required this.enabled,
    required this.tenantId,
    required this.apiKey,
    required this.softwareName,
    required this.softwareVersion,
  });

  factory CertilinkConfigModel.empty() {
    return const CertilinkConfigModel(
      enabled: false,
      tenantId: '',
      apiKey: '',
      softwareName: 'Takapp',
      softwareVersion: '1.0.0',
    );
  }

  factory CertilinkConfigModel.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};

    return CertilinkConfigModel(
      enabled: data['enabled'] == true,
      tenantId: data['tenantId']?.toString() ?? '',
      apiKey: data['apiKey']?.toString() ?? '',
      softwareName: data['softwareName']?.toString() ?? 'Takapp',
      softwareVersion: data['softwareVersion']?.toString() ?? '1.0.0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'tenantId': tenantId,
      'apiKey': apiKey,
      'softwareName': softwareName,
      'softwareVersion': softwareVersion,
    };
  }

  CertilinkConfigModel copyWith({
    bool? enabled,
    String? tenantId,
    String? apiKey,
    String? softwareName,
    String? softwareVersion,
  }) {
    return CertilinkConfigModel(
      enabled: enabled ?? this.enabled,
      tenantId: tenantId ?? this.tenantId,
      apiKey: apiKey ?? this.apiKey,
      softwareName: softwareName ?? this.softwareName,
      softwareVersion: softwareVersion ?? this.softwareVersion,
    );
  }
}
