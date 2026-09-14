import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:excel2003/excel2003.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:takapp/l10n/app_localizations.dart';

class StockItemFormPage extends StatefulWidget {
  final String establishmentId;

  const StockItemFormPage({super.key, required this.establishmentId});

  @override
  State<StockItemFormPage> createState() => _StockItemFormPageState();
}

class _StockItemFormPageState extends State<StockItemFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _stores = const ['restaurant', 'hotel', 'bar', 'divers'];

  String _selectedStore = 'restaurant';
  bool _isActive = true;

  bool _isSaving = false;
  bool _isImporting = false;
  String? _importMessage;
  bool _importHasError = false;

  String get establishmentId => widget.establishmentId.trim();

  CollectionReference<Map<String, dynamic>> get _stockItemsCol {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('stock_items');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveSingleItem() async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showMessage(l10n.errEstablishmentNotFound);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _stockItemsCol.add({
        'establishmentId': establishmentId,
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'isActive': _isActive,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'store': _selectedStore,
        'unit': _unitController.text.trim(),
      });

      _nameController.clear();
      _categoryController.clear();
      _unitController.clear();

      if (!mounted) return;
      _showMessage(l10n.menuItemSavedSuccess);
    } catch (e) {
      if (!mounted) return;
      _showMessage(l10n.errSaveFailed('$e'));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _importFromExcel() async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showMessage(l10n.errEstablishmentNotFound);
      return;
    }

    setState(() {
      _isImporting = true;
      _importMessage = null;
      _importHasError = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isImporting = false;
          _importMessage = l10n.importCancelled;
        });
        return;
      }

      final file = result.files.single;
      final fileName = file.name.toLowerCase();
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception(l10n.errCannotReadFile);
      }

      List<Map<String, dynamic>> rows;

      if (fileName.endsWith('.xlsx')) {
        rows = _readXlsxRows(bytes);
      } else if (fileName.endsWith('.xls')) {
        rows = _readXlsRows(bytes, l10n);
      } else {
        throw Exception(l10n.errUnsupportedFormatXlsx);
      }

      if (rows.isEmpty) {
        throw Exception(l10n.errNoUsableRow);
      }

      final cleanedRows = rows
          .map(_normalizeImportedRow)
          .where((row) => row != null)
          .cast<Map<String, dynamic>>()
          .toList();

      if (cleanedRows.isEmpty) {
        throw Exception(l10n.errNoValidRowAfterNormalization);
      }

      final batch = _firestore.batch();
      final now = Timestamp.now();

      for (final row in cleanedRows) {
        final docRef = _stockItemsCol.doc();

        batch.set(docRef, {
          'establishmentId': establishmentId,
          'name': row['name'],
          'category': row['category'],
          'isActive': row['isActive'],
          'createdAt': now,
          'updatedAt': now,
          'store': row['store'],
          'unit': row['unit'],
        });
      }

      await batch.commit();

      setState(() {
        _importHasError = false;
        _importMessage = l10n.importedItemsSuccessCount(cleanedRows.length);
      });

      if (!mounted) return;
      _showMessage(_importMessage!);
    } catch (e) {
      setState(() {
        _importHasError = true;
        _importMessage = l10n.errImportFailed('$e');
      });

      if (!mounted) return;
      _showMessage(_importMessage!);
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  List<Map<String, dynamic>> _readXlsxRows(Uint8List bytes) {
    final excel = xlsx.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final firstSheetName = excel.tables.keys.first;
    final sheet = excel.tables[firstSheetName];
    if (sheet == null || sheet.rows.isEmpty) return [];

    final headers = sheet.rows.first
        .map((cell) => _normalizeHeader(cell?.value?.toString() ?? ''))
        .toList();

    final rows = <Map<String, dynamic>>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final map = <String, dynamic>{};

      for (int j = 0; j < headers.length; j++) {
        final key = headers[j];
        if (key.isEmpty) continue;

        final value = j < row.length ? row[j]?.value : null;
        map[key] = value?.toString().trim() ?? '';
      }

      rows.add(map);
    }

    return rows;
  }

  List<Map<String, dynamic>> _readXlsRows(
    Uint8List bytes,
    AppLocalizations l10n,
  ) {
    if (kIsWeb) {
      throw Exception(l10n.errXlsNotSupportedWeb);
    }

    final reader = XlsReader.fromBytes(bytes);
    reader.open();

    if (reader.sheetCount == 0) return [];

    final sheet = reader.sheet(0);
    final rawRows = sheet.toMaps();

    return rawRows.map((e) {
      final normalized = <String, dynamic>{};

      e.forEach((key, value) {
        normalized[_normalizeHeader(key.toString())] =
            value?.toString().trim() ?? '';
      });

      return normalized;
    }).toList();
  }

  Map<String, dynamic>? _normalizeImportedRow(Map<String, dynamic> row) {
    final name = _pickFirst(row, ['name', 'nom']);
    final category = _pickFirst(row, ['category', 'categorie']);
    final unit = _pickFirst(row, ['unit', 'unite']);
    final store = _pickFirst(row, ['store', 'magasin']);
    final isActiveRaw = _pickFirst(row, ['isactive', 'active', 'actif']);

    if (name.isEmpty || category.isEmpty || unit.isEmpty || store.isEmpty) {
      return null;
    }

    final normalizedStore = _normalizeStore(store);

    if (normalizedStore == null) {
      return null;
    }

    return {
      'name': name,
      'category': category,
      'unit': unit,
      'store': normalizedStore,
      'isActive': _parseBool(isActiveRaw, defaultValue: true),
    };
  }

  String _pickFirst(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  String _normalizeHeader(String input) {
    return input
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

  String? _normalizeStore(String input) {
    final v = input.trim().toLowerCase();

    if (v == 'restaurant' || v == 'resturant') return 'restaurant';
    if (v == 'hotel') return 'hotel';
    if (v == 'bar') return 'bar';
    if (v == 'divers') return 'divers';

    return null;
  }

  bool _parseBool(String input, {bool defaultValue = true}) {
    final v = input.trim().toLowerCase();

    if (v.isEmpty) return defaultValue;

    if (['true', '1', 'yes', 'oui', 'actif', 'active'].contains(v)) {
      return true;
    }

    if (['false', '0', 'no', 'non', 'inactif', 'inactive'].contains(v)) {
      return false;
    }

    return defaultValue;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).errRequiredField;
        }

        return null;
      },
    );
  }

  Widget _buildImportInfoCard() {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.excelExpectedFormat,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.recommendedColumns),
            const SizedBox(height: 4),
            const Text('name | category | unit | store | isActive'),
            const SizedBox(height: 8),
            Text(l10n.exampleRowLabel),
            const SizedBox(height: 4),
            Text(l10n.stockImportExampleRow),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 700;

    if (establishmentId.isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.errEstablishmentNotFound)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockItemsManagementTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.newItemTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (isSmall) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  label: l10n.labelName,
                                  hint: l10n.hintItemNameExample,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _categoryController,
                                  label: l10n.labelCategory,
                                  hint: l10n.hintCategoryDrink,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _unitController,
                                  label: l10n.labelUnit,
                                  hint: l10n.hintUnitExamples,
                                ),
                              ] else
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _nameController,
                                        label: l10n.labelName,
                                        hint: l10n.hintItemNameExample,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _categoryController,
                                        label: l10n.labelCategory,
                                        hint: l10n.hintCategoryDrink,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _unitController,
                                        label: l10n.labelUnit,
                                        hint: l10n.hintUnitExamples,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              if (isSmall) ...[
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedStore,
                                  decoration: InputDecoration(
                                    labelText: l10n.labelStore,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _stores
                                      .map(
                                        (store) => DropdownMenuItem<String>(
                                          value: store,
                                          child: Text(store),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _selectedStore = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(l10n.labelActiveItem),
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() => _isActive = value);
                                  },
                                ),
                              ] else
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _selectedStore,
                                        decoration: InputDecoration(
                                          labelText: l10n.labelStore,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        items: _stores
                                            .map(
                                              (store) =>
                                                  DropdownMenuItem<String>(
                                                    value: store,
                                                    child: Text(store),
                                                  ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _selectedStore = value,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SwitchListTile(
                                        title: Text(l10n.labelActiveItem),
                                        value: _isActive,
                                        onChanged: (value) {
                                          setState(() => _isActive = value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveSingleItem,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                    _isSaving
                                        ? l10n.savingInProgress
                                        : l10n.actionSave,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildImportInfoCard(),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.excelImportTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.excelImportStockDescription),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isImporting ? null : _importFromExcel,
                              icon: _isImporting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(
                                _isImporting
                                    ? l10n.importingInProgress
                                    : l10n.actionImportFromExcel,
                              ),
                            ),
                          ],
                        ),
                        if (_importMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _importMessage!,
                            style: TextStyle(
                              color: _importHasError
                                  ? Colors.red
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
