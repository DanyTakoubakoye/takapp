import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/comptabilite_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/manager_transfer_model.dart';
import 'package:takapp/services/comptabilite_service.dart';

class ReceptionVersementsPage extends StatelessWidget {
  const ReceptionVersementsPage({super.key});

  // `status` reste la valeur technique stockée : seul le rendu est localisé,
  // et un statut inconnu est affiché tel quel.
  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.statusPending;
      case 'declared':
        return l10n.statusDeclared;
      case 'received':
        return l10n.statusReceived;
      case 'validated':
        return l10n.statusValidated;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final comptaService = context.read<ComptabiliteService>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    if (user.establishmentId.trim().isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    final establishmentId = user.establishmentId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.establishmentName.trim().isNotEmpty
              ? '${user.establishmentName} - ${l10n.actionReceiveHandovers}'
              : l10n.actionReceiveHandovers,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<ManagerTransferModel>>(
          stream: comptaService.streamPendingTransfers(
            establishmentId: establishmentId,
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

            final transfers = snapshot.data ?? [];

            if (transfers.isEmpty) {
              return Center(child: Text(l10n.noHandoverAwaitingReception));
            }

            return ListView.separated(
              itemCount: transfers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final transfer = transfers[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                          l10n.amountLine(transfer.amount.toStringAsFixed(0)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.statusLine(
                            _statusLabel(l10n, transfer.status),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final controller = context
                                  .read<ComptabiliteController>();

                              final success = await controller
                                  .confirmTransferReception(
                                    establishmentId: establishmentId,
                                    transferId: transfer.id,
                                    accountingId: user.uid,
                                    accountingName: user.name,
                                  );

                              if (!context.mounted) return;

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.receptionConfirmed),
                                  ),
                                );
                              } else if (controller.hasError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      controller.errorText(l10n)!,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(l10n.actionConfirmReception),
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
