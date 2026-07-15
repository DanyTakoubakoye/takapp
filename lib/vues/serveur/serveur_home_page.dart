import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/services/server_notification_service.dart';
import 'package:takapp/services/notification_service.dart';
import 'package:takapp/vues/serveur/encaissement_page.dart';
import 'package:takapp/vues/serveur/facture_consommation_chambre_page.dart';
import 'package:takapp/vues/serveur/menu_presentation_page.dart';
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

      debugPrint('Notification mobile listener lancé pour serveur=${user.uid}');
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
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable')),
      );
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('establishments')
          .doc(establishmentId)
          .snapshots(),
      builder: (context, establishmentSnapshot) {
        final establishmentData = establishmentSnapshot.data?.data();
        final establishmentName = _getEstablishmentName(establishmentData);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Espace serveur - $establishmentName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: notificationService.streamNotificationsForServer(
                  establishmentId: establishmentId,
                  serveurId: user.uid,
                ),
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
                        tooltip: 'Notifications',
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
                tooltip: 'Déconnexion',
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
  final establishmentName;

  const _ServeurWelcomeCard({
    required this.name,
    required this.establishmentName,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
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
                    'Bienvenue $name',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Espace de prise de commande et de suivi serveur',
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
    final modules = [
      _ServeurModule(
        title: 'Commandes & Chambres',
        subtitle: 'Prendre les commandes et gérer les consommations chambre',
        icon: Icons.add_shopping_cart,
        color: Colors.deepOrange,
        actions: [
          _ServeurAction(
            title: 'Menu et Commande',
            subtitle: 'Prendre une commande restaurant, bar ou chambre',
            icon: Icons.restaurant_menu,
            page: const MenuPresentationPage(),
          ),
          _ServeurAction(
            title: 'Consommations Chambre',
            subtitle: 'Facturer les consommations liées à une chambre',
            icon: Icons.hotel,
            page: const FactureConsommationChambrePage(),
          ),
        ],
      ),
      _ServeurModule(
        title: 'Paiements & Versements',
        subtitle: 'Encaisser les factures et remettre les fonds',
        icon: Icons.payments_outlined,
        color: Colors.green,
        actions: [
          _ServeurAction(
            title: 'Encaissement',
            subtitle: 'Encaisser les factures non payées',
            icon: Icons.payments_outlined,
            page: const EncaissementPage(),
          ),
          _ServeurAction(
            title: 'Versement à la gérante',
            subtitle: 'Remettre les encaissements à la gérante',
            icon: Icons.account_balance_wallet_outlined,
            page: VersementGerantePage(establishmentId: establishmentId),
          ),
        ],
      ),
      _ServeurModule(
        title: 'Suivi Préparation',
        subtitle: 'Suivre l’avancement des commandes bar et cuisine',
        icon: Icons.visibility_outlined,
        color: Colors.indigo,
        actions: [
          _ServeurAction(
            title: 'Suivi bar',
            subtitle: 'Voir l’état des commandes envoyées au bar',
            icon: Icons.local_bar,
            page: SuiviBarPage(establishmentId: establishmentId),
          ),
          _ServeurAction(
            title: 'Suivi cuisine',
            subtitle: 'Voir l’état des commandes envoyées en cuisine',
            icon: Icons.restaurant,
            page: SuiviCuisinePage(establishmentId: establishmentId),
          ),
        ],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isMobile ? 2.25 : 1.55,
      ),
      itemBuilder: (context, index) {
        return _ServeurModuleCard(module: modules[index]);
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
      color: color.withOpacity(0.10),
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
            border: Border.all(color: color.withOpacity(0.35)),
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

  const _ServeurAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}
