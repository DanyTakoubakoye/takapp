import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/vues/clients/clients_page.dart';
import 'package:takapp/vues/reception/reservations_page.dart';
import 'package:takapp/vues/reception/room_types_page.dart';
import 'package:takapp/vues/reception/rooms_page.dart';
import 'package:takapp/vues/reception/rooms_board_page.dart';
import 'package:takapp/vues/gerante/facturation_chambre_page.dart';
import 'package:takapp/vues/gerante/liste_factures_page.dart';
import 'package:takapp/core/l10n/language_selector.dart';

class ReceptionDashboardPage extends StatelessWidget {
  final String establishmentId;

  const ReceptionDashboardPage({super.key, required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isSmall = MediaQuery.of(context).size.width < 700;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    if (establishmentId.trim().isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    // Toutes les tuiles de la réception relèvent du module hôtel : si
    // l'établissement n'est pas abonné à l'hôtel, on n'affiche aucune tuile.
    final tiles = !user.canAccessHotel
        ? <_ReceptionTile>[]
        : <_ReceptionTile>[
      _ReceptionTile(
        title: l10n.tileRoomsBoardTitle,
        subtitle: l10n.tileRoomsBoardSubtitle,
        icon: Icons.grid_view_outlined,
        color: Colors.teal,
        pageBuilder: (_) => RoomsBoardPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: l10n.tileReservationsTitle,
        subtitle: l10n.tileReservationsSubtitle,
        icon: Icons.event_available_outlined,
        color: Colors.green,
        pageBuilder: (_) => ReservationsPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: l10n.tileRoomInvoicingTitle,
        subtitle: l10n.tileRoomInvoicingSubtitle,
        icon: Icons.receipt_long_outlined,
        color: Colors.indigo,
        pageBuilder: (_) =>
            FacturationChambrePage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: l10n.tileInvoicesListTitle,
        subtitle: l10n.tileInvoicesListSubtitle,
        icon: Icons.description_outlined,
        color: Colors.blueGrey,
        pageBuilder: (_) => ListeFacturesPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: l10n.tileClientsTitle,
        subtitle: l10n.tileClientsSubtitle,
        icon: Icons.people_outline,
        color: Colors.orange,
        pageBuilder: (_) => ClientsPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: l10n.roomsTitle,
        subtitle: l10n.tileRoomsSubtitle,
        icon: Icons.meeting_room_outlined,
        color: Colors.brown,
        pageBuilder: (_) => RoomsPage(establishmentId: establishmentId),
      ),
      _ReceptionTile(
        title: l10n.roomTypesTitle,
        subtitle: l10n.tileRoomTypesSubtitle,
        icon: Icons.category_outlined,
        color: Colors.deepPurple,
        pageBuilder: (_) => RoomTypesPage(establishmentId: establishmentId),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receptionTitle),
        actions: [
          const LanguageSelector(),
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            tooltip: l10n.commonLogout,
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
                              l10n.welcomeName(user.name),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.receptionSubtitle,
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
