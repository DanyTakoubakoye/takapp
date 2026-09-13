import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/stock_request_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/stock_item_model.dart';
import 'package:takapp/modeles/stock_request_item_model.dart';
import 'package:takapp/services/stock_item_service.dart';

class CreateStockRequestPage extends StatefulWidget {
  final String establishmentId;
  final String store;
  final String requestedByRole;
  final String title;

  const CreateStockRequestPage({
    super.key,
    required this.establishmentId,
    required this.store,
    required this.requestedByRole,
    required this.title,
  });

  @override
  State<CreateStockRequestPage> createState() => _CreateStockRequestPageState();
}

class _CreateStockRequestPageState extends State<CreateStockRequestPage> {
  final TextEditingController _noteController = TextEditingController();
  final List<_RequestLineInput> _lines = [_RequestLineInput()];
  final StockItemService _itemService = StockItemService();
  late final Stream<List<StockItemModel>> _itemsStream;

  Color _storeColor() {
    switch (widget.store) {
      case 'restaurant':
        return Colors.deepOrange;
      case 'bar':
        return Colors.indigo;
      case 'hotel':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _submit(List<StockItemModel> items) async {
    final auth = context.read<AuthController>();
    final controller = context.read<StockRequestController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }

    final List<StockRequestItemModel> requestItems = [];

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final quantity = double.tryParse(line.quantityController.text.trim());

      if ((line.selectedItemId == null || line.selectedItemId!.isEmpty) &&
          line.quantityController.text.trim().isEmpty) {
        continue;
      }

      if (line.selectedItemId == null || line.selectedItemId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sélectionne l’article à la ligne ${i + 1}.')),
        );
        return;
      }

      final selectedMatches = items
          .where((e) => e.id == line.selectedItemId)
          .toList();

      if (selectedMatches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Article introuvable ou supprimé à la ligne ${i + 1}.',
            ),
          ),
        );
        return;
      }

      final selected = selectedMatches.first;

      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantité invalide à la ligne ${i + 1}.')),
        );
        return;
      }

      requestItems.add(
        StockRequestItemModel(
          id: '',
          establishmentId: user.establishmentId,
          itemId: selected.id,
          itemName: selected.name,
          unit: selected.unit,
          quantityRequested: quantity,
          quantityDelivered: 0,
          status: 'pending',
          pendingSync: false,
          syncError: false,
        ),
      );
    }

    if (requestItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un article à demander.')),
      );
      return;
    }

    final success = await controller.createRequest(
      establishmentId: widget.establishmentId,
      store: widget.store,
      requestedBy: user.uid,
      requestedByName: user.name,
      requestedByRole: widget.requestedByRole,
      note: _noteController.text.trim(),
      items: requestItems,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d’approvisionnement envoyée avec succès.'),
        ),
      );
    } else {
      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorText(l10n) ?? l10n.errUnknown),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _itemsStream = _itemService.streamItems(
      establishmentId: widget.establishmentId,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestController = context.watch<StockRequestController>();
    final color = _storeColor();
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<List<StockItemModel>>(
        stream: _itemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('Aucun article disponible dans le référentiel.'),
            );
          }

          for (final line in _lines) {
            final exists = items.any((e) => e.id == line.selectedItemId);
            if (!exists) {
              line.selectedItemId = null;
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouvelle demande',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sélectionne les articles et les quantités à demander à la gérante.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Note / commentaire',
                            hintText:
                                'Ex: besoin urgent pour le service du soir',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(_lines.length, (index) {
                  final line = _lines[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Article ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_lines.length > 1)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      line.dispose();
                                      _lines.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: line.selectedItemId,
                            decoration: const InputDecoration(
                              labelText: 'Article',
                            ),
                            items: items.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.id,
                                child: Text('${item.name} (${item.unit})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                line.selectedItemId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: line.quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Quantité demandée',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _lines.add(_RequestLineInput());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un article'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: requestController.isSubmitting
                        ? null
                        : () => _submit(items),
                    icon: requestController.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Envoyer la demande'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestLineInput {
  String? selectedItemId;
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}
