import 'package:flutter/material.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/services/gerante_handover_service.dart';

class GeranteHandoverController extends ChangeNotifier {
  final GeranteHandoverService _service;

  GeranteHandoverController(this._service);

  bool _isSubmitting = false;
  String? _errorMessage;
  final List<PaymentModel> _selectedPayments = [];

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

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
    _errorMessage = null;
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
      _errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (_selectedPayments.isEmpty) {
      _errorMessage = 'Veuillez sélectionner au moins une commande/paiement.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      _errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (_selectedPayments.isEmpty) {
      _errorMessage = 'Veuillez sélectionner au moins une commande/paiement.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
