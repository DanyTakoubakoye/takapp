import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/shift_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_policy.dart';
import 'package:takapp/services/shift_service.dart';
import 'package:takapp/vues/gerante/shift_management_page.dart';

/// « Gérer mon service » (14A) : le Floor Manager crée, ouvre, ajuste et
/// clôture SON service. Mêmes composants (formulaire, carte) et même
/// `ShiftService` que la gérante ; le Floor Manager est toujours lui-même
/// (jamais choisi) et ne rouvre pas un service terminé.
class FloorManagerShiftPage extends StatefulWidget {
  const FloorManagerShiftPage({super.key});

  @override
  State<FloorManagerShiftPage> createState() => _FloorManagerShiftPageState();
}

class _FloorManagerShiftPageState extends State<FloorManagerShiftPage> {
  late final String _establishmentId;
  late final UserModel? _me;
  late final Stream<List<ShiftModel>> _shiftsStream;
  late final Future<List<UserModel>> _serversFuture;
  late final Future<List<UserModel>> _receiversFuture;

  @override
  void initState() {
    super.initState();
    _me = context.read<AuthController>().currentUser;
    _establishmentId = _me?.establishmentId ?? '';
    final service = context.read<ShiftService>();
    _shiftsStream = service.streamShiftsOfFloorManager(
      establishmentId: _establishmentId,
      floorManagerId: _me?.uid ?? '',
    );
    _serversFuture = service.fetchServers(_establishmentId);
    _receiversFuture = service.fetchCashReceivers(_establishmentId);
  }

  void _report(bool ok) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final controller = context.read<ShiftController>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.shiftSaved
              : (controller.errorText(l10n) ?? l10n.errUnknown),
        ),
      ),
    );
  }

  Future<void> _create(
    List<UserModel> servers,
    List<UserModel> receivers,
  ) async {
    final me = _me;
    if (me == null) return;
    final draft = await showDialog<ShiftDraft>(
      context: context,
      builder: (_) => ShiftFormDialog(
        staff: servers,
        establishmentId: _establishmentId,
        fixedFloorManager: me,
        cashReceivers: receivers,
      ),
    );
    if (draft == null || !mounted) return;

    final ok = await context.read<ShiftController>().createShift(
      establishmentId: _establishmentId,
      // Toujours lui-même : jamais un autre Floor Manager.
      floorManager: me,
      servers: draft.servers,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      createdBy: me.uid,
      createdByName: me.name,
      createdByRole: me.role,
      cashReceiver: draft.cashReceiver,
    );
    _report(ok);
  }

  Future<void> _edit(ShiftModel shift, List<UserModel> servers) async {
    final draft = await showDialog<ShiftDraft>(
      context: context,
      builder: (_) => ShiftFormDialog(
        staff: servers,
        establishmentId: _establishmentId,
        editing: shift,
        fixedFloorManager: _me,
      ),
    );
    if (draft == null || !mounted) return;

    final controller = context.read<ShiftController>();
    var ok = await controller.updateServers(
      establishmentId: _establishmentId,
      shiftId: shift.id,
      servers: draft.servers,
      userId: _me?.uid ?? '',
      actingFloorManagerId: _me?.uid,
    );
    if (ok &&
        ShiftPolicy.canEditSchedule(shift) &&
        (draft.startsAt != shift.startsAt || draft.endsAt != shift.endsAt)) {
      ok = await controller.updateSchedule(
        establishmentId: _establishmentId,
        shiftId: shift.id,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
      );
    }
    _report(ok);
  }

  Future<void> _open(ShiftModel shift) async {
    final ok = await context.read<ShiftController>().openShift(
      establishmentId: _establishmentId,
      shiftId: shift.id,
      userId: _me?.uid ?? '',
      actingFloorManagerId: _me?.uid,
    );
    _report(ok);
  }

  Future<void> _close(ShiftModel shift) async {
    final ok = await context.read<ShiftController>().closeShift(
      establishmentId: _establishmentId,
      shiftId: shift.id,
      userId: _me?.uid ?? '',
    );
    _report(ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSubmitting = context.watch<ShiftController>().isSubmitting;

    return FutureBuilder<List<List<UserModel>>>(
      future: Future.wait([_serversFuture, _receiversFuture]),
      builder: (context, staffSnap) {
        final servers = staffSnap.data?[0] ?? const <UserModel>[];
        final receivers = staffSnap.data?[1] ?? const <UserModel>[];

        return Scaffold(
          appBar: AppBar(title: Text(l10n.fmShiftTitle)),
          floatingActionButton: FloatingActionButton.extended(
            key: const ValueKey('fm-shift-create'),
            onPressed: staffSnap.hasData && !isSubmitting
                ? () => _create(servers, receivers)
                : null,
            icon: const Icon(Icons.add),
            label: Text(l10n.shiftCreateTitle),
          ),
          body: StreamBuilder<List<ShiftModel>>(
            stream: _shiftsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(l10n.errUnknown));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final shifts = snapshot.data!;
              if (shifts.isEmpty) {
                return Center(child: Text(l10n.shiftNoShifts));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                itemCount: shifts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final shift = shifts[index];
                  return ShiftCard(
                    shift: shift,
                    enabled: !isSubmitting,
                    asManager: false,
                    onOpen: () => _open(shift),
                    onClose: () => _close(shift),
                    onEditServers: () => _edit(shift, servers),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
