import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/vues/clients/clients_page.dart';
import 'package:takapp/vues/reception/reservations_page.dart';
import 'package:takapp/vues/reception/room_types_page.dart';
import 'package:takapp/vues/reception/rooms_page.dart';
import 'package:takapp/vues/reception/rooms_board_page.dart';
import 'package:takapp/vues/gerante/facturation_chambre_page.dart';
import 'package:takapp/vues/gerante/liste_factures_page.dart';

class ReceptionDashboardPage extends StatelessWidget {
  final String establishmentId;

  const ReceptionDashboardPage({super.key, required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isSmall = MediaQuery.of(context).size.width < 700;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable')),
      );
    }

    if (establishmentId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    // Toutes les tuiles de la réception relèvent du module hôtel : si
    // l'établissement n'est pas abonné à l'hôtel, on n'affiche aucune tuile.
    final tiles = !user.canAccessHotel
        ? <_ReceptionTile>[]
        : <_ReceptionTile>[
      _ReceptionTile(
        title: 'Plan des chambres',
        subtitle: 'Voir l\'état des chambres en temps réel',
        icon: Icons.grid_view_outlined,
        color: Colors.teal,
        pageBuilder: (_) => RoomsBoardPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: 'Réservations',
        subtitle: 'Créer et gérer les réservations',
        icon: Icons.event_available_outlined,
        color: Colors.green,
        pageBuilder: (_) => ReservationsPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: 'Facturation chambre',
        subtitle: 'Facturer et certifier un séjour',
        icon: Icons.receipt_long_outlined,
        color: Colors.indigo,
        pageBuilder: (_) =>
            FacturationChambrePage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: 'Liste des factures',
        subtitle: 'Consulter les factures chambres',
        icon: Icons.description_outlined,
        color: Colors.blueGrey,
        pageBuilder: (_) => ListeFacturesPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: 'Clients',
        subtitle: 'Fiches clients et historique',
        icon: Icons.people_outline,
        color: Colors.orange,
        pageBuilder: (_) => ClientsPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: 'Chambres',
        subtitle: 'Gérer les chambres',
        icon: Icons.meeting_room_outlined,
        color: Colors.brown,
        pageBuilder: (_) => RoomsPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: 'Types de chambres',
        subtitle: 'Configurer les catégories',
        icon: Icons.category_outlined,
        color: Colors.deepPurple,
        pageBuilder: (_) => RoomTypesPage(establishmentId: establishmentId),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réception'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmall ? 16 : 20),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 28, child: Icon(Icons.hotel)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue ${user.name}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Espace réception : chambres, séjours et factures',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmall ? 1 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isSmall ? 3.0 : 2.6,
                ),
                itemBuilder: (context, index) {
                  final tile = tiles[index];
                  return _ReceptionTileCard(tile: tile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceptionTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder pageBuilder;

  const _ReceptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.pageBuilder,
  });
}

class _ReceptionTileCard extends StatelessWidget {
  final _ReceptionTile tile;

  const _ReceptionTileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tile.color,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: tile.pageBuilder));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(tile.icon, color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tile.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tile.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
