import 'package:flutter/material.dart';

import 'package:takapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:takapp/modeles/store_stock_model.dart';
import 'package:takapp/services/store_stock_service.dart';

class StoreStockPage extends StatelessWidget {
  final String establishmentId;
  final String store;
  final String title;

  const StoreStockPage({
    super.key,
    required this.establishmentId,
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

  IconData _storeIcon() {
    switch (store) {
      case 'restaurant':
        return Icons.restaurant;
      case 'bar':
        return Icons.local_bar;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.store;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = StoreStockService();
    final isSmall = MediaQuery.of(context).size.width < 800;
    final color = _storeColor();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<StoreStockModel>>(
        stream: service.streamStocksForStore(
          establishmentId: establishmentId,
          store: store,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.commonError('${snapshot.error}')));
          }

          final stocks = snapshot.data ?? [];

          if (stocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_storeIcon(), size: 60, color: color.withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noStockForStore,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          if (isSmall) {
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: stocks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = stocks[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(_storeIcon(), color: color),
                    ),
                    title: Text(
                      item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${l10n.storeNameLine(item.store)}\n'
                      '${l10n.unitLine(item.unit)}\n'
                      '${l10n.updatedAtLine(item.updatedAt == null ? "-" : DateFormat('dd/MM/yyyy HH:mm').format(item.updatedAt!))}',
                    ),
                    trailing: Text(
                      item.quantity.toStringAsFixed(
                        item.quantity % 1 == 0 ? 0 : 2,
                      ),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  columnSpacing: 20,
                  columns: [
                    DataColumn(label: Text(l10n.labelItem)),
                    DataColumn(label: Text(l10n.labelStoreWord)),
                    DataColumn(label: Text(l10n.labelUnit)),
                    DataColumn(label: Text(l10n.labelQuantity)),
                    DataColumn(label: Text(l10n.labelLastUpdate)),
                  ],
                  rows: stocks.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item.itemName)),
                        DataCell(Text(item.store)),
                        DataCell(Text(item.unit)),
                        DataCell(
                          Text(
                            item.quantity.toStringAsFixed(
                              item.quantity % 1 == 0 ? 0 : 2,
                            ),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.updatedAt == null
                                ? '-'
                                : DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(item.updatedAt!),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
