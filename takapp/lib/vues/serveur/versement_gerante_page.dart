import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/handover_controller.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/services/handover_service.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';

class VersementGerantePage extends StatelessWidget {
  final String establishmentId;

  const VersementGerantePage({super.key, required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final handoverService = context.read<HandoverService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Versement à la gérante')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 520,
                    child: _PendingPaymentsSection(
                      establishmentId: establishmentId,
                      serveurId: user.uid,
                      serveurName: user.name,
                      handoverService: handoverService,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 520,
                    child: _HandoverHistorySection(
                      establishmentId: establishmentId,
                      serveurId: user.uid,
                      handoverService: handoverService,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _PendingPaymentsSection(
                    establishmentId: establishmentId,
                    serveurId: user.uid,
                    serveurName: user.name,
                    handoverService: handoverService,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _HandoverHistorySection(
                    establishmentId: establishmentId,
                    serveurId: user.uid,
                    handoverService: handoverService,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingPaymentsSection extends StatelessWidget {
  final String establishmentId;
  final String serveurId;
  final String serveurName;
  final HandoverService handoverService;

  const _PendingPaymentsSection({
    required this.establishmentId,
    required this.serveurId,
    required this.serveurName,
    required this.handoverService,
  });

  @override
  Widget build(BuildContext context) {
    final handoverController = context.watch<HandoverController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                Text(
                  'Paiements à verser',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (handoverController.selectedPayments.isNotEmpty)
                  Text(
                    'Sélection : ${handoverController.selectedTotal.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<PaymentModel>>(
                stream: handoverService.streamUnhandedPaymentsForServer(
                  establishmentId: establishmentId,
                  serveurId: serveurId,
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
                      child: Text('Aucun paiement disponible pour versement.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final selected = handoverController.isSelected(
                        payment.id,
                      );

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: CheckboxListTile(
                          value: selected,
                          onChanged: (_) {
                            context.read<HandoverController>().togglePayment(
                              payment,
                            );
                          },
                          title: Text(
                            payment.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${payment.method} • ${payment.amount.toStringAsFixed(0)} FCFA',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool smallButtons = constraints.maxWidth < 500;

                Future<void> submit() async {
                  final success = await context
                      .read<HandoverController>()
                      .submitHandover(
                        establishmentId: establishmentId,
                        serveurId: serveurId,
                        serveurName: serveurName,
                      );

                  if (!context.mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Versement déclaré avec succès.'),
                      ),
                    );
                  } else if (handoverController.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(handoverController.errorMessage!)),
                    );
                  }
                }

                if (smallButtons) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: handoverController.isSubmitting
                            ? null
                            : () => context
                                  .read<HandoverController>()
                                  .clearSelection(),
                        child: const Text('Vider la sélection'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: handoverController.isSubmitting
                            ? null
                            : submit,
                        child: handoverController.isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Déclarer le versement'),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: handoverController.isSubmitting
                            ? null
                            : () => context
                                  .read<HandoverController>()
                                  .clearSelection(),
                        child: const Text('Vider la sélection'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: handoverController.isSubmitting
                            ? null
                            : submit,
                        child: handoverController.isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Déclarer le versement'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HandoverHistorySection extends StatelessWidget {
  final String establishmentId;
  final String serveurId;
  final HandoverService handoverService;

  const _HandoverHistorySection({
    required this.establishmentId,
    required this.serveurId,
    required this.handoverService,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'validated':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historique des versements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<ServerHandoverModel>>(
                stream: handoverService.streamServerHandovers(
                  establishmentId: establishmentId,
                  serveurId: serveurId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final handovers = snapshot.data ?? [];

                  if (handovers.isEmpty) {
                    return const Center(
                      child: Text('Aucun versement enregistré.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: handovers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final handover = handovers[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${handover.declaredAmount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Paiements inclus : ${handover.paymentIds.length}',
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  handover.status,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(handover.status),
                                style: TextStyle(
                                  color: _statusColor(handover.status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final handoverService = context
                                      .read<HandoverService>();
                                  final pdfService = context.read<PdfService>();
                                  final printerService = context
                                      .read<PrinterService>();

                                  final payments = await handoverService
                                      .getPaymentsByIds(
                                        establishmentId: establishmentId,
                                        paymentIds: handover.paymentIds,
                                      );

                                  final bytes = await pdfService
                                      .buildServerHandoverPdf(
                                        establishmentName: "TAKHOTEL",
                                        handover: handover,
                                        payments: payments,
                                      );

                                  await printerService.printPdf(
                                    Uint8List.fromList(bytes),
                                  );
                                },
                                icon: const Icon(Icons.print_outlined),
                                label: const Text('Imprimer'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
