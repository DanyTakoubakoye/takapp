class OwnerDashboardSummaryModel {
  /// SaaS
  final String establishmentId;

  /// Totaux financiers
  final double totalOrders;
  final double totalPaid;
  final double totalHandovers;
  final double totalAccountingReceived;
  final double totalExpenses;
  final double theoreticalBalance;

  /// Statistiques
  final int ordersCount;
  final int paymentsCount;
  final int pendingHandoversCount;
  final int pendingAccountingTransfersCount;

  /// Modules activés
  final bool restaurantModuleEnabled;
  final bool barModuleEnabled;
  final bool hotelModuleEnabled;

  /// Synchronisation SaaS / Offline
  final int pendingSyncOrdersCount;
  final int syncErrorsCount;

  const OwnerDashboardSummaryModel({
    required this.establishmentId,

    required this.totalOrders,
    required this.totalPaid,
    required this.totalHandovers,
    required this.totalAccountingReceived,
    required this.totalExpenses,
    required this.theoreticalBalance,

    required this.ordersCount,
    required this.paymentsCount,
    required this.pendingHandoversCount,
    required this.pendingAccountingTransfersCount,

    required this.restaurantModuleEnabled,
    required this.barModuleEnabled,
    required this.hotelModuleEnabled,

    required this.pendingSyncOrdersCount,
    required this.syncErrorsCount,
  });

  factory OwnerDashboardSummaryModel.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

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

    return OwnerDashboardSummaryModel(
      /// SaaS
      establishmentId: (map['establishmentId'] ?? '').toString(),

      /// Finances
      totalOrders: toDouble(map['totalOrders']),

      totalPaid: toDouble(map['totalPaid']),

      totalHandovers: toDouble(map['totalHandovers']),

      totalAccountingReceived: toDouble(map['totalAccountingReceived']),

      totalExpenses: toDouble(map['totalExpenses']),

      theoreticalBalance: toDouble(map['theoreticalBalance']),

      /// Statistiques
      ordersCount: toInt(map['ordersCount']),

      paymentsCount: toInt(map['paymentsCount']),

      pendingHandoversCount: toInt(map['pendingHandoversCount']),

      pendingAccountingTransfersCount: toInt(
        map['pendingAccountingTransfersCount'],
      ),

      /// Modules
      restaurantModuleEnabled: map['restaurantModuleEnabled'] == true,

      barModuleEnabled: map['barModuleEnabled'] == true,

      hotelModuleEnabled: map['hotelModuleEnabled'] == true,

      /// Offline sync
      pendingSyncOrdersCount: toInt(map['pendingSyncOrdersCount']),

      syncErrorsCount: toInt(map['syncErrorsCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Finances
      'totalOrders': totalOrders,
      'totalPaid': totalPaid,
      'totalHandovers': totalHandovers,
      'totalAccountingReceived': totalAccountingReceived,
      'totalExpenses': totalExpenses,
      'theoreticalBalance': theoreticalBalance,

      /// Statistiques
      'ordersCount': ordersCount,
      'paymentsCount': paymentsCount,
      'pendingHandoversCount': pendingHandoversCount,
      'pendingAccountingTransfersCount': pendingAccountingTransfersCount,

      /// Modules
      'restaurantModuleEnabled': restaurantModuleEnabled,

      'barModuleEnabled': barModuleEnabled,

      'hotelModuleEnabled': hotelModuleEnabled,

      /// Offline sync
      'pendingSyncOrdersCount': pendingSyncOrdersCount,

      'syncErrorsCount': syncErrorsCount,
    };
  }

  OwnerDashboardSummaryModel copyWith({
    String? establishmentId,

    double? totalOrders,
    double? totalPaid,
    double? totalHandovers,
    double? totalAccountingReceived,
    double? totalExpenses,
    double? theoreticalBalance,

    int? ordersCount,
    int? paymentsCount,
    int? pendingHandoversCount,
    int? pendingAccountingTransfersCount,

    bool? restaurantModuleEnabled,
    bool? barModuleEnabled,
    bool? hotelModuleEnabled,

    int? pendingSyncOrdersCount,
    int? syncErrorsCount,
  }) {
    return OwnerDashboardSummaryModel(
      establishmentId: establishmentId ?? this.establishmentId,

      totalOrders: totalOrders ?? this.totalOrders,

      totalPaid: totalPaid ?? this.totalPaid,

      totalHandovers: totalHandovers ?? this.totalHandovers,

      totalAccountingReceived:
          totalAccountingReceived ?? this.totalAccountingReceived,

      totalExpenses: totalExpenses ?? this.totalExpenses,

      theoreticalBalance: theoreticalBalance ?? this.theoreticalBalance,

      ordersCount: ordersCount ?? this.ordersCount,

      paymentsCount: paymentsCount ?? this.paymentsCount,

      pendingHandoversCount:
          pendingHandoversCount ?? this.pendingHandoversCount,

      pendingAccountingTransfersCount:
          pendingAccountingTransfersCount ??
          this.pendingAccountingTransfersCount,

      restaurantModuleEnabled:
          restaurantModuleEnabled ?? this.restaurantModuleEnabled,

      barModuleEnabled: barModuleEnabled ?? this.barModuleEnabled,

      hotelModuleEnabled: hotelModuleEnabled ?? this.hotelModuleEnabled,

      pendingSyncOrdersCount:
          pendingSyncOrdersCount ?? this.pendingSyncOrdersCount,

      syncErrorsCount: syncErrorsCount ?? this.syncErrorsCount,
    );
  }
}
