import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:takapp/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

    if (selectedMenuItemId == null) return;
    try {
      await _service.updateMenuItemImage(
        establishmentId: establishmentId,
        menuItemId: selectedMenuItemId!,
        adresse: url,
      );
      if (!mounted) return;
      setState(() => _selectedItemAdresse = url);
      _showMessage(l10n.photoSaved);
    } catch (e) {
      if (!mounted) return;
      _showMessage(l10n.errPhotoSaveFailed('$e'));
    }
  }

  Future<void> _save(
    List<DocumentSnapshot<Map<String, dynamic>>> stockItems,
  ) async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showMessage(l10n.errEstablishmentNotFound);
      return;
    }

    if (selectedMenuItemId == null) {
      _showMessage(l10n.errPickKitchenItem);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final ingredients = <Map<String, dynamic>>[];

    for (final line in ingredientLines) {
      final stockItem = _findDocById(stockItems, line.selectedStockItemId);

      if (stockItem == null) {
        _showMessage(l10n.errPickAllIngredients);
        return;
      }

      final data = stockItem.data() ?? {};
      final quantity = int.tryParse(line.quantityController.text.trim());

      if (quantity == null || quantity <= 0) {
        _showMessage(l10n.errQuantityMustBePositiveInteger);
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

      _showMessage(l10n.kitchenIngredientsSaved);

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
      _showMessage(l10n.errSaveFailed('$e'));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _createDish() async {
    final l10n = AppLocalizations.of(context);
    final name = _newDishController.text.trim();

    if (name.isEmpty) {
      _showMessage(l10n.errDishNameRequired);
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
      _showMessage(l10n.dishCreatedCompose(name));
    } catch (e) {
      if (!mounted) return;
      _showMessage(l10n.commonError('$e'));
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
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showMessage(l10n.errEstablishmentNotFound);
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
      _showMessage(l10n.errFileUnreadable);
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
        _showMessage(l10n.errEmptyExcelFile);
        return;
      }
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.length < 2) {
        _showMessage(l10n.errNoDataRow);
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
      _showMessage(l10n.errImportFailed('$e'));
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
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importReportTitle),
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
                    l10n.importedRecipesCount(importes),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (lignesIgnorees > 0) ...[
                const SizedBox(height: 8),
                Text(l10n.ignoredRowsCount(lignesIgnorees)),
              ],
              if (platsNonTrouves.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.dishesNotFound,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                ...platsNonTrouves.map((p) => Text('• $p')),
              ],
              if (ingredientsNonTrouves.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.ingredientsNotFound,
                  style: const TextStyle(
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
                Text(
                  l10n.checkNamesMatchApp,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
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
    final l10n = AppLocalizations.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    if (establishmentId.isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.errEstablishmentNotFound)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kitchenItemsCompositionTitle)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _menuItemsStream,
        builder: (context, menuSnapshot) {
          if (menuSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (menuSnapshot.hasError) {
            return Center(
              child: Text(l10n.errMenuItemsStream('${menuSnapshot.error}')),
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
                  child: Text(
                    l10n.errStockItemsStream('${stockSnapshot.error}'),
                  ),
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
                                      Text(
                                        l10n.createNewDishTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.priceSetByManager,
                                        style: const TextStyle(
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
                                              decoration: InputDecoration(
                                                labelText: l10n.labelDishName,
                                                hintText: l10n.hintDishExample,
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixIcon: const Icon(
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
                                            label: Text(l10n.actionCreate),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        initialValue: _newDishCategory,
                                        decoration: InputDecoration(
                                          labelText: l10n.labelCategory,
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(
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
                                decoration: InputDecoration(
                                  labelText: l10n.labelKitchenItem,
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.restaurant_menu),
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
                                    return l10n.errPickKitchenItem;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _compositionController,
                                enabled: !isSaving,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: l10n.labelCompositionOptional,
                                  hintText: l10n.hintCompositionEmpty,
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.notes_outlined),
                                ),
                              ),
                              if (selectedMenuItemId != null) ...[
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l10n.dishPhotoTitle,
                                    style: const TextStyle(
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
                                title: Text(l10n.labelFreeAccompaniment),
                                subtitle: Text(
                                  l10n.labelFreeAccompanimentHint,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.kitchenIngredientsTitle,
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
                                    label: Text(l10n.actionAdd),
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
                                        ? l10n.savingInProgress
                                        : l10n.actionValidateKitchenComposition,
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
    final l10n = AppLocalizations.of(context);

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
            l10n.defineKitchenIngredientsTitle,
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
          label: Text(l10n.actionImportExcel),
        ),
      ],
    );
  }

  Widget _formatHint() {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.excelExpectedFormat,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l10n.oneRowPerIngredient),
          const SizedBox(height: 8),
          Text(l10n.columnsLabel),
          const SizedBox(height: 4),
          const Text(
            'plat | ingredient | quantite',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          Text(l10n.exampleLabel),
          const SizedBox(height: 4),
          Text(
            l10n.recipeImportExampleRows,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.namesMustExistInApp,
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
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
    final l10n = AppLocalizations.of(context);
    final line = ingredientLines[index];

    final ingredientDropdown = DropdownButtonFormField<String>(
      initialValue: stockItems.any((doc) => doc.id == line.selectedStockItemId)
          ? line.selectedStockItemId
          : null,
      decoration: InputDecoration(
        labelText: l10n.labelIngredientIndex(index + 1),
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
          return l10n.errChooseIngredient;
        }
        return null;
      },
    );

    final quantityField = TextFormField(
      controller: line.quantityController,
      enabled: !isSaving,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: l10n.labelQuantity,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.numbers),
      ),
      validator: (value) {
        final quantity = int.tryParse((value ?? '').trim());

        if (quantity == null || quantity <= 0) {
          return l10n.errInvalidQuantity;
        }

        return null;
      },
    );

    final deleteButton = IconButton(
      tooltip: l10n.tooltipRemoveLine,
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
