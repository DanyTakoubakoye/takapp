import 'package:certilink_flutter_sdk/certilink_flutter_sdk.dart';

import '../modeles/certilink_config_model.dart';

class CertilinkCertificationService {
  Future<CertiLinkInvoiceResponse> certifyInvoice({
    required CertilinkConfigModel config,
    required String externalInvoiceId,
    required String externalInvoiceNumber,
    required String invoiceType,
    required Map<String, dynamic> client,
    required List<Map<String, dynamic>> items,
    DateTime? invoiceDate,
  }) async {
    if (!config.enabled) {
      throw Exception('CertiLink est désactivé pour cet établissement.');
    }

    if (config.tenantId.trim().isEmpty || config.apiKey.trim().isEmpty) {
      throw Exception('Configuration CertiLink incomplète.');
    }

    if (items.isEmpty) {
      throw Exception('La facture doit contenir au moins un article.');
    }

    final certilink = CertiLinkClient(
      tenantId: config.tenantId.trim(),
      apiKey: config.apiKey.trim(),
    );

    try {
      final request = CertiLinkInvoiceRequest(
        externalInvoiceId: externalInvoiceId,
        externalInvoiceNumber: externalInvoiceNumber,
        invoiceType: invoiceType,
        client: CertiLinkInvoiceClient(
          name: client['name']?.toString() ?? '',
          ifu: client['ifu']?.toString() ?? '',
          phone: client['phone']?.toString() ?? '',
          email: client['email']?.toString() ?? '',
          address: client['address']?.toString() ?? '',
        ),
        items: items.map((item) {
          return CertiLinkInvoiceItem(
            itemId: item['itemId']?.toString() ?? '',
            ref: item['ref']?.toString() ?? '',
            name:
                item['name']?.toString() ??
                item['description']?.toString() ??
                'Article',
            description: item['description']?.toString() ?? '',
            quantity: _toDouble(item['quantity']),
            unit: item['unit']?.toString() ?? 'Unité',
            unitPrice: _toDouble(item['unitPrice']),
            discountAmount: _toDouble(item['discountAmount']),
            taxGroup: item['taxGroup']?.toString() ?? 'B',
            specificTaxAmount: _toDouble(item['specificTaxAmount']),
          );
        }).toList(),
        softwareName: config.softwareName,
        softwareVersion: config.softwareVersion,
        invoiceDate: invoiceDate ?? DateTime.now(),
      );

      return await certilink.certifyInvoice(request);
    } finally {
      certilink.close();
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.').trim()) ?? 0;
  }
}
