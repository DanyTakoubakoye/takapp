class RoomConsumptionLineModel {
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double total;
  final String source; // bar / restaurant
  final DateTime createdAt;
  final String serveur;

  RoomConsumptionLineModel({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.source,
    required this.createdAt,
    required this.serveur,
  });
}
