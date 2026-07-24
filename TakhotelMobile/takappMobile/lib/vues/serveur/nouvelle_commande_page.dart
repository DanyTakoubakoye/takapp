import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/services/menu_service.dart';

class NouvelleCommandePage extends StatefulWidget {
  const NouvelleCommandePage({super.key});

  @override
  State<NouvelleCommandePage> createState() => _NouvelleCommandePageState();
}

class _NouvelleCommandePageState extends State<NouvelleCommandePage> {
  final MenuService _menuService = MenuService();

  String clientType = 'restaurant';
  final TextEditingController tableController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  @override
  void dispose() {
    tableController.dispose();
    roomController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final auth = context.read<AuthController>();
    final orderController = context.read<OrderController>();

    final user = auth.currentUser;
    if (user == null) return;

    final success = await orderController.submitOrder(
      clientType: clientType,
      tableNumber: tableController.text,
      roomNumber: roomController.text,
      createdBy: user.uid,
      createdByName: user.name,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande envoyée avec succès.')),
      );

      tableController.clear();
      roomController.clear();
      setState(() {
        clientType = 'restaurant';
      });
    } else if (orderController.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(orderController.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle commande')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: clientType,
                        decoration: const InputDecoration(
                          labelText: 'Type de client',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'bar',
                            child: Text('Client Bar'),
                          ),
                          DropdownMenuItem(
                            value: 'restaurant',
                            child: Text('Client Restaurant'),
                          ),
                          DropdownMenuItem(
                            value: 'hotel',
                            child: Text('Client Hôtel'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            clientType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (clientType == 'restaurant')
                        TextField(
                          controller: tableController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de table',
                          ),
                        ),
                      if (clientType == 'hotel')
                        TextField(
                          controller: roomController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de chambre',
                          ),
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: StreamBuilder<List<MenuItemModel>>(
                          stream: _menuService.getAvailableMenuItems(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${snapshot.error}'),
                              );
                            }

                            final items = snapshot.data ?? [];

                            if (items.isEmpty) {
                              return const Center(
                                child: Text('Aucun article disponible.'),
                              );
                            }

                            return ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    '${item.category} • ${item.price.toStringAsFixed(0)} FCFA',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<OrderController>()
                                          .addMenuItem(item);
                                    },
                                    child: const Text('Ajouter'),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Panier',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: orderController.items.isEmpty
                            ? const Center(child: Text('Aucun article ajouté.'))
                            : ListView.separated(
                                itemCount: orderController.items.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16),
                                itemBuilder: (context, index) {
                                  final item = orderController.items[index];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.unitPrice.toStringAsFixed(0)} FCFA x ${item.quantity} = ${item.totalPrice.toStringAsFixed(0)} FCFA',
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              context
                                                  .read<OrderController>()
                                                  .decrementItem(
                                                    item.menuItemId,
                                                  );
                                            },
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          Text('${item.quantity}'),
                                          IconButton(
                                            onPressed: () {
                                              context
                                                  .read<OrderController>()
                                                  .incrementItem(
                                                    item.menuItemId,
                                                  );
                                            },
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sous-total : ${orderController.subtotal.toStringAsFixed(0)} FCFA',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total : ${orderController.total.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: orderController.isSubmitting
                            ? null
                            : _submitOrder,
                        child: orderController.isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Envoyer la commande'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
