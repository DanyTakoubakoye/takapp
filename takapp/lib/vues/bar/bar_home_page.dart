import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/services/bar_service.dart';
import 'package:takapp/services/notification_service_mobile.dart';
import 'package:takapp/vues/bar/bar_stock_item_form_page.dart';
import 'package:takapp/vues/bar/bar_menu_item_ingredients_form_page.dart';

import 'package:takapp/vues/shared/store_stock_page.dart';
import 'package:takapp/vues/shared/create_stock_request_page.dart';
import 'package:takapp/vues/shared/stock_out_page.dart';
import 'package:takapp/vues/shared/store_request_history_page.dart';
import 'package:takapp/vues/shared/stock_movement_history_page.dart';
import 'package:takapp/core/l10n/language_selector.dart';
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

  final BarService _barService = BarService();

  // Créés une seule fois : recréés dans build(), ils relanceraient
  // l'abonnement / la lecture à chaque rebuild et feraient clignoter l'écran.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _barOrdersStream;
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _establishmentFuture;

  @override
  void initState() {
    super.initState();
    _barOrdersStream = _barService.streamBarOrders(
      establishmentId: widget.establishmentId,
    );
    _establishmentFuture = FirebaseFirestore.instance
        .collection('establishments')
        .doc(widget.establishmentId)
        .get();
    // Débloque le son dès le premier clic de l'utilisateur dans la page
    unlockWebSoundAfterUserInteraction();
  }

  void _handleNewBarOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    AppLocalizations l10n,
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
      final clientLabel = _clientLabel(data, l10n);
      final orderNumber = (data['orderNumber'] ?? '').toString();

      // Son
      playWebNotificationSound(
        'bar_new_order',
        establishmentId: widget.establishmentId,
      );
      if (!kIsWeb) {
        NotificationService().playNewOrderSound(department: 'bar');
      }

      // Notification navigateur
      showWebNotification(
        title: l10n.newBarOrderTitle,
        body: l10n.orderNumberWithClient(orderNumber, clientLabel),
        establishmentId: widget.establishmentId,
        tag: 'takapp_bar_${widget.establishmentId}_${d.id}',
      );

      // Popup in-app (une seule à la fois)
      _showNewOrderPopup(orderNumber, clientLabel, l10n);
    }
  }

  Future<void> _showNewOrderPopup(
    String orderNumber,
    String clientLabel,
    AppLocalizations l10n,
  ) async {
    if (_isPopupOpen) return;
    if (!mounted) return;

    _isPopupOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.local_bar, color: Colors.indigo, size: 40),
        title: Text(l10n.newBarOrderTitle),
        content: Text('${l10n.orderNumberLine(orderNumber)}\n$clientLabel'),
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

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.statusPending;
      case 'preparing':
        return l10n.statusPreparing;
      case 'ready':
        return l10n.statusReady;
      case 'served':
        return l10n.statusServed;
      default:
        return status;
    }
  }

  String _clientLabel(Map<String, dynamic> data, AppLocalizations l10n) {
    final clientType = (data['clientType'] ?? '').toString();
    final tableNumber = (data['tableNumber'] ?? '').toString().trim();
    final roomNumber = (data['roomNumber'] ?? '').toString().trim();

    if (clientType == 'hotel' && roomNumber.isNotEmpty) {
      return l10n.labelRoom(roomNumber);
    }

    if (tableNumber.isNotEmpty) {
      return l10n.labelTable(tableNumber);
    }

    if (clientType == 'bar') {
      return l10n.labelBarClient;
    }

    return clientType.isNotEmpty ? clientType : l10n.labelClient;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final establishmentId = widget.establishmentId;
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final barService = _barService;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _establishmentFuture,
          builder: (context, snapshot) {
            final name = (snapshot.data?.data()?['name'] ?? '')
                .toString()
                .toUpperCase();
            return Text(
              name.isEmpty ? l10n.barTitle : l10n.establishmentBarTitle(name),
            );
          },
        ),
        actions: [
          const LanguageSelector(),
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(l10n.errUserNotFound))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _barOrdersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l10n.commonError('${snapshot.error}')),
                    );
                  }

                  final docs = (snapshot.data?.docs ?? []).where((d) {
                    final data = d.data();
                    return (data['status'] ?? '') != 'cancelled';
                  }).toList();
                  // Alerte son + popup pour les nouvelles commandes bar
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _handleNewBarOrders(docs, l10n);
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
                            title: l10n.statusPending,
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
                            title: l10n.statusPreparing,
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
                            title: l10n.statusReadyPlural,
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
                                title: l10n.statusPending,
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
                                title: l10n.statusPreparing,
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
                                title: l10n.statusReadyPlural,
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
    final l10n = AppLocalizations.of(context);

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
                    l10n.welcomeName(userName),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.barOrdersFollowUp,
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
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(l10n.barStockTitle),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreStockPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: l10n.barStockTitle,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: Text(l10n.actionSupply),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateStockRequestPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      requestedByRole: 'barman',
                      title: l10n.supplyRequestBarTitle,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove_shopping_cart),
              label: Text(l10n.actionStockOut),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockOutPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: l10n.stockOutBarTitle,
                      defaultReason: l10n.reasonBarConsumption,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: Text(l10n.actionMovements),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockMovementHistoryPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: l10n.movementHistoryBarTitle,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.checklist),
              label: Text(l10n.actionReceptions),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreRequestHistoryPage(
                      establishmentId: establishmentId,
                      store: 'bar',
                      title: l10n.receptionsBarTitle,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.fastfood),
              label: Text(l10n.actionBarItems),
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
              label: Text(l10n.actionIngredients),
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
  final String Function(String, AppLocalizations) statusLabelResolver;
  final BarService barService;
  final String Function(Map<String, dynamic>, AppLocalizations)
  clientLabelResolver;

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
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(AppLocalizations.of(context).noOrders),
                      ),
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
                    ? Center(child: Text(AppLocalizations.of(context).noOrders))
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
  final String Function(String, AppLocalizations) statusLabelResolver;
  final BarService barService;
  final String Function(Map<String, dynamic>, AppLocalizations)
  clientLabelResolver;

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
    final l10n = AppLocalizations.of(context);
    final data = doc.data();
    final orderId = doc.id;
    final status = (data['barStatus'] ?? 'pending').toString();

    final orderNumber = (data['orderNumber'] ?? '').toString();
    final serveurName = (data['createdByName'] ?? '').toString();
    final clientLabel = clientLabelResolver(data, l10n);

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
            child: Text(l10n.errBarItemsLoad('${itemSnapshot.error}')),
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
                Text(l10n.waiterLine(serveurName)),
                const SizedBox(height: 4),
                Text(l10n.clientLine(clientLabel)),
                const SizedBox(height: 4),
                Text(l10n.totalLine(total.toStringAsFixed(0))),
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
                    statusLabelResolver(status, l10n),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Text(
                  l10n.barItems,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                        label: Text(l10n.actionSetPreparing),
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
                        label: Text(l10n.actionMarkReady),
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
                        label: Text(l10n.actionRevert),
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
                        label: Text(l10n.actionServed),
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
