class MenuIngredientModel {
  final String itemId;
  final String itemName;
  final String store;
  final String unit;
  final double quantity;

  const MenuIngredientModel({
    required this.itemId,
    required this.itemName,
    required this.store,
    required this.unit,
    required this.quantity,
  });

  factory MenuIngredientModel.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return MenuIngredientModel(
      itemId: (map['itemId'] ?? '').toString(),
      itemName: (map['itemName'] ?? '').toString(),
      store: (map['store'] ?? '').toString(),
      unit: (map['unit'] ?? '').toString(),
      quantity: toDouble(map['quantity']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'store': store,
      'unit': unit,
      'quantity': quantity,
    };
  }
}
