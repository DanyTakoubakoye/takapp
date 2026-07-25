import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/vues/commun/module_visibility.dart';
import 'package:takapp/vues/gerante/stock_request_list_page.dart';
import 'package:takapp/vues/shared/store_stock_page.dart';

class StockManagementPage extends StatelessWidget {
  final String establishmentId;

  const StockManagementPage({super.key, required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;
    final safeEstablishmentId = establishmentId.trim();

    if (safeEstablishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    final user = context.watch<AuthController>().currentUser;

    // Un magasin dont le module n'est pas souscrit ne doit pas apparaître.
    // Établissement abonné à tout ⇒ les trois magasins restent affichés.
    final stores =
        [
          _StoreCardData(
            store: 'hotel',
            title: 'Magasin Hôtel',
            subtitle: 'Produits d’hygiène, entretien, consommables chambre',
            icon: Icons.hotel,
            color: Colors.teal,
          ),
          _StoreCardData(
            store: 'restaurant',
            title: 'Magasin Restaurant',
            subtitle: 'Denrées, cuisine, matières premières',
            icon: Icons.restaurant,
            color: Colors.deepOrange,
          ),
          _StoreCardData(
            store: 'bar',
            title: 'Magasin Bar',
            subtitle: 'Boissons, snacks, accessoires bar',
            icon: Icons.local_bar,
            color: Colors.indigo,
          ),
        ].where((s) => user == null || user.canSeeStore(s.store)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des stocks'),
        actions: [
          IconButton(
            tooltip: 'Demandes d’approvisionnement',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StockRequestListPage(
                    establishmentId: safeEstablishmentId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.inventory_2_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilotage des magasins',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Consulte les stocks, traite les demandes et valide les approvisionnements.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: stores.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmall ? 1 : 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: isSmall ? 1.7 : 1.45,
                ),
                itemBuilder: (context, index) {
                  final item = stores[index];

                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: item.color.withValues(alpha: 0.12),
                            child: Icon(item.icon, color: item.color),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: item.color,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoreStockPage(
                                        establishmentId: safeEstablishmentId,
                                        store: item.store,
                                        title: item.title,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Voir stock'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StockRequestListPage(
                                        establishmentId: safeEstablishmentId,
                                        storeFilter: item.store,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.list_alt_outlined),
                                label: const Text('Demandes'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _StoreCardData {
  final String store;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _StoreCardData({
    required this.store,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
