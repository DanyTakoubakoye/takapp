import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/client_model.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/client_service.dart';
import 'package:takapp/services/menu_service.dart';
import 'package:takapp/vues/commun/client_picker_sheet.dart';
import 'package:takapp/vues/commun/module_visibility.dart';

class NouvelleCommandePage extends StatefulWidget {
  const NouvelleCommandePage({super.key});

  @override
  State<NouvelleCommandePage> createState() => _NouvelleCommandePageState();
}

class _NouvelleCommandePageState extends State<NouvelleCommandePage> {
  final MenuService _menuService = MenuService();

  final ClientService _clientService = ClientService();

  String clientType = 'restaurant';

  final TextEditingController tableController = TextEditingController();

  final TextEditingController roomController = TextEditingController();

  /// Fiche client rattachée. Vide = commande sans client (cas courant).
  String _selectedClientId = '';
  String _selectedClientName = '';

  // L'établissement n'est connu qu'au build (AuthController) : on mémorise le
  // stream et on ne le recrée que s'il change vraiment. Sinon chaque frappe
  // dans « Table » / « Chambre » relancerait l'abonnement et remettrait le
  // menu en chargement.
  String? _menuStreamEstablishmentId;
  Stream<List<MenuItemModel>>? _menuItemsStream;

  Stream<List<MenuItemModel>> _menuStreamFor(String establishmentId) {
    if (_menuStreamEstablishmentId != establishmentId ||
        _menuItemsStream == null) {
      _menuStreamEstablishmentId = establishmentId;
      _menuItemsStream = _menuService.getAvailableMenuItems(
        establishmentId: establishmentId,
      );
    }

    return _menuItemsStream!;
  }

  @override
  void dispose() {
    tableController.dispose();
    roomController.dispose();
    super.dispose();
  }

  /// Sélection facultative d'une fiche client.
  ///
  /// PIÈGE : le sheet doit être fermé avec `Navigator.pop(sheetContext, valeur)`
  /// (géré dans ClientPickerSheet).
  Future<void> _pickClient(String establishmentId) async {
    final selected = await showModalBottomSheet<ClientModel>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ClientPickerSheet(
        establishmentId: establishmentId,
        service: _clientService,
      ),
    );

    if (!mounted) return;
    if (selected == null) return;

    setState(() {
      _selectedClientId = selected.id;
      _selectedClientName = selected.name;
    });
  }

  void _detachClient() {
    setState(() {
      _selectedClientId = '';
      _selectedClientName = '';
    });
  }

  /// Sélecteur discret : jamais bloquant, jamais obligatoire.
  Widget _buildClientSelector(String establishmentId) {
    if (_selectedClientId.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _pickClient(establishmentId),
          icon: const Icon(Icons.person_search, size: 18),
          label: const Text('Rattacher un client (optionnel)'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Client : $_selectedClientName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Détacher le client',
            icon: const Icon(Icons.close, size: 18),
            onPressed: _detachClient,
          ),
        ],
      ),
    );
  }

  Future<void> _submitOrder(String establishmentId) async {
    final auth = context.read<AuthController>();

    final orderController = context.read<OrderController>();

    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    final success = await orderController.submitOrder(
      establishmentId: establishmentId,
      clientType: clientType,
      tableNumber: tableController.text.trim(),
      roomNumber: roomController.text.trim(),
      createdBy: user.uid,
      createdByName: user.name,
      clientId: _selectedClientId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande envoyée avec succès.')),
      );

      tableController.clear();
      roomController.clear();

      setState(() {
        clientType = 'restaurant';
        _selectedClientId = '';
        _selectedClientName = '';
      });
    } else if (orderController.hasError) {
      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(orderController.errorText(l10n)!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    final orderController = context.watch<OrderController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle commande')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildMobilePanierCard(
                    context,
                    orderController,
                    establishmentId,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildArticlesCard(
                      context,
                      user: user,
                      establishmentId: establishmentId,
                      isMobile: true,
                    ),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildArticlesCard(
                    context,
                    user: user,
                    establishmentId: establishmentId,
                    isMobile: false,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  child: _buildDesktopPanierCard(
                    context,
                    orderController,
                    establishmentId,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArticlesCard(
    BuildContext context, {
    required UserModel user,
    required String establishmentId,
    required bool isMobile,
  }) {
    // Options du sélecteur "Type de client" limitées aux modules souscrits.
    // Un établissement abonné à tout conserve les trois options d'origine.
    final clientTypeOptions = <MapEntry<String, String>>[
      const MapEntry('bar', 'Client Bar'),
      const MapEntry('restaurant', 'Client Restaurant'),
      const MapEntry('hotel', 'Client Hôtel'),
    ].where((e) => user.canUseClientType(e.key)).toList();

    // Si le type courant n'est plus proposable, on bascule sur le premier
    // disponible (assignation directe hors setState, comme ailleurs dans build).
    if (clientTypeOptions.isNotEmpty &&
        !clientTypeOptions.any((e) => e.key == clientType)) {
      clientType = clientTypeOptions.first.key;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: clientType,
              decoration: const InputDecoration(
                labelText: 'Type de client',
                border: OutlineInputBorder(),
              ),
              items: clientTypeOptions
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  clientType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            if (clientType == 'restaurant')
              TextField(
                controller: tableController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de table',
                  border: OutlineInputBorder(),
                ),
              ),
            if (clientType == 'hotel')
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de chambre',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<MenuItemModel>>(
                stream: _menuStreamFor(establishmentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final items =
                      user.visibleMenuItems(snapshot.data ?? []).toList()
                        ..sort(
                          (a, b) => a.name.toLowerCase().compareTo(
                            b.name.toLowerCase(),
                          ),
                        );

                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Aucun article disponible.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.category} • ${item.price.toStringAsFixed(0)} FCFA',
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<OrderController>()
                                            .addMenuItem(item);
                                      },
                                      child: const Text('Ajouter'),
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
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.category} • ${item.price.toStringAsFixed(0)} FCFA',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<OrderController>()
                                          .addMenuItem(item);
                                    },
                                    child: const Text('Ajouter'),
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

  Widget _buildMobilePanierCard(
    BuildContext context,
    OrderController orderController,
    String establishmentId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panier', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (orderController.items.isEmpty)
              const Text('Aucun article ajouté.')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 170),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: orderController.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 14),
                  itemBuilder: (context, index) {
                    final item = orderController.items[index];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.unitPrice.toStringAsFixed(0)} FCFA x ${item.quantity} = ${item.totalPrice.toStringAsFixed(0)} FCFA',
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                context.read<OrderController>().decrementItem(
                                  item.menuItemId,
                                );
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () {
                                context.read<OrderController>().incrementItem(
                                  item.menuItemId,
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            const Divider(),
            Text(
              'Sous-total : ${orderController.subtotal.toStringAsFixed(0)} FCFA',
            ),
            const SizedBox(height: 6),
            Text(
              'Total : ${orderController.total.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            _buildClientSelector(establishmentId),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: orderController.isSubmitting
                    ? null
                    : () => _submitOrder(establishmentId),
                child: orderController.isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Envoyer la commande'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPanierCard(
    BuildContext context,
    OrderController orderController,
    String establishmentId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Panier', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: orderController.items.isEmpty
                  ? const Center(child: Text('Aucun article ajouté.'))
                  : ListView.separated(
                      itemCount: orderController.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = orderController.items[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.unitPrice.toStringAsFixed(0)} FCFA x ${item.quantity} = ${item.totalPrice.toStringAsFixed(0)} FCFA',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    context
                                        .read<OrderController>()
                                        .decrementItem(item.menuItemId);
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  onPressed: () {
                                    context
                                        .read<OrderController>()
                                        .incrementItem(item.menuItemId);
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sous-total : ${orderController.subtotal.toStringAsFixed(0)} FCFA',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total : ${orderController.total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildClientSelector(establishmentId),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: orderController.isSubmitting
                    ? null
                    : () => _submitOrder(establishmentId),
                child: orderController.isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Envoyer la commande'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
