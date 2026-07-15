import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/hygiene_daily_controller.dart';
import 'package:takapp/modeles/store_stock_model.dart';
import 'package:takapp/services/store_stock_service.dart';

class HygieneDailyPage extends StatefulWidget {
  final String establishmentId;

  const HygieneDailyPage({super.key, required this.establishmentId});

  @override
  State<HygieneDailyPage> createState() => _HygieneDailyPageState();
}

class _HygieneDailyPageState extends State<HygieneDailyPage> {
  final TextEditingController _roomController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  final List<_HygieneLineInput> _lines = [_HygieneLineInput()];

  String get establishmentId => widget.establishmentId.trim();

  Future<void> _submit(List<StoreStockModel> stocks) async {
    final auth = context.read<AuthController>();

    final controller = context.read<HygieneDailyController>();

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

    final room = _roomController.text.trim();

    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le numéro de chambre.')),
      );
      return;
    }

    final List<Map<String, dynamic>> usedItems = [];

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];

      final quantity = double.tryParse(line.quantityController.text.trim());

      if ((line.selectedStockId == null || line.selectedStockId!.isEmpty) &&
          line.quantityController.text.trim().isEmpty) {
        continue;
      }

      if (line.selectedStockId == null || line.selectedStockId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sélectionne le produit à la ligne ${i + 1}.'),
          ),
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
              'Produit introuvable ou supprimé à la ligne ${i + 1}.',
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

      usedItems.add({
        'itemId': selected.itemId,
        'itemName': selected.itemName,
        'unit': selected.unit,
        'quantityUsed': quantity,
      });
    }

    if (usedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un produit utilisé.')),
      );
      return;
    }

    final success = await controller.createDailyEntry(
      establishmentId: establishmentId,
      roomNumber: room,
      preparedBy: user.uid,
      preparedByName: user.name,
      note: _noteController.text.trim(),
      usedItems: usedItems,
    );

    if (!mounted) return;

    if (success) {
      _roomController.clear();
      _noteController.clear();

      for (final line in _lines) {
        line.dispose();
      }

      setState(() {
        _lines
          ..clear()
          ..add(_HygieneLineInput());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('État journalier enregistré avec succès.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Erreur inconnue.')),
      );
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _noteController.dispose();

    for (final line in _lines) {
      line.dispose();
    }

    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  final stockService = StoreStockService();

  final controller = context.watch<HygieneDailyController>();

  final isSmall = MediaQuery.of(context).size.width < 800;

  if (establishmentId.isEmpty) {
    return const Scaffold(
      body: Center(child: Text('Établissement introuvable.')),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Hygiène journalière'),
      actions: [
        IconButton(
          onPressed: () => context.read<AuthController>().logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: StreamBuilder<List<StoreStockModel>>(
      stream: stockService.streamStocksForStore(
        establishmentId: establishmentId,
        store: 'hotel',
      ),
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
              child: Text('Aucun produit disponible dans le stock hôtel.'),
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
                      children: [
                        TextField(
                          controller: _roomController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de chambre préparée',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            hintText:
                                'Ex: chambre prête, changement draps, serviettes renouvelées',
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
                                  'Produit ${index + 1}',
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
                              labelText: 'Produit utilisé',
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
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _lines.add(_HygieneLineInput());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un produit'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.isSubmitting
                        ? null
                        : () => _submit(stocks),
                    icon: controller.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Enregistrer l’état journalier'),
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

class _HygieneLineInput {
  String? selectedStockId;

  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}
