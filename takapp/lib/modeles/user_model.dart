import 'package:takapp/core/constants/app_roles.dart';

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
    return AppRoles.normalizeRole((value ?? '').toString());
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

  static bool _canAccessModuleByRole(String role, String module) {
    return AppRoles.canAccessModule(role: role, module: module);
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
    // floor_manager : accès définis par le RÔLE (AppRoles.modules), toujours
    // plafonnés par l'abonnement. Les `modules` stockés sur ces profils sont
    // les valeurs d'attente (tout à false) posées à la création avant que
    // leurs fonctions n'existent : ils ne font pas foi.
    final modules = role == AppRoles.floorManager
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(map['modules'] ?? {});

    final bool applySubscription =
        establishmentModules != null &&
        establishmentModules.isNotEmpty &&
        role != AppRoles.superAdmin &&
        role != AppRoles.globalAdmin;

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
        _canAccessModuleByRole(role, 'restaurant'),
      ),
      canAccessBar: effectiveAccess('bar', _canAccessModuleByRole(role, 'bar')),
      canAccessHotel: effectiveAccess(
        'hotel',
        _canAccessModuleByRole(role, 'hotel'),
      ),
      canAccessStock: effectiveAccess(
        'stock',
        _canAccessModuleByRole(role, 'stock'),
      ),
      canAccessFiscalization: effectiveAccess(
        'fiscalization',
        _canAccessModuleByRole(role, 'fiscalization'),
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
