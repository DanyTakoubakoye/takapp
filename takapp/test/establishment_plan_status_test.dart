import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/modeles/establishment_plan.dart';
import 'package:takapp/modeles/establishment_status.dart';

void main() {
  group('EstablishmentPlan', () {
    test('technical values are unique and kept as-is', () {
      expect(EstablishmentPlan.values.toSet(), hasLength(4));
      for (final value in EstablishmentPlan.values) {
        expect(EstablishmentPlan.normalize(value), value);
      }
    });

    test('legacy labels and casings map to the technical value', () {
      expect(EstablishmentPlan.normalize('Premium'), 'premium');
      expect(EstablishmentPlan.normalize(' STARTER '), 'starter');
      expect(EstablishmentPlan.normalize('Entreprise'), 'enterprise');
    });

    test('missing or unknown values fall back to standard', () {
      expect(EstablishmentPlan.normalize(null), 'standard');
      expect(EstablishmentPlan.normalize(''), 'standard');
      expect(EstablishmentPlan.normalize('gold'), 'standard');
    });
  });

  group('EstablishmentStatus', () {
    test('technical values are unique and kept as-is', () {
      expect(EstablishmentStatus.values.toSet(), hasLength(3));
      for (final value in EstablishmentStatus.values) {
        expect(EstablishmentStatus.normalize(value), value);
      }
    });

    test('legacy labels and casings map to the technical value', () {
      expect(EstablishmentStatus.normalize('Active'), 'active');
      expect(EstablishmentStatus.normalize('Actif'), 'active');
      expect(EstablishmentStatus.normalize('SUSPENDU'), 'suspended');
      expect(EstablishmentStatus.normalize('Essai'), 'trial');
    });

    test('missing status keeps the historical default', () {
      expect(EstablishmentStatus.normalize(null), 'active');
      expect(EstablishmentStatus.normalize('  '), 'active');
    });

    test('unknown status is never shown as active', () {
      expect(EstablishmentStatus.normalize('archived'), 'suspended');
    });

    test('isActive tolerates legacy casings, not missing values', () {
      expect(EstablishmentStatus.isActive('active'), isTrue);
      expect(EstablishmentStatus.isActive('Active'), isTrue);
      expect(EstablishmentStatus.isActive(' Actif '), isTrue);

      expect(EstablishmentStatus.isActive('suspended'), isFalse);
      expect(EstablishmentStatus.isActive('Suspendu'), isFalse);
      expect(EstablishmentStatus.isActive('trial'), isFalse);
      expect(EstablishmentStatus.isActive('archived'), isFalse);
      expect(EstablishmentStatus.isActive(null), isFalse);
      expect(EstablishmentStatus.isActive(''), isFalse);
    });
  });
}
