import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';

class BarStockItemFormPage extends StatefulWidget {
  final String establishmentId;
  const BarStockItemFormPage({super.key, required this.establishmentId});

  @override
  State<BarStockItemFormPage> createState() => _BarStockItemFormPageState();
}

class _BarStockItemFormPageState extends State<BarStockItemFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _categoryController = TextEditingController();

  final _unitController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSaving = false;
  bool _isActive = true;

  /// =========================
  /// SAAS HELPERS
  /// =========================

  String get establishmentId {
    final auth = context.read<AuthController>();

    return auth.currentUser?.establishmentId ?? '';
  }

  CollectionReference<Map<String, dynamic>> get _stockCollection {
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

  /// =========================
  /// SAVE ITEM
  /// =========================

  Future<void> _saveBarItem() async {
    if (establishmentId.trim().isEmpty) {
      _showMessage('Établissement introuvable.');

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final cleanName = _nameController.text.trim();

      final cleanCategory = _categoryController.text.trim();

      final cleanUnit = _unitController.text.trim();

      /// =========================
      /// CHECK DUPLICATE
      /// =========================

      final existing = await _stockCollection
          .where('name', isEqualTo: cleanName)
          .where('store', isEqualTo: 'bar')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Cet article existe déjà.');
      }

      /// =========================
      /// CREATE ITEM
      /// =========================

      final docRef = _stockCollection.doc();

      await docRef.set({
        'id': docRef.id,

        'establishmentId': establishmentId,

        'name': cleanName,

        'category': cleanCategory,

        'unit': cleanUnit,

        'store': 'bar',

        'isActive': _isActive,

        'isDeleted': false,

        'createdAt': FieldValue.serverTimestamp(),

        'updatedAt': FieldValue.serverTimestamp(),

        'pendingSync': false,

        'syncError': false,
      });

      _nameController.clear();

      _categoryController.clear();

      _unitController.clear();

      if (!mounted) return;

      _showMessage('Article du bar enregistré avec succès.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erreur lors de l’enregistrement : $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
  /// TEXT FIELD
  /// =========================

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
          return 'Champ obligatoire';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;

    if (establishmentId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Articles de stock - Bar')),

        body: const Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Articles de stock - Bar')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),

            child: Card(
              elevation: 2,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Nouvel article du bar',

                        style: Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Le store est automatiquement défini sur : bar',

                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 20),

                      if (isSmall) ...[
                        _buildTextField(
                          controller: _nameController,

                          label: 'Nom',

                          hint: 'Ex. Coca-Cola 33cl',
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _categoryController,

                          label: 'Catégorie',

                          hint: 'Ex. Boisson gazeuse',
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _unitController,

                          label: 'Unité',

                          hint: 'Ex. bouteille, canette, carton',
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _nameController,

                                label: 'Nom',

                                hint: 'Ex. Coca-Cola 33cl',
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildTextField(
                                controller: _categoryController,

                                label: 'Catégorie',

                                hint: 'Ex. Boisson gazeuse',
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildTextField(
                                controller: _unitController,

                                label: 'Unité',

                                hint: 'Ex. bouteille, canette, carton',
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,

                        title: const Text('Article actif'),

                        value: _isActive,

                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                      ),

                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerRight,

                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveBarItem,

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
                                ? 'Enregistrement...'
                                : 'Enregistrer l’article',
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
      ),
    );
  }
}
