import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/client_model.dart';
import 'package:takapp/modeles/reservation_model.dart';
import 'package:takapp/modeles/room_type_model.dart';
import 'package:takapp/services/client_service.dart';
import 'package:takapp/services/reservation_service.dart';
import 'package:takapp/services/room_type_service.dart';
import 'package:takapp/vues/gerante/facturation_chambre_page.dart';
import 'package:takapp/modeles/room_model.dart';

class ReservationsPage extends StatefulWidget {
  final String establishmentId;

  const ReservationsPage({super.key, required this.establishmentId});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final ReservationService _service = ReservationService();
  final RoomTypeService _typeService = RoomTypeService();

  final DateFormat _df = DateFormat('dd/MM/yyyy');

  // Créés une seule fois : recréés dans build(), ils relanceraient
  // l'abonnement à chaque rebuild et remettraient l'écran en chargement.
  late final Stream<List<RoomTypeModel>> _roomTypesStream;
  late final Stream<List<ReservationModel>> _reservationsStream;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();
    _roomTypesStream = _typeService.streamRoomTypes(
      establishmentId: establishmentId,
    );
    _reservationsStream = _service.streamReservations(
      establishmentId: establishmentId,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Les statuts sont des valeurs techniques stockées en base : seul leur
  /// libellé est traduit.
  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'confirmed':
        return l10n.reservationStatusConfirmed;
      case 'checked_in':
        return l10n.reservationStatusCheckedIn;
      case 'checked_out':
        return l10n.reservationStatusCheckedOut;
      case 'cancelled':
        return l10n.reservationStatusCancelled;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'checked_in':
        return Colors.green;
      case 'checked_out':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _openEditForm(ReservationModel resa) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditReservationDialog(
        establishmentId: establishmentId,
        service: _service,
        reservation: resa,
        onDone: _showMessage,
      ),
    );
  }

  Future<void> _openForm(List<RoomTypeModel> types) async {
    if (types.isEmpty) {
      _showMessage(AppLocalizations.of(context).createRoomTypeFirst);
      return;
    }

    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    await showDialog<void>(
      context: context,
      builder: (_) => _ReservationFormDialog(
        establishmentId: establishmentId,
        service: _service,
        types: types,
        createdBy: user?.uid ?? '',
        createdByName: user?.name ?? '',
        onDone: _showMessage,
      ),
    );
  }

  Future<void> _confirmCancel(ReservationModel resa) async {
    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelReservationConfirmTitle),
        content: Text(l10n.cancelReservationConfirmBody(resa.clientName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionBack),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionCancelReservation),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.cancelReservation(
        establishmentId: establishmentId,
        reservationId: resa.id,
      );
      _showMessage(l10n.reservationCancelled);
    } catch (e) {
      _showMessage(l10n.errorPrefixed(localizedError(l10n, e)));
    }
  }

  Future<void> _doCheckIn(ReservationModel resa) async {
    final l10n = AppLocalizations.of(context);

    // Charger les chambres libres du type réservé
    List<RoomModel> rooms;
    try {
      rooms = await _service.availableRoomsOfType(
        establishmentId: establishmentId,
        roomTypeId: resa.roomTypeId,
      );
    } catch (e) {
      _showMessage(l10n.errorPrefixed(localizedError(l10n, e)));
      return;
    }

    if (rooms.isEmpty) {
      _showMessage(l10n.noFreeRoomOfType(resa.roomTypeName));
      return;
    }

    if (!mounted) return;

    // Sélecteur de chambre
    final selected = await showModalBottomSheet<RoomModel>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.assignRoomTo(resa.clientName),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...rooms.map((room) {
                return ListTile(
                  leading: const Icon(Icons.meeting_room, color: Colors.green),
                  title: Text(l10n.labelRoom(room.number)),
                  subtitle: Text(
                    room.floor.isNotEmpty
                        ? l10n.floorLabel(room.floor)
                        : room.roomTypeName,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, room);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    try {
      await _service.checkIn(
        establishmentId: establishmentId,
        reservationId: resa.id,
        roomId: selected.id,
        roomNumber: selected.number,
      );
      if (!mounted) return;
      _showMessage(l10n.checkInDone(selected.number));
    } catch (e) {
      if (!mounted) return;
      _showMessage(l10n.errorPrefixed(localizedError(l10n, e)));
    }
  }

  Future<void> _doCheckOut(ReservationModel resa) async {
    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.checkOutTitle),
        content: Text(
          l10n.checkOutConfirmBody(
            resa.clientName,
            resa.assignedRoomNumber,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionConfirmDeparture),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.checkOut(
        establishmentId: establishmentId,
        reservationId: resa.id,
      );
      if (!mounted) return;
      _showMessage(l10n.checkOutDone);

      // Proposer la facturation (optionnelle)
      _proposeFacturation(resa);
    } catch (e) {
      _showMessage(l10n.errorPrefixed(localizedError(l10n, e)));
    }
  }

  Future<void> _proposeFacturation(ReservationModel resa) async {
    final l10n = AppLocalizations.of(context);

    final goToBilling = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.billStayTitle),
        content: Text(l10n.billStayBody(resa.clientName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionLater),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionBill),
          ),
        ],
      ),
    );

    if (goToBilling == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FacturationChambrePage(
            establishmentId: establishmentId,
            reservation: resa,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return StreamBuilder<List<RoomTypeModel>>(
      stream: _roomTypesStream,
      builder: (context, typesSnapshot) {
        final types = typesSnapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(title: Text(l10n.tileReservationsTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(types),
            icon: const Icon(Icons.add),
            label: Text(l10n.newReservation),
          ),
          body: StreamBuilder<List<ReservationModel>>(
            stream: _reservationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: SelectableText(
                    l10n.errorPrefixed('${snapshot.error}'),
                  ),
                );
              }

              final reservations = snapshot.data ?? [];

              if (reservations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.noReservation,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final resa = reservations[index];
                  final color = _statusColor(resa.status);
                  final dates =
                      (resa.checkInDate != null && resa.checkOutDate != null)
                      ? '${_df.format(resa.checkInDate!)} → ${_df.format(resa.checkOutDate!)}'
                      : '-';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(Icons.event_available, color: color),
                      ),
                      title: Text(
                        resa.clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${resa.roomTypeName}'
                        '${resa.assignedRoomNumber.isNotEmpty ? l10n.roomShortSuffix(resa.assignedRoomNumber) : ''}'
                        '\n$dates · ${l10n.nightsCount('${resa.numberOfNights}')}'
                        '\n${resa.roomTotal.toStringAsFixed(0)} FCFA · ${_statusLabel(l10n, resa.status)}',
                      ),
                      isThreeLine: true,
                      trailing: _buildTrailing(l10n, resa),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget? _buildTrailing(AppLocalizations l10n, ReservationModel resa) {
    if (resa.status == 'confirmed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () => _doCheckIn(resa),
            icon: const Icon(Icons.login, size: 18),
            label: Text(l10n.actionCheckIn),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _openEditForm(resa);
              if (value == 'cancel') _confirmCancel(resa);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
              PopupMenuItem(value: 'cancel', child: Text(l10n.commonCancel)),
            ],
          ),
        ],
      );
    }

    if (resa.status == 'checked_in') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () => _doCheckOut(resa),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l10n.checkOutTitle),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _openEditForm(resa);
              if (value == 'bill') _proposeFacturation(resa);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
              PopupMenuItem(value: 'bill', child: Text(l10n.actionBill)),
            ],
          ),
        ],
      );
    }

    return null;
  }
}

class _ReservationFormDialog extends StatefulWidget {
  final String establishmentId;
  final ReservationService service;
  final List<RoomTypeModel> types;
  final String createdBy;
  final String createdByName;
  final void Function(String message) onDone;

  const _ReservationFormDialog({
    required this.establishmentId,
    required this.service,
    required this.types,
    required this.createdBy,
    required this.createdByName,
    required this.onDone,
  });

  @override
  State<_ReservationFormDialog> createState() => _ReservationFormDialogState();
}

class _EditReservationDialog extends StatefulWidget {
  final String establishmentId;
  final ReservationService service;
  final ReservationModel reservation;
  final void Function(String message) onDone;

  const _EditReservationDialog({
    required this.establishmentId,
    required this.service,
    required this.reservation,
    required this.onDone,
  });

  @override
  State<_EditReservationDialog> createState() => _EditReservationDialogState();
}

class _EditReservationDialogState extends State<_EditReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ifuController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late final TextEditingController _checkInController;
  late final TextEditingController _checkOutController;

  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.reservation;
    _nameController = TextEditingController(text: r.clientName);
    _phoneController = TextEditingController(text: r.clientPhone);
    _ifuController = TextEditingController(text: r.clientIfu);
    _priceController = TextEditingController(
      text: r.pricePerNight.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: r.note);
    _checkIn = r.checkInDate;
    _checkOut = r.checkOutDate;
    _checkInController = TextEditingController(
      text: r.checkInDate != null ? _df.format(r.checkInDate!) : '',
    );
    _checkOutController = TextEditingController(
      text: r.checkOutDate != null ? _df.format(r.checkOutDate!) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ifuController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  DateTime? _parseDate(String text) {
    if (text.length != 10) return null;
    try {
      final d = _df.parseStrict(text);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<DateTime?> onParsed,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [_DateSlashFormatter()],
      maxLength: 10,
      decoration: InputDecoration(
        labelText: label,
        hintText: AppLocalizations.of(context).dateHintDdMmYyyy,
        counterText: '',
      ),
      validator: (v) {
        final l10n = AppLocalizations.of(context);
        final text = (v ?? '').trim();
        if (text.isEmpty) return l10n.fieldRequired;
        return _parseDate(text) == null ? l10n.invalidDate : null;
      },
      onChanged: (value) => onParsed(_parseDate(value.trim())),
    );
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDateRange: (_checkIn != null && _checkOut != null)
          ? DateTimeRange(start: _checkIn!, end: _checkOut!)
          : null,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() {
        _checkIn = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _checkOut = DateTime(picked.end.year, picked.end.month, picked.end.day);
        _checkInController.text = _df.format(_checkIn!);
        _checkOutController.text = _df.format(_checkOut!);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    if (_checkIn == null || _checkOut == null) {
      widget.onDone(l10n.pickStayDates);
      return;
    }
    if (!_checkOut!.isAfter(_checkIn!)) {
      widget.onDone(l10n.errCheckOutAfterCheckIn);
      return;
    }

    setState(() => _isSaving = true);

    final price =
        double.tryParse(_priceController.text.trim()) ??
        widget.reservation.pricePerNight;

    try {
      await widget.service.updateReservation(
        establishmentId: widget.establishmentId,
        reservationId: widget.reservation.id,
        clientName: _nameController.text.trim(),
        clientPhone: _phoneController.text.trim(),
        clientIfu: _ifuController.text.trim(),
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        pricePerNight: price,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDone(l10n.reservationUpdated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onDone(l10n.errorPrefixed(localizedError(l10n, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final price =
        double.tryParse(_priceController.text.trim()) ??
        widget.reservation.pricePerNight;
    final total = _nights > 0 ? price * _nights : 0;

    return AlertDialog(
      title: Text(l10n.editReservationTitle),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.reservation.roomTypeName}'
                  '${widget.reservation.assignedRoomNumber.isNotEmpty ? l10n.roomShortSuffix(widget.reservation.assignedRoomNumber) : ''}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.clientNameLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.fieldRequired
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneOptionalLabel,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ifuController,
                  decoration: InputDecoration(
                    labelText: l10n.ifuOptionalLabel,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDateField(
                        controller: _checkInController,
                        label: l10n.labelArrival,
                        onParsed: (d) => setState(() => _checkIn = d),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDateField(
                        controller: _checkOutController,
                        label: l10n.labelDeparture,
                        onParsed: (d) => setState(() => _checkOut = d),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.pickFromCalendar,
                      onPressed: _pickDates,
                      icon: const Icon(Icons.date_range),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.pricePerNightShortLabel,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteOptionalLabel,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                if (_nights > 0)
                  Text(
                    l10n.totalWithNights(
                      total.toStringAsFixed(0),
                      '$_nights',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? l10n.savingInProgress : l10n.actionSave),
        ),
      ],
    );
  }
}

class _ReservationFormDialogState extends State<_ReservationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ifuController;
  late final TextEditingController _guestsController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late final TextEditingController _checkInController;
  late final TextEditingController _checkOutController;

  final ClientService _clientService = ClientService();

  String? _selectedTypeId;
  DateTime? _checkIn;
  DateTime? _checkOut;

  /// Fiche client rattachée. Vide = réservation à la volée (walk-in).
  String _selectedClientId = '';
  String _selectedClientName = '';

  bool _isSaving = false;

  // Disponibilité
  bool _checkingAvailability = false;
  int? _availableCount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _ifuController = TextEditingController();
    _guestsController = TextEditingController(text: '1');
    _priceController = TextEditingController();
    _noteController = TextEditingController();
    _checkInController = TextEditingController();
    _checkOutController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ifuController.dispose();
    _guestsController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  RoomTypeModel? get _selectedType {
    if (_selectedTypeId == null) return null;
    try {
      return widget.types.firstWhere((t) => t.id == _selectedTypeId);
    } catch (_) {
      return null;
    }
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  /// Sélection d'une fiche client existante.
  ///
  /// PIÈGE : le sheet doit être fermé avec `Navigator.pop(sheetContext, valeur)`.
  /// `Navigator.of(sheetContext).pop(...)` remonte au mauvais Navigator et
  /// le panneau ne se ferme pas (bug déjà rencontré sur ce projet).
  Future<void> _pickClient() async {
    final selected = await showModalBottomSheet<ClientModel>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ClientPickerSheet(
        establishmentId: widget.establishmentId,
        service: _clientService,
      ),
    );

    if (!mounted) return;
    if (selected == null) return;

    setState(() {
      _selectedClientId = selected.id;
      _selectedClientName = selected.name;

      // Pré-remplissage : les champs restent librement modifiables.
      _nameController.text = selected.name;
      _phoneController.text = selected.phone;
      _ifuController.text = selected.ifu;
    });
  }

  /// Détache la fiche sans vider les champs déjà saisis.
  void _detachClient() {
    setState(() {
      _selectedClientId = '';
      _selectedClientName = '';
    });
  }

  Widget _buildClientSelector() {
    final l10n = AppLocalizations.of(context);

    if (_selectedClientId.isEmpty) {
      return OutlinedButton.icon(
        onPressed: _pickClient,
        icon: const Icon(Icons.person_search),
        label: Text(l10n.chooseExistingClient),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.attachedClient(_selectedClientName),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: l10n.detachRecord,
            icon: const Icon(Icons.close, size: 18),
            onPressed: _detachClient,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month - 1, now.day),
      lastDate: DateTime(now.year + 2),
      initialDateRange: (_checkIn != null && _checkOut != null)
          ? DateTimeRange(start: _checkIn!, end: _checkOut!)
          : null,
      // La saisie clavier du picker Material n'ouvre qu'un pavé numérique
      // (pas de « / ») : on la désactive ici, les champs texte du formulaire
      // gèrent la frappe avec insertion automatique des séparateurs.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() {
        _checkIn = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _checkOut = DateTime(picked.end.year, picked.end.month, picked.end.day);
        _checkInController.text = _df.format(_checkIn!);
        _checkOutController.text = _df.format(_checkOut!);
      });
      _refreshAvailability();
    }
  }

  /// Convertit « jj/mm/aaaa » en date, ou `null` si la saisie est incomplète
  /// ou invalide (31/02/2026 est refusé grâce à `parseStrict`).
  DateTime? _parseDate(String text) {
    if (text.length != 10) return null;
    try {
      final d = _df.parseStrict(text);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<DateTime?> onParsed,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [_DateSlashFormatter()],
      maxLength: 10,
      decoration: InputDecoration(
        labelText: label,
        hintText: AppLocalizations.of(context).dateHintDdMmYyyy,
        counterText: '',
      ),
      validator: (v) {
        final text = (v ?? '').trim();
        if (text.isEmpty) return null;
        return _parseDate(text) == null
            ? AppLocalizations.of(context).invalidDate
            : null;
      },
      onChanged: (value) => onParsed(_parseDate(value.trim())),
    );
  }

  void _onTypeChanged(String? value) {
    setState(() {
      _selectedTypeId = value;
      // Pré-remplir le prix depuis le type
      final t = _selectedType;
      if (t != null && _priceController.text.trim().isEmpty) {
        _priceController.text = t.basePrice.toStringAsFixed(0);
      }
    });
    _refreshAvailability();
  }

  Future<void> _refreshAvailability() async {
    final type = _selectedType;
    if (type == null || _checkIn == null || _checkOut == null) {
      setState(() => _availableCount = null);
      return;
    }
    if (!_checkOut!.isAfter(_checkIn!)) {
      setState(() => _availableCount = null);
      return;
    }

    setState(() {
      _checkingAvailability = true;
      _availableCount = null;
    });

    try {
      final count = await widget.service.availableCountForType(
        establishmentId: widget.establishmentId,
        roomTypeId: type.id,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
      );
      if (!mounted) return;
      setState(() => _availableCount = count);
    } catch (e) {
      if (!mounted) return;
      setState(() => _availableCount = null);
    } finally {
      if (mounted) setState(() => _checkingAvailability = false);
    }
  }

  Future<void> _save({bool force = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    if (_selectedType == null) {
      widget.onDone(l10n.pickRoomType);
      return;
    }
    if (_checkIn == null || _checkOut == null) {
      widget.onDone(l10n.pickStayDates);
      return;
    }

    setState(() => _isSaving = true);

    final type = _selectedType!;
    final price =
        double.tryParse(_priceController.text.trim()) ?? type.basePrice;
    final guests = int.tryParse(_guestsController.text.trim()) ?? 1;

    try {
      await widget.service.createReservation(
        establishmentId: widget.establishmentId,
        clientId: _selectedClientId,
        clientName: _nameController.text.trim(),
        clientPhone: _phoneController.text.trim(),
        clientIfu: _ifuController.text.trim(),
        clientAddress: '',
        roomTypeId: type.id,
        roomTypeName: type.name,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        numberOfGuests: guests,
        pricePerNight: price,
        note: _noteController.text.trim(),
        createdBy: widget.createdBy,
        createdByName: widget.createdByName,
        force: force,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDone(l10n.reservationCreated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      // Si le type est complet, proposer de forcer. On teste le CODE de
      // l'erreur et non son texte : la détection se faisait auparavant sur
      // la chaîne française, ce qui cessait de fonctionner en anglais.
      final isTypeFull =
          e is AppError && e.code == AppErrorCode.noRoomOfTypeAvailable;

      if (!force && isTypeFull) {
        _proposeForce();
      } else {
        widget.onDone(l10n.errorPrefixed(localizedError(l10n, e)));
      }
    }
  }

  Future<void> _proposeForce() async {
    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.typeFullTitle),
        content: Text(l10n.typeFullBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionNo),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionForce),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _save(force: true);
    }
  }

  Widget _buildAvailabilityHint() {
    final l10n = AppLocalizations.of(context);

    if (_checkingAvailability) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(l10n.checkingAvailability),
          ],
        ),
      );
    }

    if (_availableCount == null) return const SizedBox.shrink();

    final complete = _availableCount! <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            complete ? Icons.block : Icons.check_circle,
            color: complete ? Colors.red : Colors.green,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              complete
                  ? l10n.typeFullOnPeriod
                  : l10n.roomsAvailableCount('$_availableCount'),
              style: TextStyle(
                color: complete ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = _selectedType;
    final total = (type != null && _nights > 0)
        ? (double.tryParse(_priceController.text.trim()) ?? type.basePrice) *
              _nights
        : 0;

    return AlertDialog(
      title: Text(l10n.newReservation),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildClientSelector(),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.clientNameLabel),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.fieldRequired
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneOptionalLabel,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ifuController,
                  decoration: InputDecoration(
                    labelText: l10n.ifuOptionalLabel,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTypeId,
                  decoration: InputDecoration(labelText: l10n.roomTypeLabel),
                  items: widget.types
                      .map(
                        (t) => DropdownMenuItem<String>(
                          value: t.id,
                          child: Text(
                            l10n.roomTypeOption(
                              t.name,
                              t.basePrice.toStringAsFixed(0),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _onTypeChanged,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.chooseRoomType : null,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDateField(
                        controller: _checkInController,
                        label: l10n.labelArrival,
                        onParsed: (d) {
                          setState(() => _checkIn = d);
                          _refreshAvailability();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDateField(
                        controller: _checkOutController,
                        label: l10n.labelDeparture,
                        onParsed: (d) {
                          setState(() => _checkOut = d);
                          _refreshAvailability();
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.pickFromCalendar,
                      onPressed: _pickDates,
                      icon: const Icon(Icons.date_range),
                    ),
                  ],
                ),
                _buildAvailabilityHint(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guestsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.guestsLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.pricePerNightShortLabel,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteOptionalLabel,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                if (_nights > 0)
                  Text(
                    l10n.totalWithNights(
                      total.toStringAsFixed(0),
                      '$_nights',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : () => _save(),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? l10n.creatingInProgress : l10n.actionCreate),
        ),
      ],
    );
  }
}

/// Insère automatiquement les « / » pendant la frappe d'une date (jj/mm/aaaa).
///
/// PIÈGE : le pavé numérique des téléphones n'expose pas le caractère « / »,
/// la date était donc impossible à saisir au clavier. Ici l'utilisateur tape
/// « 27072026 » et le champ affiche « 27/07/2026 ». Les séparateurs collés/
/// tapés à la main sont ignorés puis réinsérés au bon endroit.
class _DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(capped[i]);
    }
    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Sélecteur de fiche client (panneau modal).
///
/// Le stream renvoie tous les clients actifs et le filtrage est local :
/// aucune requête Firestore n'est relancée à chaque frappe.
class _ClientPickerSheet extends StatefulWidget {
  final String establishmentId;
  final ClientService service;

  const _ClientPickerSheet({
    required this.establishmentId,
    required this.service,
  });

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  // Créé une seule fois : chaque frappe dans la recherche déclenche un
  // setState, et un stream recréé remettrait la liste en chargement.
  late final Stream<List<ClientModel>> _clientsStream;

  @override
  void initState() {
    super.initState();
    _clientsStream = widget.service.streamClients(
      establishmentId: widget.establishmentId,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClientModel> _filter(List<ClientModel> clients) {
    final query = _query.trim();

    if (query.isEmpty) return clients;

    final lowerQuery = query.toLowerCase();

    return clients.where((client) {
      return client.name.toLowerCase().contains(lowerQuery) ||
          client.phone.contains(query);
    }).toList();
  }

  String _subtitle(ClientModel client) {
    final parts = <String>[];

    if (client.phone.isNotEmpty) parts.add(client.phone);

    if (client.ifu.isNotEmpty) {
      parts.add(AppLocalizations.of(context).ifuPrefix(client.ifu));
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Text(
              l10n.chooseClient,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.searchLabel,
                  hintText: l10n.searchNameOrPhoneHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ClientModel>>(
                stream: _clientsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: SelectableText(
                        l10n.errorPrefixed('${snapshot.error}'),
                      ),
                    );
                  }

                  final clients = snapshot.data ?? [];

                  if (clients.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.noClientRecord,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final filtered = _filter(clients);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.noClientMatches,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = filtered[index];

                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_subtitle(client)),
                        // Navigator.pop(sheetContext, ...) et surtout PAS
                        // Navigator.of(sheetContext).pop(...) : voir _pickClient.
                        onTap: () => Navigator.pop(sheetContext, client),
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
