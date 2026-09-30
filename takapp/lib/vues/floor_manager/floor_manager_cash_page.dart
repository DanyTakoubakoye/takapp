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
import 'package:takapp/services/handover_ledger.dart';
import 'package:takapp/services/shift_handover_service.dart';

/// « Ma caisse » du Floor Manager (12B) : ce qu'il détient pour un service
/// (encaissements directs + remises serveurs validées), ce qu'il a déjà
/// remis, et la remise du reste à la gérante du service. Tous ses services
/// restent accessibles : la finalisation financière survit à la clôture.
class FloorManagerCashPage extends StatefulWidget {
  const FloorManagerCashPage({super.key});

  @override
  State<FloorManagerCashPage> createState() => _FloorManagerCashPageState();
}

class _FloorManagerCashPageState extends State<FloorManagerCashPage> {
  late final String _establishmentId;
  late final String _fmId;
  late final Stream<List<ShiftModel>> _shiftsStream;
  String? _shiftId;
  Stream<List<PaymentModel>>? _paymentsStream;
  Stream<List<ServerHandoverModel>>? _transfersStream;
  final Map<String, TextEditingController> _amounts = {};
  final TextEditingController _comment = TextEditingController();
  bool _isSubmitting = false;

  ShiftHandoverService get _service => context.read<ShiftHandoverService>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _establishmentId = user?.establishmentId ?? '';
    _fmId = user?.uid ?? '';
    _shiftsStream = _service.streamFloorManagerShifts(
      establishmentId: _establishmentId,
      floorManagerId: _fmId,
    );
  }

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    _comment.dispose();
    super.dispose();
  }

  void _selectShift(String shiftId) {
    if (_shiftId == shiftId) return;
    _shiftId = shiftId;
    _paymentsStream = _service.streamShiftPayments(
      establishmentId: _establishmentId,
      shiftId: shiftId,
    );
    _transfersStream = _service.streamTransfersOfFloorManager(
      establishmentId: _establishmentId,
      floorManagerId: _fmId,
      shiftId: shiftId,
    );
    for (final c in _amounts.values) {
      c.dispose();
    }
    _amounts.clear();
  }

  /// Champs pré-remplis avec le reste par moyen ; mis à jour tant que
  /// l'utilisateur ne les a pas modifiés.
  TextEditingController _amountField(String method, double remaining) {
    final value = remaining.toStringAsFixed(0);
    final controller = _amounts.putIfAbsent(
      method,
      () => TextEditingController(text: value),
    );
    return controller;
  }

  double _enteredTotal() => _amounts.values.fold<double>(
    0,
    (sum, c) => sum + (double.tryParse(c.text.replaceAll(' ', '')) ?? 0),
  );

  Future<void> _send(ShiftModel shift, FloorManagerCash cash) async {
    final l10n = AppLocalizations.of(context);
    final fm = context.read<AuthController>().currentUser;
    if (fm == null) return;

    final breakdown = <String, double>{
      for (final entry in _amounts.entries)
        entry.key: double.tryParse(entry.value.text.replaceAll(' ', '')) ?? -1,
    };

    setState(() => _isSubmitting = true);
    String message;
    try {
      await _service.transferToReceiver(
        establishmentId: _establishmentId,
        sender: fm,
        shift: shift,
        cash: cash,
        breakdown: breakdown,
        comment: _comment.text,
      );
      message = l10n.fmCashSent;
      _comment.clear();
      for (final c in _amounts.values) {
        c.dispose();
      }
      _amounts.clear();
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
      appBar: AppBar(title: Text(l10n.fmCashTitle)),
      body: StreamBuilder<List<ShiftModel>>(
        stream: _shiftsStream,
        builder: (context, shiftsSnap) {
          if (shiftsSnap.hasError) {
            return Center(child: Text(localizedError(l10n, shiftsSnap.error)));
          }
          if (!shiftsSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shifts = shiftsSnap.data!;
          if (shifts.isEmpty) {
            return Center(child: Text(l10n.handoverNoShift));
          }
          final shift = shifts.firstWhere(
            (s) => s.id == _shiftId,
            orElse: () => shifts.first,
          );
          _selectShift(shift.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                key: const ValueKey('fm-cash-shift'),
                initialValue: shift.id,
                decoration: InputDecoration(labelText: l10n.fmCashShiftLabel),
                items: [
                  for (final s in shifts)
                    DropdownMenuItem(value: s.id, child: Text(shiftRange(s))),
                ],
                onChanged: (id) {
                  if (id != null) setState(() => _selectShift(id));
                },
              ),
              if (shift.isClosed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.handoverShiftClosedNote),
                ),
              const SizedBox(height: 12),
              StreamBuilder<List<PaymentModel>>(
                stream: _paymentsStream,
                builder: (context, paySnap) {
                  return StreamBuilder<List<ServerHandoverModel>>(
                    stream: _transfersStream,
                    builder: (context, trSnap) {
                      final error = paySnap.error ?? trSnap.error;
                      if (error != null) {
                        return Text(localizedError(l10n, error));
                      }
                      if (!paySnap.hasData || !trSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final cash = FloorManagerLedger.cashOf(
                        floorManagerId: _fmId,
                        shiftId: shift.id,
                        payments: paySnap.data!,
                        transfers: trSnap.data!,
                      );
                      return _content(l10n, shift, cash, trSnap.data!);
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(
    AppLocalizations l10n,
    ShiftModel shift,
    FloorManagerCash cash,
    List<ServerHandoverModel> transfers,
  ) {
    String fcfa(double v) => v.toStringAsFixed(0);
    final receiver = shift.createdByName.isNotEmpty
        ? shift.createdByName
        : l10n.fmCashReceiverDefault;
    final methods = cash.remainingByMethod.entries
        .where((e) => e.value > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
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
                  l10n.handoverAmountLine(l10n.fmCashDirect, fcfa(cash.direct)),
                ),
                Text(
                  l10n.handoverAmountLine(
                    l10n.fmCashFromServers,
                    fcfa(cash.fromServers),
                  ),
                ),
                Text(
                  l10n.handoverAmountLine(
                    l10n.fmCashTransferred,
                    fcfa(cash.transferValidated),
                  ),
                ),
                if (cash.transferPending > 0)
                  Text(
                    l10n.handoverAmountLine(
                      l10n.fmCashTransferPending,
                      fcfa(cash.transferPending),
                    ),
                  ),
                Text(
                  l10n.handoverAmountLine(
                    l10n.handoverRemaining,
                    fcfa(cash.remaining),
                  ),
                  key: const ValueKey('fm-cash-remaining'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (methods.isEmpty)
          Text(l10n.handoverNothingToHand)
        else ...[
          Text(
            l10n.fmCashAmountsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final entry in methods)
            TextField(
              key: ValueKey('fm-cash-amount-${entry.key}'),
              controller: _amountField(entry.key, entry.value),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: AppPaymentMethods.label(l10n, entry.key),
                helperText: l10n.handoverAmountLine(
                  l10n.handoverRemaining,
                  fcfa(entry.value),
                ),
              ),
            ),
          TextField(
            controller: _comment,
            decoration: InputDecoration(labelText: l10n.fmCashComment),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const ValueKey('fm-cash-send'),
            onPressed: _isSubmitting ? null : () => _send(shift, cash),
            icon: const Icon(Icons.send),
            label: Text(l10n.handoverSendTo(fcfa(_enteredTotal()), receiver)),
          ),
        ],
        const SizedBox(height: 20),
        if (transfers.isNotEmpty) ...[
          Text(
            l10n.fmCashHistory,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final t in transfers) TransferTile(transfer: t),
        ],
      ],
    );
  }
}

String shiftRange(ShiftModel shift) {
  final day = DateFormat('dd/MM/yyyy');
  final time = DateFormat('HH:mm');
  return '${day.format(shift.startsAt)} ${time.format(shift.startsAt)} - '
      '${time.format(shift.endsAt)}';
}

String transferStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'pending':
      return l10n.transferStatusPending;
    case 'validated':
      return l10n.transferStatusValidated;
    case 'rejected':
      return l10n.transferStatusRejected;
    default:
      return status;
  }
}

/// Ligne d'historique d'une remise Floor Manager -> gérante.
class TransferTile extends StatelessWidget {
  final ServerHandoverModel transfer;
  final Widget? trailing;

  const TransferTile({super.key, required this.transfer, this.trailing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String fcfa(double v) => v.toStringAsFixed(0);
    final date = transfer.createdAt == null
        ? ''
        : DateFormat('dd/MM HH:mm').format(transfer.createdAt!);
    final details = [
      for (final e in transfer.paymentBreakdown.entries)
        l10n.handoverAmountLine(
          AppPaymentMethods.label(l10n, e.key),
          fcfa(e.value),
        ),
      if ((transfer.difference ?? 0) != 0)
        l10n.fmTransferDifference(fcfa(transfer.difference!)),
      if ((transfer.comment ?? '').isNotEmpty) transfer.comment!,
      if ((transfer.decisionComment ?? '').isNotEmpty)
        transfer.decisionComment!,
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${fcfa(transfer.declaredAmount)} FCFA • '
        '${transferStatusLabel(l10n, transfer.status)}',
      ),
      subtitle: Text([date, ...details].where((s) => s.isNotEmpty).join('\n')),
      trailing: trailing,
    );
  }
}
