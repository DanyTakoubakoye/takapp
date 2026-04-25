import 'package:flutter/material.dart';
import '../services/hygiene_daily_service.dart';

class HygieneDailyController extends ChangeNotifier {
  final HygieneDailyService _service = HygieneDailyService();

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> createDailyEntry({
    required String roomNumber,
    required String preparedBy,
    required String preparedByName,
    required String note,
    required List<Map<String, dynamic>> usedItems,
  }) async {
    try {
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();

      await _service.createDailyEntry(
        roomNumber: roomNumber,
        preparedBy: preparedBy,
        preparedByName: preparedByName,
        note: note,
        usedItems: usedItems,
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
