import 'fiscal_invoice_item_model.dart';

class FiscalInvoiceRequestModel {
  /// SaaS
  final String establishmentId;
  final String establishmentName;

  final String invoiceId;
  final String invoiceType; // FV, FA, EV, EA

  final String clientName;
  final String clientIfu;
  final String clientAddress;
  final String clientPhone;

  final String sellerName;

  final String paymentMethod; // cash, mobile_money, bank, card, credit
  final String aibType; // none, aib1, aib5

  final String roomNumber;

  final DateTime? startDate;
  final DateTime? endDate;

  final List<FiscalInvoiceItemModel> items;

  final String? originalMecefCode;

  const FiscalInvoiceRequestModel({
    required this.establishmentId,
    required this.establishmentName,
    required this.invoiceId,
    required this.invoiceType,
    required this.clientName,
    required this.clientIfu,
    required this.clientAddress,
    required this.clientPhone,
    required this.sellerName,
    required this.paymentMethod,
    required this.aibType,
    required this.roomNumber,
    required this.startDate,
    required this.endDate,
    required this.items,
    this.originalMecefCode,
  });

  double get total {
    return items.fold<double>(0, (sum, item) => sum + item.total);
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,

      'invoiceId': invoiceId,
      'invoiceType': invoiceType,

      'clientName': clientName,
      'clientIfu': clientIfu,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,

      'sellerName': sellerName,
      'paymentMethod': paymentMethod,
      'aibType': aibType,

      'roomNumber': roomNumber,

      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),

      'originalMecefCode': originalMecefCode,

      'items': items.map((e) => e.toMap()).toList(),

      'total': total,
    };
  }
}
