import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/stock_request_model.dart';
import 'package:takapp/services/stock_request_service.dart';
import 'package:takapp/vues/gerante/stock_delivery_page.dart';

class StockRequestListPage extends StatefulWidget {
  final String establishmentId;
  final String? storeFilter;

  const StockRequestListPage({
    super.key,
    required this.establishmentId,
    this.storeFilter,
  });

  @override
  State<StockRequestListPage> createState() => _StockRequestListPageState();
}

class _StockRequestListPageState extends State<StockRequestListPage> {
  // Valeur technique : elle est comparée à `item.status` tel qu'il est stocké.
  String statusFilter = 'pending';

  String get establishmentId => widget.establishmentId.trim();

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

  // `store` et `status` restent des valeurs techniques en base : seul leur
  // rendu est localisé, et une valeur inconnue est affichée telle quelle.
  String _storeLabel(AppLocalizations l10n, String store) {
    switch (store) {
      case 'restaurant':
        return l10n.storeNameRestaurant;
      case 'bar':
        return l10n.storeNameBar;
      case 'hotel':
        return l10n.storeNameHotel;
      default:
        return store;
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.statusPending;
      case 'delivered':
        return l10n.statusDelivered;
      case 'received':
        return l10n.statusReceived;
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
      return service.streamRequestsForStore(
        establishmentId: establishmentId,
        store: widget.storeFilter!,
      );
    }

    return service.streamAllRequests(establishmentId: establishmentId);
  }

  /// Les `value` des options restent techniques : seul le libellé est traduit.
  List<DropdownMenuItem<String>> _statusFilterItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem(value: 'pending', child: Text(l10n.statusPending)),
      DropdownMenuItem(value: 'delivered', child: Text(l10n.filterDelivered)),
      DropdownMenuItem(value: 'received', child: Text(l10n.filterReceived)),
      DropdownMenuItem(value: 'all', child: Text(l10n.categoryAll)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = StockRequestService();

    final isSmall = MediaQuery.of(context).size.width < 800;

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.storeFilter == null
              ? l10n.supplyRequests
              : l10n.supplyRequestsForStore(
                  _storeLabel(l10n, widget.storeFilter!),
                ),
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
                            initialValue: statusFilter,
                            decoration: InputDecoration(
                              labelText: l10n.labelStatus,
                            ),
                            items: _statusFilterItems(l10n),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                statusFilter = value;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.filterRequests,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String>(
                              initialValue: statusFilter,
                              decoration: InputDecoration(
                                labelText: l10n.labelStatus,
                              ),
                              items: _statusFilterItems(l10n),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

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
                    return Center(
                      child: Text(l10n.errorPrefixed('${snapshot.error}')),
                    );
                  }

                  final allItems = snapshot.data ?? [];

                  final items = allItems.where((item) {
                    if (statusFilter == 'all') {
                      return true;
                    }

                    return item.status == statusFilter;
                  }).toList();

                  if (items.isEmpty) {
                    return Center(child: Text(l10n.noRequestFound));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                                _storeLabel(l10n, item.store),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: storeColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(l10n.requestedByLine(item.requestedByName)),
                              // Le rôle stocké est une clé technique.
                              Text(
                                l10n.roleLine(
                                  AppRoles.label(l10n, item.requestedByRole),
                                ),
                              ),
                              Text(
                                l10n.dateLine(
                                  item.createdAt == null
                                      ? '-'
                                      : DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(item.createdAt!),
                                ),
                              ),
                              if (item.note.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(l10n.noteLine(item.note)),
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
                                      color: storeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _storeLabel(l10n, item.store),
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
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusLabel(l10n, item.status),
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
                                              establishmentId: establishmentId,
                                              request: item,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                      label: Text(l10n.actionOpen),
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
