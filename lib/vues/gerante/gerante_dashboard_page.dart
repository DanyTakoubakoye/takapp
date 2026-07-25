import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/vues/clients/clients_page.dart';
import 'package:takapp/vues/gerante/enregistrer_serveur_page.dart';
import 'package:takapp/vues/gerante/facturation_chambre_page.dart';
import 'package:takapp/vues/gerante/gestion_menu_page.dart';
import 'package:takapp/vues/gerante/liste_factures_page.dart';
import 'package:takapp/vues/gerante/suivi_encaissements_serveurs.dart';
import 'package:takapp/vues/gerante/versement_compta_page.dart';
import 'package:takapp/vues/gerante/versements_serveurs_page.dart';
import 'package:takapp/vues/gerante/create_store_stock_page.dart';
import 'package:takapp/vues/gerante/stock_management_page.dart';
import 'package:takapp/vues/gerante/stock_request_list_page.dart';
import 'package:takapp/vues/gerante/direct_stock_supply_page.dart';
import 'package:takapp/vues/reception/reservations_page.dart';
import 'package:takapp/vues/reception/room_types_page.dart';
import 'package:takapp/vues/reception/rooms_board_page.dart';
import 'package:takapp/vues/reception/rooms_page.dart';
import 'package:takapp/vues/shared/low_stock_page.dart';
import 'package:takapp/vues/shared/stock_item_registry_page.dart';

class GeranteDashboardPage extends StatelessWidget {
  final String establishmentId;
  const GeranteDashboardPage({super.key, required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final width = MediaQuery.of(context).size.width;

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

    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAKHOTEL - Gérante'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
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
              _GeranteWelcomeCard(userName: user.name),
              const SizedBox(height: 16),
              _GeranteModulesGrid(
                establishmentId: establishmentId,
                isMobile: isMobile,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeranteWelcomeCard extends StatelessWidget {
  final String userName;

  const _GeranteWelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.admin_panel_settings),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue $userName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Espace de supervision et validation',
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

class _GeranteModulesGrid extends StatelessWidget {
  final String establishmentId;
  final bool isMobile;
  final bool isTablet;

  const _GeranteModulesGrid({
    required this.establishmentId,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final canRestaurant = auth.canAccessRestaurant;
    final canBar = auth.canAccessBar;
    final canHotel = auth.canAccessHotel;

    // Magasins visibles dans l'écran « Stocks faibles » : seuls les modules
    // souscrits. Établissement abonné à tout ⇒ les trois magasins.
    final lowStockStores = <String>[
      if (canHotel) 'hotel',
      if (canRestaurant) 'restaurant',
      if (canBar) 'bar',
    ];

    final modules = [
      _GeranteModule(
        title: 'Stocks & Approvisionnements',
        subtitle: 'Stocks, demandes, seuils, articles et approvisionnements',
        icon: Icons.inventory_2_outlined,
        color: Colors.blueGrey,
        actions: [
          _GeranteAction(
            title: 'Gestion des stocks',
            icon: Icons.inventory_2,
            pageBuilder: (_) =>
                StockManagementPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Demandes stock',
            icon: Icons.assignment_outlined,
            pageBuilder: (_) =>
                StockRequestListPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Stocks faibles',
            icon: Icons.warning_amber_rounded,
            pageBuilder: (_) => LowStockPage(
              establishmentId: establishmentId,
              stores: lowStockStores,
              title: 'Stocks faibles',
            ),
          ),
          _GeranteAction(
            title: 'Approvisionner Restaurant',
            icon: Icons.restaurant,
            visible: canRestaurant,
            pageBuilder: (_) => DirectStockSupplyPage(
              establishmentId: establishmentId,
              store: 'restaurant',
              title: 'Approvisionnement direct - Restaurant',
            ),
          ),
          _GeranteAction(
            title: 'Approvisionner Bar',
            icon: Icons.local_bar,
            visible: canBar,
            pageBuilder: (_) => DirectStockSupplyPage(
              establishmentId: establishmentId,
              store: 'bar',
              title: 'Approvisionnement direct - Bar',
            ),
          ),
          _GeranteAction(
            title: 'Approvisionner Hôtel',
            icon: Icons.hotel,
            visible: canHotel,
            pageBuilder: (_) => DirectStockSupplyPage(
              establishmentId: establishmentId,
              store: 'hotel',
              title: 'Approvisionnement direct - Hôtel',
            ),
          ),
          _GeranteAction(
            title: 'Registre des articles',
            icon: Icons.inventory_2_outlined,
            pageBuilder: (_) =>
                StockItemRegistryPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Créer un stock',
            icon: Icons.add_business_outlined,
            pageBuilder: (_) =>
                CreateStoreStockPage(establishmentId: establishmentId),
          ),
        ],
      ),
      _GeranteModule(
        title: 'Serveurs & Encaissements',
        subtitle: 'Serveurs, versements et encaissements',
        icon: Icons.people_alt_outlined,
        color: Colors.blue,
        actions: [
          _GeranteAction(
            title: 'Enregistrer un serveur',
            icon: Icons.person_add,
            pageBuilder: (_) => const EnregistrerServeurPage(),
          ),
          _GeranteAction(
            title: 'Valider les versements',
            icon: Icons.fact_check_outlined,
            pageBuilder: (_) =>
                VersementsServeursPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Encaissements serveurs',
            icon: Icons.visibility,
            pageBuilder: (_) => SuiviEncaissementsServeursPage(
              establishmentId: establishmentId,
            ),
          ),
        ],
      ),

      _GeranteModule(
        title: 'Facturation & Chambres',
        subtitle: 'Factures, chambres et versement comptable',
        icon: Icons.hotel_outlined,
        color: Colors.indigo,
        visible: canHotel,
        actions: [
          _GeranteAction(
            title: 'Réservations',
            icon: Icons.event_available_outlined,
            pageBuilder: (_) =>
                ReservationsPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Clients',
            icon: Icons.people_outline,
            pageBuilder: (_) => ClientsPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Types de chambres',
            icon: Icons.category_outlined,
            pageBuilder: (_) => RoomTypesPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Chambres',
            icon: Icons.meeting_room_outlined,
            pageBuilder: (_) => RoomsPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Plan des chambres',
            icon: Icons.grid_view_outlined,
            pageBuilder: (_) =>
                RoomsBoardPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Facturation chambres',
            icon: Icons.hotel,
            pageBuilder: (_) =>
                FacturationChambrePage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Liste des factures',
            icon: Icons.receipt_long_outlined,
            pageBuilder: (_) =>
                ListeFacturesPage(establishmentId: establishmentId),
          ),
          _GeranteAction(
            title: 'Versement compta',
            icon: Icons.account_balance_outlined,
            pageBuilder: (_) =>
                VersementComptaPage(establishmentId: establishmentId),
          ),
        ],
      ),
      _GeranteModule(
        title: 'Menu & Exploitation',
        subtitle: 'Gestion du menu restaurant et bar',
        icon: Icons.restaurant_menu,
        color: Colors.green,
        visible: canRestaurant || canBar,
        actions: [
          _GeranteAction(
            title: 'Gérer le menu',
            icon: Icons.restaurant_menu,
            pageBuilder: (_) =>
                GestionMenuPage(establishmentId: establishmentId),
          ),
        ],
      ),
    ];

    // On masque les modules non souscrits, on filtre les actions non
    // souscrites, puis on retire les modules qui n'ont plus aucune action.
    final visibleModules = <_GeranteModule>[];
    for (final module in modules) {
      if (!module.visible) continue;

      final visibleActions =
          module.actions.where((action) => action.visible).toList();
      if (visibleActions.isEmpty) continue;

      visibleModules.add(
        _GeranteModule(
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
        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isMobile ? 2.25 : 1.45,
      ),
      itemBuilder: (context, index) {
        return _GeranteModuleCard(module: visibleModules[index]);
      },
    );
  }
}

class _GeranteModuleCard extends StatelessWidget {
  final _GeranteModule module;

  const _GeranteModuleCard({required this.module});

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
              builder: (_) => _GeranteModulePage(module: module),
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

class _GeranteModulePage extends StatelessWidget {
  final _GeranteModule module;

  const _GeranteModulePage({required this.module});

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
              _GeranteModuleHeader(module: module),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: module.actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isMobile ? 3.2 : 2.75,
                ),
                itemBuilder: (context, index) {
                  return _GeranteActionCard(
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

class _GeranteModuleHeader extends StatelessWidget {
  final _GeranteModule module;

  const _GeranteModuleHeader({required this.module});

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

class _GeranteActionCard extends StatelessWidget {
  final _GeranteAction action;
  final Color color;

  const _GeranteActionCard({required this.action, required this.color});

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
            MaterialPageRoute(builder: action.pageBuilder),
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
                child: Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
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

class _GeranteModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_GeranteAction> actions;

  /// Le module entier est masqué si l'établissement n'est pas abonné.
  final bool visible;

  const _GeranteModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
    this.visible = true,
  });
}

class _GeranteAction {
  final String title;
  final IconData icon;
  final WidgetBuilder pageBuilder;

  /// L'action est masquée si l'établissement n'est pas abonné au module lié.
  final bool visible;

  const _GeranteAction({
    required this.title,
    required this.icon,
    required this.pageBuilder,
    this.visible = true,
  });
}
