import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/modeles/establishment_type.dart';

void main() {
  test('technical values are unique and kept as-is', () {
    expect(EstablishmentType.values.toSet(), hasLength(4));
    for (final value in EstablishmentType.values) {
      expect(EstablishmentType.normalize(value), value);
    }
  });

  test('legacy labels and casings map to the technical value', () {
    expect(EstablishmentType.normalize('Hotel'), 'hotel');
    expect(EstablishmentType.normalize(' HÔTEL '), 'hotel');
    expect(EstablishmentType.normalize('Restaurant'), 'restaurant');
    expect(EstablishmentType.normalize('Bar'), 'bar');
    expect(
      EstablishmentType.normalize('Hôtel + Bar + Restaurant'),
      'hotel_bar_restaurant',
    );
    expect(
      EstablishmentType.normalize('hotel, bar et restaurant'),
      'hotel_bar_restaurant',
    );
  });

  test('missing or unknown values fall back explicitly', () {
    expect(EstablishmentType.normalize(null), EstablishmentType.fallback);
    expect(EstablishmentType.normalize(''), EstablishmentType.fallback);
    expect(EstablishmentType.normalize('spa'), EstablishmentType.fallback);
    expect(
      EstablishmentType.normalize('hotel_restaurant'),
      EstablishmentType.fallback,
    );
  });
}
