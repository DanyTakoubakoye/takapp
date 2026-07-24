class MenuItemModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isAvailable;
  final bool isForKitchen;
  final bool isForBar;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
    required this.isForKitchen,
    required this.isForBar,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MenuItemModel(
      id: documentId,
      name: (map['name'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      price: (map['price'] ?? 0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      isForKitchen: map['isForKitchen'] ?? false,
      isForBar: map['isForBar'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'isAvailable': isAvailable,
      'isForKitchen': isForKitchen,
      'isForBar': isForBar,
    };
  }
}
