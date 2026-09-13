import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/services/handover_service.dart';

class HandoverController extends ChangeNotifier {
  final HandoverService _handoverService;

  HandoverController(this._handoverService);

  final List<PaymentModel> _selectedPayments = [];

  bool _isSubmitting = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  List<PaymentModel> get selectedPayments {
    return List.unmodifiable(_selectedPayments);
  }

  bool get isSubmitting => _isSubmitting;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  double get selectedTotal {
    return _selectedPayments.fold<double>(0, (sum, item) => sum + item.amount);
  }

  bool isSelected(String paymentId) {
    return _selectedPayments.any((e) => e.id == paymentId);
  }

  void togglePayment(PaymentModel payment) {
    final exists = _selectedPayments.any((e) => e.id == payment.id);

    if (exists) {
      _selectedPayments.removeWhere((e) => e.id == payment.id);
    } else {
      _selectedPayments.add(payment);
    }

    notifyListeners();
  }

  void clearSelection() {
    _selectedPayments.clear();
    _error = null;
    notifyListeners();
  }

  Future<bool> submitHandover({
    required String establishmentId,
    required String serveurId,
    required String serveurName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (_selectedPayments.isEmpty) {
      _error = const AppError(AppErrorCode.selectAtLeastOnePayment);
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _handoverService.createHandover(
        establishmentId: establishmentId,
        serveurId: serveurId,
        serveurName: serveurName,
        declaredAmount: selectedTotal,
        paymentIds: _selectedPayments.map((e) => e.id).toList(),
      );

      _selectedPayments.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
