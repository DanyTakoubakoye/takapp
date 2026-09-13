import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/store_stock_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/store_stock_model.dart';
import 'package:takapp/services/store_stock_service.dart';

class StockOutPage extends StatefulWidget {
  final String establishmentId;
  final String store;
  final String title;
  final String defaultReason;

  const StockOutPage({
    super.key,
    required this.establishmentId,
    required this.store,
    required this.title,
    required this.defaultReason,
  });

  @override
  State<StockOutPage> createState() => _StockOutPageState();
}

class _StockOutPageState extends State<StockOutPage> {
  final TextEditingController _reasonController = TextEditingController();
  final List<_StockOutLineInput> _lines = [_StockOutLineInput()];
  final StoreStockService _stockService = StoreStockService();
  late final Stream<List<StoreStockModel>> _stocksStream;

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

  @override
  void initState() {
    super.initState();
    _reasonController.text = widget.defaultReason;
    _stocksStream = _stockService.streamStocksForStore(
      establishmentId: widget.establishmentId,
      store: widget.store,
    );
  }

  Future<void> _submit(List<StoreStockModel> stocks) async {
    final auth = context.read<AuthController>();
    final controller = context.read<StoreStockController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }

    bool hasValidLine = false;

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final quantity = double.tryParse(line.quantityController.text.trim());

      if ((line.selectedStockId == null || line.selectedStockId!.isEmpty) &&
          line.quantityController.text.trim().isEmpty) {
        continue;
      }

      if (line.selectedStockId == null || line.selectedStockId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sélectionne l’article à la ligne ${i + 1}.')),
        );
        return;
      }

      final selectedMatches = stocks
          .where((e) => e.itemId == line.selectedStockId)
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

      hasValidLine = true;

      final success = await controller.removeStock(
        establishmentId: widget.establishmentId,
        store: widget.store,
        itemId: selected.itemId,
        itemName: selected.itemName,
        unit: selected.unit,
        quantity: quantity,
        performedBy: user.uid,
        performedByName: user.name,
        reason: _reasonController.text.trim().isEmpty
            ? widget.defaultReason
            : _reasonController.text.trim(),
      );

      if (!mounted) return;

      if (!success) {
        final l10n = AppLocalizations.of(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorText(l10n) ?? l10n.errUnknown),
          ),
        );
        return;
      }
    }

    if (!hasValidLine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins une sortie de stock.')),
      );
      return;
    }

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sortie de stock enregistrée avec succès.')),
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
    final stockController = context.watch<StoreStockController>();
    final color = _storeColor();
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<List<StoreStockModel>>(
        stream: _stocksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final stocks = snapshot.data ?? [];

          if (stocks.isEmpty) {
            return const Center(
              child: Text('Aucun stock disponible dans ce magasin.'),
            );
          }

          for (final line in _lines) {
            final exists = stocks.any((e) => e.itemId == line.selectedStockId);
            if (!exists) {
              line.selectedStockId = null;
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
                          'Déclarer une consommation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cette action diminue automatiquement le stock du magasin.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(labelText: 'Motif'),
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
                            initialValue: line.selectedStockId,
                            decoration: const InputDecoration(
                              labelText: 'Article en stock',
                            ),
                            items: stocks.map((item) {
                              final label =
                                  '${item.itemName} (${item.unit}) - stock: ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)}';

                              return DropdownMenuItem<String>(
                                value: item.itemId,
                                child: Text(label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                line.selectedStockId = value;
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
                              labelText: 'Quantité utilisée',
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
                        _lines.add(_StockOutLineInput());
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
                    onPressed: stockController.isSubmitting
                        ? null
                        : () => _submit(stocks),
                    icon: stockController.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.remove_shopping_cart),
                    label: const Text('Enregistrer la sortie'),
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

class _StockOutLineInput {
  String? selectedStockId;
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}
