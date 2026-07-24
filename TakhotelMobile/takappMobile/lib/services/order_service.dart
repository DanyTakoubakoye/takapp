import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/order_item_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String clientType,
    required String? tableNumber,
    required String? roomNumber,
    required String createdBy,
    required String createdByName,
    required double subtotal,
    required double tax,
    required double total,
    required List<OrderItemModel> items,
  }) async {
    final now = DateTime.now();

    final orderNumber =
        'CMD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch}';

    final bool isForKitchen = items.any(
      (item) => item.targetDepartment == 'kitchen',
    );

    final docRef = _firestore.collection('orders').doc();
    final batch = _firestore.batch();

    batch.set(docRef, {
      'orderNumber': orderNumber,
      'clientType': clientType,
      'tableNumber': tableNumber,
      'roomNumber': roomNumber,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'status': 'sent',
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentStatus': 'unpaid',
      'createdAt': FieldValue.serverTimestamp(),
      'kitchenStatus': isForKitchen ? 'pending' : 'ready',
      'isForKitchen': isForKitchen,
    });

    for (final item in items) {
      final itemRef = docRef.collection('items').doc();
      batch.set(itemRef, item.toMap());
    }

    await batch.commit();
  }
}
