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
        role == 'proprietaire' ||
        role == 'super_admin';
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final role = _normalizeRole(map['role']);
    final modules = Map<String, dynamic>.from(map['modules'] ?? {});

    return UserModel(
      uid: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString().trim(),
      establishmentName: (map['establishmentName'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      phone: (map['phone'] ?? '').toString().trim(),
      role: role,
      isActive: map['isActive'] != false,
      canAccessRestaurant: _moduleValue(
        modules,
        'restaurant',
        _canAccessRestaurantByRole(role),
      ),
      canAccessBar: _moduleValue(modules, 'bar', _canAccessBarByRole(role)),
      canAccessHotel: _moduleValue(
        modules,
        'hotel',
        _canAccessHotelByRole(role),
      ),
      canAccessStock: _moduleValue(
        modules,
        'stock',
        _canAccessStockByRole(role),
      ),
      canAccessFiscalization: _moduleValue(
        modules,
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
