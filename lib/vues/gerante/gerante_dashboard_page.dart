import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
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
import 'package:takapp/vues/shared/low_stock_page.dart';
import 'package:takapp/vues/shared/stock_item_registry_page.dart';

class GeranteDashboardPage extends StatelessWidget {
  const GeranteDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userName = auth.currentUser?.name ?? '';
    final width = MediaQuery.of(context).size.width;

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
              _GeranteWelcomeCard(userName: userName),
              const SizedBox(height: 16),
              _GeranteModulesGrid(isMobile: isMobile, isTablet: isTablet),
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
  final bool isMobile;
  final bool isTablet;

  const _GeranteModulesGrid({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
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
            page: const StockManagementPage(),
          ),
          _GeranteAction(
            title: 'Demandes stock',
            icon: Icons.assignment_outlined,
            page: const StockRequestListPage(),
          ),
          _GeranteAction(
            title: 'Stocks faibles',
            icon: Icons.warning_amber_rounded,
            page: const LowStockPage(
              stores: ['hotel', 'restaurant', 'bar'],
              title: 'Stocks faibles',
            ),
          ),
          _GeranteAction(
            title: 'Approvisionner Restaurant',
            icon: Icons.restaurant,
            page: const DirectStockSupplyPage(
              store: 'restaurant',
              title: 'Approvisionnement direct - Restaurant',
            ),
          ),
          _GeranteAction(
            title: 'Approvisionner Bar',
            icon: Icons.local_bar,
            page: const DirectStockSupplyPage(
              store: 'bar',
              title: 'Approvisionnement direct - Bar',
            ),
          ),
          _GeranteAction(
            title: 'Approvisionner Hôtel',
            icon: Icons.hotel,
            page: const DirectStockSupplyPage(
              store: 'hotel',
              title: 'Approvisionnement direct - Hôtel',
            ),
          ),
          _GeranteAction(
            title: 'Registre des articles',
            icon: Icons.inventory_2_outlined,
            page: const StockItemRegistryPage(),
          ),
          _GeranteAction(
            title: 'Créer un stock',
            icon: Icons.add_business_outlined,
            page: const CreateStoreStockPage(),
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
            page: const EnregistrerServeurPage(),
          ),
          _GeranteAction(
            title: 'Valider les versements',
            icon: Icons.fact_check_outlined,
            page: const VersementsServeursPage(),
          ),
          _GeranteAction(
            title: 'Encaissements serveurs',
            icon: Icons.visibility,
            page: const SuiviEncaissementsServeursPage(),
          ),
        ],
      ),
      _GeranteModule(
        title: 'Facturation & Chambres',
        subtitle: 'Factures, chambres et versement comptable',
        icon: Icons.hotel_outlined,
        color: Colors.indigo,
        actions: [
          _GeranteAction(
            title: 'Facturation chambres',
            icon: Icons.hotel,
            page: const FacturationChambrePage(),
          ),
          _GeranteAction(
            title: 'Liste des factures',
            icon: Icons.receipt_long_outlined,
            page: const ListeFacturesPage(),
          ),
          _GeranteAction(
            title: 'Versement compta',
            icon: Icons.account_balance_outlined,
            page: const VersementComptaPage(),
          ),
        ],
      ),
      _GeranteModule(
        title: 'Menu & Exploitation',
        subtitle: 'Gestion du menu restaurant et bar',
        icon: Icons.restaurant_menu,
        color: Colors.green,
        actions: [
          _GeranteAction(
            title: 'Gérer le menu',
            icon: Icons.restaurant_menu,
            page: const GestionMenuPage(),
          ),
        ],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isMobile ? 2.25 : 1.45,
      ),
      itemBuilder: (context, index) {
        return _GeranteModuleCard(module: modules[index]);
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

  const _GeranteModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
  });
}

class _GeranteAction {
  final String title;
  final IconData icon;
  final Widget page;

  const _GeranteAction({
    required this.title,
    required this.icon,
    required this.page,
  });
}
