import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/services/cuisine_service.dart';
import 'package:takapp/vues/serveur/cancel_order_items_page.dart';

class SuiviCuisinePage extends StatelessWidget {
  const SuiviCuisinePage({super.key});

  Color _color(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey.shade300;
      case 'preparing':
        return Colors.orange.shade200;
      case 'ready':
        return Colors.green.shade200;
      case 'served':
        return Colors.blue.shade100;
      default:
        return Colors.white;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'served':
        return 'Servie';
      default:
        return status;
    }
  }

  String _clientLabel(Map<String, dynamic> data) {
    final clientType = (data['clientType'] ?? '').toString().trim();
    final tableNumber = (data['tableNumber'] ?? '').toString().trim();
    final roomNumber = (data['roomNumber'] ?? '').toString().trim();

    if (clientType == 'hotel' && roomNumber.isNotEmpty) {
      return 'Chambre $roomNumber';
    }

    if (tableNumber.isNotEmpty) {
      return 'Table $tableNumber';
    }

    if (clientType == 'bar') {
      return 'Client Bar';
    }

    return clientType.isNotEmpty ? clientType : 'Client';
  }

  bool _canCancelOrder(Map<String, dynamic> data) {
    final paymentStatus = (data['paymentStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final status = (data['status'] ?? '').toString().trim().toLowerCase();

    final isForKitchen = data['isForKitchen'] == true;
    final isForBar = data['isForBar'] == true;

    final kitchenStatus = (data['kitchenStatus'] ?? '').toString().trim();
    final barStatus = (data['barStatus'] ?? '').toString().trim();

    if (paymentStatus == 'paid') return false;
    if (status == 'cancelled') return false;

    if (isForKitchen &&
        (kitchenStatus == 'ready' || kitchenStatus == 'served')) {
      return false;
    }

    if (isForBar && (barStatus == 'ready' || barStatus == 'served')) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final cuisineService = CuisineService();
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi Cuisine')),
      body: user == null
          ? const Center(child: Text('Utilisateur introuvable'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('createdBy', isEqualTo: user.uid)
                  .where('isForKitchen', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }

                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data();
                  return (data['status'] ?? '').toString() != 'cancelled';
                }).toList();

                final pending = docs
                    .where(
                      (doc) =>
                          ((doc.data())['kitchenStatus'] ?? 'pending') ==
                          'pending',
                    )
                    .toList();

                final preparing = docs
                    .where(
                      (doc) =>
                          ((doc.data())['kitchenStatus'] ?? '') == 'preparing',
                    )
                    .toList();

                final ready = docs
                    .where(
                      (doc) => ((doc.data())['kitchenStatus'] ?? '') == 'ready',
                    )
                    .toList();

                if (isMobile) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 500,
                          child: _CuisineColumn(
                            title: 'En attente',
                            orders: pending,
                            colorBuilder: _color,
                            statusLabelBuilder: _statusLabel,
                            clientLabelBuilder: _clientLabel,
                            canCancelOrder: _canCancelOrder,
                            onCancel: (orderId, orderNumber) async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CancelOrderItemsPage(
                                    orderId: orderId,
                                    orderNumber: orderNumber,
                                  ),
                                ),
                              );
                            },
                            cuisineService: cuisineService,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 500,
                          child: _CuisineColumn(
                            title: 'En préparation',
                            orders: preparing,
                            colorBuilder: _color,
                            statusLabelBuilder: _statusLabel,
                            clientLabelBuilder: _clientLabel,
                            canCancelOrder: _canCancelOrder,
                            onCancel: (orderId, orderNumber) async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CancelOrderItemsPage(
                                    orderId: orderId,
                                    orderNumber: orderNumber,
                                  ),
                                ),
                              );
                            },
                            cuisineService: cuisineService,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 500,
                          child: _CuisineColumn(
                            title: 'Prêtes',
                            orders: ready,
                            colorBuilder: _color,
                            statusLabelBuilder: _statusLabel,
                            clientLabelBuilder: _clientLabel,
                            canCancelOrder: _canCancelOrder,
                            onCancel: (orderId, orderNumber) async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CancelOrderItemsPage(
                                    orderId: orderId,
                                    orderNumber: orderNumber,
                                  ),
                                ),
                              );
                            },
                            cuisineService: cuisineService,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CuisineColumn(
                        title: 'En attente',
                        orders: pending,
                        colorBuilder: _color,
                        statusLabelBuilder: _statusLabel,
                        clientLabelBuilder: _clientLabel,
                        canCancelOrder: _canCancelOrder,
                        onCancel: (orderId, orderNumber) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CancelOrderItemsPage(
                                orderId: orderId,
                                orderNumber: orderNumber,
                              ),
                            ),
                          );
                        },
                        cuisineService: cuisineService,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CuisineColumn(
                        title: 'En préparation',
                        orders: preparing,
                        colorBuilder: _color,
                        statusLabelBuilder: _statusLabel,
                        clientLabelBuilder: _clientLabel,
                        canCancelOrder: _canCancelOrder,
                        onCancel: (orderId, orderNumber) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CancelOrderItemsPage(
                                orderId: orderId,
                                orderNumber: orderNumber,
                              ),
                            ),
                          );
                        },
                        cuisineService: cuisineService,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CuisineColumn(
                        title: 'Prêtes',
                        orders: ready,
                        colorBuilder: _color,
                        statusLabelBuilder: _statusLabel,
                        clientLabelBuilder: _clientLabel,
                        canCancelOrder: _canCancelOrder,
                        onCancel: (orderId, orderNumber) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CancelOrderItemsPage(
                                orderId: orderId,
                                orderNumber: orderNumber,
                              ),
                            ),
                          );
                        },
                        cuisineService: cuisineService,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CuisineColumn extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;
  final Color Function(String status) colorBuilder;
  final String Function(String status) statusLabelBuilder;
  final String Function(Map<String, dynamic> data) clientLabelBuilder;
  final bool Function(Map<String, dynamic> data) canCancelOrder;
  final Future<void> Function(String orderId, String orderNumber) onCancel;
  final CuisineService cuisineService;

  const _CuisineColumn({
    required this.title,
    required this.orders,
    required this.colorBuilder,
    required this.statusLabelBuilder,
    required this.clientLabelBuilder,
    required this.canCancelOrder,
    required this.onCancel,
    required this.cuisineService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
            const SizedBox(height: 10),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('Aucune commande'))
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = orders[index];
                        final data = doc.data();
                        final canCancel = canCancelOrder(data);
                        final orderNumber = (data['orderNumber'] ?? '')
                            .toString();
                        final kitchenStatus =
                            (data['kitchenStatus'] ?? 'pending').toString();

                        final totalValue = data['total'];
                        final double total = totalValue is num
                            ? totalValue.toDouble()
                            : double.tryParse(totalValue?.toString() ?? '0') ??
                                  0;

                        return FutureBuilder<List<OrderItemModel>>(
                          future: cuisineService.getKitchenItemsForOrder(
                            doc.id,
                          ),
                          builder: (context, itemSnapshot) {
                            if (itemSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }

                            if (itemSnapshot.hasError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Erreur articles cuisine : ${itemSnapshot.error}',
                                  ),
                                ),
                              );
                            }

                            final items = itemSnapshot.data ?? [];

                            // On masque la commande si elle ne contient aucun item cuisine
                            if (items.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              color: colorBuilder(kitchenStatus),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orderNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Client : ${clientLabelBuilder(data)}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total : ${total.toStringAsFixed(0)} FCFA',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusLabelBuilder(kitchenStatus),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Articles cuisine',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...items.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('${item.quantity} x '),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.name),
                                                  if (item.note
                                                      .trim()
                                                      .isNotEmpty)
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
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (kitchenStatus == 'pending')
                                          ElevatedButton(
                                            onPressed: () async {
                                              await cuisineService
                                                  .updateKitchenStatus(
                                                    orderId: doc.id,
                                                    newKitchenStatus:
                                                        'preparing',
                                                  );
                                            },
                                            child: const Text(
                                              'Passer en préparation',
                                            ),
                                          ),
                                        if (kitchenStatus == 'preparing')
                                          ElevatedButton(
                                            onPressed: () async {
                                              await cuisineService
                                                  .updateKitchenStatus(
                                                    orderId: doc.id,
                                                    newKitchenStatus: 'ready',
                                                  );
                                            },
                                            child: const Text('Marquer prête'),
                                          ),
                                        if (kitchenStatus == 'ready')
                                          OutlinedButton(
                                            onPressed: () async {
                                              await cuisineService
                                                  .updateKitchenStatus(
                                                    orderId: doc.id,
                                                    newKitchenStatus:
                                                        'preparing',
                                                  );
                                            },
                                            child: const Text('Revenir'),
                                          ),
                                        if (kitchenStatus == 'ready')
                                          ElevatedButton(
                                            onPressed: () async {
                                              await cuisineService
                                                  .updateKitchenStatus(
                                                    orderId: doc.id,
                                                    newKitchenStatus: 'served',
                                                  );
                                            },
                                            child: const Text('Récupéré'),
                                          ),
                                        if (canCancel)
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                onCancel(doc.id, orderNumber),
                                            icon: const Icon(
                                              Icons.cancel_outlined,
                                            ),
                                            label: const Text('Annuler'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
