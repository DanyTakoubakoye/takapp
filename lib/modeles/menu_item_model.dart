import 'menu_ingredient_model.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String composition;
  final String? adresse;
  final String category;
  final double price;
  final bool isAvailable;
  final bool isForKitchen;
  final bool isForBar;
  final List<MenuIngredientModel> ingredients;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.composition,
    required this.category,
    required this.price,
    required this.isAvailable,
    required this.isForKitchen,
    required this.isForBar,
    this.adresse,
    this.ingredients = const [],
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final rawIngredients = (map['ingredients'] as List?) ?? const [];

    return MenuItemModel(
      id: documentId,
      name: (map['name'] ?? '').toString(),
      composition: (map['composition'] ?? '').toString(),
      adresse: map['adresse']?.toString(),
      category: (map['category'] ?? '').toString(),
      price: toDouble(map['price']),
      isAvailable: map['isAvailable'] ?? true,
      isForKitchen: map['isForKitchen'] ?? false,
      isForBar: map['isForBar'] ?? false,
      ingredients: rawIngredients
          .map(
            (e) => MenuIngredientModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'composition': composition,
      'category': category,
      'adresse': adresse,
      'price': price,
      'isAvailable': isAvailable,
      'isForKitchen': isForKitchen,
      'isForBar': isForBar,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
    };
  }
}
