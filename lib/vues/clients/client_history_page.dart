import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:takapp/modeles/client_model.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/reservation_model.dart';
import 'package:takapp/services/order_service.dart';
import 'package:takapp/services/reservation_service.dart';

class ClientHistoryPage extends StatefulWidget {
  final String establishmentId;
  final ClientModel client;

  const ClientHistoryPage({
    super.key,
    required this.establishmentId,
    required this.client,
  });

  @override
  State<ClientHistoryPage> createState() => _ClientHistoryPageState();
}

class _ClientHistoryPageState extends State<ClientHistoryPage> {
  final ReservationService _service = ReservationService();
  final OrderService _orderService = OrderService();
  final DateFormat _df = DateFormat('dd/MM/yyyy');
  final DateFormat _dfTime = DateFormat('dd/MM/yyyy HH:mm');

  late Future<List<ReservationModel>> _future;
  late Future<List<OrderModel>> _ordersFuture;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();
    _future = establishmentId.isEmpty
        ? Future.value(<ReservationModel>[])
        : _load();

    _ordersFuture = establishmentId.isEmpty
        ? Future.value(<OrderModel>[])
        : _loadOrders();
  }

  Future<List<ReservationModel>> _load() {
    return _service.reservationsForClient(
      establishmentId: establishmentId,
      clientId: widget.client.id,
    );
  }

  Future<List<OrderModel>> _loadOrders() {
    return _orderService.ordersForClient(
      establishmentId: establishmentId,
      clientId: widget.client.id,
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmée';
      case 'checked_in':
        return 'Arrivée';
      case 'checked_out':
        return 'Partie';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'checked_in':
        return Colors.green;
      case 'checked_out':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _orderTypeLabel(String clientType) {
    switch (clientType) {
      case 'bar':
        return 'Bar';
      case 'restaurant':
        return 'Restaurant';
      case 'hotel':
        return 'Hôtel';
      default:
        return clientType.isEmpty ? 'Commande' : clientType;
    }
  }

  String _orderStatusLabel(String status) {
    switch (status) {
      case 'sent':
        return 'Envoyée';
      case 'served':
        return 'Servie';
      case 'partially_cancelled':
        return 'Partiellement annulée';
      case 'cancelled':
        return 'Annulée';
      case 'stock_error':
        return 'Erreur stock';
      default:
        return status;
    }
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.blue;
      case 'served':
        return Colors.green;
      case 'partially_cancelled':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'stock_error':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  String _dates(ReservationModel resa) {
    final checkIn = resa.checkInDate;
    final checkOut = resa.checkOutDate;

    if (checkIn == null && checkOut == null) return 'Dates non renseignées';
    if (checkIn == null) return 'Départ le ${_df.format(checkOut!)}';
    if (checkOut == null) return 'Arrivée le ${_df.format(checkIn)}';

    return '${_df.format(checkIn)} → ${_df.format(checkOut)}';
  }

  @override
  Widget build(BuildContext context) {
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Historique · ${widget.client.name}')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [_buildStaysSection(), _buildOrdersSection()],
      ),
    );
  }

  /// =========================
  /// SÉJOURS
  /// =========================

  Widget _buildStaysSection() {
    return FutureBuilder<List<ReservationModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: SelectableText('Erreur : ${snapshot.error}')),
          );
        }

        final reservations = snapshot.data ?? [];

        // Les annulations ne comptent pas dans le total dépensé.
        final totalSpent = reservations
            .where((resa) => resa.status != 'cancelled')
            .fold<double>(0, (total, resa) => total + resa.roomTotal);

        return Column(
          children: [
            _ClientHistorySummary(
              stayCount: reservations.length,
              totalSpent: totalSpent,
            ),
            const _SectionTitle('Séjours'),
            if (reservations.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Aucun séjour enregistré pour ce client.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: reservations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final resa = reservations[index];
                  final color = _statusColor(resa.status);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        _dates(resa),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${resa.roomTypeName}'
                        '\n${resa.roomTotal.toStringAsFixed(0)} FCFA',
                      ),
                      isThreeLine: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _statusLabel(resa.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  /// =========================
  /// CONSOMMATIONS BAR / RESTAURANT
  /// =========================

  Widget _buildOrdersSection() {
    return FutureBuilder<List<OrderModel>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: SelectableText('Erreur : ${snapshot.error}')),
          );
        }

        final orders = snapshot.data ?? [];

        // Les annulations ne comptent pas dans le total consommé.
        final totalOrders = orders
            .where((order) => order.status != 'cancelled')
            .fold<double>(0, (total, order) => total + order.total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Consommations bar/restaurant'),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Aucune commande rattachée à ce client.'),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${orders.length} commande(s) · '
                  '${totalOrders.toStringAsFixed(0)} FCFA (hors annulations)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final color = _orderStatusColor(order.status);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        _dfTime.format(order.createdAt),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_orderTypeLabel(order.clientType)}'
                        '\n${order.total.toStringAsFixed(0)} FCFA',
                      ),
                      isThreeLine: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _orderStatusLabel(order.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ClientHistorySummary extends StatelessWidget {
  final int stayCount;
  final double totalSpent;

  const _ClientHistorySummary({
    required this.stayCount,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$stayCount',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stayCount > 1 ? 'séjours' : 'séjour',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${totalSpent.toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total dépensé (hors annulations)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
