import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import '../services/hygiene_daily_service.dart';

class HygieneDailyController extends ChangeNotifier {
  final HygieneDailyService _service = HygieneDailyService();

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

  Future<bool> createDailyEntry({
    required String establishmentId,
    required String roomNumber,
    required String preparedBy,
    required String preparedByName,
    required String note,
    required List<Map<String, dynamic>> usedItems,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (roomNumber.trim().isEmpty) {
      _error = const AppError(AppErrorCode.roomNumberRequired);
      notifyListeners();
      return false;
    }

    if (usedItems.isEmpty) {
      _error = const AppError(AppErrorCode.addAtLeastOneUsedItem);
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      _error = null;
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
      _error = e;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
