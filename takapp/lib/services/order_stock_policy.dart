import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/menu_ingredient_model.dart';
import 'package:takapp/modeles/stock_mode.dart';

/// =========================
/// POLITIQUE DE STOCK DES COMMANDES
/// =========================
///
/// Moteur **pur** (aucune dépendance Firebase) qui décide, pour une commande,
/// selon le [StockMode] de l'établissement :
/// - si la commande est acceptée ou refusée ;
/// - quelles déductions de stock appliquer ;
/// - quelles anomalies tracer.
///
/// `OrderService` l'appelle à l'intérieur de la transaction Firestore qui crée
/// la commande, avec les niveaux de stock lus dans cette même transaction.
///
/// Règles :
///
/// | Mode        | Recette absente / stock KO | Déduction                         |
/// |-------------|----------------------------|-----------------------------------|
/// | strict      | commande refusée           | tout ou rien (aucune si refus)    |
/// | warningOnly | acceptée + anomalie tracée | seulement les lignes couvertes    |
/// | disabled    | acceptée, rien n'est vérifié | aucune                          |
///
/// WARNING_ONLY — ce qui arrive quand la déduction est impossible :
/// chaque ingrédient agrégé est traité indépendamment. S'il est disponible
/// en quantité suffisante (et dans la bonne unité), il est déduit normalement
/// avec son mouvement de stock. Sinon il n'est **pas déduit du tout** : le
/// stock reste inchangé (jamais négatif, jamais ramené arbitrairement à 0) et
/// l'écart est enregistré sur la commande (`stockAnomalies`) avec les
/// quantités requise et disponible. La régularisation relève ensuite d'un
/// inventaire / d'une sortie manuelle par la gérance.
///
/// TODO(cloud-functions): ce moteur tourne côté client. Tant que la création
/// de commande n'est pas portée par une Cloud Function (`createOrderAndDeductStock`),
/// un client modifié peut contourner la politique. Le même algorithme devra y
/// être réimplémenté, avec lecture de `stockMode` côté serveur.
class OrderStockPolicy {
  const OrderStockPolicy._();

  /// Clé d'agrégation d'un ingrédient : identique à l'ancien calcul, pour que
  /// les restitutions à l'annulation retrouvent les mêmes lignes.
  static String ingredientKey({
    required String store,
    required String itemId,
    required String unit,
  }) {
    return '${store}_${itemId}_$unit';
  }

  /// Étape 1 — besoins en stock calculés à partir des recettes.
  ///
  /// Aucun accès au stock : les anomalies de recette (recette absente,
  /// ingrédient mal renseigné) sont collectées, pas levées. C'est
  /// [evaluate] qui décide, selon le mode, si elles bloquent.
  static StockRequirements computeRequirements(List<OrderLineRecipe> lines) {
    final Map<String, StockRequirement> aggregated = {};
    final List<StockAnomaly> anomalies = [];

    for (final line in lines) {
      if (line.ingredients.isEmpty) {
        anomalies.add(
          StockAnomaly(
            type: StockAnomalyType.missingRecipe,
            menuItemName: line.menuItemName,
            itemName: line.menuItemName,
          ),
        );
        continue;
      }

      for (final ingredient in line.ingredients) {
        final invalidType = _invalidIngredientType(ingredient);

        if (invalidType != null) {
          anomalies.add(
            StockAnomaly(
              type: invalidType,
              menuItemName: line.menuItemName,
              itemName: ingredient.itemName,
              store: ingredient.store,
              unit: ingredient.unit,
            ),
          );
          continue;
        }

        final key = ingredientKey(
          store: ingredient.store,
          itemId: ingredient.itemId,
          unit: ingredient.unit,
        );

        final quantity = ingredient.quantity * line.orderedQuantity;
        final existing = aggregated[key];

        aggregated[key] = existing == null
            ? StockRequirement(
                key: key,
                store: ingredient.store,
                itemId: ingredient.itemId,
                itemName: ingredient.itemName,
                unit: ingredient.unit,
                quantity: quantity,
              )
            : existing.withQuantity(existing.quantity + quantity);
      }
    }

    return StockRequirements(
      requirements: aggregated.values.toList(),
      recipeAnomalies: anomalies,
    );
  }

  static StockAnomalyType? _invalidIngredientType(MenuIngredientModel i) {
    if (i.store.trim().isEmpty) return StockAnomalyType.invalidIngredientStore;
    if (i.itemId.trim().isEmpty) return StockAnomalyType.invalidIngredientItem;
    if (i.unit.trim().isEmpty) return StockAnomalyType.invalidIngredientUnit;
    if (i.quantity <= 0) return StockAnomalyType.invalidIngredientQuantity;
    return null;
  }

  /// Étape 2 — décision finale à partir des niveaux de stock réels.
  ///
  /// [levels] : niveau par clé d'ingrédient ; `null` ou absent = article
  /// introuvable dans le stock. Ignoré en mode [StockMode.disabled].
  static OrderStockPlan evaluate({
    required StockMode mode,
    required StockRequirements requirements,
    required Map<String, StockLevel?> levels,
  }) {
    if (mode == StockMode.disabled) {
      return const OrderStockPlan(
        mode: StockMode.disabled,
        deductions: [],
        anomalies: [],
        refusal: null,
      );
    }

    final List<StockDeduction> deductions = [];
    final List<StockAnomaly> anomalies = [...requirements.recipeAnomalies];

    for (final requirement in requirements.requirements) {
      final level = levels[requirement.key];
      final anomaly = _checkLevel(requirement, level);

      if (anomaly != null) {
        anomalies.add(anomaly);
        continue;
      }

      final newQuantity = level!.quantity - requirement.quantity;

      deductions.add(
        StockDeduction(
          requirement: requirement,
          newQuantity: newQuantity,
          isLowStock: newQuantity <= level.minimumQuantity,
        ),
      );
    }

    if (mode == StockMode.strict && anomalies.isNotEmpty) {
      return OrderStockPlan(
        mode: mode,
        deductions: const [],
        anomalies: anomalies,
        refusal: anomalies.first.toAppError(),
      );
    }

    return OrderStockPlan(
      mode: mode,
      deductions: deductions,
      anomalies: anomalies,
      refusal: null,
    );
  }

  static StockAnomaly? _checkLevel(StockRequirement r, StockLevel? level) {
    if (level == null) {
      return StockAnomaly(
        type: StockAnomalyType.stockItemNotFound,
        itemName: r.itemName,
        store: r.store,
        unit: r.unit,
        required: r.quantity,
      );
    }

    if (level.unit != r.unit) {
      return StockAnomaly(
        type: StockAnomalyType.unitMismatch,
        itemName: r.itemName,
        store: r.store,
        unit: r.unit,
        stockUnit: level.unit,
        required: r.quantity,
        available: level.quantity,
      );
    }

    if (level.quantity < r.quantity) {
      return StockAnomaly(
        type: StockAnomalyType.insufficientStock,
        itemName: r.itemName,
        store: r.store,
        unit: r.unit,
        stockUnit: level.unit,
        required: r.quantity,
        available: level.quantity,
      );
    }

    return null;
  }
}

/// Une ligne de commande avec la recette du plat au moment de la commande.
class OrderLineRecipe {
  final String menuItemName;
  final double orderedQuantity;
  final List<MenuIngredientModel> ingredients;

  const OrderLineRecipe({
    required this.menuItemName,
    required this.orderedQuantity,
    required this.ingredients,
  });
}

/// Besoin agrégé pour un ingrédient (magasin + article + unité).
class StockRequirement {
  final String key;
  final String store;
  final String itemId;
  final String itemName;
  final String unit;
  final double quantity;

  const StockRequirement({
    required this.key,
    required this.store,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
  });

  StockRequirement withQuantity(double value) {
    return StockRequirement(
      key: key,
      store: store,
      itemId: itemId,
      itemName: itemName,
      unit: unit,
      quantity: value,
    );
  }
}

class StockRequirements {
  final List<StockRequirement> requirements;
  final List<StockAnomaly> recipeAnomalies;

  const StockRequirements({
    required this.requirements,
    required this.recipeAnomalies,
  });
}

/// Niveau réel d'un article de stock, lu dans la transaction.
class StockLevel {
  final double quantity;
  final double minimumQuantity;
  final String unit;

  const StockLevel({
    required this.quantity,
    required this.minimumQuantity,
    required this.unit,
  });
}

/// Déduction validée, prête à être écrite.
class StockDeduction {
  final StockRequirement requirement;
  final double newQuantity;
  final bool isLowStock;

  const StockDeduction({
    required this.requirement,
    required this.newQuantity,
    required this.isLowStock,
  });
}

enum StockAnomalyType {
  missingRecipe('missing_recipe'),
  invalidIngredientStore('invalid_ingredient_store'),
  invalidIngredientItem('invalid_ingredient_item'),
  invalidIngredientUnit('invalid_ingredient_unit'),
  invalidIngredientQuantity('invalid_ingredient_quantity'),
  stockItemNotFound('stock_item_not_found'),
  unitMismatch('unit_mismatch'),
  insufficientStock('insufficient_stock');

  const StockAnomalyType(this.value);

  final String value;
}

/// Anomalie de stock : refus en strict, avertissement tracé en warningOnly.
class StockAnomaly {
  final StockAnomalyType type;
  final String menuItemName;
  final String itemName;
  final String store;
  final String unit;
  final String stockUnit;
  final double required;
  final double available;

  const StockAnomaly({
    required this.type,
    this.menuItemName = '',
    required this.itemName,
    this.store = '',
    this.unit = '',
    this.stockUnit = '',
    this.required = 0,
    this.available = 0,
  });

  /// Trace structurée enregistrée sur la commande (`stockAnomalies`).
  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'menuItemName': menuItemName,
      'itemName': itemName,
      'store': store,
      'unit': unit,
      'stockUnit': stockUnit,
      'required': required,
      'available': available,
    };
  }

  /// Message traduisible réutilisant les codes d'erreur existants.
  AppError toAppError() {
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

    switch (type) {
      case StockAnomalyType.missingRecipe:
        return AppError(AppErrorCode.noRecipeDefined, name: itemName);
      case StockAnomalyType.invalidIngredientStore:
        return AppError(AppErrorCode.invalidIngredientStore, name: itemName);
      case StockAnomalyType.invalidIngredientItem:
        return AppError(AppErrorCode.invalidIngredientItemId, name: itemName);
      case StockAnomalyType.invalidIngredientUnit:
        return AppError(AppErrorCode.invalidIngredientUnit, name: itemName);
      case StockAnomalyType.invalidIngredientQuantity:
        return AppError(AppErrorCode.invalidIngredientQuantity, name: itemName);
      case StockAnomalyType.stockItemNotFound:
        return AppError(AppErrorCode.itemNotFoundInStockFor, name: itemName);
      case StockAnomalyType.unitMismatch:
        return AppError(
          AppErrorCode.inconsistentUnit,
          name: itemName,
          params: {'stockUnit': stockUnit, 'recipeUnit': unit},
        );
      case StockAnomalyType.insufficientStock:
        return AppError(
          AppErrorCode.insufficientStockDetailed,
          name: itemName,
          params: {
            'available': '${fmt(available)} $stockUnit',
            'required': '${fmt(required)} $unit',
          },
        );
    }
  }
}

/// Décision finale pour une commande.
class OrderStockPlan {
  final StockMode mode;
  final List<StockDeduction> deductions;
  final List<StockAnomaly> anomalies;

  /// Non nul = commande refusée (strict uniquement).
  final AppError? refusal;

  const OrderStockPlan({
    required this.mode,
    required this.deductions,
    required this.anomalies,
    required this.refusal,
  });

  bool get isAccepted => refusal == null;

  bool get hasWarnings => isAccepted && anomalies.isNotEmpty;

  /// Clés effectivement déduites : sert à ne restituer, à l'annulation, que
  /// ce qui a réellement été retiré du stock.
  List<String> get deductedKeys =>
      deductions.map((d) => d.requirement.key).toList();

  /// `disabled` | `deducted` | `partial` | `not_deducted` (stockStatus).
  String get stockStatus {
    if (mode == StockMode.disabled) return 'disabled';
    if (anomalies.isEmpty) return 'deducted';
    return deductions.isEmpty ? 'not_deducted' : 'partial';
  }
}
