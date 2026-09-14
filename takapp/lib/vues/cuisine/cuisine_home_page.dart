import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/kitchen_order_model.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/services/cuisine_service.dart';
import 'package:takapp/services/notification_service_mobile.dart';
import 'package:takapp/vues/shared/store_stock_page.dart';
import 'package:takapp/vues/shared/create_stock_request_page.dart';
import 'package:takapp/vues/shared/stock_out_page.dart';
import 'package:takapp/vues/shared/store_request_history_page.dart';
import 'package:takapp/vues/shared/stock_movement_history_page.dart';
import 'package:takapp/vues/cuisine/stock_item_form_page.dart';
import 'package:takapp/vues/cuisine/menu_item_ingredients_form_page.dart';
import 'package:takapp/core/l10n/language_selector.dart';
import 'package:takapp/services/notification_web_helper_stub.dart'
    if (dart.library.html) 'package:takapp/services/notification_web_helper.dart';

class CuisineHomePage extends StatefulWidget {
  final String establishmentId;
  const CuisineHomePage({super.key, required this.establishmentId});

  @override
  State<CuisineHomePage> createState() => _CuisineHomePageState();
}

class _CuisineHomePageState extends State<CuisineHomePage> {
  final Set<String> _knownOrderIds = {};
  bool _isFirstSnapshot = true;
  bool _isPopupOpen = false;

  // L'établissement n'est connu qu'au build (AuthController) : on mémorise le
  // stream et on ne le recrée que s'il change vraiment. Sinon chaque rebuild
  // relancerait l'abonnement et remettrait l'écran en chargement.
  String? _ordersStreamEstablishmentId;
  Stream<List<KitchenOrderModel>>? _ordersStream;

  Stream<List<KitchenOrderModel>> _ordersStreamFor(
    CuisineService cuisineService,
    String establishmentId,
  ) {
    if (_ordersStreamEstablishmentId != establishmentId ||
        _ordersStream == null) {
      _ordersStreamEstablishmentId = establishmentId;
      _ordersStream = cuisineService.streamKitchenOrders(
        establishmentId: establishmentId,
      );
    }

    return _ordersStream!;
  }

  @override
  void initState() {
    super.initState();
    unlockWebSoundAfterUserInteraction();
  }

  void _handleNewKitchenOrders(
    List<KitchenOrderModel> orders,
    AppLocalizations l10n,
  ) {
    if (_isFirstSnapshot) {
      for (final o in orders) {
        _knownOrderIds.add(o.id);
      }
      _isFirstSnapshot = false;
      return;
    }

    for (final o in orders) {
      if (_knownOrderIds.contains(o.id)) continue;
      _knownOrderIds.add(o.id);

      try {
        final clientLabel = _clientLabel(o, l10n);
        final orderNumber = o.orderNumber;

        playWebNotificationSound(
          'kitchen_new_order',
          establishmentId: widget.establishmentId,
        );

        if (!kIsWeb) {
          NotificationService().playNewOrderSound(department: 'kitchen');
        }

        showWebNotification(
          title: l10n.newKitchenOrderTitle,
          body: l10n.orderNumberWithClient(orderNumber, clientLabel),
          establishmentId: widget.establishmentId,
          tag: 'takapp_kitchen_${widget.establishmentId}_${o.id}',
        );

        _showNewOrderPopup(orderNumber, clientLabel, l10n);
      } catch (e) {}
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
        icon: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 40),
        title: Text(l10n.newKitchenOrderTitle),
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

  String _clientLabel(KitchenOrderModel order, AppLocalizations l10n) {
    switch (order.clientType) {
      case 'restaurant':
        return l10n.labelTable(order.tableNumber ?? '-');
      case 'hotel':
        return l10n.labelRoom(order.roomNumber ?? '-');
      case 'bar':
        return l10n.labelBarClient;
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

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
      case 'sent':
        return l10n.statusPending;
      case 'preparing':
        return l10n.statusPreparing;
      case 'ready':
        return l10n.statusReady;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final cuisineService = context.read<CuisineService>();
    final user = auth.currentUser;
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.errEstablishmentNotFound)));
    }

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
            return Text(
              name.isEmpty
                  ? l10n.kitchenTitle
                  : l10n.establishmentKitchenTitle(name),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<KitchenOrderModel>>(
          stream: _ordersStreamFor(cuisineService, establishmentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(l10n.commonError('${snapshot.error}')));
            }

            final allOrders = snapshot.data ?? [];

            final kitchenOrders = allOrders
                .where((order) => order.isForKitchen)
                .toList();
            // Alerte son + popup pour les nouvelles commandes cuisine
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleNewKitchenOrders(kitchenOrders, l10n);
            });

            final pendingOrders = kitchenOrders
                .where(
                  (order) =>
                      order.kitchenStatus == 'pending' ||
                      order.kitchenStatus == 'sent',
                )
                .toList();

            final preparingOrders = kitchenOrders
                .where((order) => order.kitchenStatus == 'preparing')
                .toList();

            final readyOrders = kitchenOrders
                .where((order) => order.kitchenStatus == 'ready')
                .toList();

            if (isSmallScreen) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _WelcomeCard(userName: user.name),
                    const SizedBox(height: 12),
                    _KitchenStockActionsCard(establishmentId: establishmentId),
                    const SizedBox(height: 12),
                    _KitchenSection(
                      establishmentId: establishmentId,
                      title: l10n.statusPending,
                      orders: pendingOrders,
                      cuisineService: cuisineService,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                      clientLabel: _clientLabel,
                      isMobile: true,
                    ),
                    const SizedBox(height: 16),
                    _KitchenSection(
                      establishmentId: establishmentId,
                      title: l10n.statusPreparing,
                      orders: preparingOrders,
                      cuisineService: cuisineService,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                      clientLabel: _clientLabel,
                      isMobile: true,
                    ),
                    const SizedBox(height: 16),
                    _KitchenSection(
                      establishmentId: establishmentId,
                      title: l10n.statusReadyPlural,
                      orders: readyOrders,
                      cuisineService: cuisineService,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                      clientLabel: _clientLabel,
                      isMobile: true,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _WelcomeCard(userName: user.name),
                const SizedBox(height: 12),
                _KitchenStockActionsCard(establishmentId: establishmentId),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _KitchenSection(
                          establishmentId: establishmentId,
                          title: l10n.statusPending,
                          orders: pendingOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                          isMobile: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KitchenSection(
                          establishmentId: establishmentId,
                          title: l10n.statusPreparing,
                          orders: preparingOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                          isMobile: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KitchenSection(
                          establishmentId: establishmentId,
                          title: l10n.statusReadyPlural,
                          orders: readyOrders,
                          cuisineService: cuisineService,
                          statusColor: _statusColor,
                          statusLabel: _statusLabel,
                          clientLabel: _clientLabel,
                          isMobile: false,
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
            const CircleAvatar(radius: 28, child: Icon(Icons.restaurant)),
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
                    l10n.kitchenOrdersFollowUp,
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

class _KitchenStockActionsCard extends StatelessWidget {
  final String establishmentId;

  const _KitchenStockActionsCard({required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    color: Colors.deepOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.kitchenStockManagementTitle,
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
                  _KitchenMainActionButton(
                    title: l10n.stockManagementCardTitle,
                    subtitle: l10n.stockManagementCardSubtitleMobile,
                    color: Colors.blue,
                    icon: Icons.settings_applications_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KitchenStockManagementPage(
                            establishmentId: establishmentId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _KitchenMainActionButton(
                    title: l10n.stockConsultationCardTitle,
                    subtitle: l10n.stockConsultationCardSubtitle,
                    color: Colors.green,
                    icon: Icons.visibility_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KitchenStockConsultationPage(
                            establishmentId: establishmentId,
                          ),
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
                    child: _KitchenMainActionButton(
                      title: l10n.stockManagementCardTitle,
                      subtitle: l10n.stockManagementCardSubtitle,
                      color: Colors.blue,
                      icon: Icons.settings_applications_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KitchenStockManagementPage(
                              establishmentId: establishmentId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _KitchenMainActionButton(
                      title: l10n.stockConsultationCardTitle,
                      subtitle: l10n.stockConsultationCardSubtitle,
                      color: Colors.green,
                      icon: Icons.visibility_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KitchenStockConsultationPage(
                              establishmentId: establishmentId,
                            ),
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

class _KitchenMainActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _KitchenMainActionButton({
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

class _KitchenSection extends StatelessWidget {
  final String establishmentId;
  final String title;
  final List<KitchenOrderModel> orders;
  final CuisineService cuisineService;
  final Color Function(String status) statusColor;
  final String Function(String status, AppLocalizations l10n) statusLabel;
  final String Function(KitchenOrderModel order, AppLocalizations l10n)
  clientLabel;
  final bool isMobile;

  const _KitchenSection({
    required this.establishmentId,
    required this.title,
    required this.orders,
    required this.cuisineService,
    required this.statusColor,
    required this.statusLabel,
    required this.clientLabel,
    required this.isMobile,
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
            if (isMobile)
              orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(AppLocalizations.of(context).noOrders),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = orders[index];

                        return _KitchenOrderCard(
                          establishmentId: establishmentId,
                          order: order,
                          cuisineService: cuisineService,
                          statusColor: statusColor,
                          statusLabel: statusLabel,
                          clientLabel: clientLabel,
                        );
                      },
                    )
            else
              Expanded(
                child: orders.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context).noOrders))
                    : ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = orders[index];

                          return _KitchenOrderCard(
                            establishmentId: establishmentId,
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

class KitchenStockManagementPage extends StatelessWidget {
  final String establishmentId;

  const KitchenStockManagementPage({super.key, required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _KitchenStockMenuPage(
      title: l10n.stockManagementCardTitle,
      color: Colors.blue,
      actions: [
        _KitchenSubAction(
          title: l10n.actionComposeMenu,
          icon: Icons.food_bank_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MenuItemIngredientsFormPage(
                  establishmentId: establishmentId,
                ),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: l10n.actionAddArticle,
          icon: Icons.add_box_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StockItemFormPage(establishmentId: establishmentId),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: l10n.actionDeclareConsumption,
          icon: Icons.remove_shopping_cart_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockOutPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: l10n.stockOutRestaurantTitle,
                  defaultReason: l10n.reasonKitchenPreparation,
                ),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: l10n.actionRequestSupply,
          icon: Icons.playlist_add_circle_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateStockRequestPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  requestedByRole: 'chef_cuisine',
                  title: l10n.supplyRequestRestaurantTitle,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class KitchenStockConsultationPage extends StatelessWidget {
  final String establishmentId;

  const KitchenStockConsultationPage({
    super.key,
    required this.establishmentId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _KitchenStockMenuPage(
      title: l10n.stockConsultationCardTitle,
      color: Colors.green,
      actions: [
        _KitchenSubAction(
          title: l10n.actionViewStocks,
          icon: Icons.inventory_2_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreStockPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: l10n.stockRestaurantTitle,
                ),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: l10n.actionConfirmAReception,
          icon: Icons.check_circle_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreRequestHistoryPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: l10n.receptionsToConfirmRestaurantTitle,
                ),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: l10n.actionStockHistory,
          icon: Icons.history,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockMovementHistoryPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: l10n.movementHistoryRestaurantTitle,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _KitchenSubAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _KitchenSubAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _KitchenStockMenuPage extends StatelessWidget {
  final String title;
  final Color color;
  final List<_KitchenSubAction> actions;

  const _KitchenStockMenuPage({
    required this.title,
    required this.color,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

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
            crossAxisCount: isSmallScreen ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isSmallScreen ? 3.2 : 3.5,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];

            return Material(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
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

class _KitchenOrderCard extends StatelessWidget {
  final String establishmentId;
  final KitchenOrderModel order;
  final CuisineService cuisineService;
  final Color Function(String status) statusColor;
  final String Function(String status, AppLocalizations l10n) statusLabel;
  final String Function(KitchenOrderModel order, AppLocalizations l10n)
  clientLabel;

  const _KitchenOrderCard({
    required this.establishmentId,
    required this.order,
    required this.cuisineService,
    required this.statusColor,
    required this.statusLabel,
    required this.clientLabel,
  });

  Future<void> _createKitchenReadyNotification(AppLocalizations l10n) async {
    final firestore = FirebaseFirestore.instance;

    final orderDoc = await firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders')
        .doc(order.id)
        .get();

    final data = orderDoc.data();

    if (data == null) return;

    final serveurId = (data['createdBy'] ?? '').toString().trim();

    if (serveurId.isEmpty) {
      return;
    }

    final clientType = (data['clientType'] ?? '').toString();
    final tableNumber = (data['tableNumber'] ?? '').toString();
    final roomNumber = (data['roomNumber'] ?? '').toString();

    String clientLabel = l10n.clientGeneric;

    if (clientType == 'hotel' && roomNumber.isNotEmpty) {
      clientLabel = l10n.roomLowercaseLine(roomNumber);
    } else if (tableNumber.isNotEmpty) {
      clientLabel = l10n.tableLowercaseLine(tableNumber);
    }

    await firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('serverNotifications')
        .doc('kitchen_${order.id}_ready')
        .set({
          'establishmentId': establishmentId,
          'title': l10n.kitchenOrderReadyTitle,
          'body': l10n.kitchenOrderReadyBody(clientLabel),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'orderId': order.id,
          'orderNumber': order.orderNumber,
          'serveurId': serveurId,
          'source': 'kitchen',
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
            Text(l10n.waiterLine(order.createdByName)),
            const SizedBox(height: 4),
            Text(l10n.clientLine(clientLabel(order, l10n))),
            const SizedBox(height: 4),
            Text(l10n.totalLine(order.total.toStringAsFixed(0))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel(order.kitchenStatus, l10n),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<OrderItemModel>>(
              future: cuisineService.getKitchenItemsForOrder(
                establishmentId: establishmentId,
                orderId: order.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Text(l10n.kitchenItemsError('${snapshot.error}'));
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Text(l10n.noKitchenItems);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(
                      l10n.kitchenItems,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                                  Text(item.name),
                                  if (item.accompanimentName.trim().isNotEmpty)
                                    Text(
                                      l10n.accompanimentPlainLine(
                                        item.accompanimentName,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8D6E63),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (item.note.trim().isNotEmpty)
                                    Text(
                                      l10n.noteLine(item.note),
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
                        establishmentId: establishmentId,
                        orderId: order.id,
                        newKitchenStatus: 'preparing',
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: Text(l10n.actionSetPreparing),
                  ),
                if (order.kitchenStatus == 'preparing')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _createKitchenReadyNotification(l10n);

                      await cuisineService.updateKitchenStatus(
                        establishmentId: establishmentId,
                        orderId: order.id,
                        newKitchenStatus: 'ready',
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.actionMarkReady),
                  ),
                if (order.kitchenStatus == 'ready')
                  OutlinedButton.icon(
                    onPressed: () async {
                      await cuisineService.updateKitchenStatus(
                        establishmentId: establishmentId,
                        orderId: order.id,
                        newKitchenStatus: 'preparing',
                      );
                    },
                    icon: const Icon(Icons.undo),
                    label: Text(l10n.actionBackToPreparing),
                  ),
                if (order.kitchenStatus == 'ready')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await cuisineService.updateKitchenStatus(
                        establishmentId: establishmentId,
                        orderId: order.id,
                        newKitchenStatus: 'served',
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
  }
}
