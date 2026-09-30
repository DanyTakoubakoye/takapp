import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/order_ticket_model.dart';
import 'package:takapp/services/payment_service.dart';
import 'package:takapp/vues/serveur/detail_consommation_page.dart';
import 'package:takapp/vues/serveur/nouvelle_commande_page.dart';
import 'package:takapp/vues/commun/ticket_payment_sheet.dart';

class UnpaidTicketsPage extends StatelessWidget {
  final String establishmentId;
  final String? serveurId;

  /// Floor Manager (10B) : contexte d'acteur. Les additions affichées sont
  /// celles du serveur responsable [OrderActorContext.assignedServerId]
  /// (lui-même en direct, Jean pour Jean) ; « Ajouter une commande » et
  /// « Encaisser » agissent dans ce même contexte.
  final OrderActorContext? actor;

  /// « Ajouter une commande » du Floor Manager (injectable pour les tests) :
  /// par défaut le parcours de commande existant, dans le même contexte.
  final Widget Function(OrderActorContext actor, OrderTicket ticket)
  addOrderPageBuilder;

  const UnpaidTicketsPage({
    super.key,
    required this.establishmentId,
    this.serveurId,
    this.actor,
    this.addOrderPageBuilder = _defaultAddOrderPage,
  });

  static Widget _defaultAddOrderPage(
    OrderActorContext actor,
    OrderTicket ticket,
  ) {
    return NouvelleCommandePage(
      initialClientType: ticket.primaryOrder.clientType,
      initialTableNumber: ticket.primaryOrder.tableNumber,
      initialRoomNumber: ticket.primaryOrder.roomNumber,
      returnAfterSubmit: true,
      actor: actor,
    );
  }

  bool get _isFloorManager => actor?.isFloorManager == true;

  /// Serveur responsable dont on affiche les additions (`null` : toutes).
  String? get _responsibleServerId => actor?.assignedServerId ?? serveurId;

  String _title(AppLocalizations l10n) {
    final current = actor;
    if (current == null || !current.isFloorManager) {
      return l10n.encaissementTitle;
    }
    return current.isDelegated
        ? l10n.fmTicketsForServerTitle(current.assignedServerName)
        : l10n.fmTicketsDirectTitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentService = context.read<PaymentService>();
    final isMobile = MediaQuery.of(context).size.width < 700;
    final serveurId = _responsibleServerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(l10n)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: paymentService.streamUnpaidOrdersForEstablishment(
          establishmentId: establishmentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorPrefixed('${snapshot.error}')));
          }

          final allTickets = OrderTicket.group(snapshot.data ?? []);
          final tickets = serveurId == null
              ? allTickets
              : allTickets
                    .where(
                      (ticket) => ticket.orders.any(
                        (order) => order.effectiveAssignedServerId == serveurId,
                      ),
                    )
                    .toList();
          if (tickets.isEmpty) {
            return Center(child: Text(l10n.noUnpaidOrder));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 3
                  : constraints.maxWidth >= 700
                  ? 2
                  : 1;

              return GridView.builder(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isMobile ? 1.8 : 1.55,
                ),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  return _TicketCard(
                    ticket: tickets[index],
                    onTap: () => _showActions(context, tickets[index]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showActions(BuildContext context, OrderTicket ticket) {
    if (_isFloorManager) {
      _showFloorManagerActions(context, ticket, actor!);
      return;
    }

    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ticket.labelFor(l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: Text(l10n.actionShowAndPrint),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailConsommationPage(
                          establishmentId: establishmentId,
                          ticket: ticket,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(l10n.actionAdd),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NouvelleCommandePage(
                          initialClientType: ticket.primaryOrder.clientType,
                          initialTableNumber: ticket.primaryOrder.tableNumber,
                          initialRoomNumber: ticket.primaryOrder.roomNumber,
                          returnAfterSubmit: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Floor Manager : [Ajouter une commande] (même moteur de commande, même
  /// contexte d'acteur) et [Encaisser] (même moteur d'encaissement). Pas de
  /// facture imprimée ni de fiscalisation ici (données réservées).
  void _showFloorManagerActions(
    BuildContext context,
    OrderTicket ticket,
    OrderActorContext actor,
  ) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ticket.labelFor(l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const ValueKey('ticket-add-order'),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(l10n.fmActionAddOrder),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => addOrderPageBuilder(actor, ticket),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const ValueKey('ticket-collect'),
                  icon: const Icon(Icons.point_of_sale),
                  label: Text(l10n.actionCollect),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => TicketPaymentSheet(
                        establishmentId: establishmentId,
                        ticket: ticket,
                        actor: actor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final OrderTicket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = ticket.primaryOrder;
    final isRoom = primary.clientType == 'hotel';
    final accent = isRoom ? Colors.indigo : Colors.deepOrange;

    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.12),
                    foregroundColor: accent,
                    child: Icon(isRoom ? Icons.hotel : Icons.table_bar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ticket.labelFor(l10n),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: accent),
                ],
              ),
              const Spacer(),
              Text(
                ticket.isMultiOrder
                    ? l10n.ordersCount('${ticket.orders.length}')
                    : primary.effectiveAssignedServerName,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 5),
              Text(
                l10n.totalToCollect(ticket.total.toStringAsFixed(0)),
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
