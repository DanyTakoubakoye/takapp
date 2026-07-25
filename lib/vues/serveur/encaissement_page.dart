import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/services/payment_service.dart';
import 'package:takapp/vues/serveur/detail_consommation_page.dart';

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
    final auth = context.watch<AuthController>();
    final paymentService = context.read<PaymentService>();
    final user = auth.currentUser;
    final isSmall = _isSmallScreen(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Encaissement')),
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
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final rawOrders = snapshot.data ?? [];
            final orders = rawOrders.where(_isVisibleForCashier).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (orders.isEmpty) {
              return const Center(
                child: Text('Aucune commande non encaissée.'),
              );
            }

            return ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 12 : 16),
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
                                        order: order,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Afficher et Imprimer'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => _PaymentDialog(
                                      establishmentId: establishmentId,
                                      order: order,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Encaisser'),
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
  final OrderModel order;

  const _PaymentDialog({required this.establishmentId, required this.order});

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

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Montant invalide.')));
      return;
    }

    final success = await paymentController.registerPayment(
      establishmentId: establishmentId,
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
              initialValue: selectedMethod,
              decoration: const InputDecoration(labelText: 'Mode de paiement'),
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
