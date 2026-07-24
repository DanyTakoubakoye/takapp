import 'package:flutter/material.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/services/menu_admin_service.dart';

class GestionMenuPage extends StatefulWidget {
  const GestionMenuPage({super.key});

  @override
  State<GestionMenuPage> createState() => _GestionMenuPageState();
}

class _GestionMenuPageState extends State<GestionMenuPage> {
  final MenuAdminService _service = MenuAdminService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool isAvailable = true;
  bool isForKitchen = false;
  bool isForBar = true;
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _saveMenuItem() async {
    final name = nameController.text.trim();
    final category = categoryController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le nom de l’article.'),
        ),
      );
      return;
    }

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner la catégorie.')),
      );
      return;
    }

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner un prix valide.')),
      );
      return;
    }

    if (!isForKitchen && !isForBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'L’article doit appartenir au bar, à la cuisine, ou aux deux.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final item = MenuItemModel(
        id: '',
        name: name,
        category: category,
        price: price,
        isAvailable: isAvailable,
        isForKitchen: isForKitchen,
        isForBar: isForBar,
      );

      await _service.addMenuItem(item);

      nameController.clear();
      categoryController.clear();
      priceController.clear();

      setState(() {
        isAvailable = true;
        isForKitchen = false;
        isForBar = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article enregistré avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion du menu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isSmallScreen
            ? Column(
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildListCard()),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildFormCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildListCard()),
                ],
              ),
      ),
    );
  }

  Widget _buildFormCard() {
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l’article',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
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
              CheckboxListTile(
                value: isForKitchen,
                onChanged: (value) {
                  setState(() {
                    isForKitchen = value ?? false;
                  });
                },
                title: const Text('Destiné à la cuisine'),
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: StreamBuilder<List<MenuItemModel>>(
          stream: _service.streamMenuItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }

            final items = snapshot.data ?? [];

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
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.category} • ${_departmentLabel(item)} • ${item.price.toStringAsFixed(0)} FCFA',
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
                                  await _service.deleteMenuItem(item.id);
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
