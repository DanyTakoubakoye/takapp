import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
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

  /// `clientType` est une valeur technique ('restaurant' / 'hotel' / 'bar')
  /// stockée en base : elle n'est jamais traduite, seul son libellé l'est.
  String _clientLabel(AppLocalizations l10n, OrderModel order) {
    switch (order.clientType) {
      case 'restaurant':
        return l10n.labelTable(order.tableNumber ?? '-');
      case 'hotel':
        return l10n.labelRoom(order.roomNumber ?? '-');
      case 'bar':
        return l10n.labelBarClient;
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
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (establishmentId.isEmpty || user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    final isToday = DateUtils.isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myInvoicesTitle)),
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
                        ? l10n.todayWithDate(
                            DateFormat('dd/MM/yyyy').format(_selectedDay),
                          )
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
                    child: Text(l10n.today),
                  ),
                IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  tooltip: l10n.pickDate,
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
                      child: SelectableText(
                        l10n.errorPrefixed('${snapshot.error}'),
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.noInvoiceForDate,
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
                              l10n.clientLine(_clientLabel(l10n, order)),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            // Les deux badges
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _statusChip(
                                  isPaid ? l10n.statusPaid : l10n.statusUnpaid,
                                  isPaid,
                                ),
                                _statusChip(
                                  isFiscalized
                                      ? l10n.statusFiscalized
                                      : l10n.statusNotFiscalized,
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
                                    label: Text(l10n.actionCollectInvoice),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () => _openDetail(order),
                                    icon: const Icon(Icons.print, size: 18),
                                    label: Text(l10n.actionPrintInvoice),
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
                                    label: Text(l10n.actionFiscalize),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () => _openDetail(order),
                                    icon: const Icon(
                                      Icons.receipt_long,
                                      size: 18,
                                    ),
                                    label: Text(
                                      l10n.actionPrintFiscalizedInvoice,
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
