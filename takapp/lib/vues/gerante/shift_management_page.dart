import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/shift_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_policy.dart';
import 'package:takapp/services/shift_service.dart';
import 'package:takapp/vues/gerante/shift_closure_page.dart';

/// Gestion minimale des services (shifts) : création, choix du Floor
/// Manager et des serveurs, ouverture, clôture, réouverture.
///
/// Réservée aux rôles `AppRoles.canManageShifts` (gérante, propriétaire,
/// administrateurs). Les règles Firestore restent l'autorité.
class ShiftManagementPage extends StatefulWidget {
  final String establishmentId;

  const ShiftManagementPage({super.key, required this.establishmentId});

  @override
  State<ShiftManagementPage> createState() => _ShiftManagementPageState();
}

class _ShiftManagementPageState extends State<ShiftManagementPage> {
  late final Stream<List<ShiftModel>> _shiftsStream;
  late Future<List<UserModel>> _staffFuture;

  @override
  void initState() {
    super.initState();
    final service = context.read<ShiftService>();
    _shiftsStream = service.streamShifts(widget.establishmentId);
    _staffFuture = service.fetchStaff(widget.establishmentId);
  }

  String get _userId => context.read<AuthController>().currentUserId;

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

  Future<void> _create(List<UserModel> staff) async {
    final draft = await showDialog<ShiftDraft>(
      context: context,
      builder: (_) => ShiftFormDialog(
        staff: staff,
        establishmentId: widget.establishmentId,
      ),
    );
    if (draft == null || !mounted) return;

    final ok = await context.read<ShiftController>().createShift(
      establishmentId: widget.establishmentId,
      floorManager: draft.floorManager,
      servers: draft.servers,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      createdBy: _userId,
      createdByName: context.read<AuthController>().currentUser?.name ?? '',
      createdByRole: context.read<AuthController>().currentUser?.role ?? '',
    );
    _report(ok);
  }

  Future<void> _editServers(ShiftModel shift, List<UserModel> staff) async {
    final draft = await showDialog<ShiftDraft>(
      context: context,
      builder: (_) => ShiftFormDialog(
        staff: staff,
        establishmentId: widget.establishmentId,
        editing: shift,
      ),
    );
    if (draft == null || !mounted) return;

    final controller = context.read<ShiftController>();
    var ok = await controller.updateServers(
      establishmentId: widget.establishmentId,
      shiftId: shift.id,
      servers: draft.servers,
      userId: _userId,
    );
    if (ok &&
        ShiftPolicy.canEditSchedule(shift) &&
        (draft.startsAt != shift.startsAt || draft.endsAt != shift.endsAt)) {
      ok = await controller.updateSchedule(
        establishmentId: widget.establishmentId,
        shiftId: shift.id,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
      );
    }
    _report(ok);
  }

  Future<void> _open(ShiftModel shift) async {
    final ok = await context.read<ShiftController>().openShift(
      establishmentId: widget.establishmentId,
      shiftId: shift.id,
      userId: _userId,
    );
    _report(ok);
  }

  Future<void> _close(ShiftModel shift) async {
    final ok = await context.read<ShiftController>().closeShift(
      establishmentId: widget.establishmentId,
      shiftId: shift.id,
      userId: _userId,
    );
    _report(ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSubmitting = context.watch<ShiftController>().isSubmitting;

    return FutureBuilder<List<UserModel>>(
      future: _staffFuture,
      builder: (context, staffSnap) {
        final staff = staffSnap.data ?? const <UserModel>[];

        return Scaffold(
          appBar: AppBar(title: Text(l10n.shiftsTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: staffSnap.hasData && !isSubmitting
                ? () => _create(staff)
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
                    onOpen: () => _open(shift),
                    onClose: () => _close(shift),
                    onEditServers: () => _editServers(shift, staff),
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

String _statusLabel(ShiftStatus status, AppLocalizations l10n) {
  return switch (status) {
    ShiftStatus.planned => l10n.shiftStatusPlanned,
    ShiftStatus.open => l10n.shiftStatusOpen,
    ShiftStatus.closed => l10n.shiftStatusClosed,
  };
}

final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

class ShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final bool enabled;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onEditServers;

  /// Gérante / propriétaire (true) ou Floor Manager de ce service (14A) :
  /// le Floor Manager ne rouvre jamais un service terminé et consulte la
  /// clôture financière sans la décider.
  final bool asManager;

  const ShiftCard({
    super.key,
    required this.shift,
    required this.enabled,
    required this.onOpen,
    required this.onClose,
    required this.onEditServers,
    this.asManager = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canOpen =
        (asManager
            ? ShiftPolicy.canTransition(shift.status, ShiftStatus.open)
            : ShiftPolicy.canFloorManagerTransition(
                shift.status,
                ShiftStatus.open,
              )) &&
        !shift.isFinanciallyReconciled;
    final canClose = ShiftPolicy.canTransition(
      shift.status,
      ShiftStatus.closed,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shift.floorManagerName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_statusLabel(shift.status, l10n))),
                if (shift.isFinanciallyReconciled) ...[
                  const SizedBox(width: 4),
                  Chip(label: Text(l10n.finStatusReconciled)),
                ],
              ],
            ),
            Text(
              '${_dateTimeFormat.format(shift.startsAt)} → '
              '${_dateTimeFormat.format(shift.endsAt)}',
            ),
            Text(l10n.shiftServersCount(shift.serverIds.length)),
            Wrap(
              spacing: 8,
              children: [
                if (!shift.isClosed)
                  TextButton.icon(
                    onPressed: enabled ? onEditServers : null,
                    icon: const Icon(Icons.group_outlined),
                    label: Text(l10n.shiftActionEditServers),
                  ),
                if (canOpen)
                  FilledButton.icon(
                    onPressed: enabled ? onOpen : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      shift.isClosed
                          ? l10n.shiftActionReopen
                          : l10n.shiftActionOpen,
                    ),
                  ),
                if (canClose)
                  OutlinedButton.icon(
                    onPressed: enabled ? onClose : null,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.shiftActionClose),
                  ),
                // Clôture financière (13B), distincte de la fermeture.
                if (shift.isClosed)
                  TextButton.icon(
                    key: ValueKey('shift-closure-${shift.id}'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftClosurePage(
                          establishmentId: shift.establishmentId,
                          shiftId: shift.id,
                          asManager: asManager,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(l10n.closureTitle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShiftDraft {
  final UserModel? floorManager;
  final List<UserModel> servers;
  final DateTime startsAt;
  final DateTime endsAt;

  /// Destinataire des remises (service créé par un Floor Manager, 14A).
  final UserModel? cashReceiver;

  const ShiftDraft({
    required this.floorManager,
    required this.servers,
    required this.startsAt,
    required this.endsAt,
    this.cashReceiver,
  });
}

/// Création d'un service, ou modification de ses serveurs ([editing]) et,
/// tant qu'il est planifié, de ses horaires.
///
/// Réutilisé par le Floor Manager (14A) : [fixedFloorManager] remplace le
/// choix du Floor Manager (toujours lui-même) et [cashReceivers] propose le
/// destinataire de ses remises.
/// Seuls les comptes éligibles (`ShiftPolicy`) sont proposés.
class ShiftFormDialog extends StatefulWidget {
  final List<UserModel> staff;
  final String establishmentId;
  final ShiftModel? editing;
  final UserModel? fixedFloorManager;
  final List<UserModel>? cashReceivers;

  const ShiftFormDialog({
    super.key,
    required this.staff,
    required this.establishmentId,
    this.editing,
    this.fixedFloorManager,
    this.cashReceivers,
  });

  @override
  State<ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<ShiftFormDialog> {
  late final List<UserModel> _floorManagers;
  late final List<UserModel> _servers;

  UserModel? _floorManager;
  UserModel? _cashReceiver;
  final Set<String> _selectedServerIds = {};
  late DateTime _startsAt;
  late DateTime _endsAt;

  bool get _isEditing => widget.editing != null;

  /// Horaires : à la création, ou tant que le service est planifié.
  bool get _canEditSchedule {
    final editing = widget.editing;
    return editing == null || ShiftPolicy.canEditSchedule(editing);
  }

  bool get _needsReceiver => widget.cashReceivers != null && !_isEditing;

  @override
  void initState() {
    super.initState();

    _floorManagers = widget.staff
        .where(
          (u) => ShiftPolicy.isEligibleFloorManager(u, widget.establishmentId),
        )
        .toList();
    _servers = widget.staff
        .where((u) => ShiftPolicy.isEligibleServer(u, widget.establishmentId))
        .toList();

    final editing = widget.editing;
    if (editing != null) {
      _selectedServerIds.addAll(editing.serverIds);
      _startsAt = editing.startsAt;
      _endsAt = editing.endsAt;
    } else {
      final now = DateTime.now();
      _startsAt = DateTime(now.year, now.month, now.day, now.hour);
      _endsAt = _startsAt.add(const Duration(hours: 8));
      if (_floorManagers.length == 1) _floorManager = _floorManagers.first;
      _floorManager = widget.fixedFloorManager ?? _floorManager;
      final receivers = widget.cashReceivers ?? const <UserModel>[];
      if (receivers.length == 1) _cashReceiver = receivers.first;
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        _isEditing ? l10n.shiftEditServersTitle : l10n.shiftCreateTitle,
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEditing && widget.fixedFloorManager == null) ...[
                if (_floorManagers.isEmpty)
                  Text(l10n.shiftNoFloorManagerAvailable)
                else
                  DropdownButtonFormField<String>(
                    initialValue: _floorManager?.uid,
                    decoration: InputDecoration(
                      labelText: l10n.shiftFloorManagerLabel,
                    ),
                    items: _floorManagers
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.uid,
                            child: Text(u.name.isEmpty ? u.email : u.name),
                          ),
                        )
                        .toList(),
                    onChanged: (uid) => setState(() {
                      _floorManager = _floorManagers
                          .where((u) => u.uid == uid)
                          .firstOrNull;
                    }),
                  ),
                const SizedBox(height: 12),
              ],
              if (_needsReceiver) ...[
                if (widget.cashReceivers!.isEmpty)
                  Text(l10n.shiftNoCashReceiver)
                else
                  DropdownButtonFormField<String>(
                    key: const ValueKey('shift-cash-receiver'),
                    initialValue: _cashReceiver?.uid,
                    decoration: InputDecoration(
                      labelText: l10n.shiftCashReceiverLabel,
                    ),
                    items: widget.cashReceivers!
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.uid,
                            child: Text(u.name.isEmpty ? u.email : u.name),
                          ),
                        )
                        .toList(),
                    onChanged: (uid) => setState(() {
                      _cashReceiver = widget.cashReceivers!
                          .where((u) => u.uid == uid)
                          .firstOrNull;
                    }),
                  ),
                const SizedBox(height: 12),
              ],
              if (_canEditSchedule) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.shiftStartsAtLabel),
                  subtitle: Text(_dateTimeFormat.format(_startsAt)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await _pickDateTime(_startsAt);
                    if (picked == null) return;
                    setState(() {
                      _startsAt = picked;
                      _endsAt = ShiftPolicy.normalizeEnd(_startsAt, _endsAt);
                    });
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.shiftEndsAtLabel),
                  subtitle: Text(_dateTimeFormat.format(_endsAt)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await _pickDateTime(_endsAt);
                    if (picked == null) return;
                    // 18:00 -> 02:00 : fin le lendemain, jamais « avant ».
                    setState(
                      () =>
                          _endsAt = ShiftPolicy.normalizeEnd(_startsAt, picked),
                    );
                  },
                ),
                const Divider(),
              ],
              Text(
                l10n.shiftServersLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_servers.isEmpty) Text(l10n.shiftNoServerAvailable),
              ..._servers.map(
                (server) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedServerIds.contains(server.uid),
                  title: Text(server.name.isEmpty ? server.email : server.name),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedServerIds.add(server.uid);
                    } else {
                      _selectedServerIds.remove(server.uid);
                    }
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const ValueKey('shift-form-submit'),
          onPressed: _needsReceiver && _cashReceiver == null
              ? null
              : () => Navigator.pop(
                  context,
                  ShiftDraft(
                    floorManager: _floorManager,
                    servers: _servers
                        .where((s) => _selectedServerIds.contains(s.uid))
                        .toList(),
                    startsAt: _startsAt,
                    endsAt: _endsAt,
                    cashReceiver: _cashReceiver,
                  ),
                ),
          child: Text(_isEditing ? l10n.actionSave : l10n.actionCreate),
        ),
      ],
    );
  }
}
