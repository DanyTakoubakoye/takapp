import 'package:flutter/material.dart';
import '../modeles/stock_request_item_model.dart';
import '../services/stock_request_service.dart';

class StockRequestController extends ChangeNotifier {
  final StockRequestService _service = StockRequestService();

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> createRequest({
    required String store,
    required String requestedBy,
    required String requestedByName,
    required String requestedByRole,
    required String note,
    required List<StockRequestItemModel> items,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.createRequest(
        store: store,
        requestedBy: requestedBy,
        requestedByName: requestedByName,
        requestedByRole: requestedByRole,
        note: note,
        items: items,
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

  Future<bool> deliverRequest({
    required String requestId,
    required String deliveredBy,
    required String deliveredByName,
    required List<StockRequestItemModel> deliveredItems,
    required String store,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.deliverRequest(
        requestId: requestId,
        deliveredBy: deliveredBy,
        deliveredByName: deliveredByName,
        deliveredItems: deliveredItems,
        store: store,
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

  Future<bool> confirmReception({
    required String requestId,
    required String receivedBy,
    required String receivedByName,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.confirmReception(
        requestId: requestId,
        receivedBy: receivedBy,
        receivedByName: receivedByName,
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
