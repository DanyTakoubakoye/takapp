import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/menu_ingredient_model.dart';
import 'package:takapp/modeles/stock_mode.dart';
import 'package:takapp/services/order_stock_policy.dart';

MenuIngredientModel _ingredient({
  String itemId = 'rice',
  String itemName = 'Riz',
  String store = 'restaurant',
  String unit = 'kg',
  double quantity = 0.2,
}) {
  return MenuIngredientModel(
    establishmentId: 'est-1',
    itemId: itemId,
    itemName: itemName,
    store: store,
    unit: unit,
    quantity: quantity,
  );
}

/// 2 plats de riz à 0,2 kg + 1 bière = 0,4 kg de riz et 1 bouteille.
List<OrderLineRecipe> _lines({bool withoutRecipe = false}) {
  return [
    OrderLineRecipe(
      menuItemName: 'Riz sauté',
      orderedQuantity: 2,
      ingredients: [_ingredient()],
    ),
    OrderLineRecipe(
      menuItemName: 'Bière',
      orderedQuantity: 1,
      ingredients: withoutRecipe
          ? const []
          : [
              _ingredient(
                itemId: 'beer',
                itemName: 'Bière 33cl',
                store: 'bar',
                unit: 'bouteille',
                quantity: 1,
              ),
            ],
    ),
  ];
}

final _riceKey = OrderStockPolicy.ingredientKey(
  store: 'restaurant',
  itemId: 'rice',
  unit: 'kg',
);

final _beerKey = OrderStockPolicy.ingredientKey(
  store: 'bar',
  itemId: 'beer',
  unit: 'bouteille',
);

Map<String, StockLevel?> _sufficientStock() => {
  _riceKey: const StockLevel(quantity: 5, minimumQuantity: 1, unit: 'kg'),
  _beerKey: const StockLevel(
    quantity: 10,
    minimumQuantity: 2,
    unit: 'bouteille',
  ),
};

/// Riz insuffisant (0,1 kg pour 0,4 kg requis), bière suffisante.
Map<String, StockLevel?> _insufficientRice() => {
  _riceKey: const StockLevel(quantity: 0.1, minimumQuantity: 1, unit: 'kg'),
  _beerKey: const StockLevel(
    quantity: 10,
    minimumQuantity: 2,
    unit: 'bouteille',
  ),
};

OrderStockPlan _evaluate(
  StockMode mode,
  Map<String, StockLevel?> levels, {
  bool withoutRecipe = false,
}) {
  return OrderStockPolicy.evaluate(
    mode: mode,
    requirements: OrderStockPolicy.computeRequirements(
      _lines(withoutRecipe: withoutRecipe),
    ),
    levels: levels,
  );
}

void main() {
  test('requirements are aggregated per store, item and unit', () {
    final requirements = OrderStockPolicy.computeRequirements([
      ..._lines(),
      OrderLineRecipe(
        menuItemName: 'Riz nature',
        orderedQuantity: 1,
        ingredients: [_ingredient(quantity: 0.3)],
      ),
    ]);

    final rice = requirements.requirements.firstWhere((r) => r.key == _riceKey);

    expect(rice.quantity, closeTo(0.7, 1e-9));
    expect(requirements.recipeAnomalies, isEmpty);
  });

  group('STRICT', () {
    test('sufficient stock -> accepted with every deduction', () {
      final plan = _evaluate(StockMode.strict, _sufficientStock());

      expect(plan.isAccepted, isTrue);
      expect(plan.hasWarnings, isFalse);
      expect(plan.stockStatus, 'deducted');
      expect(plan.deductedKeys, unorderedEquals([_riceKey, _beerKey]));

      final rice = plan.deductions.firstWhere(
        (d) => d.requirement.key == _riceKey,
      );
      expect(rice.newQuantity, closeTo(4.6, 1e-9));
      expect(rice.isLowStock, isFalse);
    });

    test('insufficient stock -> refused, nothing deducted', () {
      final plan = _evaluate(StockMode.strict, _insufficientRice());

      expect(plan.isAccepted, isFalse);
      expect(plan.deductions, isEmpty);
      expect(plan.refusal?.code, AppErrorCode.insufficientStockDetailed);
      expect(plan.refusal?.name, 'Riz');
    });

    test('missing recipe -> refused', () {
      final plan = _evaluate(
        StockMode.strict,
        _sufficientStock(),
        withoutRecipe: true,
      );

      expect(plan.isAccepted, isFalse);
      expect(plan.deductions, isEmpty);
      expect(plan.refusal?.code, AppErrorCode.noRecipeDefined);
    });

    test('unknown stock item or unit mismatch -> refused', () {
      final missing = _evaluate(StockMode.strict, {
        _beerKey: _sufficientStock()[_beerKey],
      });
      expect(missing.refusal?.code, AppErrorCode.itemNotFoundInStockFor);

      final mismatch = _evaluate(StockMode.strict, {
        ..._sufficientStock(),
        _riceKey: const StockLevel(quantity: 5, minimumQuantity: 0, unit: 'g'),
      });
      expect(mismatch.refusal?.code, AppErrorCode.inconsistentUnit);
    });
  });

  group('WARNING_ONLY', () {
    test('sufficient stock -> accepted without warning', () {
      final plan = _evaluate(StockMode.warningOnly, _sufficientStock());

      expect(plan.isAccepted, isTrue);
      expect(plan.hasWarnings, isFalse);
      expect(plan.stockStatus, 'deducted');
      expect(plan.deductedKeys, unorderedEquals([_riceKey, _beerKey]));
    });

    test('insufficient stock -> accepted with a traced warning', () {
      final plan = _evaluate(StockMode.warningOnly, _insufficientRice());

      expect(plan.isAccepted, isTrue);
      expect(plan.hasWarnings, isTrue);
      expect(plan.stockStatus, 'partial');

      // Le riz manquant n'est pas déduit ; la bière disponible l'est.
      expect(plan.deductedKeys, [_beerKey]);

      final anomaly = plan.anomalies.single;
      expect(anomaly.type, StockAnomalyType.insufficientStock);
      expect(anomaly.toMap(), {
        'type': 'insufficient_stock',
        'menuItemName': '',
        'itemName': 'Riz',
        'store': 'restaurant',
        'unit': 'kg',
        'stockUnit': 'kg',
        'required': closeTo(0.4, 1e-9),
        'available': 0.1,
      });
      expect(anomaly.toAppError().code, AppErrorCode.insufficientStockDetailed);
    });

    test('missing recipe -> accepted with warning, other lines deducted', () {
      final plan = _evaluate(
        StockMode.warningOnly,
        _sufficientStock(),
        withoutRecipe: true,
      );

      expect(plan.isAccepted, isTrue);
      expect(plan.anomalies.single.type, StockAnomalyType.missingRecipe);
      expect(plan.anomalies.single.menuItemName, 'Bière');
      expect(plan.deductedKeys, [_riceKey]);
    });

    test('nothing deductible -> accepted, status not_deducted', () {
      final plan = _evaluate(StockMode.warningOnly, const {});

      expect(plan.isAccepted, isTrue);
      expect(plan.deductions, isEmpty);
      expect(plan.anomalies, hasLength(2));
      expect(plan.stockStatus, 'not_deducted');
    });
  });

  group('DISABLED', () {
    test('insufficient stock -> accepted', () {
      final plan = _evaluate(StockMode.disabled, _insufficientRice());

      expect(plan.isAccepted, isTrue);
      expect(plan.hasWarnings, isFalse);
    });

    test('missing recipe -> accepted', () {
      final plan = _evaluate(StockMode.disabled, const {}, withoutRecipe: true);

      expect(plan.isAccepted, isTrue);
      expect(plan.anomalies, isEmpty);
    });

    test('no automatic stock movement', () {
      final plan = _evaluate(StockMode.disabled, _sufficientStock());

      expect(plan.deductions, isEmpty);
      expect(plan.deductedKeys, isEmpty);
      expect(plan.stockStatus, 'disabled');
    });
  });
}
