import 'package:flutter/material.dart';
import '../services/hygiene_daily_service.dart';

class HygieneDailyController extends ChangeNotifier {
  final HygieneDailyService _service = HygieneDailyService();

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> createDailyEntry({
    required String establishmentId,
    required String roomNumber,
    required String preparedBy,
    required String preparedByName,
    required String note,
    required List<Map<String, dynamic>> usedItems,
  }) async {
    if (establishmentId.trim().isEmpty) {
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (roomNumber.trim().isEmpty) {
      errorMessage = 'Veuillez préciser le numéro de chambre.';
      notifyListeners();
      return false;
    }

    if (usedItems.isEmpty) {
      errorMessage = 'Veuillez ajouter au moins un article utilisé.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.createDailyEntry(
        establishmentId: establishmentId,
        roomNumber: roomNumber.trim(),
        preparedBy: preparedBy,
        preparedByName: preparedByName,
        note: note.trim(),
        usedItems: usedItems,
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
}
