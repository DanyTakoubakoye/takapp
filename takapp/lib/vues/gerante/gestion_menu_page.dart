import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' as csv;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/menu_ingredient_model.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/stock_item_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/menu_admin_service.dart';
import 'package:takapp/services/stock_item_service.dart';
import 'package:takapp/vues/commun/module_visibility.dart';
import 'package:takapp/vues/shared/menu_photo_picker.dart';

class GestionMenuPage extends StatefulWidget {
  final String establishmentId;

  const GestionMenuPage({super.key, required this.establishmentId});

  @override
  State<GestionMenuPage> createState() => _GestionMenuPageState();
}

class _GestionMenuPageState extends State<GestionMenuPage> {
  late final MenuAdminService _service;
  late final StockItemService _stockItemService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController compositionController = TextEditingController();

  bool isAvailable = true;
  bool isForKitchen = false;
  bool isForBar = true;
  bool allowsFreeAccompaniment = false;
  bool isSaving = false;
  bool isImporting = false;

  /// Plat existant sélectionné dans l'Autocomplete.
  /// null = mode création (nouveau plat) ; renseigné = mode "fixer le prix".
  MenuItemModel? _selectedExistingItem;

  /// Liste des plats existants, mise à jour par le stream de la liste.
  List<MenuItemModel> _existingItems = [];

  final List<MenuIngredientModel> _ingredients = [];

  /// Streams créés une seule fois : les recréer dans build() relancerait
  /// l'abonnement à chaque frappe du formulaire et remettrait la liste (ou le
  /// dropdown du dialogue) en chargement.
  late final Stream<List<MenuItemModel>> _menuItemsStream;
  late final Stream<List<StockItemModel>> _stockItemsStream;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();

    _service = MenuAdminService(establishmentId: establishmentId);

    _stockItemService = StockItemService(establishmentId: establishmentId);

    _menuItemsStream = _service.streamMenuItems();

    _stockItemsStream = _stockItemService.streamItems();
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    compositionController.dispose();
    super.dispose();
  }

  Future<void> _saveMenuItem() async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showSnack(l10n.errEstablishmentNotFound);
      return;
    }

    final name = nameController.text.trim();
    final composition = compositionController.text.trim();
    final category = categoryController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty) {
      _showSnack(l10n.errItemNameRequired);
      return;
    }

    if (category.isEmpty) {
      _showSnack(l10n.errCategoryRequired);
      return;
    }

    if (price == null || price <= 0) {
      _showSnack(l10n.errValidPriceRequired);
      return;
    }

    if (!isForKitchen && !isForBar) {
      _showSnack(l10n.errItemMustBelongToBarOrKitchen);
      return;
    }

    if (_selectedExistingItem == null && _ingredients.isEmpty) {
      _showSnack(l10n.errAtLeastOneIngredient);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (_selectedExistingItem != null) {
        // MODE FIXER LE PRIX : on ne change que le prix du plat existant.
        await _service.updateMenuItem(
          establishmentId: establishmentId,
          item: _selectedExistingItem!.copyWith(
            price: price,
            allowsFreeAccompaniment: allowsFreeAccompaniment,
          ),
        );
      } else {
        // MODE CRÉATION : nouveau plat complet.
        final item = MenuItemModel(
          id: '',
          establishmentId: establishmentId,
          name: name,
          composition: composition,
          category: category,
          price: price,
          isAvailable: isAvailable,
          isForKitchen: isForKitchen,
          isForBar: isForBar,
          allowsFreeAccompaniment: allowsFreeAccompaniment,
          ingredients: List<MenuIngredientModel>.from(_ingredients),
        );
        await _service.addMenuItem(
          establishmentId: establishmentId,
          item: item,
        );
      }

      nameController.clear();
      categoryController.clear();
      priceController.clear();
      compositionController.clear();

      setState(() {
        isAvailable = true;
        isForKitchen = false;
        isForBar = true;
        _ingredients.clear();
        _selectedExistingItem = null;
        allowsFreeAccompaniment = false;
      });

      if (!mounted) return;

      _showSnack(l10n.menuItemSavedSuccess);
    } catch (e) {
      if (!mounted) return;

      _showSnack(l10n.errorPrefixed('$e'));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  /// Enregistre immédiatement l'URL de la photo dans le plat sélectionné.
  Future<void> _savePhotoUrl(String url) async {
    final l10n = AppLocalizations.of(context);
    final item = _selectedExistingItem;
    if (item == null) return;
    try {
      final updated = item.copyWith(adresse: url);
      await _service.updateMenuItem(
        establishmentId: establishmentId,
        item: updated,
      );
      if (!mounted) return;
      setState(() => _selectedExistingItem = updated);
      _showSnack(l10n.photoSaved);
    } catch (e) {
      if (!mounted) return;
      _showSnack(l10n.errPhotoSaveFailed('$e'));
    }
  }

  Future<void> _showAddIngredientDialog() async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showSnack(l10n.errEstablishmentNotFound);
      return;
    }

    StockItemModel? selectedItem;

    final quantityController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.addIngredientTitle),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<List<StockItemModel>>(
                stream: _stockItemsStream,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];

                  return DropdownButtonFormField<StockItemModel>(
                    initialValue: selectedItem,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.labelStockItem,
                    ),
                    items: items
                        .map(
                          (e) => DropdownMenuItem<StockItemModel>(
                            value: e,
                            child: Text('${e.name} • ${e.store} • ${e.unit}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      selectedItem = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.labelQuantityPerUnitSold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(quantityController.text.trim()) ?? 0;

              if (selectedItem == null || qty <= 0) {
                return;
              }

              setState(() {
                _ingredients.add(
                  MenuIngredientModel(
                    establishmentId: establishmentId,
                    itemId: selectedItem!.id,
                    itemName: selectedItem!.name,
                    store: selectedItem!.store,
                    unit: selectedItem!.unit,
                    quantity: qty,
                  ),
                );
              });

              Navigator.pop(context);
            },
            child: Text(l10n.actionAdd),
          ),
        ],
      ),
    );

    quantityController.dispose();
  }

  Future<void> _importMenuFile() async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showSnack(l10n.errEstablishmentNotFound);
      return;
    }

    setState(() {
      isImporting = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;

        setState(() {
          isImporting = false;
        });

        return;
      }

      final file = result.files.first;
      final fileName = file.name.toLowerCase();
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception(l10n.errFileEmptyOrUnreadable);
      }

      List<Map<String, dynamic>> rows = [];

      if (fileName.endsWith('.csv')) {
        rows = _parseCsvRows(bytes);
      } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        rows = _parseExcelRows(bytes);
      } else {
        throw Exception(l10n.errUnsupportedFormatExcel);
      }

      if (rows.isEmpty) {
        throw Exception(l10n.errNoUsableRowInFile);
      }

      int successCount = 0;
      int skippedCount = 0;

      final List<String> skippedReasons = [];

      for (final row in rows) {
        try {
          final name = (row['name'] ?? '').toString().trim();

          final composition = (row['composition'] ?? '').toString().trim();

          final category = (row['category'] ?? '').toString().trim();

          final price = _parsePrice(row['price']);

          bool parsedIsAvailable;

          if (row.containsKey('isAvailable')) {
            parsedIsAvailable = _parseBool(row['isAvailable'], fallback: true);
          } else {
            parsedIsAvailable = true;
          }

          bool parsedIsForKitchen;
          bool parsedIsForBar;

          final hasKitchenColumn = row.containsKey('isForKitchen');

          final hasBarColumn = row.containsKey('isForBar');

          if (hasKitchenColumn || hasBarColumn) {
            parsedIsForKitchen = _parseBool(
              row['isForKitchen'],
              fallback: false,
            );

            parsedIsForBar = _parseBool(row['isForBar'], fallback: true);
          } else {
            final department = (row['department'] ?? '').toString().trim();

            final inferred = _inferDepartments(
              category: category,
              department: department,
            );

            parsedIsForKitchen = inferred.$1;

            parsedIsForBar = inferred.$2;
          }

          if (name.isEmpty || category.isEmpty || price == null || price <= 0) {
            skippedCount++;

            skippedReasons.add(l10n.rowSkippedInvalidFields);

            continue;
          }

          if (!parsedIsForKitchen && !parsedIsForBar) {
            final inferred = _inferDepartments(
              category: category,
              department: (row['department'] ?? '').toString(),
            );

            parsedIsForKitchen = inferred.$1;

            parsedIsForBar = inferred.$2;
          }

          if (!parsedIsForKitchen && !parsedIsForBar) {
            skippedCount++;

            skippedReasons.add(l10n.rowSkippedNoDepartment(name));

            continue;
          }

          final item = MenuItemModel(
            id: '',
            establishmentId: establishmentId,
            name: name,
            composition: composition,
            category: category,
            price: price,
            isAvailable: parsedIsAvailable,
            isForKitchen: parsedIsForKitchen,
            isForBar: parsedIsForBar,
            ingredients: const [],
          );

          await _service.addMenuItem(
            establishmentId: establishmentId,
            item: item,
          );

          successCount++;
        } catch (e) {
          skippedCount++;

          skippedReasons.add(l10n.rowSkippedWithReason('$e'));
        }
      }

      if (!mounted) return;

      final summary = StringBuffer();

      summary.write(l10n.importedItemsCount(successCount));

      if (skippedCount > 0) {
        summary.write(l10n.skippedSuffix(skippedCount));
      }

      _showSnack(summary.toString());

      if (skippedReasons.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.importResultTitle),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Text(skippedReasons.join('\n')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionClose),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack(l10n.errImportFailed('$e'));
    } finally {
      if (mounted) {
        setState(() {
          isImporting = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseCsvRows(Uint8List bytes) {
    final content = utf8.decode(bytes, allowMalformed: true);

    List<List<dynamic>> table = const csv.CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content);

    if (table.isEmpty || table.length == 1) {
      table = const csv.CsvToListConverter(
        shouldParseNumbers: false,
        fieldDelimiter: ';',
        eol: '\n',
      ).convert(content);
    }

    if (table.isEmpty) return [];

    final headers = table.first.map((e) => e.toString()).toList();

    final mappedHeaders = headers.map(_normalizeHeader).toList();

    final rows = <Map<String, dynamic>>[];

    for (int i = 1; i < table.length; i++) {
      final line = table[i];

      if (line.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      final row = <String, dynamic>{};

      for (int j = 0; j < mappedHeaders.length; j++) {
        final key = mappedHeaders[j];

        if (key.isEmpty) continue;

        row[key] = j < line.length ? line[j] : null;
      }

      rows.add(row);
    }

    return rows;
  }

  List<Map<String, dynamic>> _parseExcelRows(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);

    final rows = <Map<String, dynamic>>[];

    for (final sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName];

      if (table == null || table.rows.isEmpty) {
        continue;
      }

      final headerCells = table.rows.first;

      final mappedHeaders = headerCells
          .map((cell) => _normalizeHeader(cell?.value?.toString() ?? ''))
          .toList();

      for (int i = 1; i < table.rows.length; i++) {
        final line = table.rows[i];

        if (line.every((cell) {
          final text = cell?.value?.toString() ?? '';

          return text.trim().isEmpty;
        })) {
          continue;
        }

        final row = <String, dynamic>{};

        for (int j = 0; j < mappedHeaders.length; j++) {
          final key = mappedHeaders[j];

          if (key.isEmpty) continue;

          row[key] = j < line.length ? line[j]?.value : null;
        }

        rows.add(row);
      }

      if (rows.isNotEmpty) {
        break;
      }
    }

    return rows;
  }

  /// Reconnaissance des en-têtes du fichier importé : ces libellés sont
  /// comparés aux données du client, ce n'est pas de l'affichage. Les clés
  /// renvoyées sont techniques. Ne pas traduire.
  String _normalizeHeader(String value) {
    final header = value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (header.isEmpty) return '';

    if ([
      'nom',
      'name',
      'nom article',
      'nom de l’article',
      'nom de l\'article',
      'article',
      'designation',
      'désignation',
      'item',
      'menu item',
    ].contains(header)) {
      return 'name';
    }

    if ([
      'composition',
      'contenu',
      'preparation',
      'préparation',
      'ingrédients',
      'ingredient',
      'ingrédient',
      'ingredients',
      'composant',
      'composants',
    ].contains(header)) {
      return 'composition';
    }

    if (['categorie', 'catégorie', 'category', 'type'].contains(header)) {
      return 'category';
    }

    if ([
      'prix',
      'price',
      'montant',
      'tarif',
      'coût',
      'cout',
    ].contains(header)) {
      return 'price';
    }

    if ([
      'disponible',
      'isavailable',
      'is available',
      'available',
      'actif',
      'active',
    ].contains(header)) {
      return 'isAvailable';
    }

    if ([
      'cuisine',
      'isforkitchen',
      'is for kitchen',
      'kitchen',
      'for kitchen',
      'destine cuisine',
      'destiné cuisine',
      'destine a la cuisine',
      'destiné à la cuisine',
    ].contains(header)) {
      return 'isForKitchen';
    }

    if ([
      'bar',
      'isforbar',
      'is for bar',
      'for bar',
      'destine bar',
      'destiné bar',
      'destine au bar',
      'destiné au bar',
    ].contains(header)) {
      return 'isForBar';
    }

    if ([
      'department',
      'departement',
      'département',
      'service',
      'destination',
    ].contains(header)) {
      return 'department';
    }

    return header;
  }

  /// Valeurs booléennes telles qu'elles peuvent être écrites dans le fichier
  /// importé : données d'entrée, pas de l'affichage. Ne pas traduire.
  bool _parseBool(dynamic value, {required bool fallback}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim().toLowerCase();

    if (text.isEmpty) {
      return fallback;
    }

    if (['true', '1', 'oui', 'yes', 'y', 'vrai', 'ok'].contains(text)) {
      return true;
    }

    if (['false', '0', 'non', 'no', 'n', 'faux'].contains(text)) {
      return false;
    }

    return fallback;
  }

  double? _parsePrice(dynamic value) {
    if (value == null) return null;

    String text = value.toString().trim();

    if (text.isEmpty) return null;

    text = text.replaceAll('FCFA', '');

    text = text.replaceAll('fcfa', '');

    text = text.replaceAll('F CFA', '');

    text = text.replaceAll('f cfa', '');

    text = text.replaceAll(' ', '');

    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(text)) {
      text = text.replaceAll('.', '');
    } else if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(text)) {
      text = text.replaceAll(',', '');
    } else if (text.contains('.') && text.contains(',')) {
      text = text.replaceAll('.', '');

      text = text.replaceAll(',', '.');
    } else if (text.contains(',') && !text.contains('.')) {
      text = text.replaceAll(',', '.');
    }

    return double.tryParse(text);
  }

  /// Déduit le rattachement bar/cuisine à partir des catégories libres du
  /// fichier importé. C'est de la classification de données d'entrée, pas de
  /// l'affichage : ces listes restent en français et ne sont pas traduites.
  (bool, bool) _inferDepartments({
    required String category,
    required String department,
  }) {
    final cat = category.trim().toLowerCase();

    final dep = department.trim().toLowerCase();

    if (dep.contains('cuisine') && dep.contains('bar')) {
      return (true, true);
    }

    if (dep.contains('bar')) {
      return (false, true);
    }

    if (dep.contains('cuisine')) {
      return (true, false);
    }

    if ([
      'boisson',
      'boissons',
      'drink',
      'drinks',
      'jus',
      'jus nature',
      'jus natures',
      'smoothie',
      'smoothies',
      'sirop',
      'sirops',
      'boisson chaude',
      'boissons chaudes',
      'vin',
      'vins',
      'vins et champagnes',
      'champagne',
      'champagnes',
      'vin rouge',
      'vins rouges',
      'vin blanc',
      'vins blancs',
      'rosé',
      'rosés',
      'bulles',
      'bière',
      'biere',
      'cocktail',
      'cocktails',
      'cocktail alcoolisé',
      'cocktails alcoolisés',
      'sans alcool',
      'shot',
      'shots',
      'shots et shots composés',
      'soda',
      'eau',
      'whisky',
      'whiskys',
      'whiskey',
      'whiskeys',
      'spiritueux',
      'cognac',
      'cognacs',
      'vodka',
      'vodkas',
      'betters/anisées',
      'anisée',
      'anisées',
      'rhum',
      'rhum/gin-tequila',
      'gin',
      'tequila',
      'liqueur',
      'liqueurs',
      'liqueurs crèmes',
      'alcool',
    ].contains(cat)) {
      return (false, true);
    }

    if ([
      'plat',
      'plats',
      'dessert',
      'desserts',
      'snack',
      'snacks',
      'pizza',
      'burger',
      'salade',
      'soupe',
      'grillade',
      'petit déjeuner',
      'petit dejeuner',
      'repas',
    ].contains(cat)) {
      return (true, false);
    }

    return (false, true);
  }

  String _departmentLabel(AppLocalizations l10n, MenuItemModel item) {
    if (item.isForKitchen && item.isForBar) {
      return l10n.departmentKitchenAndBar;
    }

    if (item.isForKitchen) {
      return l10n.departmentKitchen;
    }

    if (item.isForBar) {
      return l10n.storeNameBar;
    }

    return '-';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    final user = context.watch<AuthController>().currentUser;
    final canBar = user?.canAccessBar ?? true;
    final canRestaurant = user?.canAccessRestaurant ?? true;

    // On aligne l'état de rattachement de l'article sur les modules souscrits :
    // un module non souscrit ne peut pas être coché, et l'article doit rester
    // rattaché au module disponible. Abonné à tout ⇒ aucune coercition.
    if (!canBar && isForBar) isForBar = false;
    if (!canRestaurant && isForKitchen) isForKitchen = false;
    if (!isForBar && !isForKitchen) {
      if (canBar) {
        isForBar = true;
      } else if (canRestaurant) {
        isForKitchen = true;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuManagementTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isSmallScreen
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFormCard(
                        canBar: canBar,
                        canRestaurant: canRestaurant,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildListCard(user),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFormCard(
                        canBar: canBar,
                        canRestaurant: canRestaurant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildListCard(user)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFormCard({required bool canBar, required bool canRestaurant}) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.newItemTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<MenuItemModel>(
                displayStringForOption: (item) => item.name,
                optionsBuilder: (TextEditingValue value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) {
                    return _existingItems;
                  }
                  return _existingItems.where(
                    (it) => it.name.toLowerCase().contains(query),
                  );
                },
                onSelected: (item) {
                  setState(() {
                    _selectedExistingItem = item;
                    nameController.text = item.name;
                    categoryController.text = item.category;
                    compositionController.text = item.composition;
                    priceController.text = item.price > 0
                        ? item.price.toStringAsFixed(0)
                        : '';
                    isAvailable = item.isAvailable;
                    isForKitchen = item.isForKitchen;
                    isForBar = item.isForBar;
                    allowsFreeAccompaniment = item.allowsFreeAccompaniment;
                  });
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onSubmitted) {
                      // Synchronise le controller interne de l'Autocomplete
                      // avec notre nameController.
                      textController.text = nameController.text;
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: l10n.labelItemName,
                          prefixIcon: const Icon(Icons.fastfood_outlined),
                          helperText: _selectedExistingItem == null
                              ? l10n.helperNewOrExistingDish
                              : l10n.helperExistingDishPriceOnly,
                          suffixIcon: _selectedExistingItem != null
                              ? IconButton(
                                  tooltip: l10n.tooltipNewDish,
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedExistingItem = null;
                                      nameController.clear();
                                      textController.clear();
                                      categoryController.clear();
                                      compositionController.clear();
                                      priceController.clear();
                                      _ingredients.clear();
                                      allowsFreeAccompaniment = false;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (text) {
                          nameController.text = text;
                          // Si l'utilisateur modifie le texte à la main,
                          // on repasse en mode création.
                          if (_selectedExistingItem != null &&
                              text.trim().toLowerCase() !=
                                  _selectedExistingItem!.name
                                      .trim()
                                      .toLowerCase()) {
                            setState(() {
                              _selectedExistingItem = null;
                            });
                          }
                        },
                      );
                    },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: compositionController,
                enabled: _selectedExistingItem == null,
                decoration: InputDecoration(
                  labelText: l10n.labelCompositionFree,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: l10n.labelCategory,
                  prefixIcon: const Icon(Icons.category_outlined),
                  hintText: l10n.hintCategoryExample,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.labelPrice,
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              if (_selectedExistingItem != null) ...[
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
                  menuItemId: _selectedExistingItem!.id,
                  currentImageUrl: _selectedExistingItem!.adresse,
                  onUploaded: _savePhotoUrl,
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                value: isAvailable,
                onChanged: (value) {
                  setState(() {
                    isAvailable = value;
                  });
                },
                title: Text(l10n.labelAvailable),
              ),
              // Un module non souscrit n'est pas proposé au rattachement.
              if (canRestaurant)
                CheckboxListTile(
                  value: isForKitchen,
                  onChanged: (value) {
                    setState(() {
                      isForKitchen = value ?? false;
                    });
                  },
                  title: Text(l10n.labelForKitchen),
                ),
              if (canBar)
                CheckboxListTile(
                  value: isForBar,
                  onChanged: (value) {
                    setState(() {
                      isForBar = value ?? false;
                    });
                  },
                  title: Text(l10n.labelForBar),
                ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: allowsFreeAccompaniment,
                onChanged: (value) {
                  setState(() {
                    allowsFreeAccompaniment = value ?? false;
                  });
                },
                title: Text(l10n.labelFreeAccompaniment),
                subtitle: Text(
                  l10n.labelFreeAccompanimentHint,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.recipeIngredientsTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showAddIngredientDialog,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.actionAdd),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_ingredients.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.noIngredientAdded,
                    style: const TextStyle(color: Colors.black54),
                  ),
                )
              else
                Column(
                  children: List.generate(_ingredients.length, (index) {
                    final ingredient = _ingredients[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(ingredient.itemName),
                        subtitle: Text(
                          '${ingredient.quantity} ${ingredient.unit} • ${ingredient.store}',
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              _ingredients.removeAt(index);
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _saveMenuItem,
                  icon: const Icon(Icons.save_outlined),
                  label: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.actionSave),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isImporting ? null : _importMenuFile,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: isImporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.3),
                        )
                      : Text(l10n.actionImportExcelCsv),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.acceptedColumnsHint,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(UserModel? user) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: StreamBuilder<List<MenuItemModel>>(
          stream: _menuItemsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(l10n.errorPrefixed('${snapshot.error}')),
              );
            }

            // On masque les articles d'un module non souscrit (ex. articles
            // bar dans un établissement restaurant seul).
            final items = user == null
                ? (snapshot.data ?? [])
                : user.visibleMenuItems(snapshot.data ?? []);
            // Mémorise les plats existants pour l'Autocomplete du formulaire.
            _existingItems = snapshot.data ?? [];

            if (items.isEmpty) {
              return Center(child: Text(l10n.noItemRecorded));
            }

            return Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.menuItemsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.category} • ${_departmentLabel(l10n, item)}'
                          ' • ${item.price.toStringAsFixed(0)} FCFA'
                          ' • ${l10n.ingredientsCount(item.ingredients.length)}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            Switch(
                              value: item.isAvailable,
                              onChanged: (value) async {
                                await _service.updateAvailability(
                                  id: item.id,
                                  isAvailable: value,
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(l10n.confirmationTitle),
                                    content: Text(
                                      l10n.confirmDeleteItem(item.name),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l10n.actionCancel),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(l10n.actionDelete),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await _service.deleteMenuItem(
                                    establishmentId: establishmentId,
                                    id: item.id,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
