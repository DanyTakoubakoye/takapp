import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/services/bar_service.dart';
import 'package:takapp/vues/bar/bar_stock_item_form_page.dart';
import 'package:takapp/vues/bar/bar_menu_item_ingredients_form_page.dart';

import 'package:takapp/vues/shared/store_stock_page.dart';
import 'package:takapp/vues/shared/create_stock_request_page.dart';
import 'package:takapp/vues/shared/stock_out_page.dart';
import 'package:takapp/vues/shared/store_request_history_page.dart';
import 'package:takapp/vues/shared/stock_movement_history_page.dart';

class BarHomePage extends StatelessWidget {
  const BarHomePage({super.key});

  Color _statusColor(String status) {
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
    final clientType = (data['clientType'] ?? '').toString();
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final barService = BarService();
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAKHOTEL - Bar'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Utilisateur introuvable'))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: barService.streamBarOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }

                  final docs = (snapshot.data?.docs ?? []).where((d) {
                    final data = d.data();
                    return (data['status'] ?? '') != 'cancelled';
                  }).toList();

                  final pending = docs
                      .where(
                        (d) =>
                            (d.data()['barStatus'] ?? 'pending') == 'pending',
                      )
                      .toList();

                  final preparing = docs
                      .where((d) => d.data()['barStatus'] == 'preparing')
                      .toList();

                  final ready = docs
                      .where((d) => d.data()['barStatus'] == 'ready')
                      .toList();

                  if (isMobile) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _WelcomeCard(userName: user.name),
                          const SizedBox(height: 12),
                          const _BarStockActionsCard(),
                          const SizedBox(height: 12),
                          _BarSection(
                            title: 'En attente',
                            docs: pending,
                            isMobile: true,
                            colorResolver: _statusColor,
                            statusLabelResolver: _statusLabel,
                            barService: barService,
                            clientLabelResolver: _clientLabel,
                          ),
                          const SizedBox(height: 16),
                          _BarSection(
                            title: 'En préparation',
                            docs: preparing,
                            isMobile: true,
                            colorResolver: _statusColor,
                            statusLabelResolver: _statusLabel,
                            barService: barService,
                            clientLabelResolver: _clientLabel,
                          ),
                          const SizedBox(height: 16),
                          _BarSection(
                            title: 'Prêtes',
                            docs: ready,
                            isMobile: true,
                            colorResolver: _statusColor,
                            statusLabelResolver: _statusLabel,
                            barService: barService,
                            clientLabelResolver: _clientLabel,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _WelcomeCard(userName: user.name),
                      const SizedBox(height: 12),
                      const _BarStockActionsCard(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BarSection(
                                title: 'En attente',
                                docs: pending,
                                isMobile: false,
                                colorResolver: _statusColor,
                                statusLabelResolver: _statusLabel,
                                barService: barService,
                                clientLabelResolver: _clientLabel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BarSection(
                                title: 'En préparation',
                                docs: preparing,
                                isMobile: false,
                                colorResolver: _statusColor,
                                statusLabelResolver: _statusLabel,
                                barService: barService,
                                clientLabelResolver: _clientLabel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BarSection(
                                title: 'Prêtes',
                                docs: ready,
                                isMobile: false,
                                colorResolver: _statusColor,
                                statusLabelResolver: _statusLabel,
                                barService: barService,
                                clientLabelResolver: _clientLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;

  const _WelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.local_bar)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue : $userName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Suivi des commandes bar de tous les serveurs',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarSection extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool isMobile;
  final Color Function(String) colorResolver;
  final String Function(String) statusLabelResolver;
  final BarService barService;
  final String Function(Map<String, dynamic>) clientLabelResolver;

  const _BarSection({
    required this.title,
    required this.docs,
    required this.isMobile,
    required this.colorResolver,
    required this.statusLabelResolver,
    required this.barService,
    required this.clientLabelResolver,
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
                    '${docs.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isMobile)
              docs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: Text('Aucune commande')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _BarOrderCard(
                          doc: docs[index],
                          colorResolver: colorResolver,
                          statusLabelResolver: statusLabelResolver,
                          barService: barService,
                          clientLabelResolver: clientLabelResolver,
                        );
                      },
                    )
            else
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('Aucune commande'))
                    : ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _BarOrderCard(
                            doc: docs[index],
                            colorResolver: colorResolver,
                            statusLabelResolver: statusLabelResolver,
                            barService: barService,
                            clientLabelResolver: clientLabelResolver,
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

class _BarOrderCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Color Function(String) colorResolver;
  final String Function(String) statusLabelResolver;
  final BarService barService;
  final String Function(Map<String, dynamic>) clientLabelResolver;

  const _BarOrderCard({
    required this.doc,
    required this.colorResolver,
    required this.statusLabelResolver,
    required this.barService,
    required this.clientLabelResolver,
  });

  Future<void> _createBarReadyNotification() async {
    final data = doc.data();
    final firestore = FirebaseFirestore.instance;

    final orderId = doc.id;
    final orderNumber = (data['orderNumber'] ?? '').toString();

    final serveurId =
        (data['createdBy'] ?? data['serveurId'] ?? data['serverId'] ?? '')
            .toString()
            .trim();

    if (serveurId.isEmpty) {
      debugPrint(
        'Impossible de créer la notification bar : createdBy/serveurId vide pour orderId=$orderId',
      );
      return;
    }

    final clientType = (data['clientType'] ?? '').toString();
    final tableNumber = (data['tableNumber'] ?? '').toString().trim();
    final roomNumber = (data['roomNumber'] ?? '').toString().trim();

    String clientLabel = 'du client';

    if (clientType == 'hotel' && roomNumber.isNotEmpty) {
      clientLabel = 'de la chambre $roomNumber';
    } else if (tableNumber.isNotEmpty) {
      clientLabel = 'de la table $tableNumber';
    } else if (clientType == 'bar') {
      clientLabel = 'du client bar';
    }

    await firestore.collection('serverNotifications').add({
      'title': 'Commande bar prête',
      'body': 'La commande $clientLabel est prête au bar.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'serveurId': serveurId,
      'source': 'bar',
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final orderId = doc.id;
    final status = (data['barStatus'] ?? 'pending').toString();

    final orderNumber = (data['orderNumber'] ?? '').toString();
    final serveurName = (data['createdByName'] ?? '').toString();
    final clientLabel = clientLabelResolver(data);

    final totalValue = data['total'];
    final double total = totalValue is num
        ? totalValue.toDouble()
        : double.tryParse(totalValue?.toString() ?? '0') ?? 0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: barService.getBarItemsForOrder(orderId),
      builder: (context, itemSnapshot) {
        if (itemSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (itemSnapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text('Erreur articles bar : ${itemSnapshot.error}'),
          );
        }

        final items = itemSnapshot.data ?? [];

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: colorResolver(status),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Serveur : $serveurName'),
                const SizedBox(height: 4),
                Text('Client : $clientLabel'),
                const SizedBox(height: 4),
                Text('Total : ${total.toStringAsFixed(0)} FCFA'),
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
                    statusLabelResolver(status),
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
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${item['quantity'] ?? 1} x ${item['name'] ?? ''}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (status == 'pending')
                      ElevatedButton.icon(
                        onPressed: () async {
                          await barService.updateBarStatus(
                            orderId: orderId,
                            newBarStatus: 'preparing',
                          );
                        },
                        icon: const Icon(Icons.local_bar),
                        label: const Text('Passer en préparation'),
                      ),

                    if (status == 'preparing')
                      ElevatedButton.icon(
                        onPressed: () async {
                          await barService.updateBarStatus(
                            orderId: orderId,
                            newBarStatus: 'ready',
                          );

                          await _createBarReadyNotification();
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Marquer prête'),
                      ),

                    if (status == 'ready')
                      OutlinedButton.icon(
                        onPressed: () async {
                          await barService.updateBarStatus(
                            orderId: orderId,
                            newBarStatus: 'preparing',
                          );
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('Revenir'),
                      ),

                    if (status == 'ready')
                      ElevatedButton.icon(
                        onPressed: () async {
                          await barService.updateBarStatus(
                            orderId: orderId,
                            newBarStatus: 'served',
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
      },
    );
  }
}

class _BarStockActionsCard extends StatelessWidget {
  const _BarStockActionsCard();

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_bar, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gestion stock bar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSmallScreen)
              Column(
                children: [
                  _BarMainButton(
                    title: 'Gestion du Bar',
                    subtitle: 'Cocktails • Articles • Consommation • Réception',
                    color: Colors.indigo,
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BarManagementPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _BarMainButton(
                    title: 'Consultation & Suivi',
                    subtitle: 'Stocks • Approvisionnement • Historique',
                    color: Colors.green,
                    icon: Icons.visibility,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BarConsultationPage(),
                        ),
                      );
                    },
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _BarMainButton(
                      title: 'Gestion du Bar',
                      subtitle:
                          'Cocktails • Articles • Consommation • Réception',
                      color: Colors.indigo,
                      icon: Icons.settings,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BarManagementPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _BarMainButton(
                      title: 'Consultation & Suivi',
                      subtitle: 'Stocks • Approvisionnement • Historique',
                      color: Colors.green,
                      icon: Icons.visibility,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BarConsultationPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BarMainButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _BarMainButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 160,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarManagementPage extends StatelessWidget {
  const BarManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _BarMenuPage(
      title: 'Gestion du Bar',
      color: Colors.indigo,
      actions: [
        _BarAction(
          title: 'Composer cocktails',
          icon: Icons.local_bar,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BarMenuItemIngredientsFormPage(),
              ),
            );
          },
        ),
        _BarAction(
          title: 'Ajouter un article',
          icon: Icons.add_box,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BarStockItemFormPage()),
            );
          },
        ),
        _BarAction(
          title: 'Déclarer une consommation',
          icon: Icons.remove_shopping_cart,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StockOutPage(
                  store: 'bar',
                  title: 'Sortie de stock - Bar',
                  defaultReason: 'Consommation bar',
                ),
              ),
            );
          },
        ),
        _BarAction(
          title: 'Confirmer réception',
          icon: Icons.check_circle,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StoreRequestHistoryPage(
                  store: 'bar',
                  title: 'Réceptions à confirmer - Bar',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class BarConsultationPage extends StatelessWidget {
  const BarConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _BarMenuPage(
      title: 'Consultation & Suivi',
      color: Colors.green,
      actions: [
        _BarAction(
          title: 'Voir les stocks',
          icon: Icons.inventory,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const StoreStockPage(store: 'bar', title: 'Stock Bar'),
              ),
            );
          },
        ),
        _BarAction(
          title: 'Demander approvisionnement',
          icon: Icons.playlist_add,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateStockRequestPage(
                  store: 'bar',
                  requestedByRole: 'barman',
                  title: 'Demande approvisionnement - Bar',
                ),
              ),
            );
          },
        ),
        _BarAction(
          title: 'Historique stock',
          icon: Icons.history,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StockMovementHistoryPage(
                  store: 'bar',
                  title: 'Historique mouvements - Bar',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BarAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _BarAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _BarMenuPage extends StatelessWidget {
  final String title;
  final Color color;
  final List<_BarAction> actions;

  const _BarMenuPage({
    required this.title,
    required this.color,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: GridView.builder(
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmall ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isSmall ? 3.2 : 3.5,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];

            return Material(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: color,
                        child: Icon(action.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          action.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: color, size: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
