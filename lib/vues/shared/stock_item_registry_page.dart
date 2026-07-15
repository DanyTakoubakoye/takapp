import 'package:flutter/material.dart';
import 'package:takapp/modeles/stock_item_model.dart';
import 'package:takapp/services/stock_item_service.dart';

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

  final List<String> _categories = [
    'Céréales',
    'Boissons',
    'Condiments',
    'Viandes et poissons',
    'Légumes et fruits',
    'Produits laitiers',
    'Produits d’entretien',
    'Consommables hôtel',
    'Autres',
  ];

  final List<String> _stores = ['hotel', 'restaurant', 'bar'];

  String _selectedCategory = 'Céréales';
  String _selectedStore = 'restaurant';
  bool _isSaving = false;

  Future<void> _saveItem() async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article enregistré avec succès.')),
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

  String _storeLabel(String store) {
    switch (store.toLowerCase()) {
      case 'hotel':
        return 'Hôtel';
      case 'restaurant':
        return 'Restaurant';
      case 'bar':
        return 'Bar';
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
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registre des articles'),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xfff5f7fb),
        child: SafeArea(
          child: StreamBuilder<List<StockItemModel>>(
            stream: _service.streamItems(
              establishmentId: widget.establishmentId,
            ),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (isSmall) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _buildHeaderCard(items.length),
                          const SizedBox(height: 12),
                          _buildFormCard(),
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
                              _buildFormCard(),
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
            color: Colors.blue.withOpacity(0.18),
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
              color: Colors.white.withOpacity(0.15),
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
                const Text(
                  'Registre des articles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crée et organise les articles de stock avant approvisionnement.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
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

  Widget _buildFormCard() {
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
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nom de l’article',
                  hintText: 'Ex : Riz, Huile, Sucre',
                  prefixIcon: const Icon(Icons.inventory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir le nom de l’article.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
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
                value: _selectedStore,
                decoration: InputDecoration(
                  labelText: 'Magasin',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _stores.map((store) {
                  return DropdownMenuItem<String>(
                    value: store,
                    child: Text(_storeLabel(store)),
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
                  labelText: 'Unité',
                  hintText: 'Ex : g, cl, bouteille, sachet, pièce',
                  prefixIcon: const Icon(Icons.straighten),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir l’unité.';
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
                    _isSaving ? 'Enregistrement...' : 'Enregistrer l’article',
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
              const Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Articles enregistrés',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                      'Erreur : ${snapshot.error}',
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
                  child: const Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 42,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aucun article enregistré pour le moment.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Commence par créer des articles comme riz, huile, sucre, eau minérale, détergent, etc.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                              color: color.withOpacity(0.12),
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
                                        color: color.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        item.category,
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
                                        color: Colors.blueGrey.withOpacity(
                                          0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Unité : ${item.unit}',
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
                                        color: storeColor.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(30),
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
                                            _storeLabel(item.store),
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
            ],
          ),
        ),
      ),
    );
  }
}
