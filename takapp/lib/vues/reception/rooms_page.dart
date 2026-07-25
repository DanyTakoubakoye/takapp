import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/room_model.dart';
import 'package:takapp/modeles/room_type_model.dart';
import 'package:takapp/services/room_service.dart';
import 'package:takapp/services/room_type_service.dart';

class RoomsPage extends StatefulWidget {
  final String establishmentId;

  const RoomsPage({super.key, required this.establishmentId});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final RoomService _roomService = RoomService();
  final RoomTypeService _typeService = RoomTypeService();

  String get establishmentId => widget.establishmentId.trim();

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Libre';
      case 'occupied':
        return 'Occupée';
      case 'cleaning':
        return 'À nettoyer';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'cleaning':
        return Colors.orange;
      case 'maintenance':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openForm({
    required List<RoomTypeModel> types,
    RoomModel? existing,
  }) async {
    if (types.isEmpty) {
      _showMessage('Créez d\'abord au moins un type de chambre.');
      return;
    }

    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    await showDialog<void>(
      context: context,
      builder: (_) => _RoomFormDialog(
        establishmentId: establishmentId,
        roomService: _roomService,
        types: types,
        existing: existing,
        createdBy: user?.uid ?? '',
        createdByName: user?.name ?? '',
        onDone: _showMessage,
      ),
    );
  }

  Future<void> _confirmDisable(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette chambre ?'),
        content: Text('La chambre "${room.number}" sera retirée de la liste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _roomService.disableRoom(
        establishmentId: establishmentId,
        roomId: room.id,
      );
      _showMessage('Chambre supprimée.');
    } catch (e) {
      _showMessage('Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    // On écoute les types pour alimenter le formulaire et détecter s'il faut en créer.
    return StreamBuilder<List<RoomTypeModel>>(
      stream: _typeService.streamRoomTypes(establishmentId: establishmentId),
      builder: (context, typesSnapshot) {
        final types = typesSnapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Chambres')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(types: types),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une chambre'),
          ),
          body: StreamBuilder<List<RoomModel>>(
            stream: _roomService.streamRooms(establishmentId: establishmentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: SelectableText('Erreur : ${snapshot.error}'),
                );
              }

              final rooms = snapshot.data ?? [];

              if (rooms.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      types.isEmpty
                          ? 'Créez d\'abord un type de chambre,\npuis ajoutez vos chambres.'
                          : 'Aucune chambre.\nAjoutez vos chambres avec le bouton +.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final color = _statusColor(room.status);

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
                        child: Icon(Icons.meeting_room, color: color),
                      ),
                      title: Text(
                        'Chambre ${room.number}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${room.roomTypeName}'
                        '${room.floor.isNotEmpty ? ' · Étage ${room.floor}' : ''}'
                        '\n${_statusLabel(room.status)}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openForm(types: types, existing: room);
                          } else if (value == 'disable') {
                            _confirmDisable(room);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          PopupMenuItem(
                            value: 'disable',
                            child: Text('Supprimer'),
                          ),
                        ],
                      ),
                      onTap: () => _openForm(types: types, existing: room),
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
}

class _RoomFormDialog extends StatefulWidget {
  final String establishmentId;
  final RoomService roomService;
  final List<RoomTypeModel> types;
  final RoomModel? existing;
  final String createdBy;
  final String createdByName;
  final void Function(String message) onDone;

  const _RoomFormDialog({
    required this.establishmentId,
    required this.roomService,
    required this.types,
    required this.existing,
    required this.createdBy,
    required this.createdByName,
    required this.onDone,
  });

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberController;
  late final TextEditingController _floorController;
  late final TextEditingController _priceOverrideController;

  String? _selectedTypeId;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _numberController = TextEditingController(text: e?.number ?? '');
    _floorController = TextEditingController(text: e?.floor ?? '');
    _priceOverrideController = TextEditingController(
      text: (e?.priceOverride != null && e!.priceOverride! > 0)
          ? e.priceOverride!.toStringAsFixed(0)
          : '',
    );
    _selectedTypeId = e?.roomTypeId;
    // Si le type de la chambre n'existe plus dans la liste active, on laisse null.
    if (_selectedTypeId != null &&
        !widget.types.any((t) => t.id == _selectedTypeId)) {
      _selectedTypeId = null;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _floorController.dispose();
    _priceOverrideController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      widget.onDone('Veuillez choisir un type de chambre.');
      return;
    }

    setState(() => _isSaving = true);

    final selectedType = widget.types.firstWhere(
      (t) => t.id == _selectedTypeId,
    );
    final number = _numberController.text.trim();
    final floor = _floorController.text.trim();
    final overrideText = _priceOverrideController.text.trim();
    final priceOverride = overrideText.isEmpty
        ? null
        : double.tryParse(overrideText);

    try {
      if (_isEdit) {
        await widget.roomService.updateRoom(
          establishmentId: widget.establishmentId,
          roomId: widget.existing!.id,
          number: number,
          roomTypeId: selectedType.id,
          roomTypeName: selectedType.name,
          priceOverride: priceOverride,
          floor: floor,
        );
      } else {
        await widget.roomService.createRoom(
          establishmentId: widget.establishmentId,
          number: number,
          roomTypeId: selectedType.id,
          roomTypeName: selectedType.name,
          priceOverride: priceOverride,
          floor: floor,
          createdBy: widget.createdBy,
          createdByName: widget.createdByName,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDone(_isEdit ? 'Chambre modifiée.' : 'Chambre ajoutée.');
    } catch (e) {
      if (!mounted) return;
      widget.onDone('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifier la chambre' : 'Nouvelle chambre'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro / nom de la chambre',
                    hintText: 'Ex. 101, Jasmin, A2',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 12),
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
                  onChanged: (value) {
                    setState(() => _selectedTypeId = value);
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Choisissez un type' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _floorController,
                  decoration: const InputDecoration(
                    labelText: 'Étage (optionnel)',
                    hintText: 'Ex. 1, RDC',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceOverrideController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix spécifique (optionnel)',
                    hintText: 'Laisser vide = prix du type',
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
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    );
  }
}
