import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/floor_manager_shift_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/vues/commun/unpaid_tickets_page.dart';
import 'package:takapp/vues/serveur/menu_presentation_page.dart';
import 'package:takapp/vues/floor_manager/floor_manager_servers_page.dart';
import 'package:takapp/vues/floor_manager/floor_manager_widgets.dart';

/// Les deux grandes sections du Floor Manager. Une seule page intermédiaire
/// et une seule liste de serveurs servent les deux.
enum FloorManagerSection { orders, payments }

extension FloorManagerSectionLabels on FloorManagerSection {
  String title(AppLocalizations l10n) => switch (this) {
    FloorManagerSection.orders => l10n.fmActionOrders,
    FloorManagerSection.payments => l10n.fmActionPayments,
  };

  String subtitle(AppLocalizations l10n) => switch (this) {
    FloorManagerSection.orders => l10n.fmActionOrdersSubtitle,
    FloorManagerSection.payments => l10n.fmActionPaymentsSubtitle,
  };

  String directLabel(AppLocalizations l10n) => switch (this) {
    FloorManagerSection.orders => l10n.fmDirectOrder,
    FloorManagerSection.payments => l10n.fmDirectPayment,
  };

  IconData get icon => switch (this) {
    FloorManagerSection.orders => Icons.restaurant_menu,
    FloorManagerSection.payments => Icons.point_of_sale,
  };

  Color get color => switch (this) {
    FloorManagerSection.orders => Colors.blue,
    FloorManagerSection.payments => Colors.teal,
  };
}

/// Ouvre une page dans un contexte d'acteur (commande ou additions).
typedef ActorPageBuilder = Widget Function(OrderActorContext actor);

/// Ouvre le parcours de prise de commande pour un contexte d'acteur.
typedef OrderPageBuilder = ActorPageBuilder;

/// Parcours standard des serveurs, réutilisé tel quel (aucune copie).
Widget defaultOrderPage(OrderActorContext actor) =>
    MenuPresentationPage(actor: actor);

/// Additions non encaissées du serveur responsable du contexte, avec
/// « Ajouter une commande » et « Encaisser » (écran existant réutilisé).
Widget defaultTicketsPage(OrderActorContext actor) => UnpaidTicketsPage(
  establishmentId: actor.performedByEstablishmentId,
  actor: actor,
);

/// Page intermédiaire : action directe, ou passage par un serveur du service.
///
/// Commandes (9B) et Encaissements (10B) : même structure, même contexte
/// d'acteur ; seule la page ouverte change.
class FloorManagerActionPage extends StatelessWidget {
  final FloorManagerSection section;

  /// Page de commande ouverte (injectable pour les tests).
  final OrderPageBuilder orderPageBuilder;

  /// Page des additions ouverte (injectable pour les tests).
  final ActorPageBuilder ticketsPageBuilder;

  const FloorManagerActionPage({
    super.key,
    required this.section,
    this.orderPageBuilder = defaultOrderPage,
    this.ticketsPageBuilder = defaultTicketsPage,
  });

  ActorPageBuilder get _sectionPageBuilder =>
      section == FloorManagerSection.orders
      ? orderPageBuilder
      : ticketsPageBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<FloorManagerShiftController>().state;
    final hasOpenShift = state.hasOpenShift;
    final user = context.watch<AuthController>().currentUser;
    final shift = state.openShift;

    // Action directe : le Floor Manager agit pour lui-même, dans SON service
    // ouvert (auteur/encaisseur réel = serveur responsable = lui).
    final VoidCallback? onDirect = user != null && shift != null
        ? () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _sectionPageBuilder(
                OrderActorContext.self(user, shiftId: shift.id),
              ),
            ),
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(section.title(l10n))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Le service peut être clôturé pendant que la page est ouverte.
            if (!hasOpenShift) ...[
              const NoOpenShiftCard(),
              const SizedBox(height: 16),
            ],
            FloorManagerTile(
              key: ValueKey('fm-direct-${section.name}'),
              title: section.directLabel(l10n),
              subtitle: section == FloorManagerSection.orders
                  ? l10n.fmDirectOrderSubtitle
                  : l10n.fmDirectPaymentSubtitle,
              icon: section.icon,
              color: section.color,
              onTap: onDirect,
            ),
            const SizedBox(height: 14),
            FloorManagerTile(
              key: ValueKey('fm-servers-${section.name}'),
              title: l10n.fmServers,
              subtitle: l10n.fmServersSubtitle,
              icon: Icons.groups_outlined,
              color: section.color,
              onTap: hasOpenShift
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FloorManagerServersPage(
                          section: section,
                          orderPageBuilder: orderPageBuilder,
                          ticketsPageBuilder: ticketsPageBuilder,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
