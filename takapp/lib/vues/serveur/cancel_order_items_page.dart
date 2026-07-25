import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/services/order_service.dart';

class CancelOrderItemsPage extends StatefulWidget {
  final String establishmentId;
  final String orderId;
  final String orderNumber;

  const CancelOrderItemsPage({
    super.key,
    required this.establishmentId,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<CancelOrderItemsPage> createState() => _CancelOrderItemsPageState();
}

class _CancelOrderItemsPageState extends State<CancelOrderItemsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _reasonController = TextEditingController();

  final Set<String> _selectedItemIds = {};
  bool _isSubmitting = false;

  String get establishmentId => widget.establishmentId.trim();

  DocumentReference<Map<String, dynamic>> get _orderRef {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders')
        .doc(widget.orderId);
  }

  Future<Map<String, dynamic>?> _loadOrder() async {
    final doc = await _orderRef.get();
    return doc.data();
  }

  Future<List<OrderItemModel>> _loadItems() async {
    final snapshot = await _orderRef.collection('items').get();

    return snapshot.docs
        .map((doc) => OrderItemModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  bool _isItemCancelable(OrderItemModel item, Map<String, dynamic> orderData) {
    final paymentStatus = (orderData['paymentStatus'] ?? '')
        .toString()
        .toLowerCase();

    if (paymentStatus == 'paid') return false;
    if (item.isCancelled) return false;

    final kitchenStatus = (orderData['kitchenStatus'] ?? '').toString();
    final barStatus = (orderData['barStatus'] ?? '').toString();
    final target = item.targetDepartment.toLowerCase();

    if ((target == 'kitchen' || target == 'cuisine') &&
        (kitchenStatus == 'ready' || kitchenStatus == 'served')) {
      return false;
    }

    if (target == 'bar' && (barStatus == 'ready' || barStatus == 'served')) {
      return false;
    }

    return true;
  }

  String _itemStatusLabel(OrderItemModel item, Map<String, dynamic> orderData) {
    if (item.isCancelled) return 'Déjà annulé';

    final kitchenStatus = (orderData['kitchenStatus'] ?? '').toString();
    final barStatus = (orderData['barStatus'] ?? '').toString();
    final target = item.targetDepartment.toLowerCase();

    if ((target == 'kitchen' || target == 'cuisine') &&
        (kitchenStatus == 'ready' || kitchenStatus == 'served')) {
      return 'Cuisine déjà prête/servie';
    }

    if (target == 'bar' && (barStatus == 'ready' || barStatus == 'served')) {
      return 'Bar déjà prêt/servi';
    }

    return 'Annulable';
  }

  Future<void> _submit(List<OrderItemModel> items) async {
    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un article.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final auth = context.read<AuthController>();
      final user = auth.currentUser;
      final orderService = OrderService();

      if (user == null) {
        throw Exception('Utilisateur introuvable.');
      }

      await orderService.cancelOrderItems(
        establishmentId: establishmentId,
        orderId: widget.orderId,
        orderItemIds: _selectedItemIds.toList(),
        cancelledBy: user.uid,
        cancelledByName: user.name.isNotEmpty ? user.name : user.email,
        cancellationReason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Articles annulés et stock restitué.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  double _selectedAmount(List<OrderItemModel> items) {
    return items
        .where((item) => _selectedItemIds.contains(item.id))
        .fold<double>(0, (total, item) => total + item.totalPrice);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Annulation partielle ${widget.orderNumber}')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadOrder(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderSnapshot.hasError || orderSnapshot.data == null) {
            return Center(
              child: Text(
                'Erreur chargement commande : ${orderSnapshot.error}',
              ),
            );
          }

          final orderData = orderSnapshot.data!;

          return FutureBuilder<List<OrderItemModel>>(
            future: _loadItems(),
            builder: (context, itemsSnapshot) {
              if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (itemsSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur chargement articles : ${itemsSnapshot.error}',
                  ),
                );
              }

              final items = itemsSnapshot.data ?? [];

              if (items.isEmpty) {
                return const Center(
                  child: Text('Aucun article trouvé dans cette commande.'),
                );
              }

              final selectedAmount = _selectedAmount(items);

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final cancelable = _isItemCancelable(item, orderData);
                        final checked = _selectedItemIds.contains(item.id);

                        return Card(
                          child: CheckboxListTile(
                            value: checked,
                            onChanged: cancelable
                                ? (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedItemIds.add(item.id);
                                      } else {
                                        _selectedItemIds.remove(item.id);
                                      }
                                    });
                                  }
                                : null,
                            title: Text(item.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity} x ${item.unitPrice.toStringAsFixed(0)} FCFA = ${item.totalPrice.toStringAsFixed(0)} FCFA',
                                ),
                                const SizedBox(height: 4),
                                Text('Département : ${item.targetDepartment}'),
                                const SizedBox(height: 4),
                                Text(
                                  _itemStatusLabel(item, orderData),
                                  style: TextStyle(
                                    color: item.isCancelled
                                        ? Colors.red
                                        : cancelable
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            secondary: item.isCancelled
                                ? const Icon(Icons.block, color: Colors.red)
                                : cancelable
                                ? const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.lock_clock,
                                    color: Colors.orange,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Motif d’annulation',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Montant à retrancher : ${selectedAmount.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _submit(items),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cancel_schedule_send),
                            label: Text(
                              _isSubmitting
                                  ? 'Annulation en cours...'
                                  : 'Valider l’annulation',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
