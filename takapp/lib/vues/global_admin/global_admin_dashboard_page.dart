import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';

class GlobalAdminDashboardPage extends StatefulWidget {
  const GlobalAdminDashboardPage({super.key});

  @override
  State<GlobalAdminDashboardPage> createState() =>
      _GlobalAdminDashboardPageState();
}

class _GlobalAdminDashboardPageState extends State<GlobalAdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  bool isSaving = false;

  // Créé une seule fois : recréé dans build(), il relancerait l'abonnement à
  // chaque rebuild et remettrait la liste en chargement.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _establishmentsStream;

  @override
  void initState() {
    super.initState();
    _establishmentsStream = _firestore.collection('establishments').snapshots();
  }

  static const List<String> fallbackModules = [
    'restaurant',
    'bar',
    'hotel',
    'stock',
    'fiscalization',
    'fiscalisation',
  ];
  Future<void> _openCreateAdminDialog() async {
    final l10n = AppLocalizations.of(context);
    final establishmentsSnapshot = await _firestore
        .collection('establishments')
        .get();

    final establishments = establishmentsSnapshot.docs;

    if (establishments.isEmpty) {
      _showSnack(l10n.noEstablishmentAvailable);
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _CreateEstablishmentAdminDialog(
        establishments: establishments,
        onSubmit: _createAdminForExistingEstablishment,
      ),
    );
  }

  Future<void> _createAdminForExistingEstablishment({
    required String establishmentId,
    required String establishmentName,
    required String email,
    required String password,
    required String name,
    required String phone,
    required Map<String, dynamic> modules,
  }) async {
    final l10n = AppLocalizations.of(context);

    try {
      await _functions.httpsCallable('createEstablishmentAdmin').call({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'establishmentId': establishmentId,
        'establishmentName': establishmentName,
        'modules': modules,
      });

      if (!mounted) return;

      Navigator.pop(context);
      _showSnack(l10n.adminCreatedSuccess);
    } catch (e) {
      _showSnack(l10n.errAdminCreationFailed('$e'));
    }
  }

  Future<List<String>> _loadModuleKeys() async {
    try {
      final snapshot = await _firestore.collection('modules').get();

      if (snapshot.docs.isEmpty) {
        return fallbackModules;
      }

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (_) {
      return fallbackModules;
    }
  }

  Future<void> _openCreateDialog() async {
    final l10n = AppLocalizations.of(context);
    final moduleKeys = await _loadModuleKeys();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _EstablishmentFormDialog(
        title: l10n.createEstablishmentTitle,
        moduleKeys: moduleKeys,
        onSubmit: _createEstablishment,
      ),
    );
  }

  Future<void> _openEditDialog({
    required String establishmentId,
    required Map<String, dynamic> data,
  }) async {
    final l10n = AppLocalizations.of(context);
    final moduleKeys = await _loadModuleKeys();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _EstablishmentFormDialog(
        title: l10n.editEstablishmentTitle,
        moduleKeys: moduleKeys,
        initialData: data,
        onSubmit: (payload, adminPayload) async {
          await _updateEstablishment(
            establishmentId: establishmentId,
            payload: payload,
          );
        },
      ),
    );
  }

  Future<void> _createEstablishment(
    Map<String, dynamic> payload,
    Map<String, dynamic>? adminPayload,
  ) async {
    final l10n = AppLocalizations.of(context);

    setState(() => isSaving = true);

    try {
      final docRef = _firestore.collection('establishments').doc();
      final establishmentId = docRef.id;

      await docRef.set({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (adminPayload != null) {
        await _functions.httpsCallable('createEstablishmentAdmin').call({
          ...adminPayload,
          'role': 'proprietaire',
          'establishmentId': establishmentId,
          'establishmentName': payload['name'],
          'modules': payload['modules'],
        });
      }

      if (!mounted) return;

      Navigator.pop(context);
      _showSnack(l10n.establishmentCreatedSuccess);
    } catch (e) {
      _showSnack(l10n.errEstablishmentCreationFailed('$e'));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _updateEstablishment({
    required String establishmentId,
    required Map<String, dynamic> payload,
  }) async {
    final l10n = AppLocalizations.of(context);

    setState(() => isSaving = true);

    try {
      await _firestore.collection('establishments').doc(establishmentId).set({
        ...payload,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pop(context);
      _showSnack(l10n.establishmentUpdatedSuccess);
    } catch (e) {
      _showSnack(l10n.errEstablishmentUpdateFailed('$e'));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _toggleStatus({
    required String establishmentId,
    required String currentStatus,
  }) async {
    final nextStatus = currentStatus == 'active' ? 'suspended' : 'active';

    await _firestore.collection('establishments').doc(establishmentId).update({
      'status': nextStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.saasAdministrationTitle),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create_admin',
            onPressed: _openCreateAdminDialog,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(l10n.actionCreateAdmin),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create_establishment',
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.add_business),
            label: Text(l10n.actionCreateEstablishment),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(isSmall: isSmall),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _establishmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l10n.commonError('${snapshot.error}')),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  docs.sort((a, b) {
                    final an = (a.data()['name'] ?? '').toString();
                    final bn = (b.data()['name'] ?? '').toString();
                    return an.toLowerCase().compareTo(bn.toLowerCase());
                  });

                  if (docs.isEmpty) {
                    return Center(child: Text(l10n.noEstablishmentRecorded));
                  }

                  return GridView.builder(
                    itemCount: docs.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmall ? 1 : 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: isSmall ? 1.9 : 1.35,
                    ),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      return _EstablishmentCard(
                        establishmentId: doc.id,
                        data: data,
                        onEdit: () => _openEditDialog(
                          establishmentId: doc.id,
                          data: data,
                        ),
                        onToggleStatus: () => _toggleStatus(
                          establishmentId: doc.id,
                          currentStatus: (data['status'] ?? '').toString(),
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

class _EstablishmentFormDialog extends StatefulWidget {
  final String title;
  final List<String> moduleKeys;
  final Map<String, dynamic>? initialData;
  final Future<void> Function(
    Map<String, dynamic> payload,
    Map<String, dynamic>? adminPayload,
  )
  onSubmit;

  const _EstablishmentFormDialog({
    required this.title,
    required this.moduleKeys,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<_EstablishmentFormDialog> createState() =>
      _EstablishmentFormDialogState();
}

class _EstablishmentFormDialogState extends State<_EstablishmentFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController ifuController;
  late final TextEditingController cityController;
  late final TextEditingController countryController;
  late final TextEditingController ownerUidController;

  late final TextEditingController adminNameController;
  late final TextEditingController adminEmailController;
  late final TextEditingController adminPasswordController;

  late String selectedType;
  late String selectedStatus;
  late String selectedPlan;
  late Map<String, bool> selectedModules;

  bool isSaving = false;

  bool get isEdit => widget.initialData != null;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData ?? {};
    final modules = Map<String, dynamic>.from(data['modules'] ?? {});

    nameController = TextEditingController(
      text: (data['name'] ?? '').toString(),
    );
    ifuController = TextEditingController(text: (data['ifu'] ?? '').toString());
    cityController = TextEditingController(
      text: (data['city'] ?? '').toString(),
    );
    countryController = TextEditingController(
      text: (data['country'] ?? 'Benin').toString(),
    );
    ownerUidController = TextEditingController(
      text: (data['ownerUid'] ?? '').toString(),
    );

    adminNameController = TextEditingController();
    adminEmailController = TextEditingController();
    adminPasswordController = TextEditingController();

    selectedType = (data['type'] ?? 'hotel_bar_restaurant').toString();
    selectedStatus = (data['status'] ?? 'active').toString();
    selectedPlan = (data['plan'] ?? 'standard').toString();

    selectedModules = {
      for (final key in widget.moduleKeys) key: modules[key] == true,
    };

    for (final entry in modules.entries) {
      selectedModules.putIfAbsent(entry.key, () => entry.value == true);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ifuController.dispose();
    cityController.dispose();
    countryController.dispose();
    ownerUidController.dispose();
    adminNameController.dispose();
    adminEmailController.dispose();
    adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = nameController.text.trim();
    final city = cityController.text.trim();

    if (name.isEmpty) return;
    if (city.isEmpty) return;
    if (selectedModules.values.every((v) => v == false)) return;

    final payload = {
      'name': name,
      'ifu': ifuController.text.trim(),
      'city': city,
      'country': countryController.text.trim(),
      'ownerUid': ownerUidController.text.trim(),
      'type': selectedType,
      'status': selectedStatus,
      'plan': selectedPlan,
      'modules': selectedModules,
    };

    Map<String, dynamic>? adminPayload;

    if (!isEdit &&
        adminNameController.text.trim().isNotEmpty &&
        adminEmailController.text.trim().isNotEmpty) {
      adminPayload = {
        'name': adminNameController.text.trim(),
        'email': adminEmailController.text.trim(),
        'password': adminPasswordController.text.trim().isEmpty
            ? 'Temp@123456'
            : adminPasswordController.text.trim(),
        'phone': '',
      };
    }

    setState(() => isSaving = true);

    await widget.onSubmit(payload, adminPayload);

    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      title: Text(widget.title),
      content: SizedBox(
        width: 780,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _sectionTitle(l10n.establishmentInformation),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.labelEstablishmentName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ifuController,
                decoration: InputDecoration(labelText: l10n.labelIfu),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityController,
                      decoration: InputDecoration(labelText: l10n.labelCity),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: countryController,
                      decoration: InputDecoration(labelText: l10n.labelCountry),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: l10n.labelEstablishmentType,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'hotel_bar_restaurant',
                    child: Text(l10n.typeHotelBarRestaurant),
                  ),
                  DropdownMenuItem(
                    value: 'hotel',
                    child: Text(l10n.storeNameHotel),
                  ),
                  DropdownMenuItem(
                    value: 'restaurant',
                    child: Text(l10n.storeNameRestaurant),
                  ),
                  DropdownMenuItem(
                    value: 'bar',
                    child: Text(l10n.storeNameBar),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedType = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPlan,
                decoration: InputDecoration(labelText: l10n.labelPlan),
                items: [
                  DropdownMenuItem(value: 'starter', child: Text('Starter')),
                  DropdownMenuItem(value: 'standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'premium', child: Text('Premium')),
                  DropdownMenuItem(
                    value: 'enterprise',
                    child: Text('Enterprise'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedPlan = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: InputDecoration(labelText: l10n.labelStatus),
                items: [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text(l10n.establishmentStatusActive),
                  ),
                  DropdownMenuItem(
                    value: 'suspended',
                    child: Text(l10n.establishmentStatusSuspended),
                  ),
                  DropdownMenuItem(
                    value: 'trial',
                    child: Text(l10n.establishmentStatusTrial),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedStatus = value);
                },
              ),
              const SizedBox(height: 18),
              _sectionTitle(l10n.enabledModules),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: selectedModules.keys.map((key) {
                  final value = selectedModules[key] ?? false;
                  return FilterChip(
                    label: Text(key),
                    selected: value,
                    onSelected: (selected) {
                      setState(() => selectedModules[key] = selected);
                    },
                  );
                }).toList(),
              ),
              if (!isEdit) ...[
                const SizedBox(height: 18),
                _sectionTitle(l10n.firstEstablishmentAdmin),
                TextField(
                  controller: adminNameController,
                  decoration: InputDecoration(
                    labelText: l10n.labelAdminName,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adminEmailController,
                  decoration: InputDecoration(
                    labelText: l10n.labelAdminEmail,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adminPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.labelTemporaryPassword,
                    hintText: l10n.hintDefaultTemporaryPassword,
                  ),
                ),
              ],
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
              : Icon(isEdit ? Icons.save : Icons.add_business),
          label: Text(isEdit ? l10n.actionSave : l10n.actionCreate),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isSmall;

  const _HeaderCard({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: Colors.indigo,
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 16 : 22),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, color: Colors.indigo),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.globalConsoleTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.globalConsoleSubtitle,
                    style: const TextStyle(color: Colors.white70),
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

class _EstablishmentCard extends StatelessWidget {
  final String establishmentId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _EstablishmentCard({
    required this.establishmentId,
    required this.data,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = (data['name'] ?? '').toString();
    final city = (data['city'] ?? '').toString();
    final country = (data['country'] ?? '').toString();
    final ifu = (data['ifu'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final plan = (data['plan'] ?? '').toString();
    final type = (data['type'] ?? '').toString();
    final modules = Map<String, dynamic>.from(data['modules'] ?? {});
    final isActive = status == 'active';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name.isEmpty ? l10n.unnamedEstablishment : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.actionEdit,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('$city, $country'),
            const SizedBox(height: 6),
            Text(l10n.idLine(establishmentId)),
            Text(l10n.ifuLine(ifu.isEmpty ? '-' : ifu)),
            Text(l10n.typeLine(type)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(status.isEmpty ? l10n.noStatus : status),
                  backgroundColor: isActive
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12),
                ),
                Chip(label: Text(l10n.planChipLabel(plan.isEmpty ? '-' : plan))),
                ...modules.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => Chip(label: Text(entry.key))),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onToggleStatus,
                icon: Icon(
                  isActive ? Icons.pause_circle_outline : Icons.check_circle,
                ),
                label: Text(isActive ? 'Suspendre' : 'Activer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateEstablishmentAdminDialog extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> establishments;

  final Future<void> Function({
    required String establishmentId,
    required String establishmentName,
    required String email,
    required String password,
    required String name,
    required String phone,
    required Map<String, dynamic> modules,
  })
  onSubmit;

  const _CreateEstablishmentAdminDialog({
    required this.establishments,
    required this.onSubmit,
  });

  @override
  State<_CreateEstablishmentAdminDialog> createState() =>
      _CreateEstablishmentAdminDialogState();
}

class _CreateEstablishmentAdminDialogState
    extends State<_CreateEstablishmentAdminDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedEstablishmentId;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    selectedEstablishmentId = widget.establishments.first.id;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim().isEmpty
        ? 'Temp@123456'
        : passwordController.text.trim();

    if (selectedEstablishmentId == null || name.isEmpty || email.isEmpty) {
      return;
    }

    final establishmentDoc = widget.establishments.firstWhere(
      (doc) => doc.id == selectedEstablishmentId,
    );

    final establishmentData = establishmentDoc.data();
    final establishmentName = (establishmentData['name'] ?? '')
        .toString()
        .trim();

    final modules = Map<String, dynamic>.from(
      establishmentData['modules'] ?? {},
    );

    setState(() => isSaving = true);

    await widget.onSubmit(
      establishmentId: establishmentDoc.id,
      establishmentName: establishmentName,
      email: email,
      password: password,
      name: name,
      phone: phoneController.text.trim(),
      modules: modules,
    );

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.createEstablishmentAdminTitle),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedEstablishmentId,
                decoration: InputDecoration(
                  labelText: l10n.labelEstablishment,
                ),
                items: widget.establishments.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? doc.id).toString();

                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEstablishmentId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.labelAdminName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: l10n.labelEmail),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.labelPhone),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.labelTemporaryPassword,
                  hintText: l10n.hintDefaultTemporaryPassword,
                ),
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
