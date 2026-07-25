import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
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

  String get establishmentId => widget.establishmentId.trim();

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmée';
      case 'checked_in':
        return 'Arrivée';
      case 'checked_out':
        return 'Partie';
      case 'cancelled':
        return 'Annulée';
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

  Future<void> _openForm(List<RoomTypeModel> types) async {
    if (types.isEmpty) {
      _showMessage('Créez d\'abord au moins un type de chambre.');
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler cette réservation ?'),
        content: Text(
          'La réservation de ${resa.clientName} sera marquée annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Annuler la réservation'),
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
      _showMessage('Réservation annulée.');
    } catch (e) {
      _showMessage('Erreur : $e');
    }
  }

  Future<void> _doCheckIn(ReservationModel resa) async {
    // Charger les chambres libres du type réservé
    List<RoomModel> rooms;
    try {
      rooms = await _service.availableRoomsOfType(
        establishmentId: establishmentId,
        roomTypeId: resa.roomTypeId,
      );
    } catch (e) {
      _showMessage('Erreur : $e');
      return;
    }

    if (rooms.isEmpty) {
      _showMessage(
        'Aucune chambre libre pour le type "${resa.roomTypeName}". '
        'Libérez ou préparez une chambre d\'abord.',
      );
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
                  'Attribuer une chambre à ${resa.clientName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...rooms.map((room) {
                return ListTile(
                  leading: const Icon(Icons.meeting_room, color: Colors.green),
                  title: Text('Chambre ${room.number}'),
                  subtitle: Text(
                    room.floor.isNotEmpty
                        ? 'Étage ${room.floor}'
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
      _showMessage('Check-in effectué : chambre ${selected.number}.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('ERREUR CHECK-IN: $e');
    }
  }

  Future<void> _doCheckOut(ReservationModel resa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check-out'),
        content: Text(
          'Confirmer le départ de ${resa.clientName} '
          '(chambre ${resa.assignedRoomNumber}) ?\n\n'
          'La chambre passera "à nettoyer".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmer le départ'),
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
      _showMessage('Check-out effectué.');

      // Proposer la facturation (optionnelle)
      _proposeFacturation(resa);
    } catch (e) {
      _showMessage('Erreur : $e');
    }
  }

  Future<void> _proposeFacturation(ReservationModel resa) async {
    final goToBilling = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Facturer le séjour ?'),
        content: Text(
          'Voulez-vous établir la facture de ${resa.clientName} maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Facturer'),
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
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return StreamBuilder<List<RoomTypeModel>>(
      stream: _typeService.streamRoomTypes(establishmentId: establishmentId),
      builder: (context, typesSnapshot) {
        final types = typesSnapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Réservations')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(types),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle réservation'),
          ),
          body: StreamBuilder<List<ReservationModel>>(
            stream: _service.streamReservations(
              establishmentId: establishmentId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: SelectableText('Erreur : ${snapshot.error}'),
                );
              }

              final reservations = snapshot.data ?? [];

              if (reservations.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucune réservation.\n'
                      'Créez-en une avec le bouton +.',
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
                        '${resa.assignedRoomNumber.isNotEmpty ? ' · Ch. ${resa.assignedRoomNumber}' : ''}'
                        '\n$dates · ${resa.numberOfNights} nuit(s)'
                        '\n${resa.roomTotal.toStringAsFixed(0)} FCFA · ${_statusLabel(resa.status)}',
                      ),
                      isThreeLine: true,
                      trailing: _buildTrailing(resa),
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

  Widget? _buildTrailing(ReservationModel resa) {
    if (resa.status == 'confirmed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () => _doCheckIn(resa),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Check-in'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'cancel') _confirmCancel(resa);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'cancel', child: Text('Annuler')),
            ],
          ),
        ],
      );
    }

    if (resa.status == 'checked_in') {
      return TextButton.icon(
        onPressed: () => _doCheckOut(resa),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Check-out'),
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

class _ReservationFormDialogState extends State<_ReservationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ifuController;
  late final TextEditingController _guestsController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ifuController.dispose();
    _guestsController.dispose();
    _priceController.dispose();
    _noteController.dispose();
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
    if (_selectedClientId.isEmpty) {
      return OutlinedButton.icon(
        onPressed: _pickClient,
        icon: const Icon(Icons.person_search),
        label: const Text('Choisir un client existant'),
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
              'Client rattaché : $_selectedClientName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Détacher la fiche',
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
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDateRange: (_checkIn != null && _checkOut != null)
          ? DateTimeRange(start: _checkIn!, end: _checkOut!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _checkIn = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _checkOut = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
      _refreshAvailability();
    }
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
    if (_selectedType == null) {
      widget.onDone('Choisissez un type de chambre.');
      return;
    }
    if (_checkIn == null || _checkOut == null) {
      widget.onDone('Choisissez les dates du séjour.');
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
      widget.onDone('Réservation créée.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      // Si complet, proposer de forcer
      final msg = e.toString();
      if (!force && msg.contains('disponible')) {
        _proposeForce();
      } else {
        widget.onDone('Erreur : $e');
      }
    }
  }

  Future<void> _proposeForce() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Type complet'),
        content: const Text(
          'Aucune chambre de ce type n\'est disponible sur cette période. '
          'Voulez-vous forcer la réservation malgré tout ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Forcer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _save(force: true);
    }
  }

  Widget _buildAvailabilityHint() {
    if (_checkingAvailability) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Vérification de la disponibilité...'),
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
                  ? 'Type complet sur cette période (vous pourrez forcer).'
                  : '$_availableCount chambre(s) disponible(s).',
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
    final type = _selectedType;
    final total = (type != null && _nights > 0)
        ? (double.tryParse(_priceController.text.trim()) ?? type.basePrice) *
              _nights
        : 0;

    return AlertDialog(
      title: const Text('Nouvelle réservation'),
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
                  decoration: const InputDecoration(labelText: 'Nom du client'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ifuController,
                  decoration: const InputDecoration(
                    labelText: 'IFU (optionnel, pour la facture)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Type de chambre',
                  ),
                  items: widget.types
                      .map(
                        (t) => DropdownMenuItem<String>(
                          value: t.id,
                          child: Text(
                            '${t.name} (${t.basePrice.toStringAsFixed(0)} FCFA)',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _onTypeChanged,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Choisissez un type' : null,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDates,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    (_checkIn != null && _checkOut != null)
                        ? '${_df.format(_checkIn!)} → ${_df.format(_checkOut!)}'
                        : 'Choisir les dates',
                  ),
                ),
                _buildAvailabilityHint(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guestsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Personnes',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prix / nuit',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optionnel)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                if (_nights > 0)
                  Text(
                    'Total : ${total.toStringAsFixed(0)} FCFA '
                    '($_nights nuit(s))',
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
          child: const Text('Annuler'),
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
          label: Text(_isSaving ? 'Création...' : 'Créer'),
        ),
      ],
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

    if (client.ifu.isNotEmpty) parts.add('IFU ${client.ifu}');

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext sheetContext) {
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
              'Choisir un client',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Rechercher',
                  hintText: 'Nom ou téléphone',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ClientModel>>(
                stream: widget.service.streamClients(
                  establishmentId: widget.establishmentId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: SelectableText('Erreur : ${snapshot.error}'),
                    );
                  }

                  final clients = snapshot.data ?? [];

                  if (clients.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune fiche client.\n'
                          'Vous pouvez saisir le client à la main.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final filtered = _filter(clients);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun client ne correspond à cette recherche.',
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
