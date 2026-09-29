import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/modeles/stock_mode.dart';

void main() {
  test('stock modes serialize to their configured values', () {
    expect(StockMode.disabled.value, 'disabled');
    expect(StockMode.warningOnly.value, 'warningOnly');
    expect(StockMode.strict.value, 'strict');
  });

  test('missing legacy value defaults to strict', () {
    expect(StockMode.fromValue(null), StockMode.strict);
  });

  test('unknown values default to strict', () {
    expect(StockMode.fromValue('futureMode'), StockMode.strict);
  });

  test('configured values parse to their matching mode', () {
    for (final mode in StockMode.values) {
      expect(StockMode.fromValue(mode.value), mode);
    }
  });
}
