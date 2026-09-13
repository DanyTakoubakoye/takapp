import 'package:takapp/modeles/order_model.dart';

/// Addition d'une table ou d'une chambre.
///
/// Une addition regroupe toutes les commandes successives lancées par les
/// mêmes clients tant qu'elles n'ont pas été encaissées : la cuisine et le bar
/// continuent de recevoir un ticket par envoi, mais le client ne reçoit qu'une
/// seule facture.
class OrderTicket {
  final String ticketId;

  /// Commandes de l'addition, de la plus ancienne à la plus récente.
  final List<OrderModel> orders;

  const OrderTicket({required this.ticketId, required this.orders});

  /// Addition ne contenant qu'une seule commande (facture historique,
  /// commande de bar, etc.).
  factory OrderTicket.single(OrderModel order) {
    return OrderTicket(
      ticketId: order.ticketId.trim().isEmpty
          ? groupKeyFor(order)
          : order.ticketId.trim(),
      orders: [order],
    );
  }

  /// Commande la plus ancienne : elle porte le numéro de facture et la
  /// certification de l'addition.
  OrderModel get primaryOrder => orders.first;

  bool get isMultiOrder => orders.length > 1;

  double get total {
    return orders.fold<double>(0, (sum, order) => sum + order.total);
  }

  DateTime get openedAt => orders.first.createdAt;

  DateTime get lastOrderAt => orders.last.createdAt;

  List<String> get orderIds => orders.map((order) => order.id).toList();

  List<String> get orderNumbers {
    return orders.map((order) => order.orderNumber).toList();
  }

  String get label {
    switch (primaryOrder.clientType) {
      case 'restaurant':
        return 'Table ${primaryOrder.tableNumber ?? "-"}';

      case 'hotel':
        return 'Chambre ${primaryOrder.roomNumber ?? "-"}';

      case 'bar':
        return 'Client Bar';

      default:
        return primaryOrder.clientType;
    }
  }

  String get reference {
    return primaryOrder.roomNumber ?? primaryOrder.tableNumber ?? '-';
  }

  /// Clé de regroupement d'une commande.
  ///
  /// Les commandes créées avant l'introduction des additions n'ont pas de
  /// `ticketId` : on les regroupe alors sur leur table / chambre pour que les
  /// anciennes commandes ouvertes s'affichent elles aussi en une seule facture.
  static String groupKeyFor(OrderModel order) {
    final ticketId = order.ticketId.trim();

    if (ticketId.isNotEmpty) return ticketId;

    final type = order.clientType.trim().toLowerCase();

    final reference = type == 'hotel'
        ? (order.roomNumber ?? '').trim()
        : type == 'restaurant'
        ? (order.tableNumber ?? '').trim()
        : '';

    if (reference.isEmpty) return 'order:${order.id}';

    return 'legacy:$type:$reference';
  }

  /// Regroupe des commandes en additions, la plus récemment servie en premier.
  static List<OrderTicket> group(List<OrderModel> orders) {
    final Map<String, List<OrderModel>> grouped = {};

    for (final order in orders) {
      grouped.putIfAbsent(groupKeyFor(order), () => []).add(order);
    }

    final tickets = grouped.entries.map((entry) {
      final sorted = [...entry.value]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return OrderTicket(ticketId: entry.key, orders: sorted);
    }).toList();

    tickets.sort((a, b) => b.lastOrderAt.compareTo(a.lastOrderAt));

    return tickets;
  }
}
