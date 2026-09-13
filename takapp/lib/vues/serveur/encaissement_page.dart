import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/order_ticket_model.dart';
import 'package:takapp/services/payment_service.dart';
import 'package:takapp/vues/serveur/detail_consommation_page.dart';

class EncaissementPage extends StatelessWidget {
  const EncaissementPage({super.key});

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  bool _isVisibleForCashier(OrderModel order) {
    final status = order.status.toLowerCase().trim();
    final paymentStatus = order.paymentStatus.toLowerCase().trim();

    if (status == 'cancelled') return false;
    if (paymentStatus == 'paid') return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final paymentService = context.read<PaymentService>();
    final user = auth.currentUser;
    final isSmall = _isSmallScreen(context);

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.encaissementTitle)),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: StreamBuilder<List<OrderModel>>(
          stream: paymentService.streamUnpaidOrdersForServer(
            establishmentId: establishmentId,
            serveurId: user.uid,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(l10n.errorPrefixed('${snapshot.error}')),
              );
            }

            final rawOrders = snapshot.data ?? [];

            final orders = rawOrders.where(_isVisibleForCashier).toList();

            if (orders.isEmpty) {
              return Center(child: Text(l10n.noUnpaidOrder));
            }

            // Toutes les commandes non encaissées d'une même table ou d'une
            // même chambre forment une seule facture.
            final tickets = OrderTicket.group(orders);

            return ListView.separated(
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = tickets[index];

                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.labelFor(l10n),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (ticket.isMultiOrder)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.ordersCount('${ticket.orders.length}'),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.openedAt(
                            DateFormat('HH:mm').format(ticket.openedAt),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.createdByLine(
                            ticket.primaryOrder.createdByName,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...ticket.orders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${order.orderNumber}  •  ${order.total.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.totalToCollect(
                            ticket.total.toStringAsFixed(0),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
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
                                icon: const Icon(Icons.receipt_long),
                                label: Text(l10n.actionShowAndPrint),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => _PaymentDialog(
                                      establishmentId: establishmentId,
                                      ticket: ticket,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.payments_outlined),
                                label: Text(l10n.actionCollect),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final String establishmentId;
  final OrderTicket ticket;

  const _PaymentDialog({required this.establishmentId, required this.ticket});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController amountController;
  String selectedMethod = AppPaymentMethods.cash;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.ticket.total.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final paymentController = context.read<PaymentController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errUserNotFound)));
      return;
    }

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }

    final success = await paymentController.registerTicketPayment(
      establishmentId: establishmentId,
      ticketId: widget.ticket.ticketId,
      orderIds: widget.ticket.orderIds,
      receivedBy: user.uid,
      receivedByName: user.name,
      method: selectedMethod,
      amount: amount,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.paymentRecorded)));
    } else if (paymentController.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(paymentController.errorText(l10n)!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentController = context.watch<PaymentController>();

    return AlertDialog(
      title: Text(l10n.collectForTicket(widget.ticket.labelFor(l10n))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.ticket.isMultiOrder)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.groupedOrders(
                    '${widget.ticket.orders.length}',
                    widget.ticket.orderNumbers.join(', '),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: selectedMethod,
              decoration: InputDecoration(
                labelText: l10n.paymentMethodLabel,
              ),
              items: AppPaymentMethods.labels.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: paymentController.isSubmitting
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        selectedMethod = value;
                      });
                    },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              enabled: !paymentController.isSubmitting,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.amountReceived),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: paymentController.isSubmitting
              ? null
              : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: paymentController.isSubmitting ? null : _submit,
          child: paymentController.isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.commonValidate),
        ),
      ],
    );
  }
}
