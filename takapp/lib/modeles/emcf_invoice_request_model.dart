import 'emcf_invoice_item_model.dart';

class EmcfInvoiceRequestModel {
  final String ifu;

  final String? aib;

  /// FV, FA, EV, EA
  final String type;

  final List<EmcfInvoiceItemModel> items;

  final Map<String, dynamic>? client;

  final Map<String, dynamic> operatorData;

  final List<Map<String, dynamic>>? payment;

  final String? reference;

  /// =========================
  /// SAAS
  /// =========================

  final String? establishmentId;

  final String? establishmentName;

  const EmcfInvoiceRequestModel({
    required this.ifu,
    required this.type,
    required this.items,
    required this.operatorData,

    this.aib,
    this.client,
    this.payment,
    this.reference,

    this.establishmentId,
    this.establishmentName,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'ifu': ifu,

      'type': type,

      'items': items.map((e) => e.toMap()).toList(),

      'operator': operatorData,
    };

    if (aib != null && aib!.trim().isNotEmpty) {
      map['aib'] = aib;
    }

    if (client != null) {
      map['client'] = client;
    }

    if (payment != null && payment!.isNotEmpty) {
      map['payment'] = payment;
    }

    if (reference != null && reference!.trim().isNotEmpty) {
      map['reference'] = reference;
    }

    /// =========================
    /// SAAS
    /// =========================

    if (establishmentId != null && establishmentId!.trim().isNotEmpty) {
      map['establishmentId'] = establishmentId;
    }

    if (establishmentName != null && establishmentName!.trim().isNotEmpty) {
      map['establishmentName'] = establishmentName;
    }

    return map;
  }
}
