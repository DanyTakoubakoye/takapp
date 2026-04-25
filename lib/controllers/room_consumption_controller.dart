import 'package:flutter/material.dart';
import '../modeles/room_consumption_invoice_model.dart';
import '../services/room_consumption_service.dart';

class RoomConsumptionController extends ChangeNotifier {
  final RoomConsumptionService _service = RoomConsumptionService();

  RoomConsumptionInvoiceModel? invoice;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadConsumption({
    required String roomNumber,
    required DateTime start,
    required DateTime end,
  }) async {
    isLoading = true;
    errorMessage = null;
    invoice = null;
    notifyListeners();

    try {
      invoice = await _service.getConsumption(
        roomNumber: roomNumber,
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Erreur loadConsumption: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
