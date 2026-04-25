class StockRequestItemModel {
  final String id;
  final String itemId;
  final String itemName;
  final String unit;
  final double quantityRequested;
  final double quantityDelivered;

  StockRequestItemModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantityRequested,
    required this.quantityDelivered,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,
      'quantityRequested': quantityRequested,
      'quantityDelivered': quantityDelivered,
    };
  }

  factory StockRequestItemModel.fromMap(String id, Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StockRequestItemModel(
      id: id,
      itemId: map['itemId']?.toString() ?? '',
      itemName: map['itemName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      quantityRequested: toDouble(map['quantityRequested']),
      quantityDelivered: toDouble(map['quantityDelivered']),
    );
  }
}
