import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/menu_item_model.dart';

class MenuAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMenuItem(MenuItemModel item) async {
    await _firestore.collection('menuItems').add(item.toMap());
  }

  Stream<List<MenuItemModel>> streamMenuItems() {
    return _firestore
        .collection('menuItems')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> deleteMenuItem(String id) async {
    await _firestore.collection('menuItems').doc(id).delete();
  }

  Future<void> updateAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    await _firestore.collection('menuItems').doc(id).update({
      'isAvailable': isAvailable,
    });
  }
}
