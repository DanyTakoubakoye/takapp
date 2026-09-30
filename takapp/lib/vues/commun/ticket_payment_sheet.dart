import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_ticket_model.dart';

/// Encaissement compact d'une addition (Floor Manager).
///
/// Même moteur que les autres écrans : `PaymentController.registerTicketPayment`
/// (transaction, contrôle de double encaissement, règles Firestore). Le
/// montant est celui de l'addition, non modifiable : le service vérifie qu'il
/// correspond toujours aux commandes relues.
///
/// Renvoie `true` (via `Navigator.pop`) si l'addition a été encaissée.
class TicketPaymentSheet extends StatefulWidget {
  final String establishmentId;
  final OrderTicket ticket;
  final OrderActorContext actor;

  const TicketPaymentSheet({
    super.key,
    required this.establishmentId,
    required this.ticket,
    required this.actor,
  });

  @override
  State<TicketPaymentSheet> createState() => _TicketPaymentSheetState();
}

class _TicketPaymentSheetState extends State<TicketPaymentSheet> {
  String _method = AppPaymentMethods.cash;

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final controller = context.read<PaymentController>();

    final ok = await controller.registerTicketPayment(
      establishmentId: widget.establishmentId,
      ticketId: widget.ticket.ticketId,
      orderIds: widget.ticket.orderIds,
      actor: widget.actor,
      method: _method,
      amount: widget.ticket.total,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.paymentRecorded
              : (controller.errorText(l10n) ?? l10n.errUnknown),
        ),
      ),
    );
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSubmitting = context.watch<PaymentController>().isSubmitting;
    final ticket = widget.ticket;

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
            const SizedBox(height: 4),
            // « Vente de Jean · encaissée par Paul » : les deux notions
            // restent visibles au moment de valider.
            Text(
              l10n.fmPaymentContext(
                widget.actor.assignedServerName,
                widget.actor.performedByUserName,
              ),
              key: const ValueKey('payment-context'),
            ),
            Text(l10n.ordersCount('${ticket.orders.length}')),
            const SizedBox(height: 12),
            Text(
              l10n.totalToCollect(ticket.total.toStringAsFixed(0)),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(
                labelText: l10n.paymentMethodLabel,
                border: const OutlineInputBorder(),
              ),
              items: AppPaymentMethods.labels.keys
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(AppPaymentMethods.label(l10n, method)),
                    ),
                  )
                  .toList(),
              onChanged: isSubmitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _method = value);
                    },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('payment-confirm'),
              icon: const Icon(Icons.point_of_sale),
              label: Text(l10n.fmPaymentConfirm),
              onPressed: isSubmitting ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
