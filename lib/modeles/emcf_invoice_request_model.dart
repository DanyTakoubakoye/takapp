import 'emcf_invoice_item_model.dart';

class EmcfInvoiceRequestModel {
  final String ifu;
  final String? aib; // A=1%, B=5%, null si aucun AIB
  final String type; // FV, FA, EV, EA
  final List<EmcfInvoiceItemModel> items;
  final Map<String, dynamic>? client;
  final Map<String, dynamic> operatorData;
  final List<Map<String, dynamic>>? payment;
  final String? reference;

  const EmcfInvoiceRequestModel({
    required this.ifu,
    required this.type,
    required this.items,
    required this.operatorData,
    this.aib,
    this.client,
    this.payment,
    this.reference,
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

    return map;
  }
}
