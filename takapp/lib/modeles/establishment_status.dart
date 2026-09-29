/// Statuts d'établissement : valeurs TECHNIQUES stockées dans Firestore
/// (`establishments/{id}.status`). Les libellés affichés ne servent jamais
/// d'identifiant.
class EstablishmentStatus {
  const EstablishmentStatus._();

  static const String active = 'active';
  static const String suspended = 'suspended';
  static const String trial = 'trial';

  static const List<String> values = [active, suspended, trial];

  /// Statut absent : `active`, comme avant (établissement jamais qualifié).
  static const String missingFallback = active;

  /// Statut présent mais inconnu : `suspended`. On n'affiche pas comme actif
  /// un établissement dont on ne sait pas lire l'état.
  static const String unknownFallback = suspended;

  static const Map<String, String> _aliases = {
    'actif': active,
    'active': active,
    'suspendu': suspended,
    'suspended': suspended,
    'essai': trial,
    'trial': trial,
  };

  /// Ramène une valeur Firestore, ancienne ou saisie à la main, à une valeur
  /// technique connue : `Active`, `Actif` → `active`, `Suspendu` →
  /// `suspended`, `Essai` → `trial`.
  static String normalize(Object? raw) {
    final text = (raw ?? '').toString().trim().toLowerCase();

    if (text.isEmpty) return missingFallback;

    return _aliases[text] ?? unknownFallback;
  }

  /// Vrai si le statut stocké désigne un établissement actif (`active`,
  /// `Active`, `Actif`…). Un statut absent n'est PAS considéré comme actif
  /// ici : la carte d'établissement l'a toujours affiché comme inactif.
  static bool isActive(Object? raw) {
    final text = (raw ?? '').toString().trim();
    return text.isNotEmpty && normalize(text) == active;
  }
}
