class OrderItemModel {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String note;
  final String targetDepartment;

  const OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.note,
    required this.targetDepartment,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuItemId: (map['menuItemId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      note: (map['note'] ?? '').toString(),
      targetDepartment: (map['targetDepartment'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'note': note,
      'targetDepartment': targetDepartment,
    };
  }

  OrderItemModel copyWith({
    String? menuItemId,
    String? name,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? note,
    String? targetDepartment,
  }) {
    return OrderItemModel(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      note: note ?? this.note,
      targetDepartment: targetDepartment ?? this.targetDepartment,
    );
  }
}
