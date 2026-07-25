import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:takapp/services/menu_ingredient_service.dart';

class BarMenuItemIngredientsFormPage extends StatefulWidget {
  final String establishmentId;
  const BarMenuItemIngredientsFormPage({super.key,
  required this.establishmentId,});

  @override
  State<BarMenuItemIngredientsFormPage> createState() =>
      _BarMenuItemIngredientsFormPageState();
}

class _BarMenuItemIngredientsFormPageState
    extends State<BarMenuItemIngredientsFormPage> {
  final MenuIngredientService _service = MenuIngredientService();

  final _formKey = GlobalKey<FormState>();

  String? selectedMenuItemId;

  final List<_IngredientLine> ingredientLines = [_IngredientLine()];

  bool isSaving = false;

  /// =========================
  /// HELPERS SAAS
  /// =========================

 String get establishmentId => widget.establishmentId;
  @override
  void dispose() {
    for (final line in ingredientLines) {
      line.quantityController.dispose();
    }

    super.dispose();
  }

  /// =========================
  /// ADD LINE
  /// =========================

  void _addIngredientLine() {
    setState(() {
      ingredientLines.add(_IngredientLine());
    });
  }

  /// =========================
  /// REMOVE LINE
  /// =========================

  void _removeIngredientLine(int index) {
    if (ingredientLines.length == 1) {
      return;
    }

    setState(() {
      ingredientLines[index].quantityController.dispose();

      ingredientLines.removeAt(index);
    });
  }

  /// =========================
  /// FIND DOC
  /// =========================

  DocumentSnapshot<Map<String, dynamic>>? _findDocById(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String? id,
  ) {
    if (id == null) {
      return null;
    }

    for (final doc in docs) {
      if (doc.id == id) {
        return doc;
      }
    }

    return null;
  }

  /// =========================
  /// SAVE
  /// =========================

  Future<void> _save(
    List<DocumentSnapshot<Map<String, dynamic>>> stockItems,
  ) async {
    if (establishmentId.trim().isEmpty) {
      _showMessage('Établissement introuvable.');

      return;
    }

    if (selectedMenuItemId == null) {
      _showMessage('Veuillez choisir un cocktail ou article du bar.');

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ingredients = <Map<String, dynamic>>[];

    for (final line in ingredientLines) {
      final stockItem = _findDocById(stockItems, line.selectedStockItemId);

      if (stockItem == null) {
        _showMessage('Veuillez choisir tous les ingrédients.');

        return;
      }

      final data = stockItem.data() ?? {};

      final quantity = int.tryParse(line.quantityController.text.trim());

      if (quantity == null || quantity <= 0) {
        _showMessage('Chaque quantité doit être un nombre entier positif.');

        return;
      }

      ingredients.add({
        'itemId': stockItem.id,

        'itemName': data['name'] ?? '',

        'quantity': quantity,

        'store': data['store'] ?? 'bar',

        'unit': data['unit'] ?? '',

        /// SAAS
        'establishmentId': establishmentId,
      });
    }

    setState(() {
      isSaving = true;
    });

    try {
      await _service.updateMenuItemIngredients(
        establishmentId: establishmentId,

        menuItemId: selectedMenuItemId!,

        ingredients: ingredients,
      );

      if (!mounted) return;

      _showMessage('Ingrédients du cocktail enregistrés avec succès.');

      setState(() {
        selectedMenuItemId = null;

        for (final line in ingredientLines) {
          line.quantityController.dispose();
        }

        ingredientLines
          ..clear()
          ..add(_IngredientLine());
      });
    } catch (e) {
      _showMessage('Erreur lors de l’enregistrement : $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  /// =========================
  /// SHOW MESSAGE
  /// =========================

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// =========================
  /// DOC NAME
  /// =========================

  String _docName(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return (data['name'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    if (establishmentId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Composition cocktails bar')),
        body: const Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Composition cocktails bar')),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.streamBarMenuItems(establishmentId: establishmentId),

        builder: (context, menuSnapshot) {
          if (menuSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (menuSnapshot.hasError) {
            return Center(
              child: Text('Erreur menuItems : ${menuSnapshot.error}'),
            );
          }

          final menuItems = menuSnapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.streamBarStockItems(
              establishmentId: establishmentId,
            ),

            builder: (context, stockSnapshot) {
              if (stockSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (stockSnapshot.hasError) {
                return Center(
                  child: Text('Erreur stock_items : ${stockSnapshot.error}'),
                );
              }

              final stockItems = stockSnapshot.data?.docs ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),

                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 950),

                    child: Card(
                      elevation: 3,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(18),

                        child: Form(
                          key: _formKey,

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              _header(context),

                              const SizedBox(height: 20),

                              DropdownButtonFormField<String>(
                                initialValue:
                                    menuItems.any((doc) {
                                      return doc.id == selectedMenuItemId;
                                    })
                                    ? selectedMenuItemId
                                    : null,

                                decoration: const InputDecoration(
                                  labelText: 'Cocktail / article du bar',

                                  border: OutlineInputBorder(),

                                  prefixIcon: Icon(Icons.local_bar_outlined),
                                ),

                                items: menuItems.map((doc) {
                                  return DropdownMenuItem<String>(
                                    value: doc.id,

                                    child: Text(_docName(doc)),
                                  );
                                }).toList(),

                                onChanged: isSaving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          selectedMenuItemId = value;
                                        });
                                      },

                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez choisir un article du bar';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Ingrédients du bar',

                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),

                                  ElevatedButton.icon(
                                    onPressed: isSaving
                                        ? null
                                        : _addIngredientLine,

                                    icon: const Icon(Icons.add),

                                    label: const Text('Ajouter'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              ...List.generate(ingredientLines.length, (index) {
                                return _ingredientRow(
                                  index: index,

                                  stockItems: stockItems,

                                  isSmallScreen: isSmallScreen,
                                );
                              }),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,

                                child: ElevatedButton.icon(
                                  onPressed: isSaving
                                      ? null
                                      : () => _save(stockItems),

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey.shade800,

                                    foregroundColor: Colors.white,

                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),

                                  icon: isSaving
                                      ? const SizedBox(
                                          width: 18,

                                          height: 18,

                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,

                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save),

                                  label: Text(
                                    isSaving
                                        ? 'Enregistrement...'
                                        : 'Valider la composition du cocktail',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// =========================
  /// HEADER
  /// =========================

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.12),

            borderRadius: BorderRadius.circular(14),
          ),

          child: const Icon(Icons.local_bar_outlined, color: Colors.blueGrey),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            'Définir les ingrédients des cocktails',

            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// =========================
  /// INGREDIENT ROW
  /// =========================

  Widget _ingredientRow({
    required int index,

    required List<DocumentSnapshot<Map<String, dynamic>>> stockItems,

    required bool isSmallScreen,
  }) {
    final line = ingredientLines[index];

    final ingredientDropdown = DropdownButtonFormField<String>(
      initialValue:
          stockItems.any((doc) {
            return doc.id == line.selectedStockItemId;
          })
          ? line.selectedStockItemId
          : null,

      decoration: InputDecoration(
        labelText: 'Ingrédient ${index + 1}',

        border: const OutlineInputBorder(),

        prefixIcon: const Icon(Icons.liquor_outlined),
      ),

      items: stockItems.map((doc) {
        final data = doc.data() ?? {};

        final name = (data['name'] ?? '').toString();

        final unit = (data['unit'] ?? '').toString();

        return DropdownMenuItem<String>(
          value: doc.id,

          child: Text('$name - $unit'),
        );
      }).toList(),

      onChanged: isSaving
          ? null
          : (value) {
              setState(() {
                line.selectedStockItemId = value;
              });
            },

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Choisissez un ingrédient';
        }

        return null;
      },
    );

    final quantityField = TextFormField(
      controller: line.quantityController,

      enabled: !isSaving,

      keyboardType: TextInputType.number,

      decoration: const InputDecoration(
        labelText: 'Quantité',

        border: OutlineInputBorder(),

        prefixIcon: Icon(Icons.numbers),
      ),

      validator: (value) {
        final quantity = int.tryParse((value ?? '').trim());

        if (quantity == null || quantity <= 0) {
          return 'Quantité invalide';
        }

        return null;
      },
    );

    final deleteButton = IconButton(
      tooltip: 'Retirer cette ligne',

      onPressed: ingredientLines.length == 1 || isSaving
          ? null
          : () => _removeIngredientLine(index),

      icon: const Icon(Icons.delete_outline, color: Colors.red),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.grey.shade300),
      ),

      child: isSmallScreen
          ? Column(
              children: [
                ingredientDropdown,

                const SizedBox(height: 12),

                quantityField,

                Align(alignment: Alignment.centerRight, child: deleteButton),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Expanded(flex: 3, child: ingredientDropdown),

                const SizedBox(width: 12),

                Expanded(child: quantityField),

                const SizedBox(width: 8),

                deleteButton,
              ],
            ),
    );
  }
}

class _IngredientLine {
  String? selectedStockItemId;

  final TextEditingController quantityController = TextEditingController();
}
