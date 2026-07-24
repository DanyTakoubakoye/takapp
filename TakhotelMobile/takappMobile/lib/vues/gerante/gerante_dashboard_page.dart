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

class GeranteDashboardPage extends StatelessWidget {
  const GeranteDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isSmallScreen
            ? _GeranteDashboardMobile(userName: auth.currentUser?.name ?? '')
            : _GeranteDashboardDesktop(userName: auth.currentUser?.name ?? ''),
      ),
    );
  }
}

class _GeranteDashboardMobile extends StatelessWidget {
  final String userName;

  const _GeranteDashboardMobile({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.admin_panel_settings),
            ),
            const SizedBox(height: 12),
            Text(
              'Bienvenue $userName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Espace de supervision et validation',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EnregistrerServeurPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Enregistrer un serveur'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VersementsServeursPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Valider les versements serveurs'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GestionMenuPage()),
                  );
                },
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Gérer le menu'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FacturationChambrePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.hotel),
                label: const Text('Facturation chambres'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ListeFacturesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Liste des factures'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VersementComptaPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Versement à la comptabilité'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuiviEncaissementsServeursPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Encaissements serveurs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeranteDashboardDesktop extends StatelessWidget {
  final String userName;

  const _GeranteDashboardDesktop({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        style: Theme.of(context).textTheme.titleLarge,
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
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnregistrerServeurPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Enregistrer un serveur'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VersementsServeursPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Valider les versements'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GestionMenuPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Gérer le menu'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FacturationChambrePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.hotel),
                  label: const Text('Facturation chambres'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ListeFacturesPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Liste des factures'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VersementComptaPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_outlined),
                  label: const Text('Versement compta'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SuiviEncaissementsServeursPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Encaissements serveurs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
