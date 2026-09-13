import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import '../services/store_stock_service.dart';

class StoreStockController extends ChangeNotifier {
  final StoreStockService _service = StoreStockService();

  bool isSubmitting = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

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
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (quantity <= 0) {
      _error = const AppError(AppErrorCode.quantityMustBePositive);
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      _error = null;
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
      _error = e;
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
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (quantity <= 0) {
      _error = const AppError(AppErrorCode.quantityMustBePositive);
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      _error = null;
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
      _error = e;
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
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (stockDocId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.stockDocumentNotFound);
      notifyListeners();
      return false;
    }

    if (minimumQuantity < 0) {
      _error = const AppError(AppErrorCode.minThresholdNegative);
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      _error = null;
      notifyListeners();

      await _service.setMinimumQuantity(
        establishmentId: establishmentId,
        stockDocId: stockDocId,
        minimumQuantity: minimumQuantity,
      );

      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
