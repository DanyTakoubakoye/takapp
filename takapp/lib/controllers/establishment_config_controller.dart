import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:takapp/modeles/stock_mode.dart';
import 'package:takapp/services/establishment_config_service.dart';

class EstablishmentConfigController extends ChangeNotifier {
  final EstablishmentConfigService _service;

  EstablishmentConfigController(this._service);

  String _establishmentId = '';
  StockMode _currentStockMode = StockMode.strict;
  StreamSubscription<StockMode>? _stockModeSubscription;
  int _subscriptionGeneration = 0;

  StockMode get currentStockMode => _currentStockMode;

  void setEstablishmentId(String establishmentId) {
    final id = establishmentId.trim();
    if (id == _establishmentId) return;

    _establishmentId = id;
    final generation = ++_subscriptionGeneration;
    _stockModeSubscription?.cancel();
    _stockModeSubscription = null;
    _setStockMode(StockMode.strict);

    if (id.isEmpty) return;

    _stockModeSubscription = _service
        .watchStockMode(id)
        .listen(
          (mode) {
            if (generation == _subscriptionGeneration) _setStockMode(mode);
          },
          onError: (Object _) {
            if (generation == _subscriptionGeneration) {
              _setStockMode(StockMode.strict);
            }
          },
        );
  }

  void _setStockMode(StockMode mode) {
    if (_currentStockMode == mode) return;
    _currentStockMode = mode;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscriptionGeneration++;
    _stockModeSubscription?.cancel();
    super.dispose();
  }
}
