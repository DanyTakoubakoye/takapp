/// Catalogue des catégories de boissons du Bar.
///
/// Certaines catégories sont des SOUS-CATÉGORIES rattachées à une catégorie
/// parente. Exemple : « Cocktails alcoolisés » et « Sans alcool » sont les
/// deux sous-catégories de « Cocktails ».
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

  static const bieres = 'Bières';

  static const vins = 'Vins';

  static const spiritueux = 'Spiritueux';

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
    bieres,
    vins,
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
  };

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

  /// Catégorie parente de [category], ou `null` si c'est une catégorie de
  /// premier niveau (ou une catégorie libre inconnue du catalogue).
  static String? parentOf(String category) {
    final cat = normalize(category);

    for (final entry in children.entries) {
      for (final child in entry.value) {
        if (normalize(child) == cat) return entry.key;
      }
    }

    return null;
  }

  /// Sous-catégories de [category] (liste vide si elle n'en a pas).
  static List<String> childrenOf(String category) {
    final cat = normalize(category);

    for (final entry in children.entries) {
      if (normalize(entry.key) == cat) return entry.value;
    }

    return const [];
  }

  /// `true` si [category] est [parent] lui-même ou l'une de ses
  /// sous-catégories. Sert au filtrage : choisir « Cocktails » doit
  /// remonter aussi les « Cocktails alcoolisés » et les « Sans alcool ».
  static bool belongsTo(String category, String parent) {
    final cat = normalize(category);
    final par = normalize(parent);

    if (cat == par) return true;

    final foundParent = parentOf(category);

    return foundParent != null && normalize(foundParent) == par;
  }

  /// Libellé complet d'une catégorie : « Cocktails › Sans alcool » pour une
  /// sous-catégorie, le libellé seul sinon.
  static String displayLabel(String category) {
    final parent = parentOf(category);

    if (parent == null) return category;

    return '$parent › ${category.trim()}';
  }
}
