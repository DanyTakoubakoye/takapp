import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/room_type_model.dart';
import 'package:takapp/services/room_type_service.dart';

class RoomTypesPage extends StatefulWidget {
  final String establishmentId;

  const RoomTypesPage({super.key, required this.establishmentId});

  @override
  State<RoomTypesPage> createState() => _RoomTypesPageState();
}

class _RoomTypesPageState extends State<RoomTypesPage> {
  final RoomTypeService _service = RoomTypeService();

  String get establishmentId => widget.establishmentId.trim();

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm({RoomTypeModel? existing}) async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    await showDialog<void>(
      context: context,
      builder: (_) => _RoomTypeFormDialog(
        establishmentId: establishmentId,
        service: _service,
        existing: existing,
        createdBy: user?.uid ?? '',
        createdByName: user?.name ?? '',
        onDone: _showMessage,
      ),
    );
  }

  Future<void> _confirmDisable(RoomTypeModel type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Désactiver ce type ?'),
        content: Text(
          'Le type "${type.name}" ne sera plus proposé, '
          'mais les chambres existantes ne sont pas supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.disableRoomType(
        establishmentId: establishmentId,
        typeId: type.id,
      );
      _showMessage('Type désactivé.');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Types de chambres')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un type'),
      ),
      body: StreamBuilder<List<RoomTypeModel>>(
        stream: _service.streamRoomTypes(establishmentId: establishmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: SelectableText('Erreur : ${snapshot.error}'));
          }

          final types = snapshot.data ?? [];

          if (types.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun type de chambre.\n'
                  'Ajoutez vos catégories (Simple, Suite, Bungalow...).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final type = types[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    type.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${type.basePrice.toStringAsFixed(0)} FCFA / nuit'
                    ' · ${type.capacity} pers.'
                    '${type.description.isNotEmpty ? '\n${type.description}' : ''}',
                  ),
                  isThreeLine: type.description.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(existing: type);
                      } else if (value == 'disable') {
                        _confirmDisable(type);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      PopupMenuItem(
                        value: 'disable',
                        child: Text('Désactiver'),
                      ),
                    ],
                  ),
                  onTap: () => _openForm(existing: type),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RoomTypeFormDialog extends StatefulWidget {
  final String establishmentId;
  final RoomTypeService service;
  final RoomTypeModel? existing;
  final String createdBy;
  final String createdByName;
  final void Function(String message) onDone;

  const _RoomTypeFormDialog({
    required this.establishmentId,
    required this.service,
    required this.existing,
    required this.createdBy,
    required this.createdByName,
    required this.onDone,
  });

  @override
  State<_RoomTypeFormDialog> createState() => _RoomTypeFormDialogState();
}

class _RoomTypeFormDialogState extends State<_RoomTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amenitiesController;

  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _priceController = TextEditingController(
      text: e != null ? e.basePrice.toStringAsFixed(0) : '',
    );
    _capacityController = TextEditingController(
      text: e != null ? e.capacity.toString() : '',
    );
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _amenitiesController = TextEditingController(
      text: e != null ? e.amenities.join(', ') : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim();
    final amenities = _amenitiesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      if (_isEdit) {
        await widget.service.updateRoomType(
          establishmentId: widget.establishmentId,
          typeId: widget.existing!.id,
          name: name,
          basePrice: price,
          capacity: capacity,
          description: description,
          amenities: amenities,
        );
      } else {
        await widget.service.createRoomType(
          establishmentId: widget.establishmentId,
          name: name,
          basePrice: price,
          capacity: capacity,
          description: description,
          amenities: amenities,
          createdBy: widget.createdBy,
          createdByName: widget.createdByName,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDone(_isEdit ? 'Type modifié.' : 'Type ajouté.');
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
      title: Text(_isEdit ? 'Modifier le type' : 'Nouveau type de chambre'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du type',
                    hintText: 'Ex. Suite Présidentielle, Bungalow...',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix par nuit (FCFA)',
                    hintText: 'Ex. 25000',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return 'Prix invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacité (personnes)',
                    hintText: 'Ex. 2',
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return 'Capacité invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Équipements (séparés par des virgules)',
                    hintText: 'Ex. Clim, Wifi, TV, Minibar',
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
