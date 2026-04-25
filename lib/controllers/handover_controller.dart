import 'package:flutter/material.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/services/handover_service.dart';

class HandoverController extends ChangeNotifier {
  final HandoverService _handoverService;

  HandoverController(this._handoverService);

  final List<PaymentModel> _selectedPayments = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  List<PaymentModel> get selectedPayments =>
      List.unmodifiable(_selectedPayments);
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  double get selectedTotal {
    return _selectedPayments.fold(0, (sum, item) => sum + item.amount);
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
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submitHandover({
    required String serveurId,
    required String serveurName,
  }) async {
    if (_selectedPayments.isEmpty) {
      _errorMessage = 'Veuillez sélectionner au moins un paiement.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _handoverService.createHandover(
        serveurId: serveurId,
        serveurName: serveurName,
        declaredAmount: selectedTotal,
        paymentIds: _selectedPayments.map((e) => e.id).toList(),
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
