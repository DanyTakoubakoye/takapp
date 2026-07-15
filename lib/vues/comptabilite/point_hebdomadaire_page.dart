import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
    });
  }

  /// =========================
  /// SAAS HELPERS
  /// =========================

  String get establishmentId {
    final auth = context.read<AuthController>();

    return auth.currentUser?.establishmentId ?? '';
  }

  String get establishmentName {
    final auth = context.read<AuthController>();

    return auth.currentUser?.establishmentName ?? '';
  }

  /// =========================
  /// LOAD SUMMARY
  /// =========================

  Future<void> _loadSummary() async {
    if (establishmentId.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _service.getWeeklySummary(
        establishmentId: establishmentId,

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

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = result;
      });
    } catch (e) {
      debugPrint('ERREUR POINT HEBDO: $e');

      if (!mounted) {
        return;
      }

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

  /// =========================
  /// PICK START DATE
  /// =========================

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

  /// =========================
  /// PICK END DATE
  /// =========================

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

  /// =========================
  /// PRINT REPORT
  /// =========================

  Future<void> _printReport() async {
    if (_summary == null) {
      return;
    }

    try {
      final pdfService = context.read<PdfService>();

      final printerService = context.read<PrinterService>();

      final entries = ((_summary?['entries'] ?? 0) as num).toDouble();

      final expenses = ((_summary?['expenses'] ?? 0) as num).toDouble();

      final openingBalances = ((_summary?['openingBalances'] ?? 0) as num)
          .toDouble();

      final balance = ((_summary?['balance'] ?? 0) as num).toDouble();

      final bytes = await pdfService.buildSimpleAccountingReportPdf(
        establishmentId: establishmentId,

        establishmentName: establishmentName,

        startDate: startDate,

        endDate: endDate,

        totalEntries: entries + openingBalances,

        totalExpenses: expenses,

        theoreticalBalance: balance,
      );

      await printerService.printPdf(Uint8List.fromList(bytes));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur impression : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    final entries = ((_summary?['entries'] ?? 0) as num).toDouble();

    final expenses = ((_summary?['expenses'] ?? 0) as num).toDouble();

    final openingBalances = ((_summary?['openingBalances'] ?? 0) as num)
        .toDouble();

    final balance = ((_summary?['balance'] ?? 0) as num).toDouble();

    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 700;

    if (establishmentId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          establishmentName.trim().isNotEmpty
              ? '$establishmentName - Point hebdomadaire'
              : 'Point hebdomadaire',
        ),

        actions: [
          IconButton(
            onPressed: _summary == null ? null : _printReport,

            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),

        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: isMobile
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,

                            child: OutlinedButton(
                              onPressed: _pickStartDate,

                              child: Text(
                                'Début : ${formatter.format(startDate)}',
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,

                            child: OutlinedButton(
                              onPressed: _pickEndDate,

                              child: Text('Fin : ${formatter.format(endDate)}'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickStartDate,

                              child: Text(
                                'Début : ${formatter.format(startDate)}',
                              ),
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
                child: ListView(
                  children: [
                    _SummaryCard(
                      title: 'Versements reçus',

                      amount: entries,

                      icon: Icons.call_received,

                      color: Colors.green,
                    ),

                    const SizedBox(height: 12),

                    _SummaryCard(
                      title: 'Soldes précédents',

                      amount: openingBalances,

                      icon: Icons.account_balance_wallet,

                      color: Colors.blue,
                    ),

                    const SizedBox(height: 12),

                    _SummaryCard(
                      title: 'Sorties',

                      amount: expenses,

                      icon: Icons.call_made,

                      color: Colors.red,
                    ),

                    const SizedBox(height: 12),

                    _SummaryCard(
                      title: 'Solde théorique',

                      amount: balance,

                      icon: Icons.bar_chart_outlined,

                      color: Colors.indigo,
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
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Row(
          children: [
            CircleAvatar(
              radius: 24,

              backgroundColor: color,

              child: Icon(icon, color: Colors.white),
            ),

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
