import 'package:flutter/material.dart';
import 'package:takapp/services/comptabilite_service.dart';

class ComptabiliteController extends ChangeNotifier {
  final ComptabiliteService _service;

  ComptabiliteController(this._service);

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> confirmTransferReception({
    required String establishmentId,
    required String transferId,
    required String accountingId,
    required String accountingName,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      _errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (label.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir un libellé.';
      notifyListeners();
      return false;
    }

    if (amount <= 0) {
      _errorMessage = 'Le montant doit être supérieur à 0.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
