import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/stock_request_item_model.dart';
import '../modeles/stock_request_model.dart';
import 'store_stock_service.dart';

class StockRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StoreStockService _storeStockService = StoreStockService();

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('stock_requests');
  }

  /// =========================
  /// STREAM REQUESTS FOR STORE
  /// =========================

  Stream<List<StockRequestModel>> streamRequestsForStore({
    required String establishmentId,
    required String store,
  }) {
    return _col(
      establishmentId: establishmentId,
    ).where('store', isEqualTo: store).snapshots().map((snapshot) {
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

  /// =========================
  /// STREAM ALL REQUESTS
  /// =========================

  Stream<List<StockRequestModel>> streamAllRequests({
    required String establishmentId,
  }) {
    return _col(establishmentId: establishmentId).snapshots().map((snapshot) {
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

  /// =========================
  /// STREAM RECEIVER REQUESTS
  /// =========================

  Stream<List<StockRequestModel>> streamRequestsForReceiver({
    required String establishmentId,
    required String store,
  }) {
    return _col(establishmentId: establishmentId)
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

  /// =========================
  /// STREAM PENDING REQUESTS
  /// =========================

  Stream<List<StockRequestModel>> streamPendingRequests({
    required String establishmentId,
  }) {
    return _col(
      establishmentId: establishmentId,
    ).where('status', isEqualTo: 'pending').snapshots().map((snapshot) {
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

  /// =========================
  /// CREATE REQUEST
  /// =========================

  Future<void> createRequest({
    required String establishmentId,
    required String store,
    required String requestedBy,
    required String requestedByName,
    required String requestedByRole,
    required String note,
    required List<StockRequestItemModel> items,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }

    if (items.isEmpty) {
      throw Exception('Veuillez ajouter au moins un article.');
    }

    final docRef = await _col(establishmentId: establishmentId).add({
      'establishmentId': establishmentId,

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

      'pendingSync': false,

      'syncError': false,
    });

    for (final item in items) {
      await docRef.collection('items').add({
        ...item.toMap(),

        'establishmentId': establishmentId,

        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// =========================
  /// GET REQUEST ITEMS
  /// =========================

  Future<List<StockRequestItemModel>> getRequestItems({
    required String establishmentId,
    required String requestId,
  }) async {
    final snapshot = await _col(
      establishmentId: establishmentId,
    ).doc(requestId).collection('items').get();

    return snapshot.docs
        .map((doc) => StockRequestItemModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// =========================
  /// DELIVER REQUEST
  /// =========================

  Future<void> deliverRequest({
    required String establishmentId,
    required String requestId,
    required String deliveredBy,
    required String deliveredByName,
    required List<StockRequestItemModel> deliveredItems,
    required String store,
  }) async {
    if (deliveredItems.isEmpty) {
      throw Exception('Aucun article livré.');
    }

    for (final item in deliveredItems) {
      await _storeStockService.addStock(
        establishmentId: establishmentId,

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

      await _col(
        establishmentId: establishmentId,
      ).doc(requestId).collection('items').doc(item.id).update({
        'quantityDelivered': item.quantityDelivered,

        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await _col(establishmentId: establishmentId).doc(requestId).update({
      'status': 'delivered',

      'validatedByManager': true,

      'deliveredAt': FieldValue.serverTimestamp(),

      'deliveredBy': deliveredBy,

      'deliveredByName': deliveredByName,

      'pendingSync': false,

      'syncError': false,
    });
  }

  /// =========================
  /// CONFIRM RECEPTION
  /// =========================

  Future<void> confirmReception({
    required String establishmentId,
    required String requestId,
    required String receivedBy,
    required String receivedByName,
  }) async {
    await _col(establishmentId: establishmentId).doc(requestId).update({
      'status': 'received',

      'validatedByReceiver': true,

      'receivedAt': FieldValue.serverTimestamp(),

      'receivedBy': receivedBy,

      'receivedByName': receivedByName,

      'pendingSync': false,

      'syncError': false,
    });
  }
}
