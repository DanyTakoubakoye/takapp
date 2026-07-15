import 'package:cloud_firestore/cloud_firestore.dart';

class MenuIngredientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _menuItemsCol({
    required String establishmentId,
  }) {
    return _db
        .collection('establishments')
        .doc(establishmentId)
        .collection('menuItems');
  }

  CollectionReference<Map<String, dynamic>> _stockItemsCol({
    required String establishmentId,
  }) {
    return _db
        .collection('establishments')
        .doc(establishmentId)
        .collection('stock_items');
  }

  /// =========================
  /// STREAM KITCHEN MENU ITEMS
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamKitchenMenuItems({
    required String establishmentId,
  }) {
    return _menuItemsCol(
      establishmentId: establishmentId,
    ).where('isForKitchen', isEqualTo: true).orderBy('name').snapshots();
  }

  /// =========================
  /// STREAM RESTAURANT STOCK
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRestaurantStockItems({
    required String establishmentId,
  }) {
    return _stockItemsCol(
      establishmentId: establishmentId,
    ).where('store', isEqualTo: 'restaurant').orderBy('name').snapshots();
  }

  /// =========================
  /// STREAM BAR MENU ITEMS
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBarMenuItems({
    required String establishmentId,
  }) {
    return _menuItemsCol(
      establishmentId: establishmentId,
    ).where('isForBar', isEqualTo: true).orderBy('name').snapshots();
  }

  /// =========================
  /// STREAM BAR STOCK ITEMS
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBarStockItems({
    required String establishmentId,
  }) {
    return _stockItemsCol(
      establishmentId: establishmentId,
    ).where('store', isEqualTo: 'bar').orderBy('name').snapshots();
  }

  /// =========================
  /// STREAM HOTEL STOCK ITEMS
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamHotelStockItems({
    required String establishmentId,
  }) {
    return _stockItemsCol(
      establishmentId: establishmentId,
    ).where('store', isEqualTo: 'hotel').orderBy('name').snapshots();
  }

  /// =========================
  /// UPDATE MENU INGREDIENTS
  /// =========================

  Future<void> updateMenuItemIngredients({
    required String establishmentId,
    required String menuItemId,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }

    if (menuItemId.trim().isEmpty) {
      throw Exception('Identifiant menu invalide.');
    }

    final normalizedIngredients = ingredients.map((ingredient) {
      return {...ingredient, 'establishmentId': establishmentId};
    }).toList();

    await _menuItemsCol(
      establishmentId: establishmentId,
    ).doc(menuItemId).update({
      'ingredients': normalizedIngredients,

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });
  }
}
