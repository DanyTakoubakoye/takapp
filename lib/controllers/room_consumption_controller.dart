import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../modeles/room_consumption_invoice_model.dart';
import '../services/room_consumption_service.dart';

class RoomConsumptionController extends ChangeNotifier {
  final RoomConsumptionService _service = RoomConsumptionService();

  RoomConsumptionInvoiceModel? invoice;

  bool isLoading = false;

  String? errorMessage;

  Future<void> loadConsumption({
    required String establishmentId,
    required String roomNumber,
    required DateTime start,
    required DateTime end,
  }) async {
    if (establishmentId.trim().isEmpty) {
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return;
    }

    if (roomNumber.trim().isEmpty) {
      errorMessage = 'Veuillez préciser le numéro de chambre.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    invoice = null;

    notifyListeners();

    try {
      invoice = await _service.getConsumption(
        establishmentId: establishmentId,
        roomNumber: roomNumber.trim(),
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');

      debugPrint('Erreur loadConsumption: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearInvoice() {
    invoice = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
