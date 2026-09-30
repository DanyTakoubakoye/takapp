import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/services/handover_ledger.dart';
import 'package:takapp/services/shift_handover_service.dart';

/// Remise des encaissements d'un service au Floor Manager de ce service.
///
/// Le destinataire vient du service (jamais d'un choix libre). Le dernier
/// service du serveur est utilisé, ouvert OU clôturé : on peut finaliser
/// les remises d'un service terminé.
class ShiftHandoverPage extends StatefulWidget {
  final String establishmentId;

  const ShiftHandoverPage({super.key, required this.establishmentId});

  @override
  State<ShiftHandoverPage> createState() => _ShiftHandoverPageState();
}

class _ShiftHandoverPageState extends State<ShiftHandoverPage> {
  late final Future<ShiftModel?> _shiftFuture;
  Stream<List<PaymentModel>>? _paymentsStream;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthController>().currentUserId;
    _shiftFuture = context.read<ShiftHandoverService>().lastShiftOfServer(
      widget.establishmentId,
      uid,
    );
  }

  Stream<List<PaymentModel>> _paymentsFor(ShiftModel shift) {
    return _paymentsStream ??= context
        .read<ShiftHandoverService>()
        .streamServerShiftPayments(
          establishmentId: widget.establishmentId,
          serverId: context.read<AuthController>().currentUserId,
          shiftId: shift.id,
        );
  }

  Future<void> _handOver(ShiftModel shift, ShiftCashBalance balance) async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    String message;
    try {
      await context.read<ShiftHandoverService>().handOverToFloorManager(
        establishmentId: widget.establishmentId,
        sender: user,
        shift: shift,
        payments: balance.remainingPayments,
      );
      message = l10n.handoverSent;
    } catch (e) {
      message = localizedError(l10n, e);
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.handoverFmTitle)),
      body: FutureBuilder<ShiftModel?>(
        future: _shiftFuture,
        builder: (context, shiftSnap) {
          if (shiftSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final shift = shiftSnap.data;
          if (shift == null) {
            return Center(child: Text(l10n.handoverNoShift));
          }

          return StreamBuilder<List<PaymentModel>>(
            stream: _paymentsFor(shift),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final user = context.read<AuthController>().currentUser;
              final balance = HandoverLedger.balanceFor(
                cashierId: user?.uid ?? '',
                cashierName: user?.name ?? '',
                shiftId: shift.id,
                payments: snap.data!,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (shift.isClosed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l10n.handoverShiftClosedNote),
                    ),
                  CashBalanceCard(balance: balance),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('handover-send'),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(
                      balance.remaining > 0
                          ? l10n.handoverSendTo(
                              balance.remaining.toStringAsFixed(0),
                              shift.floorManagerName,
                            )
                          : l10n.handoverNothingToHand,
                    ),
                    onPressed: balance.remaining > 0 && !_isSubmitting
                        ? () => _handOver(shift, balance)
                        : null,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Encaissé / remis / en attente / reste (et reste par moyen de paiement).
/// Partagé par l'écran du serveur et le rapport du Floor Manager.
class CashBalanceCard extends StatelessWidget {
  final ShiftCashBalance balance;
  final bool showName;

  const CashBalanceCard({
    super.key,
    required this.balance,
    this.showName = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String fcfa(double v) => v.toStringAsFixed(0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showName)
              Text(
                balance.cashierName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            Text(
              l10n.handoverAmountLine(
                l10n.handoverCollected,
                fcfa(balance.collected),
              ),
            ),
            Text(
              l10n.handoverAmountLine(
                l10n.handoverValidated,
                fcfa(balance.validated),
              ),
            ),
            if (balance.declared > 0)
              Text(
                l10n.handoverAmountLine(
                  l10n.handoverAwaitingValidation,
                  fcfa(balance.declared),
                ),
              ),
            Text(
              l10n.handoverAmountLine(
                l10n.handoverRemaining,
                fcfa(balance.remaining),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final entry in balance.remainingByMethod.entries)
              Text(
                '  • ${l10n.handoverAmountLine(AppPaymentMethods.label(l10n, entry.key), fcfa(entry.value))}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
          ],
        ),
      ),
    );
  }
}
