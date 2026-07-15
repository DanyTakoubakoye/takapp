class StockRequestItemModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Produit
  final String itemId;
  final String itemName;
  final String unit;

  /// Quantités
  final double quantityRequested;
  final double quantityDelivered;

  /// pending | partial | delivered | rejected
  final String status;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  const StockRequestItemModel({
    required this.id,
    required this.establishmentId,

    required this.itemId,
    required this.itemName,
    required this.unit,

    required this.quantityRequested,
    required this.quantityDelivered,

    required this.status,

    required this.pendingSync,
    required this.syncError,
  });

  factory StockRequestItemModel.fromMap(String id, Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    return StockRequestItemModel(
      id: id,

      /// SaaS
      establishmentId: map['establishmentId']?.toString() ?? '',

      /// Produit
      itemId: map['itemId']?.toString() ?? '',

      itemName: map['itemName']?.toString() ?? '',

      unit: map['unit']?.toString() ?? '',

      /// Quantités
      quantityRequested: toDouble(map['quantityRequested']),

      quantityDelivered: toDouble(map['quantityDelivered']),

      /// Statut
      status: map['status']?.toString() ?? 'pending',

      /// Offline
      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Produit
      'itemId': itemId,
      'itemName': itemName,
      'unit': unit,

      /// Quantités
      'quantityRequested': quantityRequested,

      'quantityDelivered': quantityDelivered,

      /// Statut
      'status': status,

      /// Offline
      'pendingSync': pendingSync,
      'syncError': syncError,
    };
  }

  StockRequestItemModel copyWith({
    String? id,
    String? establishmentId,

    String? itemId,
    String? itemName,
    String? unit,

    double? quantityRequested,
    double? quantityDelivered,

    String? status,

    bool? pendingSync,
    bool? syncError,
  }) {
    return StockRequestItemModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      itemId: itemId ?? this.itemId,

      itemName: itemName ?? this.itemName,

      unit: unit ?? this.unit,

      quantityRequested: quantityRequested ?? this.quantityRequested,

      quantityDelivered: quantityDelivered ?? this.quantityDelivered,

      status: status ?? this.status,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,
    );
  }
}
