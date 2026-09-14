import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/stock_request_controller.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/stock_request_item_model.dart';
import 'package:takapp/modeles/stock_request_model.dart';
import 'package:takapp/services/stock_request_service.dart';

class StockDeliveryPage extends StatefulWidget {
  final String establishmentId;
  final StockRequestModel request;

  const StockDeliveryPage({
    super.key,
    required this.establishmentId,
    required this.request,
  });

  @override
  State<StockDeliveryPage> createState() => _StockDeliveryPageState();
}

class _StockDeliveryPageState extends State<StockDeliveryPage> {
  final StockRequestService _service = StockRequestService();

  List<_DeliveryLineInput> _lines = [];
  bool _isLoadingItems = true;

  String get establishmentId => widget.establishmentId.trim();

  Color _storeColor() {
    switch (widget.request.store) {
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
  String _storeLabel(AppLocalizations l10n) {
    switch (widget.request.store) {
      case 'restaurant':
        return l10n.storeNameRestaurant;
      case 'bar':
        return l10n.storeNameBar;
      case 'hotel':
        return l10n.storeNameHotel;
      default:
        return widget.request.store;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (widget.request.status) {
      case 'pending':
        return l10n.statusPending;
      case 'delivered':
        return l10n.statusDelivered;
      case 'received':
        return l10n.statusReceived;
      default:
        return widget.request.status;
    }
  }

  Future<void> _loadItems() async {
    if (establishmentId.isEmpty) {
      setState(() => _isLoadingItems = false);
      return;
    }

    final items = await _service.getRequestItems(
      establishmentId: establishmentId,
      requestId: widget.request.id,
    );

    if (!mounted) return;

    setState(() {
      _lines = items.map((item) {
        return _DeliveryLineInput(
          item: item,
          controller: TextEditingController(
            text: item.quantityDelivered > 0
                ? item.quantityDelivered.toStringAsFixed(
                    item.quantityDelivered % 1 == 0 ? 0 : 2,
                  )
                : item.quantityRequested.toStringAsFixed(
                    item.quantityRequested % 1 == 0 ? 0 : 2,
                  ),
          ),
        );
      }).toList();

      _isLoadingItems = false;
    });
  }

  Future<void> _submitDelivery() async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));
      return;
    }

    if (widget.request.status != 'pending') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requestAlreadyProcessed)));
      return;
    }

    final auth = context.read<AuthController>();
    final controller = context.read<StockRequestController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errUserNotFound)));
      return;
    }

    final deliveredItems = <StockRequestItemModel>[];

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final quantity = double.tryParse(line.controller.text.trim());

      if (quantity == null || quantity < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidDeliveredQuantityAtLine(i + 1)),
          ),
        );
        return;
      }

      deliveredItems.add(
        StockRequestItemModel(
          id: line.item.id,
          establishmentId: establishmentId,
          itemId: line.item.itemId,
          itemName: line.item.itemName,
          unit: line.item.unit,
          quantityRequested: line.item.quantityRequested,
          quantityDelivered: quantity,
          status: quantity > 0 ? 'delivered' : 'pending',
          pendingSync: false,
          syncError: false,
        ),
      );
    }

    final success = await controller.deliverRequest(
      establishmentId: establishmentId,
      requestId: widget.request.id,
      deliveredBy: user.uid,
      deliveredByName: user.name,
      deliveredItems: deliveredItems,
      store: widget.request.store,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.supplyValidatedSuccess)));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorText(l10n) ?? l10n.errUnknown),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestController = context.watch<StockRequestController>();
    final color = _storeColor();
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deliveryTitle)),
      body: _isLoadingItems
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isSmall ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _storeLabel(l10n),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.requestedByLine(
                              widget.request.requestedByName,
                            ),
                          ),
                          // Le rôle stocké est une clé technique : on le rend
                          // via le libellé localisé partagé.
                          Text(
                            l10n.roleLine(
                              AppRoles.label(
                                l10n,
                                widget.request.requestedByRole,
                              ),
                            ),
                          ),
                          Text(l10n.statusLine(_statusLabel(l10n))),
                          if (widget.request.note.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(l10n.noteLine(widget.request.note)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.quantitiesToDeliver,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._lines.map((line) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: Colors.grey.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.item.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.requestedQuantityLine(
                                        line.item.quantityRequested
                                            .toStringAsFixed(
                                              line.item.quantityRequested % 1 ==
                                                      0
                                                  ? 0
                                                  : 2,
                                            ),
                                        line.item.unit,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: line.controller,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      enabled:
                                          widget.request.status == 'pending',
                                      decoration: InputDecoration(
                                        labelText: l10n.labelQuantityDelivered,
                                        suffixText: line.item.unit,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          widget.request.status == 'pending' &&
                              !requestController.isSubmitting
                          ? _submitDelivery
                          : null,
                      icon: requestController.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.local_shipping_outlined),
                      label: Text(
                        widget.request.status == 'pending'
                            ? l10n.actionValidateDelivery
                            : l10n.requestAlreadyProcessedShort,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DeliveryLineInput {
  final StockRequestItemModel item;
  final TextEditingController controller;

  _DeliveryLineInput({required this.item, required this.controller});
}
