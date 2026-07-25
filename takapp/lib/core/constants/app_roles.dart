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
  static const barman = 'barman';
  static const majordhomme = 'majordhomme';
  static const receptionniste = 'receptionniste';

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
  ];

  /// =========================
  /// LABELS UI
  /// =========================
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
    proprietaire: [
      'restaurant',
      'bar',
      'hotel',
      'stock',
      'analytics',
      'settings',
    ],
    gerante: ['restaurant', 'bar', 'hotel', 'stock', 'analytics'],
    comptable: ['restaurant', 'bar', 'hotel', 'analytics', 'fiscalization'],
    chefCuisine: ['restaurant', 'stock'],
    serveur: ['restaurant'],
    hygiene: ['hotel', 'stock'],
    barman: ['bar', 'stock'],
    majordhomme: ['hotel', 'stock'],
    receptionniste: ['hotel', 'fiscalization'],
  };

  /// =========================
  /// LABEL ROLE
  /// =========================
  static String getLabel(String role) {
    return labels[role] ?? role;
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
    return modules[role] ?? [];
  }

  /// =========================
  /// ROLE A ACCES MODULE ?
  /// =========================
  static bool canAccessModule({required String role, required String module}) {
    final roleModules = modules[role] ?? [];
    return roleModules.contains(module);
  }

  /// =========================
  /// HELPERS
  /// =========================
  static bool isAdmin(String role) {
    return role == superAdmin || role == proprietaire || role == gerante;
  }

  static bool isStockManager(String role) {
    return role == gerante ||
        role == chefCuisine ||
        role == barman ||
        role == hygiene ||
        role == majordhomme;
  }
}
