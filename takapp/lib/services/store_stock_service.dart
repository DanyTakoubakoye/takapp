import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/store_stock_model.dart';
import '../modeles/stock_movement_model.dart';

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
  /// REMOVE STOCK FOR ORDER
  /// =========================

  Future<void> removeStockForOrder({
    required String establishmentId,
    required String orderId,
    required String orderNumber,
    required String performedBy,
    required String performedByName,
    required List<Map<String, dynamic>> deductions,
  }) async {
    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    // Affiche un nombre sans ".0" superflu (3.0 -> "3", 2.5 -> "2.5")
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

    final List<
      ({
        DocumentReference<Map<String, dynamic>> ref,
        Map<String, dynamic> deduction,
      })
    >
    stockRefs = [];

    for (final deduction in deductions) {
      final store = deduction['store']?.toString() ?? '';

      final itemId = deduction['itemId']?.toString() ?? '';

      final itemName = deduction['itemName']?.toString() ?? '';

      final unit = deduction['unit']?.toString() ?? '';

      final quantity = toDouble(deduction['quantity']);

      if (store.isEmpty) {
        throw Exception(
          'Ingrédient invalide : '
          'store vide pour $itemName',
        );
      }

      if (itemId.isEmpty) {
        throw Exception(
          'Ingrédient invalide : '
          'itemId vide pour $itemName',
        );
      }

      if (unit.isEmpty) {
        throw Exception(
          'Ingrédient invalide : '
          'unité vide pour $itemName',
        );
      }

      if (quantity <= 0) {
        throw Exception(
          'Ingrédient invalide : '
          'quantité <= 0 pour $itemName',
        );
      }

      final query = await _stockCol(establishmentId: establishmentId)
          .where('store', isEqualTo: store)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception(
          'Article introuvable '
          'dans le stock : '
          '$itemName',
        );
      }

      stockRefs.add((ref: query.docs.first.reference, deduction: deduction));
    }

    // On capture la raison d'échec dans une variable au lieu de la lancer
    // depuis l'intérieur de la transaction : sur Flutter web, un `throw` dans
    // runTransaction est "boxé" (message perdu -> "Dart exception thrown from
    // converted Future"). On relance l'exception APRÈS la transaction, avec un
    // message explicite nommant l'ingrédient concerné.
    String? stockError;

    await _firestore.runTransaction((transaction) async {
      stockError = null; // reset : la transaction peut être rejouée
      final List<Map<String, dynamic>> preparedWrites = [];

      for (final entry in stockRefs) {
        final deduction = entry.deduction;

        final itemName = deduction['itemName']?.toString() ?? '';

        final unit = deduction['unit']?.toString() ?? '';

        final quantity = toDouble(deduction['quantity']);

        final docSnap = await transaction.get(entry.ref);

        if (!docSnap.exists || docSnap.data() == null) {
          stockError = 'Stock introuvable pour « $itemName ».';
          return;
        }

        final data = Map<String, dynamic>.from(docSnap.data()!);

        final current = toDouble(data['quantity']);

        final minimumQuantity = toDouble(data['minimumQuantity']);

        final stockUnit = data['unit']?.toString() ?? '';

        if (stockUnit != unit) {
          stockError =
              'Unité incohérente pour « $itemName » : '
              'stock en "$stockUnit" mais recette en "$unit".';
          return;
        }

        if (current < quantity) {
          stockError =
              'Stock insuffisant pour « $itemName » : '
              'disponible ${fmt(current)} $stockUnit, '
              'requis ${fmt(quantity)} $unit.';
          return;
        }

        final newQuantity = current - quantity;

        preparedWrites.add({
          'ref': entry.ref,
          'deduction': deduction,
          'itemName': itemName,
          'unit': unit,
          'quantity': quantity,
          'newQuantity': newQuantity,
          'minimumQuantity': minimumQuantity,
        });
      }

      for (final prepared in preparedWrites) {
        final ref = prepared['ref'] as DocumentReference<Map<String, dynamic>>;

        final deduction = prepared['deduction'] as Map<String, dynamic>;

        final itemName = prepared['itemName']?.toString() ?? '';

        final unit = prepared['unit']?.toString() ?? '';

        final quantity = toDouble(prepared['quantity']);

        final newQuantity = toDouble(prepared['newQuantity']);

        final minimumQuantity = toDouble(prepared['minimumQuantity']);

        transaction.update(ref, {
          'quantity': newQuantity,

          'isLowStock': newQuantity <= minimumQuantity,

          'updatedAt': FieldValue.serverTimestamp(),

          'pendingSync': false,

          'syncError': false,
        });

        final movementDoc = _movementCol(
          establishmentId: establishmentId,
        ).doc();

        transaction.set(movementDoc, {
          'establishmentId': establishmentId,

          'store': deduction['store'],

          'itemId': deduction['itemId'],

          'itemName': itemName,

          'unit': unit,

          'quantity': quantity,

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
    });

    // La transaction a été volontairement abandonnée (aucune déduction faite).
    // On relance ici, hors transaction, pour que le message survive au web.
    if (stockError != null) {
      throw Exception(stockError);
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
      throw Exception('Stock introuvable.');
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
      throw Exception('Article introuvable dans le stock.');
    }

    final doc = query.docs.first;
    final current = (doc.data()['quantity'] as num?)?.toDouble() ?? 0;
    final minimumQuantity =
        (doc.data()['minimumQuantity'] as num?)?.toDouble() ?? 0;

    double newQuantity;
    if (current < quantity) {
      if (!allowNegative) {
        throw Exception('Stock insuffisant pour $itemName.');
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
