import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/floor_manager_shift_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/vues/floor_manager/floor_manager_action_page.dart';
import 'package:takapp/vues/floor_manager/floor_manager_widgets.dart';

/// Serveurs ACTIFS du service ouvert du Floor Manager, commune aux sections
/// Commandes et Encaissements.
///
/// La liste vient de `FloorManagerShiftController` (temps réel) : elle suit
/// l'ouverture / la clôture du service, les ajouts / retraits et les
/// désactivations de comptes. Jamais tous les serveurs de l'établissement.
class FloorManagerServersPage extends StatelessWidget {
  final FloorManagerSection section;

  /// Page de commande ouverte (injectable pour les tests).
  final OrderPageBuilder orderPageBuilder;

  /// Page des additions ouverte (injectable pour les tests).
  final ActorPageBuilder ticketsPageBuilder;

  const FloorManagerServersPage({
    super.key,
    required this.section,
    this.orderPageBuilder = defaultOrderPage,
    this.ticketsPageBuilder = defaultTicketsPage,
  });

  void _onServerTap(
    BuildContext context,
    ShiftModel shift,
    ShiftParticipantModel server,
  ) {
    final floorManager = context.read<AuthController>().currentUser;
    if (floorManager == null) return;

    // Contexte « pour ce serveur » : la vente lui appartient ; le Floor
    // Manager reste l'auteur / l'encaisseur réel. La présence du serveur est
    // revérifiée à la validation (service + règles Firestore), jamais
    // déduite du seul état de l'écran.
    final actor = OrderActorContext.forShiftServer(
      floorManager: floorManager,
      shift: shift,
      server: server,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => section == FloorManagerSection.orders
            ? orderPageBuilder(actor)
            // Encaissements : les additions non encaissées de ce serveur.
            : ticketsPageBuilder(actor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<FloorManagerShiftController>();
    final state = controller.state;

    Widget body;
    if (controller.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!state.hasOpenShift) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [NoOpenShiftCard()],
      );
    } else if (state.activeServers.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.fmNoActiveServer, textAlign: TextAlign.center),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.activeServers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final server = state.activeServers[index];
          return ActiveServerCard(
            key: ValueKey('fm-server-${server.serverId}'),
            server: server,
            onTap: () => _onServerTap(context, state.openShift!, server),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${section.title(l10n)} · ${l10n.fmServers}')),
      body: SafeArea(child: body),
    );
  }
}

/// Carte d'un serveur présent. Aucun profil ne porte encore de photo dans
/// TAKAPP : l'avatar affiche ses initiales.
class ActiveServerCard extends StatelessWidget {
  final ShiftParticipantModel server;
  final VoidCallback onTap;

  const ActiveServerCard({
    super.key,
    required this.server,
    required this.onTap,
  });

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = server.serverName.isEmpty
        ? server.serverId
        : server.serverName;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(radius: 26, child: Text(initials(name))),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.circle, size: 12, color: Colors.green),
                label: Text(l10n.fmServerOnDuty),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
