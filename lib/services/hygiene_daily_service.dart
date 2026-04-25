import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_stock_service.dart';

class HygieneDailyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreStockService _stockService = StoreStockService();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('hygiene_daily_entries');

  Future<void> createDailyEntry({
    required String roomNumber,
    required String preparedBy,
    required String preparedByName,
    required String note,
    required List<Map<String, dynamic>> usedItems,
  }) async {
    final docRef = await _col.add({
      'roomNumber': roomNumber.trim(),
      'preparedBy': preparedBy,
      'preparedByName': preparedByName,
      'note': note.trim(),
      'preparedAt': FieldValue.serverTimestamp(),
    });

    for (final item in usedItems) {
      await docRef.collection('items').add({
        'itemId': item['itemId'],
        'itemName': item['itemName'],
        'unit': item['unit'],
        'quantityUsed': item['quantityUsed'],
      });

      await _stockService.removeStock(
        store: 'hotel',
        itemId: item['itemId'].toString(),
        itemName: item['itemName'].toString(),
        unit: item['unit'].toString(),
        quantity: (item['quantityUsed'] as num).toDouble(),
        performedBy: preparedBy,
        performedByName: preparedByName,
        reason: 'Préparation chambre $roomNumber',
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDailyEntries() {
    return _col.orderBy('preparedAt', descending: true).snapshots();
  }
}
