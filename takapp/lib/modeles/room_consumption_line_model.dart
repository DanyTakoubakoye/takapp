class RoomConsumptionLineModel {
  /// SaaS
  final String establishmentId;

  /// Références métier
  final String orderId;
  final String paymentId;
  final String menuItemId;

  /// Produit
  final String itemName;

  final int quantity;
  final double unitPrice;
  final double total;

  /// bar | restaurant
  final String source;

  /// Serveur
  final String serveurId;
  final String serveur;

  /// Date consommation
  final DateTime createdAt;

  /// Fiscalisation
  final bool isFiscalized;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  const RoomConsumptionLineModel({
    required this.establishmentId,

    required this.orderId,
    required this.paymentId,
    required this.menuItemId,

    required this.itemName,

    required this.quantity,
    required this.unitPrice,
    required this.total,

    required this.source,

    required this.serveurId,
    required this.serveur,

    required this.createdAt,

    required this.isFiscalized,

    required this.pendingSync,
    required this.syncError,
  });

  factory RoomConsumptionLineModel.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic value) {
      if (value == null) return 0;

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(value.toString()) ?? 0;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime toDate(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }

      return DateTime.now();
    }

    return RoomConsumptionLineModel(
      /// SaaS
      establishmentId: (map['establishmentId'] ?? '').toString(),

      /// Références
      orderId: (map['orderId'] ?? '').toString(),

      paymentId: (map['paymentId'] ?? '').toString(),

      menuItemId: (map['menuItemId'] ?? '').toString(),

      /// Produit
      itemName: (map['itemName'] ?? '').toString(),

      quantity: toInt(map['quantity']),

      unitPrice: toDouble(map['unitPrice']),

      total: toDouble(map['total']),

      /// Source
      source: (map['source'] ?? '').toString(),

      /// Serveur
      serveurId: (map['serveurId'] ?? '').toString(),

      serveur: (map['serveur'] ?? '').toString(),

      /// Date
      createdAt: toDate(map['createdAt']),

      /// Fiscalisation
      isFiscalized: map['isFiscalized'] == true,

      /// Offline
      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Références
      'orderId': orderId,
      'paymentId': paymentId,
      'menuItemId': menuItemId,

      /// Produit
      'itemName': itemName,

      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,

      /// Source
      'source': source,

      /// Serveur
      'serveurId': serveurId,
      'serveur': serveur,

      /// Date
      'createdAt': createdAt.toIso8601String(),

      /// Fiscalisation
      'isFiscalized': isFiscalized,

      /// Offline
      'pendingSync': pendingSync,
      'syncError': syncError,
    };
  }

  RoomConsumptionLineModel copyWith({
    String? establishmentId,

    String? orderId,
    String? paymentId,
    String? menuItemId,

    String? itemName,

    int? quantity,
    double? unitPrice,
    double? total,

    String? source,

    String? serveurId,
    String? serveur,

    DateTime? createdAt,

    bool? isFiscalized,

    bool? pendingSync,
    bool? syncError,
  }) {
    return RoomConsumptionLineModel(
      establishmentId: establishmentId ?? this.establishmentId,

      orderId: orderId ?? this.orderId,

      paymentId: paymentId ?? this.paymentId,

      menuItemId: menuItemId ?? this.menuItemId,

      itemName: itemName ?? this.itemName,

      quantity: quantity ?? this.quantity,

      unitPrice: unitPrice ?? this.unitPrice,

      total: total ?? this.total,

      source: source ?? this.source,

      serveurId: serveurId ?? this.serveurId,

      serveur: serveur ?? this.serveur,

      createdAt: createdAt ?? this.createdAt,

      isFiscalized: isFiscalized ?? this.isFiscalized,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,
    );
  }
}
