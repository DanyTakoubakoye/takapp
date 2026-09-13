import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/services/server_notification_service.dart';
import 'package:takapp/services/notification_service.dart';
import 'package:takapp/vues/serveur/encaissement_page.dart';
import 'package:takapp/vues/serveur/facture_consommation_chambre_page.dart';
import 'package:takapp/vues/serveur/menu_presentation_page.dart';
import 'package:takapp/vues/serveur/mes_factures_serveur_page.dart';
import 'package:takapp/vues/serveur/serveur_notifications_page.dart';
import 'package:takapp/vues/serveur/suivi_bar_page.dart';
import 'package:takapp/vues/serveur/suivi_cuisine_page.dart';
import 'package:takapp/vues/serveur/versement_gerante_page.dart';

class ServeurHomePage extends StatefulWidget {
  final String establishmentId;
  const ServeurHomePage({super.key, required this.establishmentId});

  @override
  State<ServeurHomePage> createState() => _ServeurHomePageState();
}

class _ServeurHomePageState extends State<ServeurHomePage> {
  final ServerNotificationService notificationService =
      ServerNotificationService();

  String? _listeningUserId;

  // L'établissement / l'utilisateur ne sont connus qu'au build : on mémorise
  // les streams et on ne les recrée que s'ils changent vraiment. Sinon chaque
  // rebuild relancerait les abonnements et ferait clignoter l'écran.
  String? _establishmentStreamKey;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _establishmentStream;

  String? _notificationsStreamKey;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _notificationsStream;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _establishmentStreamFor(
    String establishmentId,
  ) {
    if (_establishmentStreamKey != establishmentId ||
        _establishmentStream == null) {
      _establishmentStreamKey = establishmentId;
      _establishmentStream = FirebaseFirestore.instance
          .collection('establishments')
          .doc(establishmentId)
          .snapshots();
    }

    return _establishmentStream!;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStreamFor(
    String establishmentId,
    String serveurId,
  ) {
    final key = '$establishmentId/$serveurId';

    if (_notificationsStreamKey != key || _notificationsStream == null) {
      _notificationsStreamKey = key;
      _notificationsStream = notificationService.streamNotificationsForServer(
        establishmentId: establishmentId,
        serveurId: serveurId,
      );
    }

    return _notificationsStream!;
  }

  String _getEstablishmentName(Map<String, dynamic>? data) {
    if (data == null) return 'TAKHOTEL';

    final name = (data['name'] ?? '').toString().trim();

    if (name.isNotEmpty) return name;

    return 'Hotel';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user != null && _listeningUserId != user.uid) {
      _listeningUserId = user.uid;

      NotificationService().registerTokenForCurrentUser();

      if (user.establishmentId.trim().isNotEmpty) {
        NotificationService().startServerNotificationListener(
          establishmentId: user.establishmentId.trim(),
          serveurId: user.uid,
        );
      }
    }
  }

  @override
  void dispose() {
    NotificationService().stopServerNotificationListener();
    super.dispose();
  }

  Future<void> _openNotifications({
    required String establishmentId,
    required String serveurId,
  }) async {
    try {
      await notificationService.markAllAsReadForServer(
        establishmentId: establishmentId,
        serveurId: serveurId,
      );
    } catch (e) {
      debugPrint('Erreur markAllAsReadForServer: $e');
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServeurNotificationsPage(
          establishmentId: establishmentId,
          serveurId: serveurId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _establishmentStreamFor(establishmentId),
      builder: (context, establishmentSnapshot) {
        final establishmentData = establishmentSnapshot.data?.data();
        final establishmentName = _getEstablishmentName(establishmentData);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.serveurSpaceTitle(establishmentName),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _notificationsStreamFor(establishmentId, user.uid),
                builder: (context, snapshot) {
                  int unreadCount = 0;

                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data();
                      return data['isRead'] != true;
                    }).length;
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _openNotifications(
                          establishmentId: establishmentId,
                          serveurId: user.uid,
                        ),
                        tooltip: l10n.navNotifications,
                        icon: const Icon(Icons.notifications),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                onPressed: () => context.read<AuthController>().logout(),
                tooltip: l10n.commonLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ServeurWelcomeCard(
                    name: user.name,
                    establishmentName: establishmentName,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 16),
                  _ServeurModulesGrid(
                    establishmentId: establishmentId,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServeurWelcomeCard extends StatelessWidget {
  final String name;
  final bool isMobile;
  final String establishmentName;

  const _ServeurWelcomeCard({
    required this.name,
    required this.establishmentName,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeName(name),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.serveurSpaceSubtitle,
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

class _ServeurModulesGrid extends StatelessWidget {
  final String establishmentId;
  final bool isMobile;
  final bool isTablet;

  const _ServeurModulesGrid({
    required this.establishmentId,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final canRestaurant = auth.canAccessRestaurant;
    final canBar = auth.canAccessBar;
    final canHotel = auth.canAccessHotel;

    final modules = [
      _ServeurModule(
        title: l10n.moduleOrdersRoomsTitle,
        subtitle: l10n.moduleOrdersRoomsSubtitle,
        icon: Icons.add_shopping_cart,
        color: Colors.deepOrange,
        actions: [
          _ServeurAction(
            title: l10n.actionMenuOrderTitle,
            subtitle: l10n.actionMenuOrderSubtitle,
            icon: Icons.restaurant_menu,
            visible: canRestaurant || canBar,
            page: const MenuPresentationPage(),
          ),
          _ServeurAction(
            title: l10n.actionRoomConsumptionTitle,
            subtitle: l10n.actionRoomConsumptionSubtitle,
            icon: Icons.hotel,
            visible: canHotel,
            page: const FactureConsommationChambrePage(),
          ),
        ],
      ),
      _ServeurModule(
        title: l10n.modulePaymentsTitle,
        subtitle: l10n.modulePaymentsSubtitle,
        icon: Icons.payments_outlined,
        color: Colors.green,
        actions: [
          _ServeurAction(
            title: l10n.encaissementTitle,
            subtitle: l10n.actionCollectSubtitle,
            icon: Icons.payments_outlined,
            page: const EncaissementPage(),
          ),
          _ServeurAction(
            title: l10n.myInvoicesTitle,
            subtitle: l10n.actionMyInvoicesSubtitle,
            icon: Icons.receipt_long_outlined,
            page: MesFacturesServeurPage(establishmentId: establishmentId),
          ),
          _ServeurAction(
            title: l10n.handoverTitle,
            subtitle: l10n.actionHandoverSubtitle,
            icon: Icons.account_balance_wallet_outlined,
            page: VersementGerantePage(establishmentId: establishmentId),
          ),
        ],
      ),
      _ServeurModule(
        title: l10n.moduleTrackingTitle,
        subtitle: l10n.moduleTrackingSubtitle,
        icon: Icons.visibility_outlined,
        color: Colors.indigo,
        actions: [
          _ServeurAction(
            title: l10n.suiviBarTitle,
            subtitle: l10n.actionSuiviBarSubtitle,
            icon: Icons.local_bar,
            visible: canBar,
            page: SuiviBarPage(establishmentId: establishmentId),
          ),
          _ServeurAction(
            title: l10n.suiviCuisineTitle,
            subtitle: l10n.actionSuiviCuisineSubtitle,
            icon: Icons.restaurant,
            visible: canRestaurant,
            page: SuiviCuisinePage(establishmentId: establishmentId),
          ),
        ],
      ),
    ];

    // On filtre les actions non souscrites, puis on retire les modules
    // qui n'ont plus aucune action.
    final visibleModules = <_ServeurModule>[];
    for (final module in modules) {
      final visibleActions =
          module.actions.where((action) => action.visible).toList();
      if (visibleActions.isEmpty) continue;

      visibleModules.add(
        _ServeurModule(
          title: module.title,
          subtitle: module.subtitle,
          icon: module.icon,
          color: module.color,
          actions: visibleActions,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleModules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isMobile ? 2.25 : 1.55,
      ),
      itemBuilder: (context, index) {
        return _ServeurModuleCard(module: visibleModules[index]);
      },
    );
  }
}

class _ServeurModuleCard extends StatelessWidget {
  final _ServeurModule module;

  const _ServeurModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: module.color,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _ServeurModulePage(module: module),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(module.icon, color: Colors.white, size: 34),
              const Spacer(),
              Text(
                module.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                module.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServeurModulePage extends StatelessWidget {
  final _ServeurModule module;

  const _ServeurModulePage({required this.module});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    return Scaffold(
      appBar: AppBar(
        title: Text(module.title),
        backgroundColor: module.color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ServeurModuleHeader(module: module),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: module.actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 2),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isMobile ? 3.15 : 2.85,
                ),
                itemBuilder: (context, index) {
                  return _ServeurActionCard(
                    action: module.actions[index],
                    color: module.color,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServeurModuleHeader extends StatelessWidget {
  final _ServeurModule module;

  const _ServeurModuleHeader({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: module.color,
              child: Icon(module.icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.subtitle,
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

class _ServeurActionCard extends StatelessWidget {
  final _ServeurAction action;
  final Color color;

  const _ServeurActionCard({required this.action, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => action.page),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color,
                child: Icon(action.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.2,
                        color: Colors.black54,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServeurModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_ServeurAction> actions;

  const _ServeurModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
  });
}

class _ServeurAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;

  /// L'action est masquée si l'établissement n'est pas abonné au module lié.
  final bool visible;

  const _ServeurAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
    this.visible = true,
  });
}
