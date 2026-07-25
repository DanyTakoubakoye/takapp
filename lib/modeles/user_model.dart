class UserModel {
  final String uid;

  final String establishmentId;
  final String establishmentName;

  final String name;
  final String email;
  final String phone;

  final String role;

  final bool isActive;

  final bool canAccessRestaurant;
  final bool canAccessBar;
  final bool canAccessHotel;
  final bool canAccessStock;
  final bool canAccessFiscalization;

  const UserModel({
    required this.uid,
    required this.establishmentId,
    required this.establishmentName,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.canAccessRestaurant,
    required this.canAccessBar,
    required this.canAccessHotel,
    required this.canAccessStock,
    required this.canAccessFiscalization,
  });

  static String _normalizeRole(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  static bool _moduleValue(
    Map<String, dynamic> modules,
    String key,
    bool fallback,
  ) {
    if (modules.containsKey(key)) {
      return modules[key] == true;
    }

    return fallback;
  }

  static bool _canAccessRestaurantByRole(String role) {
    return role == 'serveur' ||
        role == 'chef_cuisine' ||
        role == 'gerante' ||
        role == 'comptable' ||
        role == 'proprietaire' ||
        role == 'super_admin';
  }

  static bool _canAccessBarByRole(String role) {
    return role == 'serveur' ||
        role == 'barman' ||
        role == 'gerante' ||
        role == 'comptable' ||
        role == 'proprietaire' ||
        role == 'super_admin';
  }

  static bool _canAccessHotelByRole(String role) {
    return role == 'serveur' ||
        role == 'service_hygiene' ||
        role == 'hygiene' ||
        role == 'majordhomme' ||
        role == 'receptionniste' ||
        role == 'gerante' ||
        role == 'comptable' ||
        role == 'proprietaire' ||
        role == 'super_admin';
  }

  static bool _canAccessStockByRole(String role) {
    return role == 'chef_cuisine' ||
        role == 'barman' ||
        role == 'service_hygiene' ||
        role == 'hygiene' ||
        role == 'majordhomme' ||
        role == 'gerante' ||
        role == 'proprietaire' ||
        role == 'super_admin';
  }

  static bool _canAccessFiscalizationByRole(String role) {
    return role == 'serveur' ||
        role == 'gerante' ||
        role == 'comptable' ||
        role == 'receptionniste' ||
        role == 'proprietaire' ||
        role == 'super_admin';
  }

  /// [establishmentModules] : le champ `modules` du document
  /// `establishments/{establishmentId}` (l'ABONNEMENT de l'établissement).
  ///
  /// Règle d'accès effectif = accès du RÔLE/utilisateur ET abonnement de
  /// l'établissement (intersection stricte : l'abonnement plafonne le rôle).
  ///
  /// - [establishmentModules] == null (paramètre non fourni) : comportement
  ///   historique inchangé, seul le `modules` de l'utilisateur est pris en
  ///   compte (rétrocompatibilité pour les appels existants).
  /// - [establishmentModules] vide : fail-open, on considère TOUS les modules
  ///   comme souscrits (un document établissement mal renseigné ne doit pas
  ///   rendre l'app inutilisable).
  /// - Rôles `super_admin` / `global_admin` : jamais plafonnés par
  ///   l'abonnement (ils administrent la plateforme).
  factory UserModel.fromMap(
    Map<String, dynamic> map,
    String documentId, {
    Map<String, dynamic>? establishmentModules,
  }) {
    final role = _normalizeRole(map['role']);
    final modules = Map<String, dynamic>.from(map['modules'] ?? {});

    final bool applySubscription =
        establishmentModules != null &&
        establishmentModules.isNotEmpty &&
        role != 'super_admin' &&
        role != 'global_admin';

    bool effectiveAccess(String key, bool byRole) {
      final fromRole = _moduleValue(modules, key, byRole);
      if (!applySubscription) {
        return fromRole;
      }
      return fromRole && establishmentModules[key] == true;
    }

    return UserModel(
      uid: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString().trim(),
      establishmentName: (map['establishmentName'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      phone: (map['phone'] ?? '').toString().trim(),
      role: role,
      isActive: map['isActive'] != false,
      canAccessRestaurant: effectiveAccess(
        'restaurant',
        _canAccessRestaurantByRole(role),
      ),
      canAccessBar: effectiveAccess('bar', _canAccessBarByRole(role)),
      canAccessHotel: effectiveAccess('hotel', _canAccessHotelByRole(role)),
      canAccessStock: effectiveAccess('stock', _canAccessStockByRole(role)),
      canAccessFiscalization: effectiveAccess(
        'fiscalization',
        _canAccessFiscalizationByRole(role),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'modules': {
        'restaurant': canAccessRestaurant,
        'bar': canAccessBar,
        'hotel': canAccessHotel,
        'stock': canAccessStock,
        'fiscalization': canAccessFiscalization,
      },
    };
  }

  UserModel copyWith({
    String? uid,
    String? establishmentId,
    String? establishmentName,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    bool? canAccessRestaurant,
    bool? canAccessBar,
    bool? canAccessHotel,
    bool? canAccessStock,
    bool? canAccessFiscalization,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      canAccessRestaurant: canAccessRestaurant ?? this.canAccessRestaurant,
      canAccessBar: canAccessBar ?? this.canAccessBar,
      canAccessHotel: canAccessHotel ?? this.canAccessHotel,
      canAccessStock: canAccessStock ?? this.canAccessStock,
      canAccessFiscalization:
          canAccessFiscalization ?? this.canAccessFiscalization,
    );
  }
}
