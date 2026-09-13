import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/order_ticket_model.dart';
import 'package:takapp/services/payment_service.dart';
import 'package:takapp/vues/serveur/detail_consommation_page.dart';

class MesFacturesServeurPage extends StatefulWidget {
  final String establishmentId;

  const MesFacturesServeurPage({super.key, required this.establishmentId});

  @override
  State<MesFacturesServeurPage> createState() => _MesFacturesServeurPageState();
}

class _MesFacturesServeurPageState extends State<MesFacturesServeurPage> {
  final PaymentService _paymentService = PaymentService();
  DateTime _selectedDay = DateTime.now();

  // Le stream dépend du jour sélectionné : on le mémorise et on ne le recrée
  // que lorsque la clé change réellement. Sans ça, chaque rebuild relancerait
  // l'abonnement et remettrait la liste en chargement.
  String? _ordersStreamKey;
  Stream<List<OrderModel>>? _ordersStream;

  Stream<List<OrderModel>> _ordersStreamFor({
    required String establishmentId,
    required String serveurId,
    required DateTime day,
  }) {
    final key =
        '$establishmentId/$serveurId/${day.year}-${day.month}-${day.day}';

    if (_ordersStreamKey != key || _ordersStream == null) {
      _ordersStreamKey = key;
      _ordersStream = _paymentService.streamOrdersForServerByDay(
        establishmentId: establishmentId,
        serveurId: serveurId,
        day: day,
      );
    }

    return _ordersStream!;
  }

  String get establishmentId => widget.establishmentId.trim();

  String _clientLabel(OrderModel order) {
    switch (order.clientType) {
      case 'restaurant':
        return 'Table ${order.tableNumber ?? "-"}';
      case 'hotel':
        return 'Chambre ${order.roomNumber ?? "-"}';
      case 'bar':
        return 'Client Bar';
      default:
        return order.clientType;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
    }
  }

  /// Historique : chaque commande de la journée est consultée individuellement.
  void _openDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailConsommationPage(
          establishmentId: establishmentId,
          ticket: OrderTicket.single(order),
        ),
      ),
    );
  }

  /// Badge coloré générique (vert si ok, orange sinon).
  Widget _statusChip(String label, bool ok) {
    final color = ok ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.pending, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (establishmentId.isEmpty || user == null) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    final isToday = DateUtils.isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Mes factures')),
      body: Column(
        children: [
          // Sélecteur de date
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isToday
                        ? "Aujourd'hui (${DateFormat('dd/MM/yyyy').format(_selectedDay)})"
                        : DateFormat('dd/MM/yyyy').format(_selectedDay),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isToday)
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedDay = DateTime.now()),
                    child: const Text("Aujourd'hui"),
                  ),
                IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'Choisir une date',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _ordersStreamFor(
                establishmentId: establishmentId,
                serveurId: user.uid,
                day: _selectedDay,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText('Erreur : ${snapshot.error}'),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune facture pour cette date.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isPaid = order.paymentStatus == 'paid';
                    final isFiscalized =
                        order.isFiscalized && order.fiscalStatus == 'success';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.orderNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${order.total.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Client : ${_clientLabel(order)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            // Les deux badges
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _statusChip(
                                  isPaid ? 'Encaissée' : 'Non encaissée',
                                  isPaid,
                                ),
                                _statusChip(
                                  isFiscalized
                                      ? 'Fiscalisée'
                                      : 'Non fiscalisée',
                                  isFiscalized,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Boutons contextuels
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (!isPaid)
                                  ElevatedButton.icon(
                                    onPressed: () => _openDetail(order),
                                    icon: const Icon(
                                      Icons.payments_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Encaisser la facture'),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () => _openDetail(order),
                                    icon: const Icon(Icons.print, size: 18),
                                    label: const Text('Imprimer facture'),
                                  ),
                                if (!isFiscalized)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _openDetail(order),
                                    icon: const Icon(
                                      Icons.verified_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Fiscaliser'),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () => _openDetail(order),
                                    icon: const Icon(
                                      Icons.receipt_long,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Imprimer facture fiscalisée',
                                    ),
                                  ),
                              ],
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
    );
  }
}
