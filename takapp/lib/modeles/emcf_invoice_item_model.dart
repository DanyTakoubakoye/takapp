class EmcfInvoiceItemModel {
  final String code;
  final String name;
  final int price;
  final double quantity;
  final String taxGroup;
  final int taxSpecific;
  final int? originalPrice;
  final String? priceModification;

  const EmcfInvoiceItemModel({
    required this.code,
    required this.name,
    required this.price,
    required this.quantity,
    required this.taxGroup,
    this.taxSpecific = 0,
    this.originalPrice,
    this.priceModification,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'code': code,
      'name': name,
      'price': price,
      'quantity': quantity,
      'taxGroup': taxGroup,
    };

    if (taxSpecific > 0) {
      map['taxSpecific'] = taxSpecific;
    }

    if (originalPrice != null) {
      map['originalPrice'] = originalPrice;
    }

    if (priceModification != null && priceModification!.trim().isNotEmpty) {
      map['priceModification'] = priceModification;
    }

    return map;
  }
}
