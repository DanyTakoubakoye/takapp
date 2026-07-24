import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/room_invoice_model.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';
import 'package:takapp/services/room_invoice_service.dart';

class FacturationChambrePage extends StatefulWidget {
  const FacturationChambrePage({super.key});

  @override
  State<FacturationChambrePage> createState() => _FacturationChambrePageState();
}

class _FacturationChambrePageState extends State<FacturationChambrePage> {
  final RoomInvoiceService _service = RoomInvoiceService();

  String? currentInvoiceId;

  final TextEditingController clientController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController servicesController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = false;
  double extrasTotal = 0;

  int get nights {
    if (startDate == null || endDate == null) return 0;
    final diff = endDate!.difference(startDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get roomTotal => nights * (double.tryParse(priceController.text) ?? 0);
  double get servicesTotal =>
      double.tryParse(servicesController.text.trim()) ?? 0;
  double get total => roomTotal + extrasTotal + servicesTotal;

  void _invalidateCurrentInvoice() {
    if (currentInvoiceId != null) {
      setState(() {
        currentInvoiceId = null;
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? startDate ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = startDate;
          }
        } else {
          endDate = picked;
          if (startDate != null && endDate!.isBefore(startDate!)) {
            endDate = startDate;
          }
        }
        currentInvoiceId = null;
      });

      await _loadExtras();
    }
  }

  Future<void> _loadExtras() async {
    if (roomController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      setState(() {
        extrasTotal = 0;
      });
      return;
    }

    final start = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      0,
      0,
      0,
    );

    final end = DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
      23,
      59,
      59,
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('roomExtras')
        .where('roomNumber', isEqualTo: roomController.text.trim())
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final totalExtras = snapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + ((doc.data()['amount'] ?? 0) as num).toDouble(),
    );

    if (!mounted) return;

    setState(() {
      extrasTotal = totalExtras;
    });
  }

  Future<void> _saveInvoice() async {
    if (clientController.text.trim().isEmpty ||
        roomController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Champs obligatoires manquants')),
      );
      return;
    }

    final pricePerNight = double.tryParse(priceController.text.trim());
    if (pricePerNight == null || pricePerNight <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prix de nuitée invalide')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final invoice = RoomInvoiceModel(
        id: '',
        clientName: clientController.text.trim(),
        roomNumber: roomController.text.trim(),
        nights: nights,
        pricePerNight: pricePerNight,
        roomTotal: roomTotal,
        extrasTotal: extrasTotal,
        servicesTotal: servicesTotal,
        total: total,
        status: 'unpaid',
        startDate: startDate,
        endDate: endDate,
      );

      final docRef = await _service.createInvoice(invoice);

      if (!mounted) return;

      setState(() {
        currentInvoiceId = docRef.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facture créée. Vous pouvez maintenant encaisser.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _resetForm() {
    clientController.clear();
    roomController.clear();
    priceController.clear();
    servicesController.clear();

    setState(() {
      currentInvoiceId = null;
      startDate = null;
      endDate = null;
      extrasTotal = 0;
    });
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Choisir';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _printInvoice() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d’abord renseigner la facture.'),
        ),
      );
      return;
    }

    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildRoomInvoicePdf(
      clientName: clientController.text.trim(),
      room: roomController.text.trim(),
      nights: nights,
      pricePerNight: double.tryParse(priceController.text.trim()) ?? 0,
      extras: extrasTotal,
      services: servicesTotal,
      total: total,
      start: startDate!,
      end: endDate!,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
  }

  void _showPaymentDialog(BuildContext context, String invoiceId) {
    String method = 'cash';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Encaissement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(
                    value: 'mobile_money',
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(value: 'bank', child: Text('Banque')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    method = v;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = context.read<AuthController>().currentUser;
                if (user == null) return;

                await _service.payInvoice(
                  invoiceId: invoiceId,
                  amount: total,
                  method: method,
                  receivedBy: user.uid,
                  receivedByName: user.name,
                );

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paiement enregistré')),
                );
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    clientController.dispose();
    roomController.dispose();
    priceController.dispose();
    servicesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Facturation Chambre')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isSmall
            ? Column(
                children: [
                  Expanded(flex: 2, child: _buildForm()),
                  const SizedBox(height: 16),
                  Expanded(flex: 2, child: _buildSummary()),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 2, child: _buildForm()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildSummary()),
                ],
              ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Informations client',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clientController,
              decoration: const InputDecoration(labelText: 'Nom client'),
              onChanged: (_) => _invalidateCurrentInvoice(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(labelText: 'Chambre'),
              onChanged: (_) async {
                _invalidateCurrentInvoice();
                await _loadExtras();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(true),
                    child: Text('Début: ${formatDate(startDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(false),
                    child: Text('Fin: ${formatDate(endDate)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix / nuit'),
              onChanged: (_) {
                _invalidateCurrentInvoice();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: servicesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Autres services'),
              onChanged: (_) {
                _invalidateCurrentInvoice();
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _saveInvoice,
              icon: const Icon(Icons.save),
              label: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer facture'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.refresh),
              label: const Text('Nouvelle facture'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Résumé', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _row('Nuitées', '$nights'),
            _row('Chambre', '${roomTotal.toStringAsFixed(0)} FCFA'),
            _row(
              'Extras (bar/resto)',
              '${extrasTotal.toStringAsFixed(0)} FCFA',
            ),
            _row('Services', '${servicesTotal.toStringAsFixed(0)} FCFA'),
            const Divider(),
            _row('TOTAL', '${total.toStringAsFixed(0)} FCFA', isBold: true),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (currentInvoiceId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez d’abord enregistrer la facture.'),
                    ),
                  );
                  return;
                }

                _showPaymentDialog(context, currentInvoiceId!);
              },
              icon: const Icon(Icons.payment),
              label: const Text('Encaisser'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _printInvoice,
              icon: const Icon(Icons.print),
              label: const Text('Imprimer facture'),
            ),
            const SizedBox(height: 12),
            if (currentInvoiceId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Facture enregistrée et prête à être encaissée.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
