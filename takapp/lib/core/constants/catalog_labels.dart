import 'package:takapp/l10n/app_localizations.dart';

/// Libellés d'affichage des catégories et des motifs de mouvement de stock.
///
/// La base de données garde le libellé **français** : c'est lui la clé, et il
/// ne change jamais selon la langue de l'utilisateur. Ces helpers ne servent
/// qu'à l'affichage, sur le même modèle que [AppRoles.label].
///
/// Une valeur inconnue du catalogue (catégorie libre saisie à la main, ancien
/// libellé, motif tapé par un utilisateur) est renvoyée telle quelle : mieux
/// vaut afficher le texte d'origine qu'une chaîne vide.
class CatalogLabels {
  /// Normalise pour comparer : minuscules, espaces compactés, apostrophes et
  /// accents ramenés à une forme unique. Absorbe les variantes déjà en base
  /// (« Viandes » / « viande », « Produits d'entretien » avec l'une ou l'autre
  /// apostrophe).
  static String normalize(String value) {
    var v = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    v = v.replaceAll('’', "'");

    const accents = {
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'œ': 'oe',
    };

    accents.forEach((accented, plain) {
      v = v.replaceAll(accented, plain);
    });

    return v;
  }

  /// Libellé traduit d'une catégorie stockée en base.
  ///
  /// Couvre les catégories d'articles de stock, de plats et du bar. Les
  /// singuliers/pluriels déjà présents en base (« viande » et « Viandes »)
  /// sont traités comme des entrées distinctes, parce qu'ils le sont aussi
  /// dans les listes de saisie.
  static String category(AppLocalizations l10n, String raw) {
    switch (normalize(raw)) {
      // --- articles de stock ---
      case 'cereales':
        return l10n.catCereals;
      case 'boissons':
        return l10n.catDrinks;
      case 'condiments':
        return l10n.catCondiments;
      case 'viandes':
        return l10n.catMeats;
      case 'viande':
        return l10n.catMeat;
      case 'legumes et fruits':
        return l10n.catVegetablesFruits;
      case 'produits laitiers':
        return l10n.catDairy;
      case "produits d'entretien":
        return l10n.catCleaningProducts;
      case 'consommables hotel':
        return l10n.catHotelConsumables;
      case 'poissons':
        return l10n.catFishPlural;
      case 'poisson':
        return l10n.catFish;
      case 'accompagnements':
        return l10n.catSideDishes;
      case 'pain':
        return l10n.catBread;
      case 'pains':
        return l10n.catBreads;
      case 'fromage':
        return l10n.catCheese;
      case 'hamberger':
        return l10n.catBurger;
      case 'pate':
        return l10n.catPasta;
      case 'sauce':
        return l10n.catSauce;
      case 'sauces':
        return l10n.catSauces;
      case 'oeuf':
        return l10n.catEgg;
      case 'couverture':
        return l10n.catBlanket;
      case 'consommable':
        return l10n.catConsumable;
      case 'reutilisable':
        return l10n.catReusable;
      case 'viandes et poissons':
        return l10n.catMeatAndFish;
      case 'autres':
        return l10n.catOther;

      // --- plats ---
      case 'plat':
        return l10n.catMainDish;
      case 'volailles':
        return l10n.catPoultry;
      case 'pates':
        return l10n.catPastaPlural;
      case 'fruits de mer':
        return l10n.catSeafood;
      case 'specialites africaines':
        return l10n.catAfricanSpecialties;
      case 'burger et sandwichs':
        return l10n.catBurgersSandwiches;
      case 'etrees libanaises':
        return l10n.catLebaneseStarters;
      case 'entrees froides':
        return l10n.catColdStarters;
      case 'pizzas':
        return l10n.catPizzas;
      case 'fast food':
        return l10n.catFastFood;
      case 'desserts':
        return l10n.catDesserts;

      // --- bar ---
      case 'boisson':
        return l10n.catBarDrink;
      case 'cocktails':
        return l10n.catCocktails;
      case 'cocktails alcoolises':
        return l10n.catAlcoholicCocktails;
      case 'sans alcool':
        return l10n.catNonAlcoholic;
      case 'shots et shots composes':
        return l10n.catShots;
      case 'bieres':
        return l10n.catBeers;
      case 'bulles':
        return l10n.catSparkling;
      case 'vins et champagnes':
        return l10n.catWinesChampagnes;
      case 'vins rouges':
        return l10n.catRedWines;
      case 'vins blancs':
        return l10n.catWhiteWines;
      case 'roses':
        return l10n.catRoses;
      case 'champagnes':
        return l10n.catChampagnes;
      case 'spiritueux':
        return l10n.catSpirits;
      case 'cognacs':
        return l10n.catCognacs;
      case 'vodkas':
        return l10n.catVodkas;
      case 'betters/anisees':
        return l10n.catBittersAnise;
      case 'rhum/gin-tequila':
        return l10n.catRumGinTequila;
      case 'liqueurs cremes':
        return l10n.catCreamLiqueurs;
      case 'whiskeys':
        return l10n.catWhiskeys;
      case 'jus':
        return l10n.catJuices;
      case 'jus natures':
        return l10n.catPlainJuices;
      case 'smoothies':
        return l10n.catSmoothies;
      case 'sirop':
        return l10n.catSyrup;
      case 'boissons chaudes':
        return l10n.catHotDrinks;
      case 'sodas':
        return l10n.catSodas;
      case 'eaux':
        return l10n.catWaters;

      default:
        return raw.trim();
    }
  }

  /// Motifs de mouvement de stock **générés par l'application**.
  ///
  /// Les motifs saisis librement par un utilisateur ne sont pas traduits :
  /// ils sont stockés tels qu'il les a écrits, et renvoyés tels quels.
  static String stockReason(AppLocalizations l10n, String raw) {
    final value = raw.trim();

    if (normalize(value) == 'approvisionnement valide') {
      return l10n.reasonSupplyValidated;
    }

    final room = RegExp(
      r'^Préparation chambre (.+)$',
      caseSensitive: false,
    ).firstMatch(value);

    if (room != null) {
      return l10n.reasonRoomPreparation(room.group(1)!);
    }

    final consumption = RegExp(
      r'^Consommation automatique commande (.+)$',
      caseSensitive: false,
    ).firstMatch(value);

    if (consumption != null) {
      return l10n.reasonAutoOrderConsumption(consumption.group(1)!);
    }

    final restock = RegExp(
      r'^Restitution automatique annulation commande (.+)$',
      caseSensitive: false,
    ).firstMatch(value);

    if (restock != null) {
      return l10n.reasonAutoOrderRestock(restock.group(1)!);
    }

    return value;
  }
}
