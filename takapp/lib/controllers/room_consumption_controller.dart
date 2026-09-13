import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';

import '../modeles/room_consumption_invoice_model.dart';
import '../services/room_consumption_service.dart';

class RoomConsumptionController extends ChangeNotifier {
  final RoomConsumptionService _service = RoomConsumptionService();

  RoomConsumptionInvoiceModel? invoice;

  bool isLoading = false;

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

  Future<void> loadConsumption({
    required String establishmentId,
    required String roomNumber,
    required DateTime start,
    required DateTime end,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return;
    }

    if (roomNumber.trim().isEmpty) {
      _error = const AppError(AppErrorCode.roomNumberRequired);
      notifyListeners();
      return;
    }

    isLoading = true;
    _error = null;
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
      _error = e;

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
    _error = null;
    notifyListeners();
  }
}
