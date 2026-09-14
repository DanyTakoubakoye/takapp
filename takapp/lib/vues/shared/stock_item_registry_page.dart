import 'package:flutter/material.dart';

import 'package:takapp/core/constants/catalog_labels.dart';

import 'package:takapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/stock_item_model.dart';
import 'package:takapp/services/stock_item_service.dart';
import 'package:takapp/vues/commun/module_visibility.dart';

import 'package:excel/excel.dart' as xlsx;
import 'package:file_picker/file_picker.dart';

class StockItemRegistryPage extends StatefulWidget {
  final String establishmentId;

  const StockItemRegistryPage({super.key, required this.establishmentId});

  @override
  State<StockItemRegistryPage> createState() => _StockItemRegistryPageState();
}

class _StockItemRegistryPageState extends State<StockItemRegistryPage> {
  final StockItemService _service = StockItemService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  /// Derniers articles connus (mis à jour par le StreamBuilder).
  /// Sert à détecter les doublons lors de l'import Excel.
  List<StockItemModel> _currentItems = [];

  /// Créé une seule fois : le formulaire vit dans le StreamBuilder, donc un
  /// stream recréé à chaque rebuild détruirait les champs de saisie (le
  /// clavier s'ouvrait puis se refermait aussitôt).
  late final Stream<List<StockItemModel>> _itemsStream;

  final List<String> _categories = [
    'Céréales',
    'Boissons',
    'Condiments',
    'Viandes',
    'Légumes et fruits',
    'Produits laitiers',
    'Produits d’entretien',
    'Consommables hôtel',
    'Poissons',
    'Accompagnements',
    'Pain',
    'Pains',
    'viande',
    'poisson',
    'fromage',
    'Hamberger',
    'Condiments',
    'pate',
    'sauce',
    'Sauce',
    'Sauces',
    'œuf',
    'couverture',
    'consommable',
    'reutilisable',
    'Viandes et poissons',
    'Autres',
  ];

  final List<String> _stores = ['hotel', 'restaurant', 'bar'];

  String _selectedCategory = 'Céréales';
  String _selectedStore = 'restaurant';
  bool _isSaving = false;

  Future<void> _saveItem() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.createItem(
        establishmentId: widget.establishmentId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        unit: _unitController.text.trim(),
        store: _selectedStore,
      );

      _nameController.clear();
      _unitController.clear();

      setState(() {
        _selectedCategory = 'Céréales';
        _selectedStore = 'restaurant';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.menuItemSavedSuccess)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errSaveFailed('$e'))));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Normalise pour comparaison (minuscules + espaces compactés, sans accents gênants).
  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Convertit le libellé magasin (FR ou EN) vers la clé interne, ou null si inconnu.
  String? _resolveStore(String raw) {
    switch (_norm(raw)) {
      case 'hotel':
      case 'hôtel':
        return 'hotel';
      case 'restaurant':
        return 'restaurant';
      case 'bar':
        return 'bar';
      default:
        return null;
    }
  }

  /// Retrouve la catégorie exacte (telle que dans _categories) à partir d'un texte, ou null.
  String? _resolveCategory(String raw) {
    final n = _norm(raw);
    for (final c in _categories) {
      if (_norm(c) == n) return c;
    }
    return null;
  }

  Future<void> _importFromExcel() async {
    final l10n = AppLocalizations.of(context);

    if (widget.establishmentId.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errFileUnreadable)));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final excel = xlsx.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errEmptyExcelFile)));
        return;
      }
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.length < 2) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errNoDataRowShort)));
        return;
      }

      // Clés des articles déjà existants : nom|catégorie|magasin (normalisés).
      // Permet de sauter les doublons sans arrêter l'import.
      final clesExistantes = <String>{};
      for (final it in _currentItems) {
        clesExistantes.add(
          '${_norm(it.name)}|${_norm(it.category)}|${_norm(it.store)}',
        );
      }

      int importes = 0;
      final lignesRejetees = <String>[];
      final doublonsIgnores = <String>[];
      int lignesIgnorees = 0;

      // Ligne 0 = en-tête, on commence à 1
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) {
          lignesIgnorees++;
          continue;
        }

        final name = (row[0]?.value ?? '').toString().trim();
        final categoryRaw = (row[1]?.value ?? '').toString().trim();
        final unit = (row[2]?.value ?? '').toString().trim();
        final storeRaw = (row[3]?.value ?? '').toString().trim();

        // Ligne totalement vide → ignorée silencieusement
        if (name.isEmpty &&
            categoryRaw.isEmpty &&
            unit.isEmpty &&
            storeRaw.isEmpty) {
          continue;
        }

        if (name.isEmpty || unit.isEmpty) {
          lignesRejetees.add(l10n.rejectedRowMissingNameUnit(i + 1));
          continue;
        }

        final category = _resolveCategory(categoryRaw);
        if (category == null) {
          lignesRejetees.add(
            l10n.rejectedRowUnknownCategory(i + 1, name, categoryRaw),
          );
          continue;
        }

        final store = _resolveStore(storeRaw);
        if (store == null) {
          lignesRejetees.add(
            l10n.rejectedRowUnknownStore(i + 1, name, storeRaw),
          );
          continue;
        }

        // Doublon : même nom + même catégorie + même magasin.
        // Vérifie à la fois les articles déjà en base ET ceux déjà importés
        // dans ce même fichier. On saute sans arrêter l'import.
        final cle = '${_norm(name)}|${_norm(category)}|${_norm(store)}';
        if (clesExistantes.contains(cle)) {
          doublonsIgnores.add(
            '$name ($category, ${_storeLabel(store, l10n)})',
          );
          continue;
        }
        clesExistantes.add(cle);

        await _service.createItem(
          establishmentId: widget.establishmentId,
          name: name,
          category: category,
          unit: unit,
          store: store,
        );
        importes++;
      }

      if (!mounted) return;

      await _showImportReport(
        importes: importes,
        lignesRejetees: lignesRejetees,
        doublonsIgnores: doublonsIgnores,
        lignesIgnorees: lignesIgnorees,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errImportFailed('$e'))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showImportReport({
    required int importes,
    required List<String> lignesRejetees,
    required List<String> doublonsIgnores,
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
                    l10n.createdItemsCount(importes),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (lignesIgnorees > 0) ...[
                const SizedBox(height: 8),
                Text(l10n.ignoredEmptyRowsCount(lignesIgnorees)),
              ],
              if (doublonsIgnores.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.existingItemsIgnored,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                ...doublonsIgnores.map((d) => Text('• $d')),
              ],
              if (lignesRejetees.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.rejectedRowsTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                ...lignesRejetees.map((l) => Text('• $l')),
                const SizedBox(height: 12),
                Text(
                  l10n.validCategoriesAndStoresHint,
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Céréales':
        return Colors.amber.shade700;
      case 'Boissons':
        return Colors.blue.shade700;
      case 'Condiments':
        return Colors.deepOrange;
      case 'Viandes et poissons':
        return Colors.red.shade700;
      case 'Légumes et fruits':
        return Colors.green.shade700;
      case 'Produits laitiers':
        return Colors.indigo;
      case 'Produits d’entretien':
        return Colors.teal;
      case 'Consommables hôtel':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Céréales':
        return Icons.grain;
      case 'Boissons':
        return Icons.local_drink;
      case 'Condiments':
        return Icons.restaurant_menu;
      case 'Viandes et poissons':
        return Icons.set_meal;
      case 'Légumes et fruits':
        return Icons.eco;
      case 'Produits laitiers':
        return Icons.breakfast_dining;
      case 'Produits d’entretien':
        return Icons.cleaning_services;
      case 'Consommables hôtel':
        return Icons.hotel;
      default:
        return Icons.inventory_2;
    }
  }

  String _storeLabel(String store, AppLocalizations l10n) {
    switch (store.toLowerCase()) {
      case 'hotel':
        return l10n.storeNameHotel;
      case 'restaurant':
        return l10n.storeNameRestaurant;
      case 'bar':
        return l10n.storeNameBar;
      default:
        return store;
    }
  }

  Color _storeColor(String store) {
    switch (store.toLowerCase()) {
      case 'hotel':
        return Colors.purple;
      case 'restaurant':
        return Colors.green.shade700;
      case 'bar':
        return Colors.orange.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _storeIcon(String store) {
    switch (store.toLowerCase()) {
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'bar':
        return Icons.local_bar;
      default:
        return Icons.store;
    }
  }

  @override
  void initState() {
    super.initState();
    _itemsStream = _service.streamItems(
      establishmentId: widget.establishmentId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 800;
    final user = context.watch<AuthController>().currentUser;

    // Magasins proposables à la création, limités aux modules souscrits
    // ('divers' reste toujours proposé). Abonné à tout ⇒ liste inchangée.
    final visibleStores = _stores
        .where((s) => user == null || user.canSeeStore(s))
        .toList();

    if (visibleStores.isNotEmpty && !visibleStores.contains(_selectedStore)) {
      _selectedStore = visibleStores.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.itemRegistryTitle),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xfff5f7fb),
        child: SafeArea(
          child: StreamBuilder<List<StockItemModel>>(
            stream: _itemsStream,
            builder: (context, snapshot) {
              // On masque les articles d'un magasin non souscrit.
              final items = (snapshot.data ?? [])
                  .where((it) => user == null || user.canSeeStore(it.store))
                  .toList();

              // Mémorise les articles courants pour la détection de doublons à l'import.
              _currentItems = items;

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (isSmall) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _buildHeaderCard(items.length),
                          const SizedBox(height: 12),
                          _buildFormCard(visibleStores),
                          const SizedBox(height: 12),
                          _buildListCard(snapshot, items),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildHeaderCard(items.length),
                              const SizedBox(height: 16),
                              _buildFormCard(visibleStores),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: _buildListCard(snapshot, items),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int totalItems) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.itemRegistryTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.itemRegistrySubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalItems',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<String> stores) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_box_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Ajouter un article',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _importFromExcel,
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.actionImportFromExcel),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.excelExpectedFormat,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.columnsLabel),
                    const SizedBox(height: 4),
                    const Text(
                      'name | category | unit | store',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.exampleLabel),
                    const SizedBox(height: 4),
                    Text(
                      l10n.registryImportExampleRows,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.registryImportHint,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.labelItemName,
                  hintText: l10n.hintItemNameExamples,
                  prefixIcon: const Icon(Icons.inventory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.errItemNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: l10n.labelCategory,
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(CatalogLabels.category(l10n, category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedStore,
                decoration: InputDecoration(
                  labelText: l10n.labelStoreField,
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: stores.map((store) {
                  return DropdownMenuItem<String>(
                    value: store,
                    child: Text(_storeLabel(store, l10n)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedStore = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unitController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.labelUnit,
                  hintText: l10n.hintUnitExamplesLong,
                  prefixIcon: const Icon(Icons.straighten),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.errUnitRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt),
                  label: Text(
                    _isSaving ? l10n.savingInProgress : l10n.actionSaveItem,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(
    AsyncSnapshot<List<StockItemModel>> snapshot,
    List<StockItemModel> items,
  ) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    l10n.savedItemsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      l10n.commonError('${snapshot.error}'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 42,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.noItemRecordedYet,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.startCreatingItemsHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      itemCount: items.length,
                      shrinkWrap: true,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final color = _categoryColor(item.category);
                        final icon = _categoryIcon(item.category);
                        final storeColor = _storeColor(item.store);
                        final storeIcon = _storeIcon(item.store);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.10,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Text(
                                            CatalogLabels.category(
                                              l10n,
                                              item.category,
                                            ),
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withValues(
                                              alpha: 0.10,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.unitLine(item.unit),
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: storeColor.withValues(
                                              alpha: 0.10,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                storeIcon,
                                                size: 14,
                                                color: storeColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _storeLabel(
                                                  item.store,
                                                  l10n,
                                                ),
                                                style: TextStyle(
                                                  color: storeColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
