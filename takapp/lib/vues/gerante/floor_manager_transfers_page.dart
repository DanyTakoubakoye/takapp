import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/services/handover_ledger.dart';
import 'package:takapp/services/shift_handover_service.dart';
import 'package:takapp/vues/floor_manager/floor_manager_cash_page.dart';

/// Remises des Floor Managers à la gérante (12B). Toutes sont visibles ;
/// seules celles qui lui sont destinées peuvent être validées ou rejetées
/// (règles Firestore). La validation saisit le montant physiquement
/// compté : l'écart est tracé, le montant déclaré ne change jamais.
class FloorManagerTransfersPage extends StatefulWidget {
  final String establishmentId;

  const FloorManagerTransfersPage({super.key, required this.establishmentId});

  @override
  State<FloorManagerTransfersPage> createState() =>
      _FloorManagerTransfersPageState();
}

class _FloorManagerTransfersPageState extends State<FloorManagerTransfersPage> {
  late final Stream<List<ServerHandoverModel>> _stream;
  final Map<String, Future<ShiftModel?>> _shifts = {};
  bool _isSubmitting = false;

  ShiftHandoverService get _service => context.read<ShiftHandoverService>();

  @override
  void initState() {
    super.initState();
    _stream = _service.streamAllFloorManagerTransfers(
      establishmentId: widget.establishmentId,
    );
  }

  Future<ShiftModel?> _shift(String shiftId) => _shifts.putIfAbsent(
    shiftId,
    () => _service.shiftById(widget.establishmentId, shiftId),
  );

  Future<void> _decide(ServerHandoverModel transfer, bool validate) async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    final decision = await showDialog<_Decision>(
      context: context,
      builder: (_) => _DecisionDialog(transfer: transfer, validate: validate),
    );
    if (decision == null || !mounted) return;

    setState(() => _isSubmitting = true);
    String message;
    try {
      if (validate) {
        await _service.validateTransfer(
          establishmentId: widget.establishmentId,
          transfer: transfer,
          receiver: user,
          physicalAmount: decision.physicalAmount,
          comment: decision.comment,
        );
        message = l10n.fmTransferValidated;
      } else {
        await _service.rejectTransfer(
          establishmentId: widget.establishmentId,
          transfer: transfer,
          receiver: user,
          comment: decision.comment,
        );
        message = l10n.fmTransferRejected;
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
    final me = context.watch<AuthController>().currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fmTransfersTitle)),
      body: StreamBuilder<List<ServerHandoverModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(localizedError(l10n, snap.error)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final transfers = [...snap.data!]
            ..sort(
              (a, b) =>
                  (a.status == 'pending' ? 0 : 1) -
                  (b.status == 'pending' ? 0 : 1),
            );
          if (transfers.isEmpty) {
            return Center(child: Text(l10n.fmTransfersNone));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transfers.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final t = transfers[index];
              final mine = t.status == 'pending' && t.receiverUserId == me;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.senderUserName ?? t.serveurName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FutureBuilder<ShiftModel?>(
                    future: _shift(t.shiftId ?? ''),
                    builder: (context, s) => Text(
                      s.data == null
                          ? ''
                          : l10n.reconShift(shiftRange(s.data!)),
                    ),
                  ),
                  TransferTile(transfer: t),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (mine) ...[
                        ElevatedButton(
                          key: ValueKey('fm-transfer-validate-${t.id}'),
                          onPressed: _isSubmitting
                              ? null
                              : () => _decide(t, true),
                          child: Text(l10n.fmHandoverValidate),
                        ),
                        OutlinedButton(
                          key: ValueKey('fm-transfer-reject-${t.id}'),
                          onPressed: _isSubmitting
                              ? null
                              : () => _decide(t, false),
                          child: Text(l10n.fmHandoverReject),
                        ),
                      ],
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShiftReconciliationPage(
                              establishmentId: widget.establishmentId,
                              shiftId: t.shiftId ?? '',
                            ),
                          ),
                        ),
                        child: Text(l10n.reconTitle),
                      ),
                    ],
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

class _Decision {
  final double physicalAmount;
  final String comment;

  const _Decision(this.physicalAmount, this.comment);
}

class _DecisionDialog extends StatefulWidget {
  final ServerHandoverModel transfer;
  final bool validate;

  const _DecisionDialog({required this.transfer, required this.validate});

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  late final TextEditingController _counted = TextEditingController(
    text: widget.transfer.declaredAmount.toStringAsFixed(0),
  );
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _counted.dispose();
    _comment.dispose();
    super.dispose();
  }

  double? get _countedValue =>
      double.tryParse(_counted.text.replaceAll(' ', ''));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counted = _countedValue;
    final difference = counted == null
        ? null
        : counted - widget.transfer.declaredAmount;

    return AlertDialog(
      title: Text(
        widget.validate ? l10n.fmTransferValidateTitle : l10n.fmHandoverReject,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.validate) ...[
            TextField(
              key: const ValueKey('fm-transfer-counted'),
              controller: _counted,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.fmTransferCounted),
              onChanged: (_) => setState(() {}),
            ),
            if (difference != null && difference != 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.fmTransferDifference(difference.toStringAsFixed(0)),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
          TextField(
            controller: _comment,
            decoration: InputDecoration(
              labelText: l10n.fmTransferDecisionComment,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          key: const ValueKey('fm-transfer-confirm'),
          onPressed: widget.validate && (counted == null || counted < 0)
              ? null
              : () => Navigator.pop(
                  context,
                  _Decision(counted ?? 0, _comment.text),
                ),
          child: Text(
            widget.validate ? l10n.fmHandoverValidate : l10n.fmHandoverReject,
          ),
        ),
      ],
    );
  }
}

/// Rapprochement financier d'un service (vue gérante), enregistré dans
/// `accountClosures` avec `scope: shift`.
class ShiftReconciliationPage extends StatefulWidget {
  final String establishmentId;
  final String shiftId;

  const ShiftReconciliationPage({
    super.key,
    required this.establishmentId,
    required this.shiftId,
  });

  @override
  State<ShiftReconciliationPage> createState() =>
      _ShiftReconciliationPageState();
}

class _ShiftReconciliationPageState extends State<ShiftReconciliationPage> {
  late final Future<ShiftModel?> _shiftFuture;
  late final Stream<List<PaymentModel>> _payments;
  late final Stream<List<ServerHandoverModel>> _transfers;
  TextEditingController? _physical;
  final TextEditingController _comment = TextEditingController();
  bool _isSubmitting = false;

  ShiftHandoverService get _service => context.read<ShiftHandoverService>();

  @override
  void initState() {
    super.initState();
    _shiftFuture = _service.shiftById(widget.establishmentId, widget.shiftId);
    _payments = _service.streamShiftPayments(
      establishmentId: widget.establishmentId,
      shiftId: widget.shiftId,
    );
    _transfers = _service.streamTransfersOfShift(
      establishmentId: widget.establishmentId,
      shiftId: widget.shiftId,
    );
  }

  @override
  void dispose() {
    _physical?.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _record(ShiftModel shift, ShiftReconciliation recon) async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthController>().currentUser;
    final physical = double.tryParse(
      (_physical?.text ?? '').replaceAll(' ', ''),
    );
    if (user == null || physical == null) return;

    setState(() => _isSubmitting = true);
    String message;
    try {
      await _service.recordShiftReconciliation(
        establishmentId: widget.establishmentId,
        shift: shift,
        reconciliation: recon,
        physicalAmount: physical,
        user: user,
        comment: _comment.text,
      );
      message = l10n.reconRecorded;
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
    String fcfa(double v) => v.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reconTitle)),
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
            stream: _payments,
            builder: (context, paySnap) =>
                StreamBuilder<List<ServerHandoverModel>>(
                  stream: _transfers,
                  builder: (context, trSnap) {
                    final error = paySnap.error ?? trSnap.error;
                    if (error != null) {
                      return Center(child: Text(localizedError(l10n, error)));
                    }
                    if (!paySnap.hasData || !trSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final recon = FloorManagerLedger.reconcile(
                      floorManagerId: shift.floorManagerId,
                      shiftId: shift.id,
                      payments: paySnap.data!,
                      transfers: trSnap.data!,
                    );
                    _physical ??= TextEditingController(
                      text: fcfa(recon.physicalReceived),
                    );
                    Widget line(String label, double v, {bool bold = false}) =>
                        Text(
                          l10n.handoverAmountLine(label, fcfa(v)),
                          style: bold
                              ? const TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        );

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          l10n.reconFloorManager(shift.floorManagerName),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(l10n.reconShift(shiftRange(shift))),
                        if (shift.isOpen) Text(l10n.reconOpenShiftNote),
                        const Divider(),
                        line(l10n.reconFmDirect, recon.floorManagerDirect),
                        line(
                          l10n.reconServersCollected,
                          recon.serversCollected,
                        ),
                        line(l10n.reconServersHanded, recon.serversHandedOver),
                        line(
                          l10n.reconTransfersValidated,
                          recon.transfersValidated,
                        ),
                        line(
                          l10n.reconTransfersPending,
                          recon.transfersPending,
                        ),
                        line(l10n.reconStillHeld, recon.stillHeld, bold: true),
                        const Divider(),
                        line(l10n.reconTheoretical, recon.theoretical),
                        line(l10n.reconPhysical, recon.physicalReceived),
                        line(
                          l10n.reconCountingDifference,
                          recon.countingDifference,
                        ),
                        line(
                          l10n.reconDifference,
                          recon.difference,
                          bold: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _physical,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.reconPhysicalField,
                          ),
                        ),
                        TextField(
                          controller: _comment,
                          decoration: InputDecoration(
                            labelText: l10n.fmTransferDecisionComment,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _record(shift, recon),
                          child: Text(l10n.reconRecord),
                        ),
                      ],
                    );
                  },
                ),
          );
        },
      ),
    );
  }
}
