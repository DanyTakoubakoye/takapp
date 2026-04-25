import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/services/comptabilite_service.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';

class PointHebdomadairePage extends StatefulWidget {
  const PointHebdomadairePage({super.key});

  @override
  State<PointHebdomadairePage> createState() => _PointHebdomadairePageState();
}

class _PointHebdomadairePageState extends State<PointHebdomadairePage> {
  final ComptabiliteService _service = ComptabiliteService();

  bool _isLoading = false;
  Map<String, dynamic>? _summary;

  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = now.subtract(const Duration(days: 7));
    endDate = now;
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _service.getWeeklySummary(
        startDate: DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        ),
        endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      );

      setState(() {
        _summary = result;
      });
    } catch (e) {
      debugPrint('ERREUR POINT HEBDO: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement point hebdo : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });
      await _loadSummary();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
      await _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final entries = (_summary?['entries'] ?? 0) as double;
    final expenses = (_summary?['expenses'] ?? 0) as double;
    final openingBalances = (_summary?['openingBalances'] ?? 0) as double;
    final balance = (_summary?['balance'] ?? 0) as double;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point hebdomadaire'),
        actions: [
          IconButton(
            onPressed: _summary == null
                ? null
                : () async {
                    final pdfService = context.read<PdfService>();
                    final printerService = context.read<PrinterService>();

                    final bytes = await pdfService
                        .buildSimpleAccountingReportPdf(
                          startDate: startDate,
                          endDate: endDate,
                          totalEntries: entries + openingBalances,
                          totalExpenses: expenses,
                          theoreticalBalance: balance,
                        );

                    await printerService.printPdf(Uint8List.fromList(bytes));
                  },
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickStartDate,
                        child: Text('Début : ${formatter.format(startDate)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickEndDate,
                        child: Text('Fin : ${formatter.format(endDate)}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: Column(
                  children: [
                    _SummaryCard(
                      title: 'Versements reçus',
                      amount: entries,
                      icon: Icons.call_received,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Soldes précédents',
                      amount: openingBalances,
                      icon: Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Sorties',
                      amount: expenses,
                      icon: Icons.call_made,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Solde théorique',
                      amount: balance,
                      icon: Icons.bar_chart_outlined,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Text(
              '${amount.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
