import 'menu_ingredient_model.dart';

class MenuItemModel {
  final String id;
  final String establishmentId;
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
    required this.establishmentId,
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
      establishmentId: (map['establishmentId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      composition: (map['composition'] ?? '').toString(),
      adresse: map['adresse']?.toString(),
      category: (map['category'] ?? '').toString(),
      price: toDouble(map['price']),
      isAvailable: map['isAvailable'] == true,
      isForKitchen: map['isForKitchen'] == true,
      isForBar: map['isForBar'] == true,
      ingredients: rawIngredients
          .whereType<Map>()
          .map((e) => MenuIngredientModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
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

  MenuItemModel copyWith({
    String? id,
    String? establishmentId,
    String? name,
    String? composition,
    String? adresse,
    String? category,
    double? price,
    bool? isAvailable,
    bool? isForKitchen,
    bool? isForBar,
    List<MenuIngredientModel>? ingredients,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      name: name ?? this.name,
      composition: composition ?? this.composition,
      adresse: adresse ?? this.adresse,
      category: category ?? this.category,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      isForKitchen: isForKitchen ?? this.isForKitchen,
      isForBar: isForBar ?? this.isForBar,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}
