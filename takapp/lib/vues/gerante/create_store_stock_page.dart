import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/core/errors/app_error.dart';

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

  /// Les erreurs de ligne d'import sont levées déjà localisées puis
  /// recomposées dans le rapport : on retire seulement le préfixe technique.
  String _plain(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

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

    final l10n = AppLocalizations.of(context);

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errLoadItemsFailed('$e'))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errSelectAnItem)));
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());

    if (quantity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errQuantityMustBeInteger)));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _upsertStoreStock(itemId: _selectedItem!.id, quantity: quantity);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.stockSavedSuccess)));

      _quantityController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errSaveFailed('$e'))));
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
      // Invariant interne : ne devrait jamais remonter a l'utilisateur, mais
      // reste traduisible si c'est le cas.
      throw const AppError(AppErrorCode.itemNotFoundInStockItems);
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
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));
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
          _importMessage = l10n.importCancelled;
        });
        return;
      }

      final file = result.files.single;
      final fileName = file.name.toLowerCase();
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception(l10n.errFileUnreadable);
      }

      List<Map<String, String>> rows;

      if (fileName.endsWith('.csv')) {
        rows = _readCsvRows(bytes);
      } else if (fileName.endsWith('.xlsx')) {
        rows = _readXlsxRows(bytes);
      } else {
        throw Exception(l10n.errUnsupportedFormat);
      }

      if (rows.isEmpty) {
        throw Exception(l10n.errNoUsableRow);
      }

      int successCount = 0;

      final errors = <String>[];

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];

        try {
          // Les en-têtes acceptés sont des clés techniques normalisées.
          final itemName = _pick(row, ['itemname', 'name', 'article', 'nom']);

          final quantityText = _pick(row, ['quantity', 'quantite', 'qty']);

          if (itemName.isEmpty) {
            throw Exception(l10n.errItemNameMissing);
          }

          final quantity = int.tryParse(quantityText);

          if (quantity == null) {
            throw Exception(l10n.errQuantityInvalidShort);
          }

          final stockItemQuery = await _stockItemsCol
              .where('name', isEqualTo: itemName)
              .limit(1)
              .get();

          if (stockItemQuery.docs.isEmpty) {
            throw Exception(l10n.errItemNotInStockItems(itemName));
          }

          final itemId = stockItemQuery.docs.first.id;

          await _upsertStoreStock(itemId: itemId, quantity: quantity);

          successCount++;
        } catch (e) {
          errors.add(l10n.lineErrorLine(i + 2, _plain(e)));
        }
      }

      setState(() {
        if (errors.isEmpty) {
          _importMessage = l10n.importSuccessCount(successCount);
        } else {
          _importMessage =
              '${l10n.importPartialResult(successCount, errors.length)}\n'
              '${errors.join('\n')}';
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importedCountShort(successCount))),
      );
    } catch (e) {
      setState(() {
        _importMessage = l10n.errImportFailed(_plain(e));
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errImportFailed(_plain(e)))),
      );
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

  // Normalisation des en-têtes du fichier importé : c'est de la
  // classification de données, pas de l'affichage. Ne pas traduire.
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
    final l10n = AppLocalizations.of(context);

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
                    l10n.createStockTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createStockSubtitle,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.manualEntry,
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.noActiveItemFound),
                )
              else ...[
                DropdownButtonFormField<_StockItemOption>(
                  initialValue: _selectedItem,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.labelStockItem,
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
                      return l10n.errChooseAnItem;
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.labelQuantity,
                    hintText: l10n.hintQuantityExample,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return l10n.errQuantityRequired;
                    }

                    final parsed = int.tryParse(text);

                    if (parsed == null) {
                      return l10n.errQuantityMustBeInteger;
                    }

                    if (parsed < 0) {
                      return l10n.errQuantityNegative;
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
                    // `MinimumQuantity` et `isLowStock` sont des noms de
                    // champs Firestore : ils restent tels quels.
                    child: isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.storeLine(_selectedItem!.store)),
                              const SizedBox(height: 6),
                              Text(l10n.unitLine(_selectedItem!.unit)),
                              const SizedBox(height: 6),
                              const Text('MinimumQuantity : 0'),
                              const SizedBox(height: 6),
                              const Text('isLowStock : false'),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.storeLine(_selectedItem!.store),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  l10n.unitLine(_selectedItem!.unit),
                                ),
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
                            ? l10n.importingInProgress
                            : l10n.actionImportCsvExcel,
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
                        _isSubmitting
                            ? l10n.savingInProgress
                            : l10n.commonValidate,
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
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.importRecommendedFormat,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.expectedColumns),
            const SizedBox(height: 4),
            // En-têtes techniques attendus dans le fichier.
            const Text('itemName | quantity'),
            const SizedBox(height: 8),
            Text(l10n.exampleLabel),
            const SizedBox(height: 4),
            Text(l10n.importExampleRow1),
            Text(l10n.importExampleRow2),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fieldsSavedInStoreStocks,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Noms de champs Firestore : jamais traduits.
            const Text('• itemId'),
            const Text('• itemName'),
            const Text('• quantity'),
            const Text('• minimumQuantity = 0'),
            const Text('• isLowStock = false'),
            const Text('• createdAt'),
            const Text('• updatedAt'),
            const Text('• store'),
            const Text('• unit'),
            const Text('• establishmentId'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createStockPageTitle)),
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
