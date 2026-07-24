import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/comptabilite_controller.dart';
import 'package:takapp/modeles/expense_model.dart';
import 'package:takapp/services/comptabilite_service.dart';

class DepensesPage extends StatefulWidget {
  const DepensesPage({super.key});

  @override
  State<DepensesPage> createState() => _DepensesPageState();
}

class _DepensesPageState extends State<DepensesPage> {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String selectedAccountType = 'cash';

  final List<String> accountTypes = [
    'cash',
    'banque',
    'mobile_money',
    'benin_resto',
    'credit',
  ];

  @override
  void dispose() {
    labelController.dispose();
    categoryController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final controller = context.read<ComptabiliteController>();
    final user = auth.currentUser;

    if (user == null) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Montant invalide.')));
      return;
    }

    final success = await controller.createExpense(
      label: labelController.text.trim(),
      category: categoryController.text.trim().isEmpty
          ? 'divers'
          : categoryController.text.trim(),
      amount: amount,
      createdBy: user.uid,
      createdByName: user.name,
      accountType: selectedAccountType,
    );

    if (!mounted) return;

    if (success) {
      labelController.clear();
      categoryController.clear();
      amountController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dépense enregistrée.')));
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final comptaService = context.read<ComptabiliteService>();
    final controller = context.watch<ComptabiliteController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Dépenses')),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nouvelle dépense',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(labelText: 'Libellé'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedAccountType,
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
                            selectedAccountType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Montant'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.isSubmitting ? null : _submit,
                        child: controller.isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Enregistrer'),
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
                  child: StreamBuilder<List<ExpenseModel>>(
                    stream: comptaService.streamExpenses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur: ${snapshot.error}'));
                      }

                      final expenses = snapshot.data ?? [];

                      if (expenses.isEmpty) {
                        return const Center(
                          child: Text('Aucune dépense enregistrée.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return ListTile(
                            title: Text(expense.label),
                            subtitle: Text(
                              '${expense.category} • ${expense.accountType} • ${expense.createdByName}',
                            ),
                            trailing: Text(
                              '${expense.amount.toStringAsFixed(0)} FCFA',
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
