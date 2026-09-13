import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';

import '../modeles/stock_item_model.dart';

class StockItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String? establishmentId;

  StockItemService({this.establishmentId});

  /// =========================
  /// HELPERS SAAS
  /// =========================

  String _resolveEstablishmentId(String? id) {
    final resolved = (id ?? establishmentId ?? '').trim();

    if (resolved.isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    return resolved;
  }

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('stock_items');
  }

  List<StockItemModel> _sortItems(List<StockItemModel> items) {
    items.sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  /// =========================
  /// STREAM ALL ITEMS
  /// =========================

  Stream<List<StockItemModel>> streamItems({
    String? establishmentId,
    String? store,
  }) {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    Query<Map<String, dynamic>> query = _col(
      establishmentId: resolvedEstablishmentId,
    );

    if (store != null && store.trim().isNotEmpty) {
      query = query.where('store', isEqualTo: store.trim());
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => StockItemModel.fromMap(doc.id, doc.data()))
          .where((item) => item.isActive)
          .toList();

      return _sortItems(items);
    });
  }

  /// =========================
  /// STREAM STORE ITEMS
  /// =========================

  Stream<List<StockItemModel>> streamItemsForStore({
    String? establishmentId,
    required String store,
  }) {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    return _col(establishmentId: resolvedEstablishmentId)
        .where('store', isEqualTo: store.trim())
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => StockItemModel.fromMap(doc.id, doc.data()))
              .toList();

          return _sortItems(items);
        });
  }

  /// =========================
  /// CREATE ITEM
  /// =========================

  Future<void> createItem({
    String? establishmentId,
    required String name,
    required String category,
    required String unit,
    required String store,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    final cleanName = name.trim();

    final cleanCategory = category.trim();

    final cleanUnit = unit.trim();

    final cleanStore = store.trim();

    if (cleanName.isEmpty) {
      throw const AppError(AppErrorCode.invalidItemName);
    }

    if (cleanStore.isEmpty) {
      throw const AppError(AppErrorCode.invalidStore);
    }

    /// =========================
    /// CHECK DUPLICATE
    /// =========================

    final existing = await _col(establishmentId: resolvedEstablishmentId)
        .where('name', isEqualTo: cleanName)
        .where('store', isEqualTo: cleanStore)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw const AppError(AppErrorCode.itemAlreadyExistsInStore);
    }

    /// =========================
    /// CREATE ITEM
    /// =========================

    final docRef = _col(establishmentId: resolvedEstablishmentId).doc();

    await docRef.set({
      'id': docRef.id,
      'establishmentId': resolvedEstablishmentId,
      'name': cleanName,
      'category': cleanCategory,
      'unit': cleanUnit,
      'store': cleanStore,
      'isActive': true,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }

  /// =========================
  /// UPDATE ITEM
  /// =========================

  Future<void> updateItem({
    String? establishmentId,
    required String itemId,
    required String name,
    required String category,
    required String unit,
    required String store,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(itemId).update({
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'store': store.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }

  /// =========================
  /// DISABLE ITEM
  /// =========================

  Future<void> disableItem({
    String? establishmentId,
    required String itemId,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(itemId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// ENABLE ITEM
  /// =========================

  Future<void> enableItem({
    String? establishmentId,
    required String itemId,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(itemId).update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
