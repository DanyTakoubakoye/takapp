import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/stock_request_item_model.dart';
import '../modeles/stock_request_model.dart';
import 'store_stock_service.dart';

class StockRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreStockService _storeStockService = StoreStockService();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('stock_requests');

  Stream<List<StockRequestModel>> streamRequestsForStore(String store) {
    return _col.where('store', isEqualTo: store).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => StockRequestModel.fromMap(doc.id, doc.data()))
          .toList();

      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Stream<List<StockRequestModel>> streamAllRequests() {
    return _col.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => StockRequestModel.fromMap(doc.id, doc.data()))
          .toList();

      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  Stream<List<StockRequestModel>> streamRequestsForReceiver(String store) {
    return _col
        .where('store', isEqualTo: store)
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => StockRequestModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort((a, b) {
            final aDate = a.deliveredAt ?? DateTime(2000);
            final bDate = b.deliveredAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });

          return items;
        });
  }

  Stream<List<StockRequestModel>> streamPendingRequests() {
    return _col.where('status', isEqualTo: 'pending').snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => StockRequestModel.fromMap(doc.id, doc.data()))
          .toList();

      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Future<void> createRequest({
    required String store,
    required String requestedBy,
    required String requestedByName,
    required String requestedByRole,
    required String note,
    required List<StockRequestItemModel> items,
  }) async {
    final docRef = await _col.add({
      'store': store,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedByRole': requestedByRole,
      'status': 'pending',
      'note': note,
      'validatedByManager': false,
      'validatedByReceiver': false,
      'createdAt': FieldValue.serverTimestamp(),
      'deliveredAt': null,
      'receivedAt': null,
      'receivedBy': '',
      'receivedByName': '',
    });

    for (final item in items) {
      await docRef.collection('items').add(item.toMap());
    }
  }

  Future<List<StockRequestItemModel>> getRequestItems(String requestId) async {
    final snapshot = await _col.doc(requestId).collection('items').get();
    return snapshot.docs
        .map((doc) => StockRequestItemModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> deliverRequest({
    required String requestId,
    required String deliveredBy,
    required String deliveredByName,
    required List<StockRequestItemModel> deliveredItems,
    required String store,
  }) async {
    for (final item in deliveredItems) {
      await _storeStockService.addStock(
        store: store,
        itemId: item.itemId,
        itemName: item.itemName,
        unit: item.unit,
        quantity: item.quantityDelivered,
        performedBy: deliveredBy,
        performedByName: deliveredByName,
        reason: 'Approvisionnement validé',
        sourceRequestId: requestId,
      );

      await _col.doc(requestId).collection('items').doc(item.id).update({
        'quantityDelivered': item.quantityDelivered,
      });
    }

    await _col.doc(requestId).update({
      'status': 'delivered',
      'validatedByManager': true,
      'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmReception({
    required String requestId,
    required String receivedBy,
    required String receivedByName,
  }) async {
    await _col.doc(requestId).update({
      'status': 'received',
      'validatedByReceiver': true,
      'receivedAt': FieldValue.serverTimestamp(),
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,
    });
  }
}
