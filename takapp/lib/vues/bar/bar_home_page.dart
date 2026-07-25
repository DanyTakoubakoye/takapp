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
import 'package:takapp/services/notification_web_helper_stub.dart'
    if (dart.library.html) 'package:takapp/services/notification_web_helper.dart';

class BarHomePage extends StatefulWidget {
  final String establishmentId;

  const BarHomePage({super.key, required this.establishmentId});

  @override
  State<BarHomePage> createState() => _BarHomePageState();
}

class _BarHomePageState extends State<BarHomePage> {
  final Set<String> _knownOrderIds = {};
  bool _isFirstSnapshot = true;
  bool _isPopupOpen = false;

  @override
  void initState() {
    super.initState();
    // Débloque le son dès le premier clic de l'utilisateur dans la page
    unlockWebSoundAfterUserInteraction();
  }

  void _handleNewBarOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    // Au tout premier chargement, on mémorise sans alerter
    if (_isFirstSnapshot) {
      for (final d in docs) {
        _knownOrderIds.add(d.id);
      }
      _isFirstSnapshot = false;
      return;
    }

    for (final d in docs) {
      if (_knownOrderIds.contains(d.id)) continue;
      _knownOrderIds.add(d.id);

      final data = d.data();
      final clientLabel = _clientLabel(data);
      final orderNumber = (data['orderNumber'] ?? '').toString();

      // Son
      playWebNotificationSound(
        'bar_new_order',
        establishmentId: widget.establishmentId,
      );

      // Notification navigateur
      showWebNotification(
        title: 'Nouvelle commande bar',
        body: 'Commande $orderNumber - $clientLabel',
        establishmentId: widget.establishmentId,
        tag: 'takapp_bar_${widget.establishmentId}_${d.id}',
      );

      // Popup in-app (une seule à la fois)
      _showNewOrderPopup(orderNumber, clientLabel);
    }
  }

  Future<void> _showNewOrderPopup(
    String orderNumber,
    String clientLabel,
  ) async {
    if (_isPopupOpen) return;
    if (!mounted) return;

    _isPopupOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.local_bar, color: Colors.indigo, size: 40),
        title: const Text('Nouvelle commande bar'),
        content: Text('Commande $orderNumber\n$clientLabel'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _isPopupOpen = false;
  }

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
    final establishmentId = widget.establishmentId;
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final barService = BarService();
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('establishments')
              .doc(establishmentId)
              .get(),
          builder: (context, snapshot) {
            final name = (snapshot.data?.data()?['name'] ?? '')
                .toString()
                .toUpperCase();
            return Text(name.isEmpty ? 'Bar' : '$name - Bar');
          },
        ),
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
                stream: barService.streamBarOrders(
                  establishmentId: establishmentId,
                ),
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
                  // Alerte son + popup pour les nouvelles commandes bar
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _handleNewBarOrders(docs);
                  });

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
                          _BarStockActionsCard(
                            establishmentId: establishmentId,
                          ),
                          const SizedBox(height: 12),
                          _BarSection(
                            establishmentId: establishmentId,
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
                            establishmentId: establishmentId,
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
                            establishmentId: establishmentId,
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
                      _BarStockActionsCard(establishmentId: establishmentId),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BarSection(
                                establishmentId: establishmentId,
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
                                establishmentId: establishmentId,
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
                                establishmentId: establishmentId,
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

class _BarStockActionsCard extends StatelessWidget {
  final String establishmentId;

  const _BarStockActionsCard({required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Stock Bar'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreStockPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: 'Stock Bar',
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: const Text('Approvisionnement'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateStockRequestPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      requestedByRole: 'barman',
                      title: 'Demande approvisionnement Bar',
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove_shopping_cart),
              label: const Text('Sortie Stock'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockOutPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: 'Sortie Stock Bar',
                      defaultReason: 'Consommation Bar',
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Mouvements'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockMovementHistoryPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: 'Historique mouvements Bar',
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.checklist),
              label: const Text('Réceptions'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreRequestHistoryPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: 'Réceptions Bar',
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.fastfood),
              label: const Text('Articles Bar'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BarStockItemFormPage(establishmentId: establishmentId),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_drink),
              label: const Text('Ingrédients'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BarMenuItemIngredientsFormPage(
                      establishmentId: establishmentId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BarSection extends StatelessWidget {
  final String establishmentId;
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool isMobile;
  final Color Function(String) colorResolver;
  final String Function(String) statusLabelResolver;
  final BarService barService;
  final String Function(Map<String, dynamic>) clientLabelResolver;

  const _BarSection({
    required this.establishmentId,
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
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _BarOrderCard(
                          establishmentId: establishmentId,
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _BarOrderCard(
                            establishmentId: establishmentId,
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
  final String establishmentId;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Color Function(String) colorResolver;
  final String Function(String) statusLabelResolver;
  final BarService barService;
  final String Function(Map<String, dynamic>) clientLabelResolver;

  const _BarOrderCard({
    required this.establishmentId,
    required this.doc,
    required this.colorResolver,
    required this.statusLabelResolver,
    required this.barService,
    required this.clientLabelResolver,
  });

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
      future: barService.getBarItemsForOrder(
        establishmentId: establishmentId,
        orderId: orderId,
      ),
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
                    color: Colors.white.withValues(alpha: 0.7),
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
                            establishmentId: establishmentId,
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
                            establishmentId: establishmentId,
                            orderId: orderId,
                            newBarStatus: 'ready',
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Marquer prête'),
                      ),
                    if (status == 'ready')
                      OutlinedButton.icon(
                        onPressed: () async {
                          await barService.updateBarStatus(
                            establishmentId: establishmentId,
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
                            establishmentId: establishmentId,
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
