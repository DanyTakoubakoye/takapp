import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/services/gerante_handover_service.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';

class VersementsServeursPage extends StatelessWidget {
  const VersementsServeursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GeranteHandoverService();

    return Scaffold(
      appBar: AppBar(title: const Text('Versements des serveurs')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<ServerHandoverModel>>(
          stream: service.streamPendingHandovers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final handovers = snapshot.data ?? [];

            if (handovers.isEmpty) {
              return const Center(child: Text('Aucun versement en attente.'));
            }

            return ListView.separated(
              itemCount: handovers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final handover = handovers[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          handover.serveurName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Montant déclaré : ${handover.declaredAmount.toStringAsFixed(0)} FCFA',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Paiements inclus : ${handover.paymentIds.length}',
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GeranteHandoverDetailPage(
                                    handover: handover,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Ouvrir'),
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

class GeranteHandoverDetailPage extends StatefulWidget {
  final ServerHandoverModel handover;

  const GeranteHandoverDetailPage({super.key, required this.handover});

  @override
  State<GeranteHandoverDetailPage> createState() =>
      _GeranteHandoverDetailPageState();
}

class _GeranteHandoverDetailPageState extends State<GeranteHandoverDetailPage> {
  late final TextEditingController validatedAmountController;
  final Set<String> selectedPaymentIds = {};

  final GeranteHandoverService geranteService = GeranteHandoverService();

  @override
  void initState() {
    super.initState();
    validatedAmountController = TextEditingController(
      text: widget.handover.declaredAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    validatedAmountController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;

    final amount = double.tryParse(validatedAmountController.text.trim());
    if (amount == null) return;

    await geranteService.validateSelectedPayments(
      handoverId: widget.handover.id,
      selectedPaymentIds: selectedPaymentIds.toList(),
      validatedAmount: amount,
      managerId: user.uid,
      managerName: user.name,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Commandes validées.')));
  }

  Future<void> _reject() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;

    final amount = double.tryParse(validatedAmountController.text.trim());
    if (amount == null) return;

    await geranteService.rejectSelectedPayments(
      handoverId: widget.handover.id,
      selectedPaymentIds: selectedPaymentIds.toList(),
      validatedAmount: amount,
      managerId: user.uid,
      managerName: user.name,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Commandes rejetées.')));
  }

  @override
  Widget build(BuildContext context) {
    final pdfService = context.read<PdfService>();
    final printerService = context.read<PrinterService>();

    return Scaffold(
      appBar: AppBar(title: Text('Versement - ${widget.handover.serveurName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Montant déclaré : ${widget.handover.declaredAmount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: validatedAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant constaté',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<List<PaymentModel>>(
                    future: geranteService.getPaymentsForHandover(
                      widget.handover.paymentIds,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur: ${snapshot.error}'));
                      }

                      final payments = snapshot.data ?? [];

                      if (payments.isEmpty) {
                        return const Center(
                          child: Text('Aucun paiement trouvé.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          final alreadyValidated = widget
                              .handover
                              .validatedPaymentIds
                              .contains(payment.id);
                          final alreadyRejected = widget
                              .handover
                              .rejectedPaymentIds
                              .contains(payment.id);

                          return CheckboxListTile(
                            value: selectedPaymentIds.contains(payment.id),
                            onChanged: (alreadyValidated || alreadyRejected)
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedPaymentIds.add(payment.id);
                                      } else {
                                        selectedPaymentIds.remove(payment.id);
                                      }
                                    });
                                  },
                            title: Text(payment.orderNumber),
                            subtitle: Text(
                              '${payment.method} • ${payment.amount.toStringAsFixed(0)} FCFA'
                              '${alreadyValidated ? " • déjà validée" : ""}'
                              '${alreadyRejected ? " • rejetée" : ""}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: selectedPaymentIds.isEmpty ? null : _reject,
                    child: const Text('Rejeter sélection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedPaymentIds.isEmpty ? null : _validate,
                    child: const Text('Valider sélection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final payments = await geranteService
                          .getPaymentsForHandover(widget.handover.paymentIds);

                      final bytes = await pdfService.buildManagerValidationPdf(
                        handover: widget.handover,
                        payments: payments,
                      );

                      await printerService.printPdf(Uint8List.fromList(bytes));
                    },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
