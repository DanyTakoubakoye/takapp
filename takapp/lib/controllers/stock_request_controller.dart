import 'package:flutter/material.dart';

import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';

import '../modeles/stock_request_item_model.dart';
import '../services/stock_request_service.dart';

class StockRequestController extends ChangeNotifier {
  final StockRequestService _service = StockRequestService();

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

  Future<bool> createRequest({
    required String establishmentId,

    required String store,

    required String requestedBy,
    required String requestedByName,
    required String requestedByRole,

    required String note,

    required List<StockRequestItemModel> items,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (store.trim().isEmpty) {
      _error = const AppError(AppErrorCode.storeRequired);
      notifyListeners();
      return false;
    }

    if (items.isEmpty) {
      _error = const AppError(AppErrorCode.addAtLeastOneItem);
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      _error = null;

      notifyListeners();

      await _service.createRequest(
        establishmentId: establishmentId,

        store: store.trim(),

        requestedBy: requestedBy,
        requestedByName: requestedByName,
        requestedByRole: requestedByRole,

        note: note.trim(),

        items: items,
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

  Future<bool> deliverRequest({
    required String establishmentId,

    required String requestId,

    required String deliveredBy,
    required String deliveredByName,

    required List<StockRequestItemModel> deliveredItems,

    required String store,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (requestId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.requestNotFound);
      notifyListeners();
      return false;
    }

    if (deliveredItems.isEmpty) {
      _error = const AppError(AppErrorCode.selectAtLeastOneItem);
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      _error = null;

      notifyListeners();

      await _service.deliverRequest(
        establishmentId: establishmentId,

        requestId: requestId,

        deliveredBy: deliveredBy,
        deliveredByName: deliveredByName,

        deliveredItems: deliveredItems,

        store: store.trim(),
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

  Future<bool> confirmReception({
    required String establishmentId,

    required String requestId,

    required String receivedBy,
    required String receivedByName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (requestId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.requestNotFound);
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      _error = null;

      notifyListeners();

      await _service.confirmReception(
        establishmentId: establishmentId,

        requestId: requestId,

        receivedBy: receivedBy,
        receivedByName: receivedByName,
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
