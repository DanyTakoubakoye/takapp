import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/store_stock_controller.dart';
import 'package:takapp/modeles/store_stock_model.dart';
import 'package:takapp/services/store_stock_service.dart';
import 'package:takapp/vues/gerante/direct_stock_supply_page.dart';

class LowStockPage extends StatelessWidget {
  final String establishmentId;
  final List<String> stores;
  final String title;

  const LowStockPage({
    super.key,
    required this.establishmentId,
    required this.stores,
    required this.title,
  });

  Color _storeColor(String store) {
    switch (store) {
      case 'restaurant':
        return Colors.deepOrange;
      case 'bar':
        return Colors.indigo;
      case 'hotel':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = StoreStockService();
    final controller = context.watch<StoreStockController>();
    final isSmall = MediaQuery.of(context).size.width < 800;

    final Stream<List<StoreStockModel>> stream = stores.length == 1
        ? service.streamLowStocksForStore(
            establishmentId: establishmentId,
            store: stores.first,
          )
        : service.streamLowStocksForStores(
            establishmentId: establishmentId,
            stores: stores,
          );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<StoreStockModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('Aucun stock faible détecté.'));
          }

          return ListView.separated(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final color = _storeColor(item.store);
              final minController = TextEditingController(
                text: item.minimumQuantity.toStringAsFixed(
                  item.minimumQuantity % 1 == 0 ? 0 : 2,
                ),
              );

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Magasin : ${item.store}'),
                      Text(
                        'Stock actuel : ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.unit}',
                      ),
                      Text(
                        'Seuil minimum : ${item.minimumQuantity.toStringAsFixed(item.minimumQuantity % 1 == 0 ? 0 : 2)} ${item.unit}',
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nouveau seuil minimum',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DirectStockSupplyPage(
                                      establishmentId: establishmentId,
                                      store: item.store,
                                      title: 'Approvisionnement direct',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Approvisionner'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: color,
                                side: BorderSide(color: color),
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: controller.isSubmitting
                                  ? null
                                  : () async {
                                      final min = double.tryParse(
                                        minController.text.trim(),
                                      );

                                      if (min == null || min < 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Seuil invalide.'),
                                          ),
                                        );
                                        return;
                                      }

                                      final success = await controller
                                          .setMinimumQuantity(
                                            establishmentId: establishmentId,
                                            stockDocId: item.id,
                                            minimumQuantity: min,
                                          );

                                      if (!context.mounted) return;

                                      if (success) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Seuil mis à jour.'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              controller.errorMessage ??
                                                  'Erreur inconnue.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: controller.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.edit_outlined),
                              label: const Text('Mettre à jour le seuil'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
