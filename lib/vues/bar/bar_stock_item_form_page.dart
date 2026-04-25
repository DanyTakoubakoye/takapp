import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BarStockItemFormPage extends StatefulWidget {
  const BarStockItemFormPage({super.key});

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

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveBarItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('stock_items').add({
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'unit': _unitController.text.trim(),
        'store': 'bar',
        'isActive': _isActive,
        'createdAt': Timestamp.now(),
      });

      _nameController.clear();
      _categoryController.clear();
      _unitController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article du bar enregistré avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’enregistrement : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
          return 'Champ obligatoire';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;

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
                        onChanged: (value) {
                          setState(() => _isActive = value);
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
