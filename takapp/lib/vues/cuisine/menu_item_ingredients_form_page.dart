import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:takapp/services/menu_ingredient_service.dart';

import 'package:excel/excel.dart' as xlsx;
import 'package:file_picker/file_picker.dart';

import 'package:takapp/vues/shared/menu_photo_picker.dart';

class MenuItemIngredientsFormPage extends StatefulWidget {
  final String establishmentId;

  const MenuItemIngredientsFormPage({super.key, required this.establishmentId});

  @override
  State<MenuItemIngredientsFormPage> createState() =>
      _MenuItemIngredientsFormPageState();
}

class _MenuItemIngredientsFormPageState
    extends State<MenuItemIngredientsFormPage> {
  final MenuIngredientService _service = MenuIngredientService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newDishController = TextEditingController();
  final List<String> _dishCategories = const [
    'Viandes',
    'plat',
    'Volailles',
    'Pates',
    'Accompagnements',
    'Fruits de mer',
    'Spécialités africaines',
    'Burger et Sandwichs',
    'Etrées libanaises',
    'Entrées froides',
    'Pizzas',
    'Fast food',
    'Desserts',
    'Autres',
  ];
  String _newDishCategory = 'plat';
  final TextEditingController _compositionController = TextEditingController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _menuItemsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stockItemsStream;

  String? selectedMenuItemId;
  String _selectedItemAdresse = '';
  final List<_IngredientLine> ingredientLines = [_IngredientLine()];

  bool isSaving = false;
  bool _allowsFreeAccompaniment = false;

  String get establishmentId => widget.establishmentId.trim();
  @override
  void initState() {
    super.initState();
    _menuItemsStream = _service.streamKitchenMenuItems(
      establishmentId: establishmentId,
    );
    _stockItemsStream = _service.streamRestaurantStockItems(
      establishmentId: establishmentId,
    );
  }

  @override
  void dispose() {
    for (final line in ingredientLines) {
      line.quantityController.dispose();
    }
    _newDishController.dispose();
    _compositionController.dispose();
    super.dispose();
  }

  void _addIngredientLine() {
    setState(() {
      ingredientLines.add(_IngredientLine());
    });
  }

  void _removeIngredientLine(int index) {
    if (ingredientLines.length == 1) return;

    setState(() {
      ingredientLines[index].quantityController.dispose();
      ingredientLines.removeAt(index);
    });
  }

  DocumentSnapshot<Map<String, dynamic>>? _findDocById(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String? id,
  ) {
    if (id == null) return null;

    for (final doc in docs) {
      if (doc.id == id) return doc;
    }

    return null;
  }

  Future<void> _savePhotoUrl(String url) async {
    if (selectedMenuItemId == null) return;
    try {
      await _service.updateMenuItemImage(
        establishmentId: establishmentId,
        menuItemId: selectedMenuItemId!,
        adresse: url,
      );
      if (!mounted) return;
      setState(() => _selectedItemAdresse = url);
      _showMessage('Photo enregistrée.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur enregistrement photo : $e');
    }
  }

  Future<void> _save(
    List<DocumentSnapshot<Map<String, dynamic>>> stockItems,
  ) async {
    if (establishmentId.isEmpty) {
      _showMessage('Établissement introuvable.');
      return;
    }

    if (selectedMenuItemId == null) {
      _showMessage('Veuillez choisir un article cuisine.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

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
        'store': data['store'] ?? 'restaurant',
        'unit': data['unit'] ?? '',
      });
    }

    setState(() => isSaving = true);

    try {
      await _service.updateMenuItemIngredients(
        establishmentId: establishmentId,
        menuItemId: selectedMenuItemId!,
        ingredients: ingredients,
        composition: _compositionController.text,
        allowsFreeAccompaniment: _allowsFreeAccompaniment,
      );

      if (!mounted) return;

      _showMessage('Ingrédients cuisine enregistrés avec succès.');

      setState(() {
        selectedMenuItemId = null;
        _compositionController.clear();
        _allowsFreeAccompaniment = false;

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
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _createDish() async {
    final name = _newDishController.text.trim();
    if (name.isEmpty) {
      _showMessage('Saisissez le nom du plat.');
      return;
    }
    setState(() => isSaving = true);
    try {
      await _service.createKitchenMenuItem(
        establishmentId: establishmentId,
        name: name,
        category: _newDishCategory,
      );
      _newDishController.clear();
      if (!mounted) return;
      _showMessage('Plat « $name » créé. Vous pouvez maintenant le composer.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  /// Normalise un nom pour le matching (minuscules + espaces compactés).
  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _importFromExcel(
    List<DocumentSnapshot<Map<String, dynamic>>> menuItems,
    List<DocumentSnapshot<Map<String, dynamic>>> stockItems,
  ) async {
    if (establishmentId.isEmpty) {
      _showMessage('Établissement introuvable.');
      return;
    }

    // 1. Choisir le fichier
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      _showMessage('Impossible de lire le fichier.');
      return;
    }

    setState(() => isSaving = true);

    try {
      // 2. Index des noms → id (normalisés)
      final menuByName = <String, String>{}; // nom -> menuItemId
      final menuNameById = <String, String>{}; // menuItemId -> nom affiché
      for (final doc in menuItems) {
        final name = (doc.data()?['name'] ?? '').toString();
        if (name.trim().isEmpty) continue;
        menuByName[_norm(name)] = doc.id;
        menuNameById[doc.id] = name;
      }

      final stockByName = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in stockItems) {
        final name = (doc.data()?['name'] ?? '').toString();
        if (name.trim().isEmpty) continue;
        stockByName[_norm(name)] = doc;
      }

      // 3. Lire l'Excel
      final excel = xlsx.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        _showMessage('Fichier Excel vide.');
        return;
      }
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.length < 2) {
        _showMessage('Le fichier ne contient aucune ligne de données.');
        return;
      }

      // 4. Regrouper par plat : menuItemId -> liste d'ingrédients
      final recipes = <String, List<Map<String, dynamic>>>{};
      final platsNonTrouves = <String>{};
      final ingredientsNonTrouves = <String>{};
      int lignesIgnorees = 0;

      // On saute la ligne d'en-tête (index 0)
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 3) {
          lignesIgnorees++;
          continue;
        }

        final platName = (row[0]?.value ?? '').toString().trim();
        final ingName = (row[1]?.value ?? '').toString().trim();
        final qtyRaw = (row[2]?.value ?? '').toString().trim();

        // Ligne vide → on ignore silencieusement
        if (platName.isEmpty && ingName.isEmpty && qtyRaw.isEmpty) continue;

        final quantity = int.tryParse(qtyRaw);
        if (platName.isEmpty ||
            ingName.isEmpty ||
            quantity == null ||
            quantity <= 0) {
          lignesIgnorees++;
          continue;
        }

        final menuId = menuByName[_norm(platName)];
        if (menuId == null) {
          platsNonTrouves.add(platName);
          continue;
        }

        final stockDoc = stockByName[_norm(ingName)];
        if (stockDoc == null) {
          ingredientsNonTrouves.add(ingName);
          continue;
        }

        final data = stockDoc.data() ?? {};
        recipes.putIfAbsent(menuId, () => []).add({
          'itemId': stockDoc.id,
          'itemName': data['name'] ?? '',
          'quantity': quantity,
          'store': data['store'] ?? 'restaurant',
          'unit': data['unit'] ?? '',
        });
      }

      // 5. Enregistrer chaque recette (remplacement)
      int importes = 0;
      for (final entry in recipes.entries) {
        await _service.updateMenuItemIngredients(
          establishmentId: establishmentId,
          menuItemId: entry.key,
          ingredients: entry.value,
        );
        importes++;
      }

      if (!mounted) return;

      // 6. Rapport
      await _showImportReport(
        importes: importes,
        platsNonTrouves: platsNonTrouves.toList()..sort(),
        ingredientsNonTrouves: ingredientsNonTrouves.toList()..sort(),
        lignesIgnorees: lignesIgnorees,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur lors de l\'import : $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _showImportReport({
    required int importes,
    required List<String> platsNonTrouves,
    required List<String> ingredientsNonTrouves,
    required int lignesIgnorees,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rapport d\'import'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$importes recette(s) importée(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (lignesIgnorees > 0) ...[
                const SizedBox(height: 8),
                Text('$lignesIgnorees ligne(s) ignorée(s) (incomplètes).'),
              ],
              if (platsNonTrouves.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Plats non trouvés :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                ...platsNonTrouves.map((p) => Text('• $p')),
              ],
              if (ingredientsNonTrouves.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Ingrédients non trouvés :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                ...ingredientsNonTrouves.map((i) => Text('• $i')),
              ],
              if (platsNonTrouves.isNotEmpty ||
                  ingredientsNonTrouves.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Vérifiez que ces noms correspondent exactement à ceux '
                  'saisis dans l\'application.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _docName(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return (data['name'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Composition articles cuisine')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _menuItemsStream,
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
            stream: _stockItemsStream,
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
                              _header(context, menuItems, stockItems),
                              _formatHint(),
                              const SizedBox(height: 20),
                              Card(
                                color: Colors.deepOrange.withValues(
                                  alpha: 0.04,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: Colors.deepOrange.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Créer un nouveau plat',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Le prix sera fixé par la gérante.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _newDishController,
                                              enabled: !isSaving,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: const InputDecoration(
                                                labelText: 'Nom du plat',
                                                hintText: 'Ex : Poulet braisé',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.restaurant,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            onPressed: isSaving
                                                ? null
                                                : _createDish,
                                            icon: const Icon(Icons.add),
                                            label: const Text('Créer'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        initialValue: _newDishCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'Catégorie',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(
                                            Icons.category_outlined,
                                          ),
                                          isDense: true,
                                        ),
                                        items: _dishCategories.map((cat) {
                                          return DropdownMenuItem<String>(
                                            value: cat,
                                            child: Text(cat),
                                          );
                                        }).toList(),
                                        onChanged: isSaving
                                            ? null
                                            : (value) {
                                                if (value == null) return;
                                                setState(() {
                                                  _newDishCategory = value;
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    menuItems.any(
                                      (doc) => doc.id == selectedMenuItemId,
                                    )
                                    ? selectedMenuItemId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Article cuisine',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.restaurant_menu),
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
                                          final doc = _findDocById(
                                            menuItems,
                                            value,
                                          );
                                          _compositionController.text =
                                              (doc?.data()?['composition'] ??
                                                      '')
                                                  .toString();
                                          _selectedItemAdresse =
                                              (doc?.data()?['adresse'] ?? '')
                                                  .toString();
                                          _allowsFreeAccompaniment =
                                              (doc?.data()?['allowsFreeAccompaniment'] ??
                                                  false) ==
                                              true;
                                        });
                                      },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez choisir un article cuisine';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _compositionController,
                                enabled: !isSaving,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Composition (optionnel)',
                                  hintText:
                                      'Laissez vide pour afficher la liste des ingrédients',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.notes_outlined),
                                ),
                              ),
                              if (selectedMenuItemId != null) ...[
                                const SizedBox(height: 16),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Photo du plat',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                MenuPhotoPicker(
                                  establishmentId: establishmentId,
                                  menuItemId: selectedMenuItemId!,
                                  currentImageUrl: _selectedItemAdresse,
                                  onUploaded: _savePhotoUrl,
                                ),
                              ],
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: _allowsFreeAccompaniment,
                                onChanged: isSaving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _allowsFreeAccompaniment =
                                              value ?? false;
                                        });
                                      },
                                title: const Text(
                                  'Donne droit à un accompagnement gratuit',
                                ),
                                subtitle: const Text(
                                  'Le client pourra choisir 1 accompagnement offert.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Ingrédients cuisine',
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
                                    backgroundColor: Colors.deepOrange,
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
                                        : 'Valider la composition cuisine',
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

  Widget _header(
    BuildContext context,
    List<DocumentSnapshot<Map<String, dynamic>>> menuItems,
    List<DocumentSnapshot<Map<String, dynamic>>> stockItems,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.food_bank_outlined, color: Colors.deepOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Définir les ingrédients cuisine',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isSaving
              ? null
              : () => _importFromExcel(menuItems, stockItems),
          icon: const Icon(Icons.upload_file),
          label: const Text('Importer Excel'),
        ),
      ],
    );
  }

  Widget _formatHint() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.25)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Format Excel attendu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Une ligne par ingrédient (le nom du plat est répété).'),
          SizedBox(height: 8),
          Text('Colonnes :'),
          SizedBox(height: 4),
          Text(
            'plat | ingredient | quantite',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          SizedBox(height: 8),
          Text('Exemple :'),
          SizedBox(height: 4),
          Text(
            'Poulet braisé | Poulet | 1\n'
            'Poulet braisé | Oignon | 2',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          SizedBox(height: 8),
          Text(
            'Les noms des plats et ingrédients doivent déjà exister '
            'dans l\'application.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _ingredientRow({
    required int index,
    required List<DocumentSnapshot<Map<String, dynamic>>> stockItems,
    required bool isSmallScreen,
  }) {
    final line = ingredientLines[index];

    final ingredientDropdown = DropdownButtonFormField<String>(
      initialValue: stockItems.any((doc) => doc.id == line.selectedStockItemId)
          ? line.selectedStockItemId
          : null,
      decoration: InputDecoration(
        labelText: 'Ingrédient ${index + 1}',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.inventory_2_outlined),
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
