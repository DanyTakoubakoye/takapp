import 'package:takapp/l10n/app_localizations.dart';

class AppRoles {
  /// =========================
  /// ROLES SAAS
  /// =========================
  static const String globalAdmin = 'global_admin';
  static const superAdmin = 'super_admin';
  static const proprietaire = 'proprietaire';
  static const gerante = 'gerante';
  static const comptable = 'comptable';
  static const chefCuisine = 'chef_cuisine';
  static const serveur = 'serveur';
  static const hygiene = 'service_hygiene';
  static const legacyHygiene = 'hygiene';
  static const barman = 'barman';
  static const majordhomme = 'majordhomme';
  static const receptionniste = 'receptionniste';

  /// Responsable de salle : entre la gérante et les serveurs, SANS hériter
  /// des droits de la gérante. Valeur technique unique, indépendante de la
  /// langue (jamais « floorManager », « Floor Manager »…).
  static const floorManager = 'floor_manager';

  static String normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    return normalized == legacyHygiene ? hygiene : normalized;
  }

  /// =========================
  /// LISTE COMPLETE
  /// =========================
  static const all = [
    globalAdmin,
    superAdmin,
    proprietaire,
    gerante,
    comptable,
    chefCuisine,
    serveur,
    hygiene,
    barman,
    majordhomme,
    receptionniste,
    floorManager,
  ];

  /// =========================
  /// LABELS DE REPLI
  /// =========================
  ///
  /// Conservés en français pour les usages hors interface. Pour
  /// l'AFFICHAGE, utiliser [label].
  static const labels = {
    globalAdmin: 'Administrateur global',
    superAdmin: 'Super Administrateur',
    proprietaire: 'Propriétaire',
    gerante: 'Gérante',
    comptable: 'Comptable',
    chefCuisine: 'Chef Cuisine',
    serveur: 'Serveur',
    hygiene: 'Service Hygiène',
    barman: 'Barman',
    majordhomme: 'Majordhomme',
    receptionniste: 'Réceptionniste',
    floorManager: 'Floor Manager',
  };

  /// =========================
  /// MODULES AUTORISÉS
  /// =========================
  ///
  /// SaaS :
  /// chaque rôle peut accéder
  /// à certains modules seulement.
  static const modules = {
    superAdmin: [
      'restaurant',
      'bar',
      'hotel',
      'stock',
      'fiscalization',
      'analytics',
      'settings',
    ],
    proprietaire: ['restaurant', 'bar', 'hotel', 'analytics', 'settings'],
    gerante: ['restaurant', 'bar', 'hotel', 'stock', 'analytics'],
    comptable: ['restaurant', 'bar', 'hotel', 'analytics', 'fiscalization'],
    chefCuisine: ['restaurant', 'stock'],
    serveur: ['restaurant', 'bar', 'hotel', 'fiscalization'],
    hygiene: ['hotel', 'stock'],
    barman: ['bar', 'stock'],
    majordhomme: ['hotel', 'stock'],
    receptionniste: ['hotel', 'fiscalization'],
    // Moindre privilège : aucun module tant que ses fonctions (services,
    // affectations, encaissements délégués…) ne sont pas implémentées.
    floorManager: <String>[],
  };

  /// =========================
  /// LABEL ROLE (REPLI)
  /// =========================
  static String getLabel(String role) {
    final normalized = normalizeRole(role);
    return labels[normalized] ?? normalized;
  }

  /// =========================
  /// LABEL ROLE (AFFICHAGE)
  /// =========================
  ///
  /// Le rôle reste une valeur technique ('gerante', 'chef_cuisine'…)
  /// stockée en base et comparée partout : seul son rendu est localisé.
  static String label(AppLocalizations l10n, String role) {
    switch (normalizeRole(role)) {
      case globalAdmin:
        return l10n.roleGlobalAdmin;
      case superAdmin:
        return l10n.roleSuperAdmin;
      case proprietaire:
        return l10n.roleOwner;
      case gerante:
        return l10n.roleManager;
      case comptable:
        return l10n.roleAccountant;
      case chefCuisine:
        return l10n.roleHeadChef;
      case serveur:
        return l10n.roleWaiter;
      case hygiene:
        return l10n.roleHousekeeping;
      case barman:
        return l10n.roleBartender;
      case majordhomme:
        return l10n.roleButler;
      case receptionniste:
        return l10n.roleReceptionist;
      case floorManager:
        return l10n.roleFloorManager;
      default:
        return role;
    }
  }

  /// =========================
  /// VERIFIER ROLE
  /// =========================
  static bool exists(String role) {
    return all.contains(role);
  }

  /// =========================
  /// MODULES D'UN ROLE
  /// =========================
  static List<String> getModules(String role) {
    return modules[normalizeRole(role)] ?? [];
  }

  /// =========================
  /// ROLE A ACCES MODULE ?
  /// =========================
  static bool canAccessModule({required String role, required String module}) {
    final roleModules = modules[normalizeRole(role)] ?? [];
    return roleModules.contains(module);
  }

  /// =========================
  /// HELPERS
  /// =========================
  static bool isAdmin(String role) {
    final normalized = normalizeRole(role);
    return normalized == superAdmin ||
        normalized == proprietaire ||
        normalized == gerante;
  }

  static bool isStockManager(String role) {
    final normalized = normalizeRole(role);
    return normalized == gerante ||
        normalized == chefCuisine ||
        normalized == barman ||
        normalized == hygiene ||
        normalized == majordhomme;
  }

  /// Réglage `stockMode` d'un établissement : réservé à l'administration
  /// plateforme. Miroir de `isSuperAdmin()` dans firestore.rules, qui est
  /// l'autorité réelle ; ce helper ne sert qu'à l'affichage.
  ///
  /// Propriétaire et gérante sont volontairement exclus : le mode strict est
  /// un contrôle anti-perte, celui qui gère le stock ne doit pas pouvoir le
  /// désactiver lui-même.
  static bool canEditStockMode(String role) {
    final normalized = normalizeRole(role);
    return normalized == globalAdmin || normalized == superAdmin;
  }
}
