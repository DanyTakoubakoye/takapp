import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MenuItemModel>> getAvailableMenuItems() {
    return _firestore
        .collection('menuItems')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
