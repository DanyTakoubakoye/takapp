import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/services/bar_service.dart';
import 'package:takapp/vues/serveur/cancel_order_items_page.dart';

class SuiviBarPage extends StatelessWidget {
  final String establishmentId;

  const SuiviBarPage({super.key, required this.establishmentId});

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
        return 'Récupérée';
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
    final kitchenStatus = (data['kitchenStatus'] ?? '').toString().trim();
    final barStatus = (data['barStatus'] ?? '').toString().trim();

    if (paymentStatus == 'paid') return false;
    if (status == 'cancelled') return false;
    if (kitchenStatus == 'ready' || kitchenStatus == 'served') return false;
    if (barStatus == 'ready' || barStatus == 'served') return false;

    return true;
  }

  Widget _buildOrderCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    List<Map<String, dynamic>> barItems,
    String safeEstablishmentId,
  ) {
    final barService = BarService();
    final data = doc.data() as Map<String, dynamic>;

    final totalValue = data['total'];
    final total = totalValue is num
        ? totalValue.toDouble()
        : double.tryParse(totalValue?.toString() ?? '0') ?? 0;

    final orderNumber = (data['orderNumber'] ?? '').toString();
    final barStatus = (data['barStatus'] ?? 'pending').toString();
    final createdByName = (data['createdByName'] ?? '').toString();
    final canCancel = _canCancelOrder(data);

    return Card(
      color: _color(barStatus),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('Serveur : $createdByName'),
            const SizedBox(height: 4),
            Text('Client : ${_clientLabel(data)}'),
            const SizedBox(height: 4),
            Text(
              'Total commande : ${total.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(barStatus),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Text(
              'Articles bar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...barItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item['quantity'] ?? 1} x '),
                    Expanded(child: Text((item['name'] ?? '').toString())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (barStatus == 'pending')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await barService.updateBarStatus(
                        establishmentId: safeEstablishmentId,
                        orderId: doc.id,
                        newBarStatus: 'preparing',
                      );
                    },
                    icon: const Icon(Icons.local_bar),
                    label: const Text('Passer en préparation'),
                  ),
                if (barStatus == 'preparing')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await barService.updateBarStatus(
                        establishmentId: safeEstablishmentId,
                        orderId: doc.id,
                        newBarStatus: 'ready',
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marquer prête'),
                  ),
                if (barStatus == 'ready')
                  OutlinedButton.icon(
                    onPressed: () async {
                      await barService.updateBarStatus(
                        establishmentId: safeEstablishmentId,
                        orderId: doc.id,
                        newBarStatus: 'preparing',
                      );
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Revenir en préparation'),
                  ),
                if (barStatus == 'ready')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await barService.updateBarStatus(
                        establishmentId: safeEstablishmentId,
                        orderId: doc.id,
                        newBarStatus: 'served',
                      );
                    },
                    icon: const Icon(Icons.done_all),
                    label: const Text('Récupéré'),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CancelOrderItemsPage(
                            establishmentId: safeEstablishmentId,
                            orderId: doc.id,
                            orderNumber: orderNumber,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnCard(
    BuildContext context,
    String title,
    List<QueryDocumentSnapshot> orders,
    String safeEstablishmentId,
  ) {
    final barService = BarService();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('Aucune commande'))
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = orders[index];

                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: barService.getBarItemsForOrder(
                            establishmentId: safeEstablishmentId,
                            orderId: doc.id,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
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

                            if (snapshot.hasError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Erreur articles bar : ${snapshot.error}',
                                  ),
                                ),
                              );
                            }

                            final barItems = snapshot.data ?? [];

                            if (barItems.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return _buildOrderCard(
                              context,
                              doc,
                              barItems,
                              safeEstablishmentId,
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

  @override
  Widget build(BuildContext context) {
    final safeEstablishmentId = establishmentId.trim();
    final user = context.watch<AuthController>().currentUser;
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final serveurId = user.uid;

    if (safeEstablishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi Bar')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('establishments')
            .doc(safeEstablishmentId)
            .collection('orders')
            .where('createdBy', isEqualTo: serveurId)
            .where('isForBar', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '').toString() != 'cancelled';
          }).toList();

          final pending = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['barStatus'] ?? 'pending') == 'pending';
          }).toList();

          final preparing = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['barStatus'] ?? '') == 'preparing';
          }).toList();

          final ready = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['barStatus'] ?? '') == 'ready';
          }).toList();

          if (isSmallScreen) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox(
                    height: 500,
                    child: _buildColumnCard(
                      context,
                      'En attente',
                      pending,
                      safeEstablishmentId,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 500,
                    child: _buildColumnCard(
                      context,
                      'En préparation',
                      preparing,
                      safeEstablishmentId,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 500,
                    child: _buildColumnCard(
                      context,
                      'Prêtes',
                      ready,
                      safeEstablishmentId,
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
                child: _buildColumnCard(
                  context,
                  'En attente',
                  pending,
                  safeEstablishmentId,
                ),
              ),
              Expanded(
                child: _buildColumnCard(
                  context,
                  'En préparation',
                  preparing,
                  safeEstablishmentId,
                ),
              ),
              Expanded(
                child: _buildColumnCard(
                  context,
                  'Prêtes',
                  ready,
                  safeEstablishmentId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
