import 'package:flutter/material.dart';
import '../services/store_stock_service.dart';

class StoreStockController extends ChangeNotifier {
  final StoreStockService _service = StoreStockService();

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> addStock({
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
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.addStock(
        store: store,
        itemId: itemId,
        itemName: itemName,
        unit: unit,
        quantity: quantity,
        performedBy: performedBy,
        performedByName: performedByName,
        reason: reason,
        sourceRequestId: sourceRequestId,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> directSupply({
    required String store,
    required String itemId,
    required String itemName,
    required String unit,
    required double quantity,
    required String performedBy,
    required String performedByName,
    required String reason,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.directSupply(
        store: store,
        itemId: itemId,
        itemName: itemName,
        unit: unit,
        quantity: quantity,
        performedBy: performedBy,
        performedByName: performedByName,
        reason: reason,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> removeStock({
    required String store,
    required String itemId,
    required String itemName,
    required String unit,
    required double quantity,
    required String performedBy,
    required String performedByName,
    required String reason,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.removeStock(
        store: store,
        itemId: itemId,
        itemName: itemName,
        unit: unit,
        quantity: quantity,
        performedBy: performedBy,
        performedByName: performedByName,
        reason: reason,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> setMinimumQuantity({
    required String stockDocId,
    required double minimumQuantity,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.setMinimumQuantity(
        stockDocId: stockDocId,
        minimumQuantity: minimumQuantity,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
