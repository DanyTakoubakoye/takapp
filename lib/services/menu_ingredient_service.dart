import 'package:cloud_firestore/cloud_firestore.dart';

class MenuIngredientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamKitchenMenuItems() {
    return _db
        .collection('menuItems')
        .where('isForKitchen', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRestaurantStockItems() {
    return _db
        .collection('stock_items')
        .where('store', isEqualTo: 'restaurant')
        .orderBy('name')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBarMenuItems() {
    return _db
        .collection('menuItems')
        .where('isForBar', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBarStockItems() {
    return _db
        .collection('stock_items')
        .where('store', isEqualTo: 'bar')
        .orderBy('name')
        .snapshots();
  }

  Future<void> updateMenuItemIngredients({
    required String menuItemId,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    await _db.collection('menuItems').doc(menuItemId).update({
      'ingredients': ingredients,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
