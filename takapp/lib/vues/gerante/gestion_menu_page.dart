import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' as csv;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
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
    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
      return;
    }

    final name = nameController.text.trim();
    final composition = compositionController.text.trim();
    final category = categoryController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty) {
      _showSnack('Veuillez renseigner le nom de l’article.');
      return;
    }

    if (category.isEmpty) {
      _showSnack('Veuillez renseigner la catégorie.');
      return;
    }

    if (price == null || price <= 0) {
      _showSnack('Veuillez renseigner un prix valide.');
      return;
    }

    if (!isForKitchen && !isForBar) {
      _showSnack(
        'L’article doit appartenir au bar, à la cuisine, ou aux deux.',
      );
      return;
    }

    if (_selectedExistingItem == null && _ingredients.isEmpty) {
      _showSnack('Veuillez définir au moins un ingrédient pour cet article.');
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

      _showSnack('Article enregistré avec succès.');
    } catch (e) {
      if (!mounted) return;

      _showSnack('Erreur : $e');
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
      _showSnack('Photo enregistrée.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur enregistrement photo : $e');
    }
  }

  Future<void> _showAddIngredientDialog() async {
    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
      return;
    }

    StockItemModel? selectedItem;

    final quantityController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un ingrédient'),
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
                    decoration: const InputDecoration(
                      labelText: 'Article de stock',
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
                decoration: const InputDecoration(
                  labelText: 'Quantité consommée par unité vendue',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    quantityController.dispose();
  }

  Future<void> _importMenuFile() async {
    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
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
        throw Exception('Fichier vide ou illisible.');
      }

      List<Map<String, dynamic>> rows = [];

      if (fileName.endsWith('.csv')) {
        rows = _parseCsvRows(bytes);
      } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        rows = _parseExcelRows(bytes);
      } else {
        throw Exception('Format non supporté. Utilisez CSV ou Excel.');
      }

      if (rows.isEmpty) {
        throw Exception('Aucune ligne exploitable trouvée dans le fichier.');
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

            skippedReasons.add(
              'Ligne ignorée : nom/catégorie/prix invalide(s).',
            );

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

            skippedReasons.add('Article "$name" ignoré : ni bar ni cuisine.');

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

          skippedReasons.add('Ligne ignorée : $e');
        }
      }

      if (!mounted) return;

      final summary = StringBuffer();

      summary.write('$successCount article(s) importé(s)');

      if (skippedCount > 0) {
        summary.write(' • $skippedCount ignoré(s)');
      }

      _showSnack(summary.toString());

      if (skippedReasons.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Résultat de l’import'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Text(skippedReasons.join('\n')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack('Erreur import : $e');
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
      'bière',
      'biere',
      'cocktail',
      'soda',
      'eau',
      'whisky',
      'spiritueux',
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

  String _departmentLabel(MenuItemModel item) {
    if (item.isForKitchen && item.isForBar) {
      return 'Cuisine + Bar';
    }

    if (item.isForKitchen) {
      return 'Cuisine';
    }

    if (item.isForBar) {
      return 'Bar';
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
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
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
      appBar: AppBar(title: const Text('Gestion du menu')),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nouvel article',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          labelText: 'Nom de l’article',
                          prefixIcon: const Icon(Icons.fastfood_outlined),
                          helperText: _selectedExistingItem == null
                              ? 'Tapez un nouveau nom, ou choisissez un plat existant'
                              : 'Plat existant : seul le prix est modifiable',
                          suffixIcon: _selectedExistingItem != null
                              ? IconButton(
                                  tooltip: 'Nouveau plat',
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
                decoration: const InputDecoration(
                  labelText: 'Composition (texte libre)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: 'Ex: boisson, plat, dessert, snack...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              if (_selectedExistingItem != null) ...[
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Photo du plat',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                title: const Text('Disponible'),
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
                  title: const Text('Destiné à la cuisine'),
                ),
              if (canBar)
                CheckboxListTile(
                  value: isForBar,
                  onChanged: (value) {
                    setState(() {
                      isForBar = value ?? false;
                    });
                  },
                  title: const Text('Destiné au bar'),
                ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: allowsFreeAccompaniment,
                onChanged: (value) {
                  setState(() {
                    allowsFreeAccompaniment = value ?? false;
                  });
                },
                title: const Text('Donne droit à un accompagnement gratuit'),
                subtitle: const Text(
                  'Le client pourra choisir 1 accompagnement offert.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recette / ingrédients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showAddIngredientDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_ingredients.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Aucun ingrédient ajouté.',
                    style: TextStyle(color: Colors.black54),
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
                      : const Text('Enregistrer'),
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
                      : const Text('Importer Excel / CSV'),
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Colonnes acceptées : nom, composition, catégorie, prix, disponible, cuisine, bar.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(UserModel? user) {
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
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }

            // On masque les articles d'un module non souscrit (ex. articles
            // bar dans un établissement restaurant seul).
            final items = user == null
                ? (snapshot.data ?? [])
                : user.visibleMenuItems(snapshot.data ?? []);
            // Mémorise les plats existants pour l'Autocomplete du formulaire.
            _existingItems = snapshot.data ?? [];

            if (items.isEmpty) {
              return const Center(child: Text('Aucun article enregistré.'));
            }

            return Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Articles du menu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          '${item.category} • ${_departmentLabel(item)} • ${item.price.toStringAsFixed(0)} FCFA • ${item.ingredients.length} ingrédient(s)',
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
                                    title: const Text('Confirmation'),
                                    content: Text(
                                      'Supprimer l’article "${item.name}" ?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Supprimer'),
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
