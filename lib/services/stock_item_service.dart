import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/stock_item_model.dart';

class StockItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('stock_items');

  Stream<List<StockItemModel>> streamItems() {
    return _col.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => StockItemModel.fromMap(doc.id, doc.data()))
          .where((item) => item.isActive)
          .toList();

      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return items;
    });
  }

  Stream<List<StockItemModel>> streamItemsForStore(String store) {
    return _col
        .where('store', isEqualTo: store)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => StockItemModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return items;
        });
  }

  Future<void> createItem({
    required String name,
    required String category,
    required String unit,
    required String store,
  }) async {
    await _col.add({
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'store': store.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
