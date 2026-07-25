import 'package:flutter/material.dart';

import '../modeles/stock_request_item_model.dart';
import '../services/stock_request_service.dart';

class StockRequestController extends ChangeNotifier {
  final StockRequestService _service = StockRequestService();

  bool isSubmitting = false;

  String? errorMessage;

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
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (store.trim().isEmpty) {
      errorMessage = 'Veuillez préciser le magasin.';
      notifyListeners();
      return false;
    }

    if (items.isEmpty) {
      errorMessage = 'Veuillez ajouter au moins un article.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = null;

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
      errorMessage = e.toString().replaceFirst('Exception: ', '');

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
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (requestId.trim().isEmpty) {
      errorMessage = 'Demande introuvable.';
      notifyListeners();
      return false;
    }

    if (deliveredItems.isEmpty) {
      errorMessage = 'Veuillez sélectionner au moins un article.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = null;

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
      errorMessage = e.toString().replaceFirst('Exception: ', '');

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
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (requestId.trim().isEmpty) {
      errorMessage = 'Demande introuvable.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = null;

      notifyListeners();

      await _service.confirmReception(
        establishmentId: establishmentId,

        requestId: requestId,

        receivedBy: receivedBy,
        receivedByName: receivedByName,
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
