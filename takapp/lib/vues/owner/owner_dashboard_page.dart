import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/services/owner_dashboard_service.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';
import 'package:takapp/vues/clients/clients_page.dart';
import 'package:takapp/vues/comptabilite/soldes_precedents_page.dart';
import 'package:takapp/vues/reception/reception_dashboard_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  final String establishmentId;
  const OwnerDashboardPage({super.key, required this.establishmentId});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  final OwnerDashboardService service = OwnerDashboardService();

  String selectedPeriod = '7d';

  late DateTime startDate;
  late DateTime endDate;

  bool isLoading = true;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute.
  /// Jamais un texte destiné à l'affichage — la traduction a lieu au
  /// moment du rendu, dans la langue active.
  Object? _error;

  Map<String, double> balancesByType = {};

  final Map<String, TextEditingController> physicalControllers = {};
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  String establishmentId = '';

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 7));

    selectedPeriod = '7d';
    startDate = DateTime(from.year, from.month, from.day, 0, 0, 0);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = context.read<AuthController>();
      final user = auth.currentUser;

      if (user == null || user.establishmentId.trim().isEmpty) {
        setState(() {
          isLoading = false;
          _error = const AppError(AppErrorCode.establishmentNotFound);
        });
        return;
      }

      establishmentId = user.establishmentId.trim();
      _load();
    });
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

  Future<void> _openCreateUserDialog() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null || user.establishmentId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errEstablishmentNotFound)),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _CreateTenantUserDialog(onSubmit: _createTenantUser),
    );
  }

  Future<void> _createTenantUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final l10n = AppLocalizations.of(context);

    try {
      await _functions.httpsCallable('createTenantUser').call({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userCreatedSuccess)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errUserCreationFailed('$e'))),
      );
    }
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
    if (establishmentId.trim().isEmpty) {
      setState(() {
        isLoading = false;
        _error = const AppError(AppErrorCode.establishmentNotFound);
      });
      return;
    }

    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final result = await service.getTheoreticalBalancesByType(
        establishmentId: establishmentId,
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
        _error = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double get totalTheoretical =>
      balancesByType.values.fold(0, (sum, item) => sum + item);

  Future<void> _validateAccount({
    required String accountType,
    required double theoretical,
    required double physical,
  }) async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();

    final user = auth.currentUser;

    if (user == null) return;

    if (theoretical != physical) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errAmountsNotEquivalent)),
      );

      return;
    }

    await service.validateAccountBalance(
      establishmentId: establishmentId,
      accountType: accountType,
      theoreticalAmount: theoretical,
      physicalAmount: physical,
      validatedById: user.uid,
      validatedByName: user.name,
    );

    if (!mounted) return;

    final pdfService = context.read<PdfService>();

    final printerService = context.read<PrinterService>();

    final bytes = await pdfService.buildQuitusPdf(
      l10n: l10n,
      establishmentName: user.establishmentName,
      establishmentId: user.establishmentId,
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
    ).showSnackBar(SnackBar(content: Text(l10n.quitusGenerated)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();

    final formatter = DateFormat('dd/MM/yyyy');

    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.establishmentOwnerTitle(
              user.establishmentName.isNotEmpty == true
                  ? user.establishmentName
                  : 'TAKHOTEL',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.establishmentOwnerTitle(
            user.establishmentName.isNotEmpty == true
                ? user.establishmentName
                : 'TAKHOTEL',
          ),
        ),
        actions: [
          // Réception & Clients relèvent du module hôtel : masqués si
          // l'établissement n'est pas abonné à l'hôtel.
          if (auth.canAccessHotel)
            IconButton(
              tooltip: l10n.receptionTitle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceptionDashboardPage(
                      establishmentId: establishmentId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.hotel),
            ),
          if (auth.canAccessHotel)
            IconButton(
              tooltip: 'Clients',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ClientsPage(establishmentId: establishmentId),
                  ),
                );
              },
              icon: const Icon(Icons.people_outline),
            ),
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateUserDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.actionCreateUser),
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
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Text(
                        localizedError(AppLocalizations.of(context), _error),
                      ),
                    ),
                  )
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
    final l10n = AppLocalizations.of(context);

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
                              l10n.periodLine(
                              formatter.format(startDate),
                              formatter.format(endDate),
                            ),
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
                        label: Text(l10n.labelPeriod),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SoldesPrecedentsPage(
                                establishmentId: establishmentId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: Text(l10n.previousBalancesTitle),
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
                          l10n.periodLine(
                            formatter.format(startDate),
                            formatter.format(endDate),
                          ),
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
                    label: Text(l10n.labelPeriod),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SoldesPrecedentsPage(
                            establishmentId: establishmentId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(l10n.previousBalancesTitle),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDesktopBalancesView() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.labelAccount,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.theoreticalBalance,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.physicalBalance,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.labelAction,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
    final l10n = AppLocalizations.of(context);

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
                  l10n.theoreticalBalanceAmount(
                    entry.value.toStringAsFixed(0),
                  ),
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
                l10n.totalTheoreticalBalanceAmount(
                  totalTheoretical.toStringAsFixed(0),
                ),
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

class _CreateTenantUserDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  })
  onSubmit;

  const _CreateTenantUserDialog({required this.onSubmit});

  @override
  State<_CreateTenantUserDialog> createState() =>
      _CreateTenantUserDialogState();
}

class _CreateTenantUserDialogState extends State<_CreateTenantUserDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isSaving = false;

  String selectedRole = 'serveur';

  /// Rôles proposés : seule la valeur technique est stockée, le libellé
  /// affiché vient de [AppRoles.label].
  final List<String> roles = const [
    AppRoles.gerante,
    AppRoles.comptable,
    AppRoles.serveur,
    AppRoles.barman,
    AppRoles.chefCuisine,
    AppRoles.hygiene,
    AppRoles.majordhomme,
    AppRoles.receptionniste,
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errNameEmailPasswordRequired)),
      );
      return;
    }

    setState(() => isSaving = true);

    await widget.onSubmit(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: selectedRole,
    );

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.createUserTitle),
      insetPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom complet *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.labelPhone),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe temporaire *',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(labelText: l10n.labelRole),
                items: roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(AppRoles.label(l10n, role)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton.icon(
          onPressed: isSaving ? null : _submit,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt_1),
          label: Text(l10n.actionCreate),
        ),
      ],
    );
  }
}
