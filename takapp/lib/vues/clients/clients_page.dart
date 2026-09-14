import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/client_model.dart';
import 'package:takapp/services/client_service.dart';
import 'package:takapp/vues/clients/client_history_page.dart';

class ClientsPage extends StatefulWidget {
  final String establishmentId;

  const ClientsPage({super.key, required this.establishmentId});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final ClientService _service = ClientService();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  // Créé une seule fois : chaque frappe dans la recherche déclenche un
  // setState, et un stream recréé remettrait la liste en chargement.
  late final Stream<List<ClientModel>> _clientsStream;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();
    _clientsStream = _service.streamClients(establishmentId: establishmentId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _clientTypeLabel(String clientType) {
    switch (clientType) {
      case 'particulier':
        return 'Particulier';
      case 'entreprise':
        return 'Entreprise';
      default:
        return clientType;
    }
  }

  String _subtitle(ClientModel client) {
    final parts = <String>[];

    if (client.phone.isNotEmpty) parts.add(client.phone);

    parts.add(_clientTypeLabel(client.clientType));

    if (client.ifu.isNotEmpty) parts.add('IFU ${client.ifu}');

    return parts.join(' · ');
  }

  /// Filtrage local : le stream renvoie tous les clients actifs,
  /// aucune requête Firestore n'est relancée à chaque frappe.
  List<ClientModel> _filter(List<ClientModel> clients) {
    final query = _query.trim();

    if (query.isEmpty) return clients;

    final lowerQuery = query.toLowerCase();

    return clients.where((client) {
      return client.name.toLowerCase().contains(lowerQuery) ||
          client.phone.contains(query);
    }).toList();
  }

  Future<void> _openForm({ClientModel? existing}) async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    await showDialog<void>(
      context: context,
      builder: (_) => _ClientFormDialog(
        establishmentId: establishmentId,
        service: _service,
        existing: existing,
        createdBy: user?.uid ?? '',
        createdByName: user?.name ?? '',
        onDone: _showMessage,
      ),
    );
  }

  Future<void> _confirmDisable(ClientModel client) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.disableClientTitle),
        content: Text(l10n.disableClientBody(client.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDisable),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.disableClient(
        establishmentId: establishmentId,
        clientId: client.id,
      );
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).clientDisabled);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _showMessage(l10n.errorPrefixed(localizedError(l10n, e)));
    }
  }

  void _openHistory(ClientModel client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ClientHistoryPage(establishmentId: establishmentId, client: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tileClientsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddClient),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchLabel,
                hintText: l10n.searchNameOrPhoneHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.actionClear,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ClientModel>>(
              stream: _clientsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: SelectableText(l10n.commonError('${snapshot.error}')),
                  );
                }

                final clients = snapshot.data ?? [];

                if (clients.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.noClientRegistered,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final filtered = _filter(clients);

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.noClientMatchesSearch,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final client = filtered[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_subtitle(client)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openForm(existing: client);
                            } else if (value == 'disable') {
                              _confirmDisable(client);
                            } else if (value == 'history') {
                              _openHistory(client);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.actionEdit),
                            ),
                            PopupMenuItem(
                              value: 'disable',
                              child: Text(l10n.actionDisable),
                            ),
                            PopupMenuItem(
                              value: 'history',
                              child: Text(l10n.actionViewHistory),
                            ),
                          ],
                        ),
                        onTap: () => _openHistory(client),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientFormDialog extends StatefulWidget {
  final String establishmentId;
  final ClientService service;
  final ClientModel? existing;
  final String createdBy;
  final String createdByName;
  final void Function(String message) onDone;

  const _ClientFormDialog({
    required this.establishmentId,
    required this.service,
    required this.existing,
    required this.createdBy,
    required this.createdByName,
    required this.onDone,
  });

  @override
  State<_ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<_ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ifuController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _noteController;

  late String _clientType;

  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _ifuController = TextEditingController(text: e?.ifu ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');

    final existingType = e?.clientType ?? '';
    _clientType = ClientService.clientTypes.contains(existingType)
        ? existingType
        : 'particulier';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ifuController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // l10n lu en tete : apres le pop, le context n'est plus exploitable
    // pour lire les localisations.
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final ifu = _ifuController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final note = _noteController.text.trim();

    try {
      if (_isEdit) {
        await widget.service.updateClient(
          establishmentId: widget.establishmentId,
          clientId: widget.existing!.id,
          name: name,
          phone: phone,
          ifu: ifu,
          address: address,
          email: email,
          note: note,
          clientType: _clientType,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onDone(l10n.clientUpdated);
        return;
      }

      /// =========================
      /// DÉTECTION DE DOUBLONS
      /// =========================
      /// Uniquement à la création. Jamais bloquant : les homonymes existent.

      final duplicates = await widget.service.findPotentialDuplicates(
        establishmentId: widget.establishmentId,
        name: name,
        phone: phone,
      );

      if (!mounted) return;

      if (duplicates.isNotEmpty) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => _DuplicateWarningDialog(duplicates: duplicates),
        );

        if (!mounted) return;

        // Retour au formulaire : rien n'est créé.
        if (confirm != true) return;
      }

      await widget.service.createClient(
        establishmentId: widget.establishmentId,
        name: name,
        phone: phone,
        ifu: ifu,
        address: address,
        email: email,
        note: note,
        clientType: _clientType,
        createdBy: widget.createdBy,
        createdByName: widget.createdByName,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onDone(l10n.clientAdded);
    } catch (e) {
      if (!mounted) return;
      widget.onDone(l10n.errorPrefixed(localizedError(l10n, e)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(_isEdit ? l10n.editClientTitle : l10n.newClientTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.labelNameOrCompany,
                    hintText: l10n.hintClientNameExample,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _clientType,
                  decoration: InputDecoration(
                    labelText: l10n.clientTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'particulier',
                      child: Text(l10n.clientTypeIndividual),
                    ),
                    DropdownMenuItem(
                      value: 'entreprise',
                      child: Text(l10n.clientTypeCompany),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _clientType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.labelPhone,
                    hintText: l10n.hintPhoneExample,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ifuController,
                  decoration: InputDecoration(
                    labelText: l10n.labelIfuOptional,
                    hintText: l10n.hintIfuPurpose,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.labelAddressOptional,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.labelEmailOptional,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteOptionalLabel,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    );
  }
}

class _DuplicateWarningDialog extends StatelessWidget {
  final List<ClientModel> duplicates;

  const _DuplicateWarningDialog({required this.duplicates});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.duplicateClientTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.duplicateClientBody),
              const SizedBox(height: 12),
              ...duplicates.map(
                (client) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          client.phone.isNotEmpty
                              ? l10n.nameDotPhone(client.name, client.phone)
                              : client.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homonymsExistHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionCreateAnyway),
        ),
      ],
    );
  }
}
