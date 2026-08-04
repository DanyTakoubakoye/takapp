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
/// Enregistre uniquement l'URL de la photo d'un plat (sans toucher aux
  /// ingrédients). Utilisé par le sélecteur de photo côté chef.
  Future<void> updateMenuItemImage({
    required String establishmentId,
    required String menuItemId,
    required String adresse,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }
    if (menuItemId.trim().isEmpty) {
      throw Exception('Identifiant menu invalide.');
    }
    await _menuItemsCol(
      establishmentId: establishmentId,
    ).doc(menuItemId).update({
      'adresse': adresse,
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }
  Future<void> updateMenuItemIngredients({
    required String establishmentId,
    required String menuItemId,
    required List<Map<String, dynamic>> ingredients,
    String? composition,
    bool? allowsFreeAccompaniment,
    String? adresse,
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
    final data = <String, dynamic>{
      'ingredients': normalizedIngredients,
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    };
    // On n'écrit la composition que si elle est fournie (non null).
    if (composition != null) {
      data['composition'] = composition.trim();
    }
    if (allowsFreeAccompaniment != null) {
      data['allowsFreeAccompaniment'] = allowsFreeAccompaniment;
    }
    if (adresse != null) {
      data['adresse'] = adresse;
    }
    await _menuItemsCol(
      establishmentId: establishmentId,
    ).doc(menuItemId).update(data);
  }

  /// Crée un plat cuisine (article menu) sans prix.
  /// Le chef définit le nom ; la gérante fixera le prix ensuite.
  Future<void> createKitchenMenuItem({
    required String establishmentId,
    required String name,
    String category = 'plat',
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }
    if (name.trim().isEmpty) {
      throw Exception('Nom du plat obligatoire.');
    }
    final docRef = _menuItemsCol(establishmentId: establishmentId).doc();
    await docRef.set({
      'id': docRef.id,
      'establishmentId': establishmentId,
      'name': name.trim(),
      'composition': '',
      'category': category.trim().isEmpty ? 'plat' : category.trim(),
      'price': 0,
      'isAvailable': true,
      'isForKitchen': true,
      'isForBar': false,
      'ingredients': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }
}
