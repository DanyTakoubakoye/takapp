import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/kitchen_order_model.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/services/cuisine_service.dart';

class CuisineHomePage extends StatelessWidget {
  const CuisineHomePage({super.key});

  String _clientLabel(KitchenOrderModel order) {
    switch (order.clientType) {
      case 'restaurant':
        return 'Table ${order.tableNumber ?? "-"}';
      case 'hotel':
        return 'Chambre ${order.roomNumber ?? "-"}';
      case 'bar':
        return 'Client Bar';
      default:
        return order.clientType;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'sent':
        return Colors.grey.shade300;
      case 'preparing':
        return Colors.orange.shade200;
      case 'ready':
        return Colors.green.shade200;
      default:
        return Colors.white;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
      case 'sent':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cuisineService = context.read<CuisineService>();
    final user = auth.currentUser;
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAKHOTEL - Cuisine'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.restaurant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue : ${user?.name ?? ""}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suivi des commandes cuisine de tous les serveurs',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<KitchenOrderModel>>(
                stream: cuisineService.streamKitchenOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final allOrders = snapshot.data ?? [];

                  final kitchenOrders = allOrders
                      .where((order) => order.isForKitchen)
                      .toList();

                  if (kitchenOrders.isEmpty) {
                    return const Center(
                      child: Text('Aucune commande cuisine en attente.'),
                    );
                  }

                  final pendingOrders = kitchenOrders
                      .where(
                        (order) =>
                            order.kitchenStatus == 'pending' &&
                                order.kitchenStatus != 'served' ||
                            order.kitchenStatus == 'sent',
                      )
                      .toList();

                  final preparingOrders = kitchenOrders
                      .where(
                        (order) =>
                            order.kitchenStatus == 'preparing' &&
                            order.kitchenStatus != 'served',
                      )
                      .toList();

                  final readyOrders = kitchenOrders
                      .where(
                        (order) =>
                            order.kitchenStatus == 'ready' &&
                            order.kitchenStatus != 'served',
                      )
                      .toList();

                  if (isSmallScreen) {
                    return ListView(
                      children: [
                        _KitchenSection(
                          title: 'En attente',
                          orders: pendingOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                        ),
                        const SizedBox(height: 16),
                        _KitchenSection(
                          title: 'En préparation',
                          orders: preparingOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                        ),
                        const SizedBox(height: 16),
                        _KitchenSection(
                          title: 'Prêtes',
                          orders: readyOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _KitchenSection(
                          title: 'En attente',
                          orders: pendingOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KitchenSection(
                          title: 'En préparation',
                          orders: preparingOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KitchenSection(
                          title: 'Prêtes',
                          orders: readyOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenSection extends StatelessWidget {
  final String title;
  final List<KitchenOrderModel> orders;
  final CuisineService cuisineService;
  final Color Function(String status) statusColor;
  final String Function(String status) statusLabel;
  final String Function(KitchenOrderModel order) clientLabel;

  const _KitchenSection({
    required this.title,
    required this.orders,
    required this.cuisineService,
    required this.statusColor,
    required this.statusLabel,
    required this.clientLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    '${orders.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// 🔥 SCROLL VERTICAL PAR COLONNE
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('Aucune commande'))
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _KitchenOrderCard(
                          order: order,
                          cuisineService: cuisineService,
                          statusColor: statusColor,
                          statusLabel: statusLabel,
                          clientLabel: clientLabel,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final KitchenOrderModel order;
  final CuisineService cuisineService;
  final Color Function(String status) statusColor;
  final String Function(String status) statusLabel;
  final String Function(KitchenOrderModel order) clientLabel;

  const _KitchenOrderCard({
    required this.order,
    required this.cuisineService,
    required this.statusColor,
    required this.statusLabel,
    required this.clientLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: statusColor(order.kitchenStatus),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('Serveur : ${order.createdByName}'),
            const SizedBox(height: 4),
            Text('Client : ${clientLabel(order)}'),
            const SizedBox(height: 4),
            Text('Total : ${order.total.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel(order.kitchenStatus),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<OrderItemModel>>(
              future: cuisineService.getKitchenItemsForOrder(order.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Erreur articles: ${snapshot.error}');
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Text('Aucun article cuisine.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text(
                      'Articles cuisine',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.quantity} x '),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name),
                                  if (item.note.trim().isNotEmpty)
                                    Text(
                                      'Note : ${item.note}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (order.kitchenStatus == 'pending' ||
                    order.kitchenStatus == 'sent')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await cuisineService.updateKitchenStatus(
                        orderId: order.id,
                        newKitchenStatus: 'preparing',
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Passer en préparation'),
                  ),

                if (order.kitchenStatus == 'preparing')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await cuisineService.updateKitchenStatus(
                        orderId: order.id,
                        newKitchenStatus: 'ready',
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marquer prête'),
                  ),

                if (order.kitchenStatus == 'ready')
                  OutlinedButton.icon(
                    onPressed: () async {
                      await cuisineService.updateKitchenStatus(
                        orderId: order.id,
                        newKitchenStatus: 'preparing',
                      );
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Revenir en préparation'),
                  ),

                // ✅ NOUVEAU BOUTON SERVI
                if (order.kitchenStatus == 'ready')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await cuisineService.updateKitchenStatus(
                        orderId: order.id,
                        newKitchenStatus: 'served',
                      );
                    },
                    icon: const Icon(Icons.delivery_dining),
                    label: const Text('Servi'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
