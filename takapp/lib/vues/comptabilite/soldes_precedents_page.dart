import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';

import 'package:takapp/core/constants/account_types.dart';

import 'package:takapp/l10n/app_localizations.dart';

import 'package:takapp/modeles/account_balance_model.dart';

import 'package:takapp/services/comptabilite_service.dart';

class SoldesPrecedentsPage extends StatefulWidget {
  final String establishmentId;
  const SoldesPrecedentsPage({super.key, required this.establishmentId});

  @override
  State<SoldesPrecedentsPage> createState() => _SoldesPrecedentsPageState();
}

class _SoldesPrecedentsPageState extends State<SoldesPrecedentsPage> {
  final TextEditingController amountController = TextEditingController();

  // Valeur technique stockée en base.
  String selectedType = AccountTypes.cash;

  DateTime selectedDate = DateTime.now();

  final ComptabiliteService service = ComptabiliteService();

  // L'établissement n'est connu qu'au build : on mémorise le stream et on ne
  // le recrée que s'il change. Sinon chaque frappe dans le formulaire
  // relancerait l'abonnement et remettrait la liste en chargement.
  String? _balancesStreamEstablishmentId;
  Stream<List<AccountBalanceModel>>? _balancesStream;

  Stream<List<AccountBalanceModel>> _balancesStreamFor(String establishmentId) {
    if (_balancesStreamEstablishmentId != establishmentId ||
        _balancesStream == null) {
      _balancesStreamEstablishmentId = establishmentId;
      _balancesStream = service.streamOpeningBalances(
        establishmentId: establishmentId,
      );
    }

    return _balancesStream!;
  }

  @override
  void dispose() {
    amountController.dispose();

    super.dispose();
  }

  /// =========================
  /// SAVE OPENING BALANCE
  /// =========================

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    final auth = context.read<AuthController>();

    final user = auth.currentUser;

    if (user == null) {
      return;
    }

    if (user.establishmentId.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));

      return;
    }

    final amount = double.tryParse(
      amountController.text.trim().replaceAll(',', '.'),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));

      return;
    }

    try {
      await service.setOpeningBalance(
        establishmentId: user.establishmentId,

        type: selectedType,

        amount: amount,

        date: selectedDate,

        createdBy: user.uid,

        createdByName: user.name,
      );

      if (!mounted) {
        return;
      }

      amountController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.previousBalanceSaved)));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorPrefixed('$e'))));
    }
  }

  /// =========================
  /// PICK DATE
  /// =========================

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
    final l10n = AppLocalizations.of(context);

    final auth = context.watch<AuthController>();

    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    if (user.establishmentId.trim().isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.establishmentName.trim().isNotEmpty
              ? '${user.establishmentName} - ${l10n.previousBalancesTitle}'
              : l10n.previousBalancesTitle,
        ),
      ),

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

                  Expanded(
                    child: _buildBalancesCard(
                      establishmentId: user.establishmentId,

                      isMobile: true,
                    ),
                  ),
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

                Expanded(
                  flex: 3,

                  child: _buildBalancesCard(
                    establishmentId: user.establishmentId,

                    isMobile: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// =========================
  /// FORM CARD
  /// =========================

  Widget _buildFormCard({required bool isMobile}) {
    final l10n = AppLocalizations.of(context);

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
                l10n.newPreviousBalanceTitle,

                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: selectedType,

              decoration: InputDecoration(
                labelText: l10n.labelAccountType,

                border: const OutlineInputBorder(),
              ),

              // La valeur reste technique : seul le libellé est localisé.
              items: AccountTypes.all.map((e) {
                return DropdownMenuItem<String>(
                  value: e,

                  child: Text(AccountTypes.label(l10n, e)),
                );
              }).toList(),

              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  selectedType = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: amountController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: InputDecoration(
                labelText: l10n.labelAmount,

                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: _pickDate,

                icon: const Icon(Icons.calendar_today_outlined),

                label: Text(
                  l10n.dateLine(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _save,

                child: Text(l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// BALANCES CARD
  /// =========================

  Widget _buildBalancesCard({
    required String establishmentId,

    required bool isMobile,
  }) {
    final l10n = AppLocalizations.of(context);

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
                l10n.balanceHistoryTitle,

                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<List<AccountBalanceModel>>(
                stream: _balancesStreamFor(establishmentId),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l10n.errorPrefixed('${snapshot.error}')),
                    );
                  }

                  final balances = snapshot.data ?? [];

                  if (balances.isEmpty) {
                    return Center(child: Text(l10n.noPreviousBalance));
                  }

                  return ListView.separated(
                    itemCount: balances.length,

                    separatorBuilder: (_, _) => const SizedBox(height: 10),

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
                                    AccountTypes.label(l10n, item.type),

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

                                  Text(l10n.enteredByLine(item.createdByName)),

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
                                          AccountTypes.label(l10n, item.type),

                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,

                                            fontSize: 15,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          '${item.date?.day}/${item.date?.month}/${item.date?.year}'
                                          ' • ${item.createdByName}',
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
