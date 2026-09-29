import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/controllers/establishment_config_controller.dart';
import 'package:takapp/modeles/stock_mode.dart';
import 'package:takapp/services/establishment_config_service.dart';

class _FakeEstablishmentConfigService implements EstablishmentConfigService {
  final Map<String, StreamController<StockMode>> _streams = {};

  @override
  Stream<StockMode> watchStockMode(String establishmentId) {
    return _streams
        .putIfAbsent(
          establishmentId,
          () => StreamController<StockMode>.broadcast(sync: true),
        )
        .stream;
  }

  void emit(String establishmentId, StockMode mode) {
    _streams[establishmentId]?.add(mode);
  }

  Future<void> close() async {
    for (final stream in _streams.values) {
      await stream.close();
    }
  }
}

void main() {
  test(
    'defaults to strict and updates when the establishment changes',
    () async {
      final service = _FakeEstablishmentConfigService();
      final controller = EstablishmentConfigController(service);

      expect(controller.currentStockMode, StockMode.strict);

      controller.setEstablishmentId('establishment-a');
      service.emit('establishment-a', StockMode.disabled);
      expect(controller.currentStockMode, StockMode.disabled);

      service.emit('establishment-a', StockMode.warningOnly);
      expect(controller.currentStockMode, StockMode.warningOnly);

      controller.setEstablishmentId('establishment-b');
      expect(controller.currentStockMode, StockMode.strict);
      service.emit('establishment-a', StockMode.disabled);
      expect(controller.currentStockMode, StockMode.strict);
      service.emit('establishment-b', StockMode.strict);
      expect(controller.currentStockMode, StockMode.strict);

      controller.dispose();
      await service.close();
    },
  );

  test('clears tenant configuration when no establishment is active', () async {
    final service = _FakeEstablishmentConfigService();
    final controller = EstablishmentConfigController(service);

    controller.setEstablishmentId('establishment-a');
    service.emit('establishment-a', StockMode.disabled);
    expect(controller.currentStockMode, StockMode.disabled);

    controller.setEstablishmentId('');
    expect(controller.currentStockMode, StockMode.strict);

    controller.dispose();
    await service.close();
  });
}
