import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    unlockWebSoundAfterUserInteraction();
  }

  void _handleNewKitchenOrders(List<KitchenOrderModel> orders) {
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
        final clientLabel = _clientLabel(o);
        final orderNumber = o.orderNumber;

        playWebNotificationSound(
          'kitchen_new_order',
          establishmentId: widget.establishmentId, 
        );
        debugPrint(
          'SON DEBUG cuisine: kIsWeb=$kIsWeb, appel playNewOrderSound',
        );
        if (!kIsWeb) {
          NotificationService().playNewOrderSound(department: 'kitchen');
        }

        showWebNotification(
          title: 'Nouvelle commande cuisine',
          body: 'Commande $orderNumber - $clientLabel',
          establishmentId: widget.establishmentId,
          tag: 'takapp_kitchen_${widget.establishmentId}_${o.id}',
        );

        _showNewOrderPopup(orderNumber, clientLabel);
      } catch (e) {
        debugPrint('Notif cuisine ignorée: $e');
      }
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
        icon: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 40),
        title: const Text('Nouvelle commande cuisine'),
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
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
            return Text(name.isEmpty ? 'Cuisine' : '$name - Cuisine');
          },
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<KitchenOrderModel>>(
          stream: cuisineService.streamKitchenOrders(
            establishmentId: establishmentId,
          ),
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
            // Alerte son + popup pour les nouvelles commandes cuisine
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleNewKitchenOrders(kitchenOrders);
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
                      title: 'En attente',
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
                      title: 'En préparation',
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
                      title: 'Prêtes',
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
                          title: 'En attente',
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
                          title: 'En préparation',
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
                          title: 'Prêtes',
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
                    'Bienvenue : $userName',
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
    );
  }
}

class _KitchenStockActionsCard extends StatelessWidget {
  final String establishmentId;

  const _KitchenStockActionsCard({required this.establishmentId});

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
                    'Gestion stock cuisine',
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
                    title: 'Gestion de Stocks',
                    subtitle:
                        'Composer menu • Ajouter article\nDéclarer consommation • Demander approvisionnement',
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
                    title: 'Consulter Stocks',
                    subtitle:
                        'Voir les stocks • Confirmer réception • Historique stocks',
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
                      title: 'Gestion de Stocks',
                      subtitle:
                          'Composer menu • Ajouter article • Déclarer consommation • Demander approvisionnement',
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
                      title: 'Consulter Stocks',
                      subtitle:
                          'Voir les stocks • Confirmer réception • Historique stocks',
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
  final String Function(String status) statusLabel;
  final String Function(KitchenOrderModel order) clientLabel;
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
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: Text('Aucune commande')),
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
                    ? const Center(child: Text('Aucune commande'))
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
    return _KitchenStockMenuPage(
      title: 'Gestion de Stocks',
      color: Colors.blue,
      actions: [
        _KitchenSubAction(
          title: 'Composer menu',
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
          title: 'Ajouter article',
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
          title: 'Déclarer une consommation',
          icon: Icons.remove_shopping_cart_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockOutPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: 'Sortie de stock - Restaurant',
                  defaultReason: 'Préparation cuisine',
                ),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: 'Demander un approvisionnement',
          icon: Icons.playlist_add_circle_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateStockRequestPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  requestedByRole: 'chef_cuisine',
                  title: 'Demande approvisionnement - Restaurant',
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
    return _KitchenStockMenuPage(
      title: 'Consulter Stocks',
      color: Colors.green,
      actions: [
        _KitchenSubAction(
          title: 'Voir les stocks',
          icon: Icons.inventory_2_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreStockPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: 'Stock Restaurant',
                ),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: 'Confirmer une réception',
          icon: Icons.check_circle_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreRequestHistoryPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: 'Réceptions à confirmer - Restaurant',
                ),
              ),
            );
          },
        ),
        _KitchenSubAction(
          title: 'Historique stocks',
          icon: Icons.history,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockMovementHistoryPage(
                  establishmentId: establishmentId,
                  store: 'restaurant',
                  title: 'Historique mouvements - Restaurant',
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
  final String Function(String status) statusLabel;
  final String Function(KitchenOrderModel order) clientLabel;

  const _KitchenOrderCard({
    required this.establishmentId,
    required this.order,
    required this.cuisineService,
    required this.statusColor,
    required this.statusLabel,
    required this.clientLabel,
  });

  Future<void> _createKitchenReadyNotification() async {
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
      debugPrint('Impossible de créer la notification : createdBy vide.');
      return;
    }

    final clientType = (data['clientType'] ?? '').toString();
    final tableNumber = (data['tableNumber'] ?? '').toString();
    final roomNumber = (data['roomNumber'] ?? '').toString();

    String clientLabel = 'client';

    if (clientType == 'hotel' && roomNumber.isNotEmpty) {
      clientLabel = 'la chambre $roomNumber';
    } else if (tableNumber.isNotEmpty) {
      clientLabel = 'la table $tableNumber';
    }

    await firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('serverNotifications')
        .doc('kitchen_${order.id}_ready')
        .set({
          'establishmentId': establishmentId,
          'title': 'Commande cuisine prête',
          'body': 'La commande de $clientLabel est prête en cuisine.',
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
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel(order.kitchenStatus),
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
                        establishmentId: establishmentId,
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
                      await _createKitchenReadyNotification();

                      await cuisineService.updateKitchenStatus(
                        establishmentId: establishmentId,
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
                        establishmentId: establishmentId,
                        orderId: order.id,
                        newKitchenStatus: 'preparing',
                      );
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Revenir en préparation'),
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
