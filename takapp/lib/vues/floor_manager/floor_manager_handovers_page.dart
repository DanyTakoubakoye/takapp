import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/services/handover_ledger.dart';
import 'package:takapp/services/shift_handover_service.dart';
import 'package:takapp/vues/serveur/shift_handover_page.dart';

/// Remises des serveurs du service du Floor Manager (ouvert OU clôturé, pour
/// finaliser après la clôture) : situation par serveur, puis remises à
/// valider / rejeter. Les règles Firestore limitent tout à SON service.
class FloorManagerHandoversPage extends StatefulWidget {
  const FloorManagerHandoversPage({super.key});

  @override
  State<FloorManagerHandoversPage> createState() =>
      _FloorManagerHandoversPageState();
}

class _FloorManagerHandoversPageState extends State<FloorManagerHandoversPage> {
  late final String _establishmentId;
  late final Future<ShiftModel?> _shiftFuture;
  Future<List<ShiftParticipantModel>>? _participantsFuture;
  Stream<List<PaymentModel>>? _paymentsStream;
  Stream<List<ServerHandoverModel>>? _handoversStream;
  bool _isSubmitting = false;

  ShiftHandoverService get _service => context.read<ShiftHandoverService>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _establishmentId = user?.establishmentId ?? '';
    _shiftFuture = _service.lastShiftOfFloorManager(
      _establishmentId,
      user?.uid ?? '',
    );
  }

  void _initStreams(ShiftModel shift) {
    final fmId = context.read<AuthController>().currentUserId;
    _participantsFuture ??= _service.shiftParticipants(
      establishmentId: _establishmentId,
      shiftId: shift.id,
    );
    _paymentsStream ??= _service.streamShiftPayments(
      establishmentId: _establishmentId,
      shiftId: shift.id,
    );
    _handoversStream ??= _service.streamHandoversForFloorManager(
      establishmentId: _establishmentId,
      floorManagerId: fmId,
      shiftId: shift.id,
    );
  }

  Future<void> _decide(ServerHandoverModel handover, bool validate) async {
    final l10n = AppLocalizations.of(context);
    final fm = context.read<AuthController>().currentUser;
    if (fm == null) return;

    setState(() => _isSubmitting = true);
    String message;
    try {
      if (validate) {
        await _service.validate(
          establishmentId: _establishmentId,
          handover: handover,
          floorManager: fm,
        );
        message = l10n.fmHandoverValidated;
      } else {
        await _service.reject(
          establishmentId: _establishmentId,
          handover: handover,
          floorManager: fm,
        );
        message = l10n.fmHandoverRejected;
      }
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
    final fmId = context.watch<AuthController>().currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fmHandoversTitle)),
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
          _initStreams(shift);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (shift.isClosed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.handoverShiftClosedNote),
                ),
              Text(
                l10n.fmHandoversReport,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<ShiftParticipantModel>>(
                future: _participantsFuture,
                builder: (context, partSnap) {
                  final names = <String, String>{
                    for (final p
                        in partSnap.data ?? const <ShiftParticipantModel>[])
                      p.serverId: p.serverName,
                  };
                  return StreamBuilder<List<PaymentModel>>(
                    stream: _paymentsStream,
                    builder: (context, paySnap) {
                      if (!paySnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final balances = HandoverLedger.balancesForShift(
                        shiftId: shift.id,
                        payments: paySnap.data!,
                        names: names,
                        // Le Floor Manager ne se remet pas à lui-même.
                        excludeCashierIds: {fmId},
                      );
                      return Column(
                        children: [
                          for (final balance in balances)
                            CashBalanceCard(
                              key: ValueKey('balance-${balance.cashierId}'),
                              balance: balance,
                              showName: true,
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.fmHandoversPendingTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<ServerHandoverModel>>(
                stream: _handoversStream,
                builder: (context, snap) {
                  final pending = (snap.data ?? const [])
                      .where((h) => h.isOpen)
                      .toList();
                  if (pending.isEmpty) return Text(l10n.fmHandoversNone);
                  return Column(
                    children: [
                      for (final handover in pending)
                        _HandoverCard(
                          key: ValueKey('handover-${handover.id}'),
                          handover: handover,
                          enabled: !_isSubmitting,
                          onValidate: () => _decide(handover, true),
                          onReject: () => _decide(handover, false),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HandoverCard extends StatelessWidget {
  final ServerHandoverModel handover;
  final bool enabled;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  const _HandoverCard({
    super.key,
    required this.handover,
    required this.enabled,
    required this.onValidate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = handover.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              handover.senderUserName ?? handover.serveurName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text('${handover.declaredAmount.toStringAsFixed(0)} FCFA'),
            if (date != null) Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
            for (final entry in handover.paymentBreakdown.entries)
              Text(
                '  • ${l10n.handoverAmountLine(AppPaymentMethods.label(l10n, entry.key), entry.value.toStringAsFixed(0))}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: ValueKey('handover-validate-${handover.id}'),
                  onPressed: enabled ? onValidate : null,
                  child: Text(l10n.fmHandoverValidate),
                ),
                OutlinedButton(
                  key: ValueKey('handover-reject-${handover.id}'),
                  onPressed: enabled ? onReject : null,
                  child: Text(l10n.fmHandoverReject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
