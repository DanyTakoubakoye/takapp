import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:takapp/modeles/stock_request_model.dart';
import 'package:takapp/services/stock_request_service.dart';
import 'package:takapp/vues/gerante/stock_delivery_page.dart';

class StockRequestListPage extends StatefulWidget {
  final String? storeFilter;

  const StockRequestListPage({super.key, this.storeFilter});

  @override
  State<StockRequestListPage> createState() => _StockRequestListPageState();
}

class _StockRequestListPageState extends State<StockRequestListPage> {
  String statusFilter = 'pending';

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

  String _storeLabel(String store) {
    switch (store) {
      case 'restaurant':
        return 'Restaurant';
      case 'bar':
        return 'Bar';
      case 'hotel':
        return 'Hôtel';
      default:
        return store;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'delivered':
        return 'Livrée';
      case 'received':
        return 'Réceptionnée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.blue;
      case 'received':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Stream<List<StockRequestModel>> _buildStream(StockRequestService service) {
    if (widget.storeFilter != null && widget.storeFilter!.trim().isNotEmpty) {
      return service.streamRequestsForStore(widget.storeFilter!);
    }
    return service.streamAllRequests();
  }

  @override
  Widget build(BuildContext context) {
    final service = StockRequestService();
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.storeFilter == null
              ? 'Demandes d’approvisionnement'
              : 'Demandes - ${_storeLabel(widget.storeFilter!)}',
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: isSmall
                    ? Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Statut',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('En attente'),
                              ),
                              DropdownMenuItem(
                                value: 'delivered',
                                child: Text('Livrées'),
                              ),
                              DropdownMenuItem(
                                value: 'received',
                                child: Text('Réceptionnées'),
                              ),
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Toutes'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                statusFilter = value;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filtrer les demandes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String>(
                              value: statusFilter,
                              decoration: const InputDecoration(
                                labelText: 'Statut',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('En attente'),
                                ),
                                DropdownMenuItem(
                                  value: 'delivered',
                                  child: Text('Livrées'),
                                ),
                                DropdownMenuItem(
                                  value: 'received',
                                  child: Text('Réceptionnées'),
                                ),
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Toutes'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  statusFilter = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<StockRequestModel>>(
                stream: _buildStream(service),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }

                  final allItems = snapshot.data ?? [];

                  final items = allItems.where((item) {
                    if (statusFilter == 'all') return true;
                    return item.status == statusFilter;
                  }).toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('Aucune demande trouvée.'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final storeColor = _storeColor(item.store);
                      final statusColor = _statusColor(item.status);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _storeLabel(item.store),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: storeColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Demandé par : ${item.requestedByName}'),
                              Text('Rôle : ${item.requestedByRole}'),
                              Text(
                                'Date : ${item.createdAt == null ? "-" : DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!)}',
                              ),
                              if (item.note.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Note : ${item.note}'),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: storeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _storeLabel(item.store),
                                      style: TextStyle(
                                        color: storeColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusLabel(item.status),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => StockDeliveryPage(
                                              request: item,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                      label: const Text('Ouvrir'),
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
            ),
          ],
        ),
      ),
    );
  }
}
