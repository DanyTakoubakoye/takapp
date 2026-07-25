import 'package:flutter/material.dart';
import '../services/store_stock_service.dart';

class StoreStockController extends ChangeNotifier {
  final StoreStockService _service = StoreStockService();

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> addStock({
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
    if (establishmentId.trim().isEmpty) {
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (quantity <= 0) {
      errorMessage = 'La quantité doit être supérieure à 0.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.addStock(
        establishmentId: establishmentId,
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
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> directSupply({
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
    return addStock(
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

  Future<bool> removeStock({
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
    if (establishmentId.trim().isEmpty) {
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (quantity <= 0) {
      errorMessage = 'La quantité doit être supérieure à 0.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.removeStock(
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

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> setMinimumQuantity({
    required String establishmentId,
    required String stockDocId,
    required double minimumQuantity,
  }) async {
    if (establishmentId.trim().isEmpty) {
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (stockDocId.trim().isEmpty) {
      errorMessage = 'Document de stock introuvable.';
      notifyListeners();
      return false;
    }

    if (minimumQuantity < 0) {
      errorMessage = 'Le seuil minimum ne peut pas être négatif.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.setMinimumQuantity(
        establishmentId: establishmentId,
        stockDocId: stockDocId,
        minimumQuantity: minimumQuantity,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
