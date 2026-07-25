import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:takapp/modeles/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _menuCol({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('menuItems');
  }

  /// =========================
  /// AVAILABLE MENU ITEMS
  /// =========================

  Stream<List<MenuItemModel>> getAvailableMenuItems({
    required String establishmentId,
  }) {
    return _menuCol(
      establishmentId: establishmentId,
    ).where('isAvailable', isEqualTo: true).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
          .toList();

      items.sort((a, b) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return items;
    });
  }

  /// =========================
  /// AVAILABLE KITCHEN ITEMS
  /// =========================

  Stream<List<MenuItemModel>> getAvailableKitchenMenuItems({
    required String establishmentId,
  }) {
    return _menuCol(establishmentId: establishmentId)
        .where('isAvailable', isEqualTo: true)
        .where('isForKitchen', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
              .toList();

          items.sort((a, b) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return items;
        });
  }

  /// =========================
  /// AVAILABLE BAR ITEMS
  /// =========================

  Stream<List<MenuItemModel>> getAvailableBarMenuItems({
    required String establishmentId,
  }) {
    return _menuCol(establishmentId: establishmentId)
        .where('isAvailable', isEqualTo: true)
        .where('isForBar', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
              .toList();

          items.sort((a, b) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return items;
        });
  }
}
