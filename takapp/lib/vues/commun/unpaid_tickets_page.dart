import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/order_ticket_model.dart';
import 'package:takapp/services/payment_service.dart';
import 'package:takapp/vues/serveur/detail_consommation_page.dart';
import 'package:takapp/vues/serveur/nouvelle_commande_page.dart';

class UnpaidTicketsPage extends StatelessWidget {
  final String establishmentId;
  final String? serveurId;

  const UnpaidTicketsPage({
    super.key,
    required this.establishmentId,
    this.serveurId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentService = context.read<PaymentService>();
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.encaissementTitle),
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
                        (order) => order.createdBy == serveurId,
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
                    : primary.createdByName,
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
