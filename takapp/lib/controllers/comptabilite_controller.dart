import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/services/comptabilite_service.dart';

class ComptabiliteController extends ChangeNotifier {
  final ComptabiliteService _service;

  ComptabiliteController(this._service);

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

  Future<bool> confirmTransferReception({
    required String establishmentId,
    required String transferId,
    required String accountingId,
    required String accountingName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.confirmTransferReception(
        establishmentId: establishmentId,
        transferId: transferId,
        accountingId: accountingId,
        accountingName: accountingName,
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

  Future<bool> createExpense({
    required String establishmentId,
    required String label,
    required String category,
    required String accountType,
    required double amount,
    required String createdBy,
    required String createdByName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (label.trim().isEmpty) {
      _error = const AppError(AppErrorCode.labelRequired);
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
      await _service.createExpense(
        establishmentId: establishmentId,
        label: label.trim(),
        category: category.trim(),
        accountType: accountType.trim(),
        amount: amount,
        createdBy: createdBy,
        createdByName: createdByName,
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
}
