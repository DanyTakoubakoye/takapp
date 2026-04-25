class FiscalInvoiceItemModel {
  final String code;
  final String name;
  final double quantity;
  final double unitPrice;
  final String taxGroup;
  final String unit;

  const FiscalInvoiceItemModel({
    required this.code,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.taxGroup,
    this.unit = 'Qte',
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxGroup': taxGroup,
      'unit': unit,
      'total': total,
    };
  }

  factory FiscalInvoiceItemModel.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return FiscalInvoiceItemModel(
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      quantity: toDouble(map['quantity']),
      unitPrice: toDouble(map['unitPrice']),
      taxGroup: map['taxGroup']?.toString() ?? 'B',
      unit: map['unit']?.toString() ?? 'Qte',
    );
  }
}
