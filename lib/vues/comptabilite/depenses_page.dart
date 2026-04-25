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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildFormCard(controller, isMobile: true),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildExpensesCard(comptaService, isMobile: true),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormCard(controller, isMobile: false),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildExpensesCard(comptaService, isMobile: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard(
    ComptabiliteController controller, {
    required bool isMobile,
  }) {
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
                'Nouvelle dépense',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Libellé',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedAccountType,
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
                  selectedAccountType = value;
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCard(
    ComptabiliteService comptaService, {
    required bool isMobile,
  }) {
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
                'Historique des dépenses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];

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
                                    expense.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${expense.category} • ${expense.accountType}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Saisi par : ${expense.createdByName}'),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${expense.amount.toStringAsFixed(0)} FCFA',
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
                                          expense.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${expense.category} • ${expense.accountType} • ${expense.createdByName}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${expense.amount.toStringAsFixed(0)} FCFA',
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
