import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_discrepancy_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/services/shift_closure_policy.dart';
import 'package:takapp/services/shift_closure_service.dart';
import 'package:takapp/services/shift_handover_service.dart';
import 'package:takapp/vues/floor_manager/floor_manager_cash_page.dart';

String financialStatusLabel(AppLocalizations l10n, ShiftFinancialStatus s) {
  switch (s) {
    case ShiftFinancialStatus.pending:
      return l10n.finStatusPending;
    case ShiftFinancialStatus.ready:
      return l10n.finStatusReady;
    case ShiftFinancialStatus.reconciled:
      return l10n.finStatusReconciled;
    case ShiftFinancialStatus.disputed:
      return l10n.finStatusDisputed;
  }
}

String operationalStatusLabel(AppLocalizations l10n, ShiftStatus s) {
  switch (s) {
    case ShiftStatus.planned:
      return l10n.shiftStatusPlanned;
    case ShiftStatus.open:
      return l10n.shiftStatusOpen;
    case ShiftStatus.closed:
      return l10n.shiftStatusClosed;
  }
}

String closureBlockerLabel(AppLocalizations l10n, ClosureBlocker b) {
  final amount = b.amount.toStringAsFixed(0);
  switch (b.kind) {
    case ClosureBlockerKind.shiftNotClosed:
      return l10n.closureBlockShiftNotClosed;
    case ClosureBlockerKind.serverRemaining:
      return l10n.closureBlockServerRemaining(b.name, amount);
    case ClosureBlockerKind.serverHandoverPending:
      return l10n.closureBlockServerPending(b.name, amount);
    case ClosureBlockerKind.floorManagerRemaining:
      return l10n.closureBlockFmRemaining(amount);
    case ClosureBlockerKind.floorManagerTransferPending:
      return l10n.closureBlockFmPending(amount);
    case ClosureBlockerKind.discrepancyPending:
      return l10n.closureBlockDiscrepancyPending(b.name, amount);
    case ClosureBlockerKind.discrepancyMismatch:
      return l10n.closureBlockDiscrepancyMismatch(b.name, amount);
  }
}

/// Clôture financière d'un service (13B).
///
/// Vue gérante / propriétaire ([asManager]) : décision sur les écarts et
/// clôture finale. Vue Floor Manager : consultation, déclaration d'écarts,
/// jamais de validation ni de clôture (les règles l'interdisent aussi).
class ShiftClosurePage extends StatefulWidget {
  final String establishmentId;
  final String shiftId;
  final bool asManager;

  const ShiftClosurePage({
    super.key,
    required this.establishmentId,
    required this.shiftId,
    required this.asManager,
  });

  @override
  State<ShiftClosurePage> createState() => _ShiftClosurePageState();
}

class _ShiftClosurePageState extends State<ShiftClosurePage> {
  late final Stream<ShiftModel?> _shift;
  late final Stream<List<PaymentModel>> _payments;
  late final Stream<List<ServerHandoverModel>> _transfers;
  late final Stream<List<ShiftDiscrepancyModel>> _discrepancies;
  late final Future<List<ShiftParticipantModel>> _participants;
  bool _isSubmitting = false;

  ShiftClosureService get _closure => context.read<ShiftClosureService>();

  @override
  void initState() {
    super.initState();
    final handovers = context.read<ShiftHandoverService>();
    final uid = context.read<AuthController>().currentUserId;
    final e = widget.establishmentId;
    _shift = _closure.streamShift(e, widget.shiftId);
    _payments = handovers.streamShiftPayments(
      establishmentId: e,
      shiftId: widget.shiftId,
    );
    // Le Floor Manager ne lit que SES remises à la gérante.
    _transfers = widget.asManager
        ? handovers.streamTransfersOfShift(
            establishmentId: e,
            shiftId: widget.shiftId,
          )
        : handovers.streamTransfersOfFloorManager(
            establishmentId: e,
            floorManagerId: uid,
            shiftId: widget.shiftId,
          );
    _discrepancies = _closure.streamDiscrepancies(
      establishmentId: e,
      shiftId: widget.shiftId,
    );
    _participants = handovers.shiftParticipants(
      establishmentId: e,
      shiftId: widget.shiftId,
    );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);
    String message;
    try {
      await action();
      message = success;
    } catch (e) {
      message = localizedError(l10n, e);
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _declare(
    ShiftModel shift,
    ClosureCashierLine line,
    String role,
  ) async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final input = await showDialog<_DiscrepancyInput>(
      context: context,
      builder: (_) => _DiscrepancyDialog(expected: line.unresolved),
    );
    if (input == null || !mounted) return;
    await _run(
      () => _closure.declareDiscrepancy(
        establishmentId: widget.establishmentId,
        shift: shift,
        subjectUserId: line.userId,
        subjectName: line.name,
        subjectRole: role,
        expectedAmount: input.expected,
        physicalAmount: input.physical,
        reason: input.reason,
        recordedBy: user,
      ),
      l10n.discrepancyDeclared,
    );
  }

  Future<void> _decide(ShiftDiscrepancyModel d, bool approve) async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    await _run(
      () => _closure.decideDiscrepancy(
        establishmentId: widget.establishmentId,
        discrepancy: d,
        approve: approve,
        decidedBy: user,
      ),
      approve ? l10n.discrepancyApproved : l10n.discrepancyRejected,
    );
  }

  Future<void> _close() async {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    await _run(
      () => _closure.closeFinancially(
        establishmentId: widget.establishmentId,
        shiftId: widget.shiftId,
        closedBy: user,
      ),
      l10n.closureClosed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.closureTitle)),
      body: StreamBuilder<ShiftModel?>(
        stream: _shift,
        builder: (context, shiftSnap) {
          final shift = shiftSnap.data;
          if (shiftSnap.hasError) {
            return Center(child: Text(localizedError(l10n, shiftSnap.error)));
          }
          if (shift == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<List<ShiftParticipantModel>>(
            future: _participants,
            builder: (context, partSnap) => StreamBuilder<List<PaymentModel>>(
              stream: _payments,
              builder: (context, paySnap) =>
                  StreamBuilder<List<ServerHandoverModel>>(
                    stream: _transfers,
                    builder: (context, trSnap) =>
                        StreamBuilder<List<ShiftDiscrepancyModel>>(
                          stream: _discrepancies,
                          builder: (context, dSnap) {
                            final error =
                                paySnap.error ?? trSnap.error ?? dSnap.error;
                            if (error != null) {
                              return Center(
                                child: Text(localizedError(l10n, error)),
                              );
                            }
                            if (!paySnap.hasData ||
                                !trSnap.hasData ||
                                !dSnap.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final review = ShiftClosurePolicy.review(
                              shift: shift,
                              payments: paySnap.data!,
                              transfers: trSnap.data!,
                              discrepancies: dSnap.data!,
                              serverNames: {
                                for (final p
                                    in partSnap.data ??
                                        const <ShiftParticipantModel>[])
                                  p.serverId: p.serverName,
                              },
                            );
                            return _content(l10n, review);
                          },
                        ),
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(AppLocalizations l10n, ShiftClosureReview review) {
    final shift = review.shift;
    final open = !shift.isFinanciallyReconciled && !_isSubmitting;
    String fcfa(double v) => v.toStringAsFixed(0);
    final title = Theme.of(context).textTheme.titleMedium;

    Widget cashierCard(ClosureCashierLine line, String role, String heldLabel) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name, style: title),
              Text(l10n.handoverAmountLine(heldLabel, fcfa(line.collected))),
              Text(
                l10n.handoverAmountLine(
                  l10n.closureHandedOver,
                  fcfa(line.handedOver),
                ),
              ),
              if (line.pending > 0)
                Text(
                  l10n.handoverAmountLine(
                    l10n.closurePending,
                    fcfa(line.pending),
                  ),
                ),
              if (line.documentedShortage != 0)
                Text(
                  l10n.handoverAmountLine(
                    l10n.closureDocumented,
                    fcfa(line.documentedShortage),
                  ),
                ),
              Text(
                l10n.handoverAmountLine(
                  l10n.handoverRemaining,
                  fcfa(line.remaining),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (open && line.unresolved > ShiftClosurePolicy.epsilon)
                TextButton(
                  key: ValueKey('closure-declare-${line.userId}'),
                  onPressed: () => _declare(shift, line, role),
                  child: Text(l10n.closureDeclareDiscrepancy),
                ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.reconFloorManager(shift.floorManagerName), style: title),
        Text(l10n.reconShift(shiftRange(shift))),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(
                l10n.closureOperational(
                  operationalStatusLabel(l10n, shift.status),
                ),
              ),
            ),
            Chip(
              key: const ValueKey('closure-financial-status'),
              label: Text(
                l10n.closureFinancial(
                  financialStatusLabel(l10n, review.status),
                ),
              ),
            ),
          ],
        ),
        if (shift.isFinanciallyReconciled && shift.financialClosedAt != null)
          Text(
            l10n.closureClosedBy(
              shift.financialClosedByName,
              DateFormat('dd/MM/yyyy HH:mm').format(shift.financialClosedAt!),
            ),
          ),
        const SizedBox(height: 12),
        Text(l10n.closureServersTitle, style: title),
        for (final s in review.servers)
          cashierCard(s, AppRoles.serveur, l10n.handoverCollected),
        const SizedBox(height: 12),
        Text(l10n.closureFmTitle, style: title),
        cashierCard(
          review.floorManager,
          AppRoles.floorManager,
          l10n.closureFmHeld,
        ),
        Text(
          l10n.handoverAmountLine(
            l10n.fmCashDirect,
            fcfa(review.floorManagerCash.direct),
          ),
        ),
        Text(
          l10n.handoverAmountLine(
            l10n.fmCashFromServers,
            fcfa(review.floorManagerCash.fromServers),
          ),
        ),
        if (review.discrepancies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.closureDiscrepanciesTitle, style: title),
          for (final d in review.discrepancies) _discrepancyTile(l10n, d),
        ],
        const Divider(height: 32),
        Text(
          l10n.handoverAmountLine(
            l10n.closureTotalRemaining,
            fcfa(review.totalRemaining),
          ),
        ),
        Text(
          l10n.handoverAmountLine(
            l10n.closureTotalDocumented,
            fcfa(review.documentedShortage),
          ),
        ),
        Text(
          l10n.handoverAmountLine(
            l10n.closureTotalDifference,
            fcfa(review.reconciliation.difference),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (!shift.isFinanciallyReconciled) ...[
          Text(l10n.closureRemainingActions, style: title),
          if (review.blockers.isEmpty)
            Text(l10n.closureAllSettled)
          else
            for (final b in review.blockers)
              Text(
                '• ${closureBlockerLabel(l10n, b)}',
                style: const TextStyle(color: Colors.red),
              ),
          const SizedBox(height: 12),
          if (widget.asManager)
            ElevatedButton(
              key: const ValueKey('closure-close'),
              onPressed: open && review.canClose ? _close : null,
              child: Text(l10n.closureCloseAction),
            )
          else
            Text(l10n.closureFmNote),
        ],
      ],
    );
  }

  Widget _discrepancyTile(AppLocalizations l10n, ShiftDiscrepancyModel d) {
    final status = switch (d.status) {
      ShiftDiscrepancyModel.approvedStatus => l10n.discrepancyStatusApproved,
      ShiftDiscrepancyModel.rejectedStatus => l10n.discrepancyStatusRejected,
      _ => l10n.discrepancyStatusPending,
    };
    final canDecide = widget.asManager && d.isPending && !_isSubmitting;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.discrepancyLine(
          d.subjectName,
          d.expectedAmount.toStringAsFixed(0),
          d.physicalAmount.toStringAsFixed(0),
        ),
      ),
      subtitle: Text('$status\n${d.reason}'),
      trailing: canDecide
          ? Wrap(
              spacing: 4,
              children: [
                IconButton(
                  key: ValueKey('discrepancy-approve-${d.id}'),
                  tooltip: l10n.discrepancyApprove,
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _decide(d, true),
                ),
                IconButton(
                  key: ValueKey('discrepancy-reject-${d.id}'),
                  tooltip: l10n.discrepancyReject,
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _decide(d, false),
                ),
              ],
            )
          : null,
    );
  }
}

class _DiscrepancyInput {
  final double expected;
  final double physical;
  final String reason;

  const _DiscrepancyInput(this.expected, this.physical, this.reason);
}

class _DiscrepancyDialog extends StatefulWidget {
  final double expected;

  const _DiscrepancyDialog({required this.expected});

  @override
  State<_DiscrepancyDialog> createState() => _DiscrepancyDialogState();
}

class _DiscrepancyDialogState extends State<_DiscrepancyDialog> {
  late final TextEditingController _expected = TextEditingController(
    text: widget.expected.toStringAsFixed(0),
  );
  final TextEditingController _physical = TextEditingController(text: '0');
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _expected.dispose();
    _physical.dispose();
    _reason.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(' ', ''));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expected = _parse(_expected);
    final physical = _parse(_physical);
    final valid =
        expected != null &&
        expected > 0 &&
        physical != null &&
        physical >= 0 &&
        physical <= expected &&
        _reason.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(l10n.closureDeclareDiscrepancy),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _expected,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.discrepancyExpected),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _physical,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.discrepancyPhysical),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _reason,
            decoration: InputDecoration(labelText: l10n.discrepancyReason),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: valid
              ? () => Navigator.pop(
                  context,
                  _DiscrepancyInput(expected, physical, _reason.text),
                )
              : null,
          child: Text(l10n.closureDeclareDiscrepancy),
        ),
      ],
    );
  }
}

/// Services du Floor Manager, pour ouvrir leur clôture.
class FloorManagerClosureListPage extends StatelessWidget {
  const FloorManagerClosureListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.read<AuthController>().currentUser;
    final establishmentId = user?.establishmentId ?? '';
    final stream = context
        .read<ShiftHandoverService>()
        .streamFloorManagerShifts(
          establishmentId: establishmentId,
          floorManagerId: user?.uid ?? '',
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.closureTitle)),
      body: StreamBuilder<List<ShiftModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(localizedError(l10n, snap.error)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shifts = snap.data!;
          if (shifts.isEmpty) return Center(child: Text(l10n.handoverNoShift));
          return ListView(
            children: [
              for (final s in shifts)
                ListTile(
                  title: Text(shiftRange(s)),
                  subtitle: Text(
                    '${operationalStatusLabel(l10n, s.status)} • '
                    '${financialStatusLabel(l10n, s.financialStatus)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShiftClosurePage(
                        establishmentId: establishmentId,
                        shiftId: s.id,
                        asManager: false,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
