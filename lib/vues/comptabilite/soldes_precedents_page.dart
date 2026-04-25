import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/modeles/account_balance_model.dart';
import 'package:takapp/services/comptabilite_service.dart';

class SoldesPrecedentsPage extends StatefulWidget {
  const SoldesPrecedentsPage({super.key});

  @override
  State<SoldesPrecedentsPage> createState() => _SoldesPrecedentsPageState();
}

class _SoldesPrecedentsPageState extends State<SoldesPrecedentsPage> {
  final TextEditingController amountController = TextEditingController();
  String selectedType = 'cash';
  DateTime selectedDate = DateTime.now();

  final List<String> accountTypes = [
    'cash',
    'banque',
    'mobile_money',
    'benin_resto',
    'credit',
  ];

  final ComptabiliteService service = ComptabiliteService();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;

    await service.setOpeningBalance(
      type: selectedType,
      amount: amount,
      date: selectedDate,
      createdBy: user.uid,
      createdByName: user.name,
    );

    if (!mounted) return;
    amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solde précédent enregistré.')),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soldes précédents')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildFormCard(isMobile: true),
                  const SizedBox(height: 12),
                  Expanded(child: _buildBalancesCard(isMobile: true)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildFormCard(isMobile: false)),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _buildBalancesCard(isMobile: false)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard({required bool isMobile}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nouveau solde précédent',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de compte',
                border: OutlineInputBorder(),
              ),
              items: accountTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  'Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalancesCard({required bool isMobile}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historique des soldes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<AccountBalanceModel>>(
                stream: service.streamOpeningBalances(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final balances = snapshot.data ?? [];

                  if (balances.isEmpty) {
                    return const Center(child: Text('Aucun solde précédent.'));
                  }

                  return ListView.separated(
                    itemCount: balances.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = balances[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.type,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.date?.day}/${item.date?.month}/${item.date?.year}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Saisi par : ${item.createdByName}'),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${item.amount.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.type,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.date?.day}/${item.date?.month}/${item.date?.year} • ${item.createdByName}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${item.amount.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
