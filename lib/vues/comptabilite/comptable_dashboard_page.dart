import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';

import 'package:takapp/core/constants/app_roles.dart';

import 'package:takapp/vues/comptabilite/depenses_page.dart';
import 'package:takapp/vues/comptabilite/point_hebdomadaire_page.dart';
import 'package:takapp/vues/comptabilite/reception_gerante_page.dart';
import 'package:takapp/vues/comptabilite/reception_versements_page.dart';
import 'package:takapp/vues/comptabilite/soldes_precedents_page.dart';
import 'package:takapp/vues/comptabilite/suivi_factures_non_versees.dart';

class ComptableDashboardPage extends StatelessWidget {
  final String establishmentId;
  const ComptableDashboardPage({super.key,
  required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    final user = auth.currentUser;

    final userName = user?.name ?? '';

    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 700;

    final isTablet = width >= 700 && width < 1100;

    /// =========================
    /// SAAS SECURITY
    /// =========================

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user.establishmentId.trim().isEmpty &&
        user.role != AppRoles.superAdmin) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    if (user.role != AppRoles.comptable &&
        user.role != AppRoles.gerante &&
        user.role != AppRoles.proprietaire &&
        user.role != AppRoles.superAdmin) {
      return const Scaffold(body: Center(child: Text('Accès refusé.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.establishmentName.trim().isNotEmpty
              ? '${user.establishmentName} - Comptabilité'
              : 'TAKHOTEL - Comptabilité',
        ),

        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthController>().logout();
            },

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
              _ComptableWelcomeCard(
                userName: userName,
                establishmentId: user.establishmentId,

                establishmentName: user.establishmentName,
              ),

              const SizedBox(height: 16),

              _ComptableModulesGrid(isMobile: isMobile, isTablet: isTablet),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComptableWelcomeCard extends StatelessWidget {
  final String userName;
  final String establishmentName;
  final String establishmentId ;

  const _ComptableWelcomeCard({
    required this.userName,
    required this.establishmentName,
    required this.establishmentId
  });

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

              child: Icon(Icons.calculate_outlined),
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

                  if (establishmentName.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),

                    Text(
                      establishmentName,

                      style: const TextStyle(
                        fontWeight: FontWeight.w600,

                        color: Colors.blueGrey,
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),

                  Text(
                    'Réception, contrôle, dépenses, soldes et rapports',

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

class _ComptableModulesGrid extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _ComptableModulesGrid({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable')),
      );
    }
   
    final modules = [
      _ComptableModule(
        title: 'Réceptions & Contrôles',

        subtitle: 'Versements serveurs, gérante et factures non versées',

        icon: Icons.fact_check_outlined,

        color: Colors.blue,

        actions: [
          _ComptableAction(
            title: 'Réception des versements',

            subtitle: 'Contrôler les versements des serveurs',

            icon: Icons.inventory_2_outlined,

            page: const ReceptionVersementsPage(),
          ),

          _ComptableAction(
            title: 'Réception gérante',

            subtitle: 'Recevoir les versements transmis par la gérante',

            icon: Icons.move_to_inbox_outlined,

            page: const ReceptionGerantePage(),
          ),

          _ComptableAction(
            title: 'Suivi non versés',

            subtitle: 'Suivre les factures non encore versées',

            icon: Icons.visibility_outlined,

            page: const SuiviFacturesNonVerseesPage(),
          ),
        ],
      ),

      _ComptableModule(
        title: 'Dépenses & Soldes',

        subtitle: 'Dépenses courantes et soldes précédents',

        icon: Icons.account_balance_wallet_outlined,

        color: Colors.green,

        actions: [
          _ComptableAction(
            title: 'Dépenses',

            subtitle: 'Enregistrer et consulter les dépenses',

            icon: Icons.money_off_csred_outlined,

            page: const DepensesPage(),
          ),

          _ComptableAction(
            title: 'Soldes précédents',

            subtitle: 'Gérer les soldes d’ouverture ou antérieurs',

            icon: Icons.account_balance_wallet_outlined,

            page: SoldesPrecedentsPage(establishmentId: user.establishmentId,),
          ),
        ],
      ),

      _ComptableModule(
        title: 'Rapports & Points',

        subtitle: 'Synthèse hebdomadaire et suivi comptable',

        icon: Icons.bar_chart_outlined,

        color: Colors.indigo,

        actions: [
          _ComptableAction(
            title: 'Point hebdomadaire',

            subtitle: 'Produire le point hebdomadaire de comptabilité',

            icon: Icons.bar_chart_outlined,

            page: const PointHebdomadairePage(),
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
        return _ComptableModuleCard(module: modules[index]);
      },
    );
  }
}

class _ComptableModuleCard extends StatelessWidget {
  final _ComptableModule module;

  const _ComptableModuleCard({required this.module});

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
              builder: (_) => _ComptableModulePage(module: module),
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

class _ComptableModulePage extends StatelessWidget {
  final _ComptableModule module;

  const _ComptableModulePage({required this.module});

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
              _ComptableModuleHeader(module: module),

              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),

                itemCount: module.actions.length,

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),

                  crossAxisSpacing: 14,

                  mainAxisSpacing: 14,

                  childAspectRatio: isMobile ? 3.15 : 2.85,
                ),

                itemBuilder: (context, index) {
                  return _ComptableActionCard(
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

class _ComptableModuleHeader extends StatelessWidget {
  final _ComptableModule module;

  const _ComptableModuleHeader({required this.module});

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

class _ComptableActionCard extends StatelessWidget {
  final _ComptableAction action;
  final Color color;

  const _ComptableActionCard({required this.action, required this.color});

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

class _ComptableModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_ComptableAction> actions;

  const _ComptableModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
  });
}

class _ComptableAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;

  const _ComptableAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}
