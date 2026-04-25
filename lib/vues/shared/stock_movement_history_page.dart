import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:takapp/modeles/stock_movement_model.dart';
import 'package:takapp/services/store_stock_service.dart';

class StockMovementHistoryPage extends StatelessWidget {
  final String store;
  final String title;

  const StockMovementHistoryPage({
    super.key,
    required this.store,
    required this.title,
  });

  Color _storeColor() {
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
    _storeColor();
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<StockMovementModel>>(
        stream: service.streamMovementsForStore(store),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('Aucun mouvement enregistré.'));
          }

          return ListView.separated(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final isIn = item.movementType == 'in';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (isIn ? Colors.green : Colors.red)
                        .withOpacity(0.12),
                    child: Icon(
                      isIn ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIn ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    item.itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Type : ${isIn ? "Entrée" : "Sortie"}\n'
                    'Quantité : ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.unit}\n'
                    'Motif : ${item.reason}\n'
                    'Par : ${item.performedByName}\n'
                    'Date : ${item.createdAt == null ? "-" : DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!)}',
                  ),
                  trailing: Text(
                    isIn ? '+${item.quantity}' : '-${item.quantity}',
                    style: TextStyle(
                      color: isIn ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
