/// Formules d'abonnement : valeurs TECHNIQUES stockées dans Firestore
/// (`establishments/{id}.plan`). Les libellés affichés ne servent jamais
/// d'identifiant.
class EstablishmentPlan {
  const EstablishmentPlan._();

  static const String starter = 'starter';
  static const String standard = 'standard';
  static const String premium = 'premium';
  static const String enterprise = 'enterprise';

  static const List<String> values = [starter, standard, premium, enterprise];

  /// Valeur utilisée quand le plan est absent ou inconnu : c'était déjà la
  /// valeur par défaut d'un établissement sans plan.
  static const String fallback = standard;

  /// Ramène une valeur Firestore, ancienne ou saisie à la main, à une valeur
  /// technique connue : `Premium`, ` PREMIUM ` → `premium`,
  /// `Entreprise` → `enterprise`. Toute autre valeur → [fallback].
  static String normalize(Object? raw) {
    final text = (raw ?? '').toString().trim().toLowerCase();

    if (values.contains(text)) return text;
    if (text == 'entreprise') return enterprise;

    return fallback;
  }
}
