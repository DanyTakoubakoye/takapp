import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/services/owner_dashboard_service.dart';

class OwnerDashboardController extends ChangeNotifier {
  final OwnerDashboardService _service;

  OwnerDashboardController(this._service);

  bool _isLoading = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  Map<String, double> _balancesByType = {};

  bool get isLoading => _isLoading;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  Map<String, double> get balancesByType {
    return _balancesByType;
  }

  double get totalBalance {
    return _balancesByType.values.fold<double>(0, (sum, item) => sum + item);
  }

  Future<void> loadBalances({
    required String establishmentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      final result = await _service.getTheoreticalBalancesByType(
        establishmentId: establishmentId,
        startDate: startDate,
        endDate: endDate,
      );

      _balancesByType = result;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearBalances() {
    _balancesByType = {};
    notifyListeners();
  }
}
