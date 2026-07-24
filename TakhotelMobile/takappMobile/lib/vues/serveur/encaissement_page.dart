import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/services/payment_service.dart';

class EncaissementPage extends StatelessWidget {
  const EncaissementPage({super.key});

  String _clientLabel(OrderModel order) {
    switch (order.clientType) {
      case 'restaurant':
        return 'Table ${order.tableNumber ?? "-"}';
      case 'hotel':
        return 'Chambre ${order.roomNumber ?? "-"}';
      case 'bar':
        return 'Client Bar';
      default:
        return order.clientType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final paymentService = context.read<PaymentService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Encaissement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<OrderModel>>(
          stream: paymentService.streamUnpaidOrdersForServer(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return const Center(
                child: Text('Aucune commande non encaissée.'),
              );
            }

            return ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Client : ${_clientLabel(order)}'),
                        const SizedBox(height: 4),
                        Text('Créée par : ${order.createdByName}'),
                        const SizedBox(height: 4),
                        Text(
                          'Montant : ${order.total.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => _PaymentDialog(order: order),
                              );
                            },
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Encaisser'),
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
  final OrderModel order;

  const _PaymentDialog({required this.order});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController amountController;
  String selectedMethod = AppPaymentMethods.cash;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.order.total.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final paymentController = context.read<PaymentController>();
    final user = auth.currentUser;

    if (user == null) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Montant invalide.')));
      return;
    }

    final success = await paymentController.registerPayment(
      orderId: widget.order.id,
      orderNumber: widget.order.orderNumber,
      receivedBy: user.uid,
      receivedByName: user.name,
      method: selectedMethod,
      amount: amount,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement enregistré avec succès.')),
      );
    } else if (paymentController.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(paymentController.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentController = context.watch<PaymentController>();

    return AlertDialog(
      title: const Text('Encaisser la commande'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedMethod,
              decoration: const InputDecoration(labelText: 'Mode de paiement'),
              items: AppPaymentMethods.labels.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedMethod = value;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant reçu'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: paymentController.isSubmitting
              ? null
              : () => Navigator.pop(context),
          child: const Text('Annuler'),
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
              : const Text('Valider'),
        ),
      ],
    );
  }
}
