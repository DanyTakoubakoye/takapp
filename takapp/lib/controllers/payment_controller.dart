import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/services/payment_service.dart';

class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService;

  PaymentController(this._paymentService);

  bool _isSubmitting = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  bool get isSubmitting => _isSubmitting;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  /// Encaisse une addition complète (une ou plusieurs commandes d'une même
  /// table ou chambre) en un seul règlement.
  Future<bool> registerTicketPayment({
    required String establishmentId,
    required String ticketId,
    required List<String> orderIds,
    required String receivedBy,
    required String receivedByName,
    required String method,
    required double amount,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (orderIds.where((id) => id.trim().isNotEmpty).isEmpty) {
      _error = const AppError(AppErrorCode.orderNotFound);
      notifyListeners();
      return false;
    }

    if (method.trim().isEmpty) {
      _error = const AppError(AppErrorCode.selectPaymentMethod);
      notifyListeners();
      return false;
    }

    if (amount <= 0) {
      _error = const AppError(AppErrorCode.amountMustBePositive);
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;

    notifyListeners();

    try {
      await _paymentService.registerTicketPayment(
        establishmentId: establishmentId,
        ticketId: ticketId,
        orderIds: orderIds,
        receivedBy: receivedBy,
        receivedByName: receivedByName,
        method: method,
        amount: amount,
      );

      return true;
    } catch (e) {
      _error = e;

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
