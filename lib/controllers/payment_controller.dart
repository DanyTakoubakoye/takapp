import 'package:flutter/material.dart';
import 'package:takapp/services/payment_service.dart';

class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService;

  PaymentController(this._paymentService);

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  Future<bool> registerPayment({
    required String establishmentId,
    required String orderId,
    required String orderNumber,
    required String receivedBy,
    required String receivedByName,
    required String method,
    required double amount,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (orderId.trim().isEmpty) {
      _errorMessage = 'Commande introuvable.';
      notifyListeners();
      return false;
    }

    if (method.trim().isEmpty) {
      _errorMessage = 'Veuillez choisir un mode de paiement.';
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
      await _paymentService.registerPayment(
        establishmentId: establishmentId,
        orderId: orderId,
        orderNumber: orderNumber,
        receivedBy: receivedBy,
        receivedByName: receivedByName,
        method: method,
        amount: amount,
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
