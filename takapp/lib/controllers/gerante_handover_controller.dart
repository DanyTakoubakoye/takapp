import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/services/gerante_handover_service.dart';

class GeranteHandoverController extends ChangeNotifier {
  final GeranteHandoverService _service;

  GeranteHandoverController(this._service);

  bool _isSubmitting = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  final List<PaymentModel> _selectedPayments = [];

  bool get isSubmitting => _isSubmitting;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  List<PaymentModel> get selectedPayments {
    return List.unmodifiable(_selectedPayments);
  }

  bool isSelected(String paymentId) {
    return _selectedPayments.any((e) => e.id == paymentId);
  }

  double get selectedTotal {
    return _selectedPayments.fold<double>(0, (sum, item) => sum + item.amount);
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

  Future<bool> validateSelectedPayments({
    required String establishmentId,
    required ServerHandoverModel handover,
    required double validatedAmount,
    required String managerId,
    required String managerName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (_selectedPayments.isEmpty) {
      _error = const AppError(AppErrorCode.selectAtLeastOneOrderOrPayment);
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.validateSelectedPayments(
        establishmentId: establishmentId,
        handoverId: handover.id,
        selectedPaymentIds: _selectedPayments.map((e) => e.id).toList(),
        validatedAmount: validatedAmount,
        managerId: managerId,
        managerName: managerName,
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

  Future<bool> rejectSelectedPayments({
    required String establishmentId,
    required ServerHandoverModel handover,
    required double validatedAmount,
    required String managerId,
    required String managerName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (_selectedPayments.isEmpty) {
      _error = const AppError(AppErrorCode.selectAtLeastOneOrderOrPayment);
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.rejectSelectedPayments(
        establishmentId: establishmentId,
        handoverId: handover.id,
        selectedPaymentIds: _selectedPayments.map((e) => e.id).toList(),
        validatedAmount: validatedAmount,
        managerId: managerId,
        managerName: managerName,
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
