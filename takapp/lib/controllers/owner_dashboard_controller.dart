import 'package:flutter/material.dart';
import 'package:takapp/services/owner_dashboard_service.dart';

class OwnerDashboardController extends ChangeNotifier {
  final OwnerDashboardService _service;

  OwnerDashboardController(this._service);

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, double> _balancesByType = {};

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

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
      _errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _service.getTheoreticalBalancesByType(
        establishmentId: establishmentId,
        startDate: startDate,
        endDate: endDate,
      );

      _balancesByType = result;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
