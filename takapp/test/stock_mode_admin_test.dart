import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/modeles/stock_mode.dart';
import 'package:takapp/services/establishment_config_service.dart';

void main() {
  group('lecture de stockMode sur le document établissement', () {
    StockMode read(Map<String, dynamic>? data) =>
        EstablishmentConfigService.stockModeFromData(data);

    test('disabled', () {
      expect(read({'stockMode': 'disabled'}), StockMode.disabled);
    });

    test('warningOnly', () {
      expect(read({'stockMode': 'warningOnly'}), StockMode.warningOnly);
    });

    test('strict', () {
      expect(read({'stockMode': 'strict'}), StockMode.strict);
    });

    test('champ absent (établissement ancien) => strict', () {
      expect(read({'name': 'Hôtel ancien'}), StockMode.strict);
    });

    test('document absent => strict', () {
      expect(read(null), StockMode.strict);
    });

    test('valeur inconnue => strict', () {
      expect(read({'stockMode': 'futureMode'}), StockMode.strict);
      expect(read({'stockMode': 42}), StockMode.strict);
      expect(read({'stockMode': ''}), StockMode.strict);
    });
  });

  group('permission de modifier stockMode', () {
    test('réservée à l\'administration plateforme', () {
      expect(AppRoles.canEditStockMode(AppRoles.globalAdmin), isTrue);
      expect(AppRoles.canEditStockMode(AppRoles.superAdmin), isTrue);
      expect(AppRoles.canEditStockMode(' GLOBAL_ADMIN '), isTrue);
    });

    test('refusée aux rôles d\'établissement et opérationnels', () {
      for (final role in [
        AppRoles.proprietaire,
        AppRoles.gerante,
        AppRoles.serveur,
        AppRoles.barman,
        AppRoles.chefCuisine,
        AppRoles.comptable,
        AppRoles.hygiene,
        AppRoles.legacyHygiene,
        AppRoles.majordhomme,
        AppRoles.receptionniste,
        '',
        'inconnu',
      ]) {
        expect(AppRoles.canEditStockMode(role), isFalse, reason: role);
      }
    });
  });
}
