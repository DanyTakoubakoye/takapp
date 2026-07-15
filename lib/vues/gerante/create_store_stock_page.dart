import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CreateStoreStockPage extends StatefulWidget {
  final String establishmentId;

  const CreateStoreStockPage({super.key, required this.establishmentId});

  @override
  State<CreateStoreStockPage> createState() => _CreateStoreStockPageState();
}

class _CreateStoreStockPageState extends State<CreateStoreStockPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoadingItems = true;
  bool _isSubmitting = false;
  bool _isImporting = false;

  List<_StockItemOption> _items = [];
  _StockItemOption? _selectedItem;

  String? _importMessage;

  String get establishmentId => widget.establishmentId.trim();

  CollectionReference<Map<String, dynamic>> get _stockItemsCol {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('stock_items');
  }

  CollectionReference<Map<String, dynamic>> get _storeStocksCol {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('store_stocks');
  }

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadStockItems() async {
    if (establishmentId.isEmpty) return;

    setState(() {
      _isLoadingItems = true;
    });

    try {
      final snapshot = await _stockItemsCol
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();

            return _StockItemOption(
              id: doc.id,
              name: (data['name'] ?? '').toString(),
              store: (data['store'] ?? '').toString(),
              unit: (data['unit'] ?? '').toString(),
            );
          })
          .where((item) => item.name.trim().isNotEmpty)
          .toList();

      setState(() {
        _items = items;
        _selectedItem = items.isNotEmpty ? items.first : null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement articles : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un article.')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());

    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être un entier.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _upsertStoreStock(itemId: _selectedItem!.id, quantity: quantity);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock enregistré avec succès.')),
      );

      _quantityController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’enregistrement : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _upsertStoreStock({
    required String itemId,
    required int quantity,
  }) async {
    final stockItemDoc = await _stockItemsCol.doc(itemId).get();

    final stockItemData = stockItemDoc.data();

    if (stockItemData == null) {
      throw Exception('Article introuvable dans stock_items');
    }

    final itemName = (stockItemData['name'] ?? '').toString();

    final store = (stockItemData['store'] ?? '').toString();

    final unit = (stockItemData['unit'] ?? '').toString();

    final existing = await _storeStocksCol
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'establishmentId': establishmentId,
        'itemName': itemName,
        'quantity': quantity,
        'minimumQuantity': 0,
        'isLowStock': false,
        'store': store,
        'unit': unit,
        'updatedAt': Timestamp.now(),
      });
    } else {
      await _storeStocksCol.add({
        'establishmentId': establishmentId,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'minimumQuantity': 0,
        'isLowStock': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'store': store,
        'unit': unit,
      });
    }
  }

  Future<void> _importFile() async {
    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _importMessage = 'Import annulé.';
        });
        return;
      }

      final file = result.files.single;
      final fileName = file.name.toLowerCase();
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Impossible de lire le fichier sélectionné.');
      }

      List<Map<String, String>> rows;

      if (fileName.endsWith('.csv')) {
        rows = _readCsvRows(bytes);
      } else if (fileName.endsWith('.xlsx')) {
        rows = _readXlsxRows(bytes);
      } else {
        throw Exception('Format non supporté. Utilise CSV ou XLSX.');
      }

      if (rows.isEmpty) {
        throw Exception('Aucune ligne exploitable trouvée.');
      }

      int successCount = 0;

      final errors = <String>[];

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];

        try {
          final itemName = _pick(row, ['itemname', 'name', 'article', 'nom']);

          final quantityText = _pick(row, ['quantity', 'quantite', 'qty']);

          if (itemName.isEmpty) {
            throw Exception('nom d’article manquant');
          }

          final quantity = int.tryParse(quantityText);

          if (quantity == null) {
            throw Exception('quantité invalide');
          }

          final stockItemQuery = await _stockItemsCol
              .where('name', isEqualTo: itemName)
              .limit(1)
              .get();

          if (stockItemQuery.docs.isEmpty) {
            throw Exception('article "$itemName" introuvable dans stock_items');
          }

          final itemId = stockItemQuery.docs.first.id;

          await _upsertStoreStock(itemId: itemId, quantity: quantity);

          successCount++;
        } catch (e) {
          errors.add('Ligne ${i + 2}: $e');
        }
      }

      setState(() {
        if (errors.isEmpty) {
          _importMessage = '$successCount stock(s) importé(s) avec succès.';
        } else {
          _importMessage =
              '$successCount import(s) réussi(s), ${errors.length} erreur(s).\n${errors.join('\n')}';
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount stock(s) importé(s).')),
      );
    } catch (e) {
      setState(() {
        _importMessage = 'Erreur import : $e';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur import : $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  List<Map<String, String>> _readCsvRows(Uint8List bytes) {
    final content = utf8.decode(bytes);

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.isEmpty) return [];

    final headers = rows.first
        .map((e) => _normalizeHeader(e.toString()))
        .toList();

    final output = <Map<String, String>>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final map = <String, String>{};

      for (int j = 0; j < headers.length; j++) {
        final key = headers[j];

        if (key.isEmpty) continue;

        final value = j < row.length ? row[j].toString().trim() : '';

        map[key] = value;
      }

      output.add(map);
    }

    return output;
  }

  List<Map<String, String>> _readXlsxRows(Uint8List bytes) {
    final excel = xlsx.Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) return [];

    final firstSheetName = excel.tables.keys.first;

    final sheet = excel.tables[firstSheetName];

    if (sheet == null || sheet.rows.isEmpty) {
      return [];
    }

    final headers = sheet.rows.first
        .map((cell) => _normalizeHeader(cell?.value?.toString() ?? ''))
        .toList();

    final output = <Map<String, String>>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      final map = <String, String>{};

      for (int j = 0; j < headers.length; j++) {
        final key = headers[j];

        if (key.isEmpty) continue;

        final value = j < row.length
            ? row[j]?.value?.toString().trim() ?? ''
            : '';

        map[key] = value;
      }

      output.add(map);
    }

    return output;
  }

  String _normalizeHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _pick(Map<String, String> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];

      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.inventory_2_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Création / import de stock',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choisissez un article actif, saisissez la quantité, ou importez plusieurs lignes depuis un fichier.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 700;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saisie manuelle',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isLoadingItems)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Aucun article actif trouvé dans stock_items.'),
                )
              else ...[
                DropdownButtonFormField<_StockItemOption>(
                  value: _selectedItem,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Article de stock',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _items.map((item) {
                    return DropdownMenuItem<_StockItemOption>(
                      value: item,
                      child: Text(item.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItem = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez choisir un article';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantité',
                    hintText: 'Ex. 25',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Veuillez saisir une quantité';
                    }

                    final parsed = int.tryParse(text);

                    if (parsed == null) {
                      return 'La quantité doit être un entier';
                    }

                    if (parsed < 0) {
                      return 'La quantité ne peut pas être négative';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedItem != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Store : ${_selectedItem!.store}'),
                              const SizedBox(height: 6),
                              Text('Unité : ${_selectedItem!.unit}'),
                              const SizedBox(height: 6),
                              const Text('MinimumQuantity : 0'),
                              const SizedBox(height: 6),
                              const Text('isLowStock : false'),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text('Store : ${_selectedItem!.store}'),
                              ),
                              Expanded(
                                child: Text('Unité : ${_selectedItem!.unit}'),
                              ),
                              const Expanded(
                                child: Text('MinimumQuantity : 0'),
                              ),
                              const Expanded(child: Text('isLowStock : false')),
                            ],
                          ),
                  ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isImporting ? null : _importFile,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        _isImporting
                            ? 'Import en cours...'
                            : 'Importer CSV / Excel',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSubmitting ? 'Enregistrement...' : 'Valider',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportInfoCard() {
    return Card(
      elevation: 1,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format d’import recommandé',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Colonnes attendues :'),
            SizedBox(height: 4),
            Text('itemName | quantity'),
            SizedBox(height: 8),
            Text('Exemple :'),
            SizedBox(height: 4),
            Text('Eau minérale | 48'),
            Text('Riz local | 120'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 1,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Champs enregistrés dans store_stocks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• itemId'),
            Text('• itemName'),
            Text('• quantity'),
            Text('• minimumQuantity = 0'),
            Text('• isLowStock = false'),
            Text('• createdAt'),
            Text('• updatedAt'),
            Text('• store'),
            Text('• unit'),
            Text('• establishmentId'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Création stock gérante')),
      body: RefreshIndicator(
        onRefresh: _loadStockItems,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildForm(context),
            const SizedBox(height: 16),
            _buildImportInfoCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            if (_importMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_importMessage!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StockItemOption {
  final String id;
  final String name;
  final String store;
  final String unit;

  const _StockItemOption({
    required this.id,
    required this.name,
    required this.store,
    required this.unit,
  });
}
