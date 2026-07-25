import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/store_stock_controller.dart';
import 'package:takapp/modeles/stock_item_model.dart';
import 'package:takapp/services/stock_item_service.dart';

class DirectStockSupplyPage extends StatefulWidget {
  final String establishmentId;
  final String store;
  final String title;

  const DirectStockSupplyPage({
    super.key,
    required this.establishmentId,
    required this.store,
    required this.title,
  });

  @override
  State<DirectStockSupplyPage> createState() => _DirectStockSupplyPageState();
}

class _DirectStockSupplyPageState extends State<DirectStockSupplyPage> {
  final TextEditingController _reasonController = TextEditingController(
    text: 'Approvisionnement direct gérante',
  );

  final List<_SupplyLineInput> _lines = [_SupplyLineInput()];

  String get establishmentId => widget.establishmentId.trim();

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
    final controller = context.read<StoreStockController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];

      final selected = items.cast<StockItemModel?>().firstWhere(
        (item) => item?.id == line.selectedItemId,
        orElse: () => null,
      );

      final quantity = double.tryParse(line.quantityController.text.trim());

      if (selected == null && line.quantityController.text.trim().isEmpty) {
        continue;
      }

      if (selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sélectionne l’article à la ligne ${i + 1}.')),
        );
        return;
      }

      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantité invalide à la ligne ${i + 1}.')),
        );
        return;
      }

      final success = await controller.directSupply(
        establishmentId: establishmentId,
        store: widget.store,
        itemId: selected.id,
        itemName: selected.name,
        unit: selected.unit,
        quantity: quantity,
        performedBy: user.uid,
        performedByName: user.name,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Erreur inconnue.'),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Approvisionnement direct enregistré avec succès.'),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();

    for (final line in _lines) {
      line.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = StockItemService();
    final controller = context.watch<StoreStockController>();
    final color = _storeColor();
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<List<StockItemModel>>(
        stream: service.streamItems(
          establishmentId: establishmentId,
          store: widget.store,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('Aucun article disponible.'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Motif'),
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
                                  onPressed: controller.isSubmitting
                                      ? null
                                      : () {
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
                            initialValue:
                                items.any(
                                  (item) => item.id == line.selectedItemId,
                                )
                                ? line.selectedItemId
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Article',
                            ),
                            items: items.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.id,
                                child: Text('${item.name} (${item.unit})'),
                              );
                            }).toList(),
                            onChanged: controller.isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      line.selectedItemId = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: line.quantityController,
                            enabled: !controller.isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Quantité approvisionnée',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _lines.add(_SupplyLineInput());
                          });
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un article'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.isSubmitting
                        ? null
                        : () => _submit(items),
                    icon: controller.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_business),
                    label: const Text('Valider l’approvisionnement'),
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

class _SupplyLineInput {
  String? selectedItemId;
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}
