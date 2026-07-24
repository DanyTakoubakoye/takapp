import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/modeles/room_invoice_model.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';
import 'package:takapp/services/room_invoice_service.dart';

class ListeFacturesPage extends StatefulWidget {
  const ListeFacturesPage({super.key});

  @override
  State<ListeFacturesPage> createState() => _ListeFacturesPageState();
}

class _ListeFacturesPageState extends State<ListeFacturesPage> {
  final RoomInvoiceService _service = RoomInvoiceService();
  final TextEditingController searchController = TextEditingController();

  String statusFilter = 'all';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _printInvoice(RoomInvoiceModel item) async {
    if (item.startDate == null || item.endDate == null) return;

    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildRoomInvoicePdf(
      clientName: item.clientName,
      room: item.roomNumber,
      nights: item.nights,
      pricePerNight: item.pricePerNight,
      extras: item.extrasTotal,
      services: item.servicesTotal,
      total: item.total,
      start: item.startDate!,
      end: item.endDate!,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Liste des factures chambres')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Recherche client / chambre',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: statusFilter,
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous')),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Payées'),
                          ),
                          DropdownMenuItem(
                            value: 'unpaid',
                            child: Text('Non payées'),
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
              child: StreamBuilder<List<RoomInvoiceModel>>(
                stream: _service.streamInvoices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final allItems = snapshot.data ?? [];
                  final query = searchController.text.trim().toLowerCase();

                  final items = allItems.where((item) {
                    final matchSearch =
                        item.clientName.toLowerCase().contains(query) ||
                        item.roomNumber.toLowerCase().contains(query);

                    final matchStatus = statusFilter == 'all'
                        ? true
                        : item.status == statusFilter;

                    return matchSearch && matchStatus;
                  }).toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('Aucune facture trouvée.'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Chambre : ${item.roomNumber}'),
                              Text(
                                'Période : '
                                '${item.startDate == null ? "-" : dateFormat.format(item.startDate!)}'
                                ' → '
                                '${item.endDate == null ? "-" : dateFormat.format(item.endDate!)}',
                              ),
                              Text(
                                'Total : ${item.total.toStringAsFixed(0)} FCFA',
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: item.status == 'paid'
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.status == 'paid' ? 'Payée' : 'Non payée',
                                  style: TextStyle(
                                    color: item.status == 'paid'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    if (item.status != 'paid')
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await _service.markAsPaid(item.id);
                                        },
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        label: const Text('Marquer payée'),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: () => _printInvoice(item),
                                      icon: const Icon(Icons.print_outlined),
                                      label: const Text('Imprimer'),
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
