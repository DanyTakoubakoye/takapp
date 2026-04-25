import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/comptabilite_controller.dart';
import 'package:takapp/modeles/manager_transfer_model.dart';
import 'package:takapp/services/comptabilite_service.dart';

class ReceptionVersementsPage extends StatelessWidget {
  const ReceptionVersementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final comptaService = context.read<ComptabiliteService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Réception des versements')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<ManagerTransferModel>>(
          stream: comptaService.streamPendingTransfers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final transfers = snapshot.data ?? [];

            if (transfers.isEmpty) {
              return const Center(
                child: Text('Aucun versement en attente de réception.'),
              );
            }

            return ListView.separated(
              itemCount: transfers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final transfer = transfers[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transfer.serveurName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Montant : ${transfer.amount.toStringAsFixed(0)} FCFA',
                        ),
                        const SizedBox(height: 6),
                        Text('Statut : ${transfer.status}'),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await context
                                  .read<ComptabiliteController>()
                                  .confirmTransferReception(
                                    transferId: transfer.id,
                                    accountingId: user.uid,
                                    accountingName: user.name,
                                  );

                              if (!context.mounted) return;

                              final controller = context
                                  .read<ComptabiliteController>();

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Réception confirmée.'),
                                  ),
                                );
                              } else if (controller.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(controller.errorMessage!),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Confirmer réception'),
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
