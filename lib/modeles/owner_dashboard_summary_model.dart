class OwnerDashboardSummaryModel {
  final double totalOrders;
  final double totalPaid;
  final double totalHandovers;
  final double totalAccountingReceived;
  final double totalExpenses;
  final double theoreticalBalance;

  final int ordersCount;
  final int paymentsCount;
  final int pendingHandoversCount;
  final int pendingAccountingTransfersCount;

  const OwnerDashboardSummaryModel({
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
  });
}
