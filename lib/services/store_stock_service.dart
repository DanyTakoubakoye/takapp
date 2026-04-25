import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modeles/store_stock_model.dart';
import '../modeles/stock_movement_model.dart';

class StoreStockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _stockCol =>
      _firestore.collection('store_stocks');

  CollectionReference<Map<String, dynamic>> get _movementCol =>
      _firestore.collection('stock_movements');

  Stream<List<StoreStockModel>> streamStocksForStore(String store) {
    return _stockCol.where('store', isEqualTo: store).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => StoreStockModel.fromMap(doc.id, doc.data()))
          .toList();

      items.sort(
        (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
      );
      return items;
    });
  }

  Stream<List<StoreStockModel>> streamLowStocksForStore(String store) {
    return _stockCol
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

  Stream<List<StoreStockModel>> streamLowStocksForStores(List<String> stores) {
    return _stockCol
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

  Future<void> removeStockForOrder({
    required String orderId,
    required String orderNumber,
    required String performedBy,
    required String performedByName,
    required List<Map<String, dynamic>> deductions,
  }) async {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

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
        throw Exception('Ingrédient invalide : store vide pour $itemName');
      }

      if (itemId.isEmpty) {
        throw Exception('Ingrédient invalide : itemId vide pour $itemName');
      }

      if (unit.isEmpty) {
        throw Exception('Ingrédient invalide : unité vide pour $itemName');
      }

      if (quantity <= 0) {
        throw Exception('Ingrédient invalide : quantité <= 0 pour $itemName');
      }

      debugPrint(
        'Vérification ingrédient: store=$store, itemId=$itemId, itemName=$itemName',
      );

      final query = await _stockCol
          .where('store', isEqualTo: store)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception(
          'Article introuvable dans le stock : $itemName '
          '(store=$store, itemId=$itemId, unit=$unit, quantity=$quantity).',
        );
      }

      stockRefs.add((ref: query.docs.first.reference, deduction: deduction));
    }

    await _firestore.runTransaction((transaction) async {
      final List<Map<String, dynamic>> preparedWrites = [];

      // 1) Toutes les lectures d'abord
      for (final entry in stockRefs) {
        final deduction = entry.deduction;
        final itemName = deduction['itemName']?.toString() ?? '';
        final unit = deduction['unit']?.toString() ?? '';
        final quantity = toDouble(deduction['quantity']);

        debugPrint(
          'Lecture transaction: item=$itemName, unit=$unit, quantity=$quantity',
        );

        final docSnap = await transaction.get(entry.ref);

        if (!docSnap.exists || docSnap.data() == null) {
          throw Exception('Document de stock introuvable pour $itemName.');
        }

        final data = Map<String, dynamic>.from(docSnap.data()!);

        debugPrint('Stock brut pour $itemName: $data');

        final current = toDouble(data['quantity']);
        final minimumQuantity = toDouble(data['minimumQuantity']);
        final stockUnit = data['unit']?.toString() ?? '';

        debugPrint(
          'Stock lu pour $itemName => current=$current, '
          'minimumQuantity=$minimumQuantity, stockUnit=$stockUnit',
        );

        if (stockUnit != unit) {
          throw Exception(
            'Unité incohérente pour $itemName. '
            'Stock=$stockUnit, recette=$unit.',
          );
        }

        if (current < quantity) {
          throw Exception(
            'Stock insuffisant pour $itemName. '
            'Disponible : $current $unit, requis : $quantity $unit.',
          );
        }

        final newQuantity = current - quantity;

        debugPrint('Nouveau stock calculé pour $itemName => $newQuantity');

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

      // 2) Toutes les écritures ensuite
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
        });

        final movementDoc = _movementCol.doc();

        transaction.set(movementDoc, {
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
        });

        debugPrint('Écriture transaction OK pour $itemName');
      }
    });
  }

  Future<void> restoreStockForCancelledOrder({
    required String orderId,
    required String orderNumber,
    required String performedBy,
    required String performedByName,
    required List<Map<String, dynamic>> restitutions,
  }) async {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final List<
      ({
        DocumentReference<Map<String, dynamic>> ref,
        Map<String, dynamic> restitution,
      })
    >
    stockRefs = [];

    for (final restitution in restitutions) {
      final store = restitution['store']?.toString() ?? '';
      final itemId = restitution['itemId']?.toString() ?? '';
      final itemName = restitution['itemName']?.toString() ?? '';
      final unit = restitution['unit']?.toString() ?? '';
      final quantity = toDouble(restitution['quantity']);

      if (store.isEmpty) {
        throw Exception('Restitution invalide : store vide pour $itemName');
      }

      if (itemId.isEmpty) {
        throw Exception('Restitution invalide : itemId vide pour $itemName');
      }

      if (unit.isEmpty) {
        throw Exception('Restitution invalide : unité vide pour $itemName');
      }

      if (quantity <= 0) {
        throw Exception('Restitution invalide : quantité <= 0 pour $itemName');
      }

      final query = await _stockCol
          .where('store', isEqualTo: store)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception(
          'Article introuvable dans le stock pour restitution : '
          '$itemName (store=$store, itemId=$itemId, unit=$unit, quantity=$quantity).',
        );
      }

      stockRefs.add((
        ref: query.docs.first.reference,
        restitution: restitution,
      ));
    }

    await _firestore.runTransaction((transaction) async {
      final List<Map<String, dynamic>> preparedWrites = [];

      // 1. Toutes les lectures d'abord
      for (final entry in stockRefs) {
        final restitution = entry.restitution;
        final itemName = restitution['itemName']?.toString() ?? '';
        final unit = restitution['unit']?.toString() ?? '';
        final quantity = toDouble(restitution['quantity']);

        final docSnap = await transaction.get(entry.ref);

        if (!docSnap.exists || docSnap.data() == null) {
          throw Exception(
            'Document de stock introuvable pour restitution : $itemName.',
          );
        }

        final data = Map<String, dynamic>.from(docSnap.data()!);

        final current = toDouble(data['quantity']);
        final minimumQuantity = toDouble(data['minimumQuantity']);
        final stockUnit = data['unit']?.toString() ?? '';

        if (stockUnit != unit) {
          throw Exception(
            'Unité incohérente pour restitution de $itemName. '
            'Stock=$stockUnit, restitution=$unit.',
          );
        }

        final newQuantity = current + quantity;

        preparedWrites.add({
          'ref': entry.ref,
          'restitution': restitution,
          'itemName': itemName,
          'unit': unit,
          'quantity': quantity,
          'newQuantity': newQuantity,
          'minimumQuantity': minimumQuantity,
        });
      }

      // 2. Toutes les écritures ensuite
      for (final prepared in preparedWrites) {
        final ref = prepared['ref'] as DocumentReference<Map<String, dynamic>>;
        final restitution = prepared['restitution'] as Map<String, dynamic>;
        final itemName = prepared['itemName']?.toString() ?? '';
        final unit = prepared['unit']?.toString() ?? '';
        final quantity = toDouble(prepared['quantity']);
        final newQuantity = toDouble(prepared['newQuantity']);
        final minimumQuantity = toDouble(prepared['minimumQuantity']);

        transaction.update(ref, {
          'quantity': newQuantity,
          'isLowStock': newQuantity <= minimumQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final movementDoc = _movementCol.doc();

        transaction.set(movementDoc, {
          'store': restitution['store'],
          'itemId': restitution['itemId'],
          'itemName': itemName,
          'unit': unit,
          'quantity': quantity,
          'movementType': 'in',
          'reason': 'Restitution automatique annulation commande $orderNumber',
          'performedBy': performedBy,
          'performedByName': performedByName,
          'validatedBy': '',
          'validatedByName': '',
          'sourceRequestId': orderId,
          'orderId': orderId,
          'orderNumber': orderNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<List<StockMovementModel>> streamMovementsForStore(String store) {
    return _movementCol.where('store', isEqualTo: store).snapshots().map((
      snapshot,
    ) {
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

  Future<void> setMinimumQuantity({
    required String stockDocId,
    required double minimumQuantity,
  }) async {
    final doc = await _stockCol.doc(stockDocId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Stock introuvable.');
    }

    final data = doc.data()!;
    final currentQuantity = (data['quantity'] as num?)?.toDouble() ?? 0;

    await _stockCol.doc(stockDocId).update({
      'minimumQuantity': minimumQuantity,
      'isLowStock': currentQuantity <= minimumQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addStock({
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
    final query = await _stockCol
        .where('store', isEqualTo: store)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    final batch = _firestore.batch();

    if (query.docs.isEmpty) {
      final newDoc = _stockCol.doc();
      batch.set(newDoc, {
        'store': store,
        'itemId': itemId,
        'itemName': itemName,
        'unit': unit,
        'quantity': quantity,
        'minimumQuantity': 0,
        'isLowStock': false,
        'updatedAt': FieldValue.serverTimestamp(),
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
      });
    }

    final movementDoc = _movementCol.doc();
    batch.set(movementDoc, {
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
    });

    await batch.commit();
  }

  Future<void> directSupply({
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

  Future<void> removeStock({
    required String store,
    required String itemId,
    required String itemName,
    required String unit,
    required double quantity,
    required String performedBy,
    required String performedByName,
    required String reason,
  }) async {
    final query = await _stockCol
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

    if (current < quantity) {
      throw Exception('Stock insuffisant pour $itemName.');
    }

    final newQuantity = current - quantity;
    final batch = _firestore.batch();

    batch.update(doc.reference, {
      'quantity': newQuantity,
      'isLowStock': newQuantity <= minimumQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final movementDoc = _movementCol.doc();
    batch.set(movementDoc, {
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
    });

    await batch.commit();
  }
}
