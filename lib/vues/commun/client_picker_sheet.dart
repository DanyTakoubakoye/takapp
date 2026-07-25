import 'package:flutter/material.dart';

import 'package:takapp/modeles/client_model.dart';
import 'package:takapp/services/client_service.dart';

/// Sélecteur de fiche client (panneau modal).
///
/// Reprend la mécanique du formulaire de réservation : le stream renvoie tous
/// les clients actifs et le filtrage est local, aucune requête Firestore n'est
/// relancée à chaque frappe.
///
/// PIÈGE : le sheet doit être fermé avec `Navigator.pop(sheetContext, valeur)`.
/// `Navigator.of(sheetContext).pop(...)` remonte au mauvais Navigator et le
/// panneau ne se ferme pas (bug déjà rencontré sur ce projet).
class ClientPickerSheet extends StatefulWidget {
  final String establishmentId;
  final ClientService service;

  const ClientPickerSheet({
    super.key,
    required this.establishmentId,
    required this.service,
  });

  @override
  State<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<ClientPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClientModel> _filter(List<ClientModel> clients) {
    final query = _query.trim();

    if (query.isEmpty) return clients;

    final lowerQuery = query.toLowerCase();

    return clients.where((client) {
      return client.name.toLowerCase().contains(lowerQuery) ||
          client.phone.contains(query);
    }).toList();
  }

  String _subtitle(ClientModel client) {
    final parts = <String>[];

    if (client.phone.isNotEmpty) parts.add(client.phone);

    if (client.ifu.isNotEmpty) parts.add('IFU ${client.ifu}');

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext sheetContext) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Text(
              'Choisir un client',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Rechercher',
                  hintText: 'Nom ou téléphone',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ClientModel>>(
                stream: widget.service.streamClients(
                  establishmentId: widget.establishmentId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: SelectableText('Erreur : ${snapshot.error}'),
                    );
                  }

                  final clients = snapshot.data ?? [];

                  if (clients.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune fiche client.\n'
                          'La commande peut être envoyée sans client.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final filtered = _filter(clients);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun client ne correspond à cette recherche.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = filtered[index];

                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_subtitle(client)),
                        // Navigator.pop(sheetContext, ...) et surtout PAS
                        // Navigator.of(sheetContext).pop(...) : voir la doc
                        // de la classe.
                        onTap: () => Navigator.pop(sheetContext, client),
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
