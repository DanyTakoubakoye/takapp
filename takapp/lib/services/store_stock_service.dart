import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';

import '../modeles/store_stock_model.dart';
import '../modeles/stock_movement_model.dart';
import 'order_stock_policy.dart';

class StoreStockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _stockCol({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('store_stocks');
  }

  CollectionReference<Map<String, dynamic>> _movementCol({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('stock_movements');
  }

  /// =========================
  /// STREAM STOCKS
  /// =========================

  Stream<List<StoreStockModel>> streamStocksForStore({
    required String establishmentId,
    required String store,
  }) {
    return _stockCol(
      establishmentId: establishmentId,
    ).where('store', isEqualTo: store).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => StoreStockModel.fromMap(doc.id, doc.data()))
          .toList();

      items.sort(
        (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
      );

      return items;
    });
  }

  /// =========================
  /// LOW STOCKS
  /// =========================

  Stream<List<StoreStockModel>> streamLowStocksForStore({
    required String establishmentId,
    required String store,
  }) {
    return _stockCol(establishmentId: establishmentId)
        .where('store', isEqualTo: store)
        .where('isLowStock', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => StoreStockModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort(
            (a, b) =>
                a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
          );

          return items;
        });
  }

  Stream<List<StoreStockModel>> streamLowStocksForStores({
    required String establishmentId,
    required List<String> stores,
  }) {
    return _stockCol(establishmentId: establishmentId)
        .where('store', whereIn: stores)
        .where('isLowStock', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => StoreStockModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort(
            (a, b) =>
                a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
          );

          return items;
        });
  }

  /// =========================
  /// STOCK DES COMMANDES (TRANSACTIONNEL)
  /// =========================
  ///
  /// La création d'une commande et la déduction de son stock se font dans
  /// UNE SEULE transaction (voir `OrderService.createOrder`) : soit tout est
  /// écrit, soit rien. La décision (accepter / refuser / avertir) est prise
  /// par `OrderStockPolicy` ; ce service ne fait que lire et écrire.

  /// Document de stock d'un article dans un magasin, ou `null` s'il n'existe
  /// pas. Les requêtes étant interdites dans une transaction client, les
  /// références sont résolues AVANT, puis relues DANS la transaction.
  Future<DocumentReference<Map<String, dynamic>>?> findStockRef({
    required String establishmentId,
    required String store,
    required String itemId,
  }) async {
    final query = await _stockCol(establishmentId: establishmentId)
        .where('store', isEqualTo: store)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    return query.docs.isEmpty ? null : query.docs.first.reference;
  }

  /// Niveau de stock lu dans la transaction, ou `null` si le document a
  /// disparu entre-temps.
  Future<StockLevel?> readStockLevel(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snap = await transaction.get(ref);
    final data = snap.data();

    if (!snap.exists || data == null) return null;

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return StockLevel(
      quantity: toDouble(data['quantity']),
      minimumQuantity: toDouble(data['minimumQuantity']),
      unit: data['unit']?.toString() ?? '',
    );
  }

  /// Écrit, dans la transaction de création de commande, les déductions
  /// validées et leurs mouvements de sortie.
  void writeOrderDeductions(
    Transaction transaction, {
    required String establishmentId,
    required String orderId,
    required String orderNumber,
    required String performedBy,
    required String performedByName,
    required List<StockDeduction> deductions,
    required Map<String, DocumentReference<Map<String, dynamic>>> stockRefs,
  }) {
    for (final deduction in deductions) {
      final requirement = deduction.requirement;
      final ref = stockRefs[requirement.key];

      // Impossible si la politique a validé la ligne : garde-fou.
      if (ref == null) continue;

      transaction.update(ref, {
        'quantity': deduction.newQuantity,
        'isLowStock': deduction.isLowStock,
        'updatedAt': FieldValue.serverTimestamp(),
        'pendingSync': false,
        'syncError': false,
      });

      transaction.set(_movementCol(establishmentId: establishmentId).doc(), {
        'establishmentId': establishmentId,
        'store': requirement.store,
        'itemId': requirement.itemId,
        'itemName': requirement.itemName,
        'unit': requirement.unit,
        'quantity': requirement.quantity,
        'movementType': 'out',
        'reason': 'Consommation automatique commande $orderNumber',
        'performedBy': performedBy,
        'performedByName': performedByName,
        'validatedBy': '',
        'validatedByName': '',
        'sourceRequestId': orderId,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'pendingSync': false,
        'syncError': false,
      });
    }
  }

  /// =========================
  /// RESTORE STOCK
  /// =========================

  Future<void> restoreStockForCancelledOrder({
    required String establishmentId,
    required String orderId,
    required String orderNumber,
    required String performedBy,
    required String performedByName,
    required List<Map<String, dynamic>> restitutions,
  }) async {
    for (final restitution in restitutions) {
      await addStock(
        establishmentId: establishmentId,

        store: restitution['store'].toString(),

        itemId: restitution['itemId'].toString(),

        itemName: restitution['itemName'].toString(),

        unit: restitution['unit'].toString(),

        quantity: (restitution['quantity'] as num).toDouble(),

        performedBy: performedBy,

        performedByName: performedByName,

        reason: 'Restitution automatique annulation commande $orderNumber',

        sourceRequestId: orderId,
      );
    }
  }

  /// =========================
  /// STREAM MOVEMENTS
  /// =========================

  Stream<List<StockMovementModel>> streamMovementsForStore({
    required String establishmentId,
    required String store,
  }) {
    return _movementCol(
      establishmentId: establishmentId,
    ).where('store', isEqualTo: store).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => StockMovementModel.fromMap(doc.id, doc.data()))
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
  /// MINIMUM QUANTITY
  /// =========================

  Future<void> setMinimumQuantity({
    required String establishmentId,
    required String stockDocId,
    required double minimumQuantity,
  }) async {
    final doc = await _stockCol(
      establishmentId: establishmentId,
    ).doc(stockDocId).get();

    if (!doc.exists || doc.data() == null) {
      throw const AppError(AppErrorCode.stockNotFound);
    }

    final data = doc.data()!;

    final currentQuantity = (data['quantity'] as num?)?.toDouble() ?? 0;

    await _stockCol(establishmentId: establishmentId).doc(stockDocId).update({
      'minimumQuantity': minimumQuantity,

      'isLowStock': currentQuantity <= minimumQuantity,

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });
  }

  /// =========================
  /// ADD STOCK
  /// =========================

  Future<void> addStock({
    required String establishmentId,
    required String store,
    required String itemId,
    required String itemName,
    required String unit,
    required double quantity,
    required String performedBy,
    required String performedByName,
    required String reason,
    String sourceRequestId = '',
  }) async {
    final query = await _stockCol(establishmentId: establishmentId)
        .where('store', isEqualTo: store)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    final batch = _firestore.batch();

    if (query.docs.isEmpty) {
      final newDoc = _stockCol(establishmentId: establishmentId).doc();

      batch.set(newDoc, {
        'establishmentId': establishmentId,

        'store': store,

        'itemId': itemId,

        'itemName': itemName,

        'unit': unit,

        'quantity': quantity,

        'minimumQuantity': 0,

        'isLowStock': false,

        'updatedAt': FieldValue.serverTimestamp(),

        'pendingSync': false,

        'syncError': false,
      });
    } else {
      final doc = query.docs.first;

      final current = (doc.data()['quantity'] as num?)?.toDouble() ?? 0;

      final minimumQuantity =
          (doc.data()['minimumQuantity'] as num?)?.toDouble() ?? 0;

      final newQuantity = current + quantity;

      batch.update(doc.reference, {
        'quantity': newQuantity,

        'isLowStock': newQuantity <= minimumQuantity,

        'updatedAt': FieldValue.serverTimestamp(),

        'pendingSync': false,

        'syncError': false,
      });
    }

    final movementDoc = _movementCol(establishmentId: establishmentId).doc();

    batch.set(movementDoc, {
      'establishmentId': establishmentId,

      'store': store,

      'itemId': itemId,

      'itemName': itemName,

      'unit': unit,

      'quantity': quantity,

      'movementType': 'in',

      'reason': reason,

      'performedBy': performedBy,

      'performedByName': performedByName,

      'validatedBy': '',

      'validatedByName': '',

      'sourceRequestId': sourceRequestId,

      'createdAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });

    await batch.commit();
  }

  /// =========================
  /// DIRECT SUPPLY
  /// =========================

  Future<void> directSupply({
    required String establishmentId,
    required String store,
    required String itemId,
    required String itemName,
    required String unit,
    required double quantity,
    required String performedBy,
    required String performedByName,
    required String reason,
  }) async {
    await addStock(
      establishmentId: establishmentId,

      store: store,

      itemId: itemId,

      itemName: itemName,

      unit: unit,

      quantity: quantity,

      performedBy: performedBy,

      performedByName: performedByName,

      reason: reason,
    );
  }

  /// =========================
  /// REMOVE STOCK
  /// =========================

  Future<void> removeStock({
    required String establishmentId,
    required String store,
    required String itemId,
    required String itemName,
    required String unit,
    required double quantity,
    required String performedBy,
    required String performedByName,
    required String reason,
    bool allowNegative = false,
  }) async {
    final query = await _stockCol(establishmentId: establishmentId)
        .where('store', isEqualTo: store)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw const AppError(AppErrorCode.itemNotFoundInStock);
    }

    final doc = query.docs.first;
    final current = (doc.data()['quantity'] as num?)?.toDouble() ?? 0;
    final minimumQuantity =
        (doc.data()['minimumQuantity'] as num?)?.toDouble() ?? 0;

    double newQuantity;
    if (current < quantity) {
      if (!allowNegative) {
        throw AppError(AppErrorCode.stockInsufficient, name: itemName);
      }
      // Stock insuffisant mais on laisse passer : on planche à 0.
      newQuantity = 0;
    } else {
      newQuantity = current - quantity;
    }

    final batch = _firestore.batch();

    batch.update(doc.reference, {
      'quantity': newQuantity,

      'isLowStock': newQuantity <= minimumQuantity,

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });

    final movementDoc = _movementCol(establishmentId: establishmentId).doc();

    batch.set(movementDoc, {
      'establishmentId': establishmentId,

      'store': store,

      'itemId': itemId,

      'itemName': itemName,

      'unit': unit,

      'quantity': quantity,

      'movementType': 'out',

      'reason': reason,

      'performedBy': performedBy,

      'performedByName': performedByName,

      'validatedBy': '',

      'validatedByName': '',

      'sourceRequestId': '',

      'createdAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });

    await batch.commit();
  }
}
