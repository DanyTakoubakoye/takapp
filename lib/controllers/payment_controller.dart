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
    required String orderId,
    required String orderNumber,
    required String receivedBy,
    required String receivedByName,
    required String method,
    required double amount,
  }) async {
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
}
