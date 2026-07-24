import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/vues/comptabilite/depenses_page.dart';
import 'package:takapp/vues/comptabilite/point_hebdomadaire_page.dart';
import 'package:takapp/vues/comptabilite/reception_versements_page.dart';
import 'package:takapp/vues/comptabilite/soldes_precedents_page.dart';

// 🔥 AJOUTÉS
import 'package:takapp/vues/comptabilite/reception_gerante_page.dart';
import 'package:takapp/vues/comptabilite/suivi_factures_non_versees.dart';

class ComptableDashboardPage extends StatelessWidget {
  const ComptableDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isSmallScreen = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAKHOTEL - Comptabilité'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: isSmallScreen
                // ================= MOBILE =================
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.calculate_outlined),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bienvenue ${auth.currentUser?.name ?? ""}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Réception, dépenses, soldes précédents et point hebdomadaire',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      // Réception serveur
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReceptionVersementsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Réception des versements'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🔥 NOUVEAU : Réception gérante
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReceptionGerantePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.move_to_inbox_outlined),
                          label: const Text('Réception gérante'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🔥 NOUVEAU : Suivi non versés
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SuiviFacturesNonVerseesPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Suivi non versés'),
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
                                builder: (_) => const DepensesPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.money_off_csred_outlined),
                          label: const Text('Dépenses'),
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
                                builder: (_) => const SoldesPrecedentsPage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          label: const Text('Soldes précédents'),
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
                                builder: (_) => const PointHebdomadairePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bar_chart_outlined),
                          label: const Text('Point hebdomadaire'),
                        ),
                      ),
                    ],
                  )
                // ================= DESKTOP =================
                : Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.calculate_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue ${auth.currentUser?.name ?? ""}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Réception, dépenses, soldes précédents et point hebdomadaire',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      // Réception serveur
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceptionVersementsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Réception'),
                      ),
                      const SizedBox(width: 10),

                      // 🔥 NOUVEAU
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceptionGerantePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.move_to_inbox_outlined),
                        label: const Text('Réception gérante'),
                      ),
                      const SizedBox(width: 10),

                      // 🔥 NOUVEAU
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SuiviFacturesNonVerseesPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Suivi non versés'),
                      ),
                      const SizedBox(width: 10),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DepensesPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.money_off_csred_outlined),
                        label: const Text('Dépenses'),
                      ),
                      const SizedBox(width: 10),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SoldesPrecedentsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('Soldes'),
                      ),
                      const SizedBox(width: 10),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PointHebdomadairePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bar_chart_outlined),
                        label: const Text('Point hebdo'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
