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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type de compte',
                        ),
                        items: accountTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
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
                        decoration: const InputDecoration(labelText: 'Montant'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _pickDate,
                        child: Text(
                          'Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        return const Center(
                          child: Text('Aucun solde précédent.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: balances.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = balances[index];
                          return ListTile(
                            title: Text(item.type),
                            subtitle: Text(
                              '${item.date?.day}/${item.date?.month}/${item.date?.year} • ${item.createdByName}',
                            ),
                            trailing: Text(
                              '${item.amount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
