import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/services/owner_dashboard_service.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';
import 'package:takapp/vues/comptabilite/soldes_precedents_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  final OwnerDashboardService service = OwnerDashboardService();

  String selectedPeriod = '7d';
  late DateTime startDate;
  late DateTime endDate;

  bool isLoading = true;
  String? errorMessage;
  Map<String, double> balancesByType = {};

  final Map<String, TextEditingController> physicalControllers = {};

  @override
  void initState() {
    super.initState();
    _applyPeriod('7d');
  }

  @override
  void dispose() {
    for (final c in physicalControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPeriod(String period) {
    final now = DateTime.now();

    selectedPeriod = period;

    if (period == 'today') {
      startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (period == '7d') {
      final from = now.subtract(const Duration(days: 7));
      startDate = DateTime(from.year, from.month, from.day, 0, 0, 0);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      final from = now.subtract(const Duration(days: 30));
      startDate = DateTime(from.year, from.month, from.day, 0, 0, 0);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    _load();
  }

  Future<void> _pickCustomPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (picked != null) {
      setState(() {
        selectedPeriod = 'custom';
        startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
          0,
          0,
          0,
        );
        endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });

      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await service.getTheoreticalBalancesByType(
        startDate: startDate,
        endDate: endDate,
      );

      for (final key in result.keys) {
        physicalControllers.putIfAbsent(key, () => TextEditingController());
      }
      physicalControllers.putIfAbsent(
        '__total__',
        () => TextEditingController(),
      );

      setState(() {
        balancesByType = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double get totalTheoretical =>
      balancesByType.values.fold(0, (sum, item) => sum + item);

  Future<void> _validateAccount({
    required String accountType,
    required double theoretical,
    required double physical,
  }) async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;

    if (theoretical != physical) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montants non équivalents.')),
      );
      return;
    }

    await service.validateAccountBalance(
      accountType: accountType,
      theoreticalAmount: theoretical,
      physicalAmount: physical,
      validatedById: user.uid,
      validatedByName: user.name,
    );

    final pdfService = context.read<PdfService>();
    final printerService = context.read<PrinterService>();

    final bytes = await pdfService.buildQuitusPdf(
      accountType: accountType,
      theoreticalAmount: theoretical,
      physicalAmount: physical,
      date: DateTime.now(),
      validatedByName: user.name,
    );

    await printerService.printPdf(Uint8List.fromList(bytes));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quitus généré.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAKHOTEL - Propriétaire'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              children: [
                _buildHeaderCard(context, auth, formatter, isMobile: isMobile),
                const SizedBox(height: 16),
                if (isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (errorMessage != null)
                  Expanded(child: Center(child: Text(errorMessage!)))
                else
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 14 : 18),
                        child: isMobile
                            ? _buildMobileBalancesView()
                            : _buildDesktopBalancesView(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    AuthController auth,
    DateFormat formatter, {
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.assessment_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue ${auth.currentUser?.name ?? ""}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Période : ${formatter.format(startDate)} - ${formatter.format(endDate)}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _applyPeriod('today')),
                        child: const Text("Aujourd'hui"),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _applyPeriod('7d')),
                        child: const Text('7 jours'),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _applyPeriod('30d')),
                        child: const Text('30 jours'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickCustomPeriod,
                        icon: const Icon(Icons.date_range_outlined),
                        label: const Text('Période'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SoldesPrecedentsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('Soldes précédents'),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.assessment_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue ${auth.currentUser?.name ?? ""}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Période : ${formatter.format(startDate)} - ${formatter.format(endDate)}',
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _applyPeriod('today')),
                    child: const Text("Aujourd'hui"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _applyPeriod('7d')),
                    child: const Text('7 jours'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _applyPeriod('30d')),
                    child: const Text('30 jours'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickCustomPeriod,
                    icon: const Icon(Icons.date_range_outlined),
                    label: const Text('Période'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SoldesPrecedentsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Soldes précédents'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDesktopBalancesView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Compte',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Solde théorique',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Solde physique',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(),
          ...balancesByType.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Expanded(
                    child: Text('${entry.value.toStringAsFixed(0)} FCFA'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: physicalControllers[entry.key],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Montant physique',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final physical =
                            double.tryParse(
                              physicalControllers[entry.key]!.text.trim(),
                            ) ??
                            0;

                        _validateAccount(
                          accountType: entry.key,
                          theoretical: entry.value,
                          physical: physical,
                        );
                      },
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(thickness: 1.2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${totalTheoretical.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: physicalControllers['__total__'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Solde physique total',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final physical =
                          double.tryParse(
                            physicalControllers['__total__']!.text.trim(),
                          ) ??
                          0;

                      _validateAccount(
                        accountType: 'total',
                        theoretical: totalTheoretical,
                        physical: physical,
                      );
                    },
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBalancesView() {
    return ListView(
      children: [
        ...balancesByType.entries.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solde théorique : ${entry.value.toStringAsFixed(0)} FCFA',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: physicalControllers[entry.key],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Solde physique',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final physical =
                          double.tryParse(
                            physicalControllers[entry.key]!.text.trim(),
                          ) ??
                          0;

                      _validateAccount(
                        accountType: entry.key,
                        theoretical: entry.value,
                        physical: physical,
                      );
                    },
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Solde théorique total : ${totalTheoretical.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: physicalControllers['__total__'],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Solde physique total',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final physical =
                        double.tryParse(
                          physicalControllers['__total__']!.text.trim(),
                        ) ??
                        0;

                    _validateAccount(
                      accountType: 'total',
                      theoretical: totalTheoretical,
                      physical: physical,
                    );
                  },
                  child: const Text('Valider'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
