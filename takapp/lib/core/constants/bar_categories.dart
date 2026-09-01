/// Catalogue des catégories de boissons du Bar.
///
/// Certaines catégories sont des SOUS-CATÉGORIES rattachées à une catégorie
/// parente. Exemple : « Cocktails alcoolisés » et « Sans alcool » sont les
/// deux sous-catégories de « Cocktails », « Cognacs », « Vodkas »… celles de
/// « Spiritueux », et « Vins rouges », « Champagnes »… celles de « Vins et
/// Champagnes ».
///
/// En base, un article de menu ne stocke qu'une seule chaîne dans son champ
/// `category` (la sous-catégorie quand il y en a une). Le rattachement au
/// parent se fait ici, ce qui évite toute migration des données existantes.
class BarCategories {
  /// =========================
  /// CATÉGORIES
  /// =========================

  static const boisson = 'boisson';

  static const cocktails = 'Cocktails';

  static const cocktailsAlcoolises = 'Cocktails alcoolisés';

  static const sansAlcool = 'Sans alcool';

  static const shots = 'Shots et shots composés';

  static const bieres = 'Bières';

  static const bulles = 'Bulles';

  static const vinsEtChampagnes = 'Vins et Champagnes';

  static const vinsRouges = 'Vins rouges';

  static const vinsBlancs = 'Vins blancs';

  static const roses = 'Rosés';

  static const champagnes = 'Champagnes';

  static const spiritueux = 'Spiritueux';

  static const cognacs = 'Cognacs';

  static const vodkas = 'Vodkas';

  static const bettersAnisees = 'Betters/Anisées';

  static const rhumGinTequila = 'Rhum/Gin-Tequila';

  static const liqueursCremes = 'Liqueurs crèmes';

  static const whiskeys = 'Whiskeys';

  static const jus = 'Jus';

  static const jusNatures = 'Jus natures';

  static const smoothies = 'Smoothies';

  static const sirop = 'Sirop';

  static const boissonsChaudes = 'Boissons chaudes';

  static const sodas = 'Sodas';

  static const eaux = 'Eaux';

  /// =========================
  /// ARBORESCENCE
  /// =========================

  /// Catégories de premier niveau, dans l'ordre d'affichage.
  static const List<String> parents = [
    boisson,
    cocktails,
    shots,
    bieres,
    bulles,
    vinsEtChampagnes,
    spiritueux,
    jus,
    jusNatures,
    smoothies,
    sirop,
    boissonsChaudes,
    sodas,
    eaux,
  ];

  /// Sous-catégories, par catégorie parente, dans l'ordre d'affichage.
  static const Map<String, List<String>> children = {
    cocktails: [cocktailsAlcoolises, sansAlcool],
    vinsEtChampagnes: [vinsRouges, vinsBlancs, roses, champagnes],
    spiritueux: [
      cognacs,
      vodkas,
      bettersAnisees,
      rhumGinTequila,
      liqueursCremes,
      whiskeys,
    ],
  };

  /// Anciens libellés encore stockés en base, rattachés à leur libellé
  /// actuel. Évite de devoir migrer les articles déjà saisis quand une
  /// catégorie est renommée (« Vins » → « Vins et Champagnes »).
  static const Map<String, String> legacyLabels = {'vins': vinsEtChampagnes};

  /// Toutes les catégories sélectionnables (parents + sous-catégories),
  /// à plat et dans l'ordre d'affichage.
  static List<String> get all => [
    for (final parent in parents) ...[parent, ...?children[parent]],
  ];

  /// =========================
  /// HELPERS
  /// =========================

  /// Normalise pour comparer (minuscules + espaces compactés).
  static String normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Libellé actuel de [category] : les anciens libellés renommés sont
  /// remplacés par le nouveau, les autres sont renvoyés tels quels.
  static String canonical(String category) =>
      legacyLabels[normalize(category)] ?? category.trim();

  /// Catégorie parente de [category], ou `null` si c'est une catégorie de
  /// premier niveau (ou une catégorie libre inconnue du catalogue).
  static String? parentOf(String category) {
    final cat = normalize(canonical(category));

    for (final entry in children.entries) {
      for (final child in entry.value) {
        if (normalize(child) == cat) return entry.key;
      }
    }

    return null;
  }

  /// Sous-catégories de [category] (liste vide si elle n'en a pas).
  static List<String> childrenOf(String category) {
    final cat = normalize(canonical(category));

    for (final entry in children.entries) {
      if (normalize(entry.key) == cat) return entry.value;
    }

    return const [];
  }

  /// `true` si [category] est [parent] lui-même ou l'une de ses
  /// sous-catégories. Sert au filtrage : choisir « Spiritueux » doit
  /// remonter aussi les « Cognacs », « Vodkas »…
  static bool belongsTo(String category, String parent) {
    final cat = normalize(canonical(category));
    final par = normalize(canonical(parent));

    if (cat == par) return true;

    final foundParent = parentOf(category);

    return foundParent != null && normalize(foundParent) == par;
  }

  /// Libellé complet d'une catégorie : « Cocktails › Sans alcool » pour une
  /// sous-catégorie, le libellé seul sinon.
  static String displayLabel(String category) {
    final label = canonical(category);
    final parent = parentOf(label);

    if (parent == null) return label;

    return '$parent › $label';
  }
}
