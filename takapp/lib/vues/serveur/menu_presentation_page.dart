import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/modeles/client_model.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/services/client_service.dart';
import 'package:takapp/services/menu_service.dart';
import 'package:takapp/vues/commun/client_picker_sheet.dart';
import 'package:takapp/vues/commun/module_visibility.dart';

class MenuPresentationPage extends StatefulWidget {
  const MenuPresentationPage({super.key});

  @override
  State<MenuPresentationPage> createState() => _MenuPresentationPageState();
}

class _MenuPresentationPageState extends State<MenuPresentationPage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final PageStorageKey _menuListKey = const PageStorageKey(
    'menu_presentation_list',
  );

  Stream<List<MenuItemModel>>? _menuItemsStream;

  String searchText = '';
  String selectedCategory = 'Toutes';
  String? activeItemId;

  final Map<String, int> selectedQuantities = {};

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleItem(MenuItemModel item) {
    setState(() {
      selectedQuantities.putIfAbsent(item.id, () => 1);
      activeItemId = item.id;
    });
  }

  void _increaseQuantity(MenuItemModel item) {
    setState(() {
      selectedQuantities[item.id] = (selectedQuantities[item.id] ?? 0) + 1;
      activeItemId = item.id;
    });
  }

  void _decreaseQuantity(MenuItemModel item) {
    setState(() {
      final current = selectedQuantities[item.id] ?? 0;

      if (current <= 1) {
        selectedQuantities.remove(item.id);
        if (activeItemId == item.id) activeItemId = null;
      } else {
        selectedQuantities[item.id] = current - 1;
        activeItemId = item.id;
      }
    });
  }

  int _quantityOf(MenuItemModel item) => selectedQuantities[item.id] ?? 0;

  bool _isSelected(MenuItemModel item) =>
      selectedQuantities.containsKey(item.id);

  double _totalAmount(List<MenuItemModel> allItems) {
    double total = 0;

    for (final item in allItems) {
      final qty = selectedQuantities[item.id] ?? 0;
      if (qty > 0) total += item.price * qty;
    }

    return total;
  }

  List<_SelectedMenuLine> _buildSelectedLines(List<MenuItemModel> allItems) {
    return allItems
        .where((item) => (selectedQuantities[item.id] ?? 0) > 0)
        .map(
          (item) => _SelectedMenuLine(
            item: item,
            quantity: selectedQuantities[item.id]!,
          ),
        )
        .toList();
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

    _menuItemsStream ??= MenuService().getAvailableMenuItems(
      establishmentId: establishmentId,
    );

    return GestureDetector(
      onTap: () {
        if (activeItemId != null) {
          setState(() => activeItemId = null);
        }
      },
      behavior: HitTestBehavior.deferToChild,
      child: Scaffold(
        backgroundColor: const Color(0xFF4E342E),
        appBar: AppBar(
          title: const Text('Présentation du menu'),
          backgroundColor: const Color(0xFF3E2723),
        ),
        body: SafeArea(
          child: StreamBuilder<List<MenuItemModel>>(
            stream: _menuItemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: [
                    _buildTopSearchZone(),
                    _buildCategoryDropdown(const ['Toutes']),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  children: [
                    _buildTopSearchZone(),
                    _buildCategoryDropdown(const ['Toutes']),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Erreur : ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final rawItems =
                  List<MenuItemModel>.from(
                      user.visibleMenuItems(snapshot.data ?? []),
                    )
                    ..sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );

              final availableCategories =
                  <String>{
                    'Toutes',
                    ...rawItems
                        .map((e) => e.category.trim())
                        .where((category) => category.isNotEmpty),
                  }.toList()..sort((a, b) {
                    if (a == 'Toutes') return -1;
                    if (b == 'Toutes') return 1;
                    return a.toLowerCase().compareTo(b.toLowerCase());
                  });

              if (!availableCategories.contains(selectedCategory)) {
                selectedCategory = 'Toutes';
              }

              if (rawItems.isEmpty) {
                return Column(
                  children: [
                    _buildTopSearchZone(),
                    _buildCategoryDropdown(availableCategories),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Aucun article disponible.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final filteredItems =
                  rawItems.where((item) {
                    final query = searchText.toLowerCase();

                    final matchesSearch =
                        item.name.toLowerCase().contains(query) ||
                        item.category.toLowerCase().contains(query);

                    final matchesCategory =
                        selectedCategory == 'Toutes' ||
                        item.category.toLowerCase() ==
                            selectedCategory.toLowerCase();

                    return matchesSearch && matchesCategory;
                  }).toList()..sort((a, b) {
                    final catCompare = a.category.toLowerCase().compareTo(
                      b.category.toLowerCase(),
                    );
                    if (catCompare != 0) return catCompare;
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });

              final groupedItems = _groupByCategory(filteredItems);

              return Column(
                children: [
                  _buildTopSearchZone(),
                  _buildStickyCategoryZone(availableCategories),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView(
                          key: _menuListKey,
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          children: [
                            ...groupedItems.entries.map(
                              (entry) =>
                                  _buildCategorySection(entry.key, entry.value),
                            ),
                          ],
                        ),
                        if (selectedQuantities.isNotEmpty)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: _buildRecapButton(
                              establishmentId: establishmentId,
                              allItems: rawItems,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearchZone() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF3E2723),
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchText = value),
        decoration: InputDecoration(
          hintText: 'Rechercher un article ou une catégorie...',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStickyCategoryZone(List<String> categories) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      color: const Color(0xFF3E2723),
      child: _buildCategoryDropdown(categories),
    );
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedCategory = value);
          },
        ),
      ),
    );
  }

  Map<String, List<MenuItemModel>> _groupByCategory(List<MenuItemModel> items) {
    final map = <String, List<MenuItemModel>>{};

    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }

    return map;
  }

  Widget _buildCategorySection(String category, List<MenuItemModel> items) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final crossAxisCount = isMobile
        ? 1
        : screenWidth < 1100
        ? 3
        : 4;

    final childAspectRatio = isMobile ? 1.55 : 0.78;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          category.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _buildItemCard(items[index]);
          },
        ),
      ],
    );
  }

  Widget _buildMenuImage(MenuItemModel item, bool isMobile) {
    final adresse = (item.adresse ?? '').trim();

    if (adresse.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 38));
    }

    if (adresse.startsWith('assets/')) {
      return Image.asset(
        adresse,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const Center(child: Icon(Icons.image_outlined, size: 38));
        },
      );
    }

    if (adresse.startsWith('http://') || adresse.startsWith('https://')) {
      return Image.network(
        adresse,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const Center(child: Icon(Icons.image_outlined, size: 38));
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return Image.asset(
      adresse,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return const Center(child: Icon(Icons.image_outlined, size: 38));
      },
    );
  }

  Widget _buildItemCard(MenuItemModel item) {
    final selected = _isSelected(item);
    final showQuantityBox = activeItemId == item.id;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final composition = item.composition.trim();
    final hasComposition = composition.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFE0B2) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFFBF7B30) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleItem(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: isMobile ? 72 : 95,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildMenuImage(item, isMobile),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (hasComposition) ...[
                    const SizedBox(height: 6),
                    Text(
                      composition,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${item.price.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  if (selected)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D4037),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Sélectionné • Qté ${_quantityOf(item)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showQuantityBox) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _decreaseQuantity(item),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                    icon: const Icon(
                      Icons.remove,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_quantityOf(item)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _increaseQuantity(item),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                    icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecapButton({
    required String establishmentId,
    required List<MenuItemModel> allItems,
  }) {
    final totalSelected = selectedQuantities.values.fold<int>(
      0,
      (sum, qty) => sum + qty,
    );

    final totalAmount = _totalAmount(allItems);

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: Colors.white,
        elevation: 10,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () async {
        final lines = _buildSelectedLines(allItems);

        final orderConfirmed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _OrderRecapPage(establishmentId: establishmentId, lines: lines),
          ),
        );

        if (orderConfirmed == true && mounted) {
          setState(() {
            selectedQuantities.clear();
            activeItemId = null;
          });
        }
      },
      icon: const Icon(Icons.receipt_long_outlined),
      label: Text(
        'Voir le récapitulatif ($totalSelected) • ${totalAmount.toStringAsFixed(0)} FCFA',
      ),
    );
  }
}

class _OrderRecapPage extends StatefulWidget {
  final String establishmentId;
  final List<_SelectedMenuLine> lines;

  const _OrderRecapPage({required this.establishmentId, required this.lines});

  @override
  State<_OrderRecapPage> createState() => _OrderRecapPageState();
}

class _OrderRecapPageState extends State<_OrderRecapPage> {
  String clientType = 'restaurant';

  final TextEditingController tableController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  final ClientService _clientService = ClientService();

  /// Fiche client rattachée. Vide = commande sans client (cas courant).
  String _selectedClientId = '';
  String _selectedClientName = '';

  String get establishmentId => widget.establishmentId.trim();

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
  Future<void> _pickClient() async {
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
  Widget _buildClientSelector(bool isSubmitting) {
    if (_selectedClientId.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: isSubmitting ? null : _pickClient,
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
            onPressed: isSubmitting ? null : _detachClient,
          ),
        ],
      ),
    );
  }

  double get totalAmount {
    return widget.lines.fold<double>(0, (sum, line) => sum + line.totalPrice);
  }

  Future<void> _confirmOrder() async {
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

    if (clientType == 'restaurant' && tableController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le numéro de table.'),
        ),
      );
      return;
    }

    if (clientType == 'hotel' && roomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le numéro de chambre.'),
        ),
      );
      return;
    }

    final existingItems = List.of(orderController.items);

    for (final item in existingItems) {
      for (int i = 0; i < item.quantity; i++) {
        orderController.decrementItem(item.menuItemId);
      }
    }

    for (final line in widget.lines) {
      for (int i = 0; i < line.quantity; i++) {
        orderController.addMenuItem(line.item);
      }
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

      Navigator.pop(context, true);
    } else if (orderController.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(orderController.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final user = context.watch<AuthController>().currentUser;

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    // Options du sélecteur limitées aux modules souscrits (identiques à
    // l'origine pour un établissement abonné à tout).
    final clientTypeOptions = <MapEntry<String, String>>[
      const MapEntry('bar', 'Client Bar'),
      const MapEntry('restaurant', 'Client Restaurant'),
      const MapEntry('hotel', 'Client Hôtel'),
    ].where((e) => user == null || user.canUseClientType(e.key)).toList();

    if (clientTypeOptions.isNotEmpty &&
        !clientTypeOptions.any((e) => e.key == clientType)) {
      clientType = clientTypeOptions.first.key;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Récapitulatif de la commande')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
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
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: orderController.isSubmitting
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => clientType = value);
                        },
                ),
                const SizedBox(height: 12),
                if (clientType == 'restaurant')
                  TextField(
                    controller: tableController,
                    enabled: !orderController.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de table',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (clientType == 'hotel')
                  TextField(
                    controller: roomController,
                    enabled: !orderController.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de chambre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.lines.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final line = widget.lines[index];

                      return ListTile(
                        title: Text(
                          line.item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${line.item.category} • ${line.item.price.toStringAsFixed(0)} FCFA x ${line.quantity}',
                        ),
                        trailing: Text(
                          '${line.totalPrice.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Total : ${totalAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildClientSelector(orderController.isSubmitting),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: orderController.isSubmitting
                        ? null
                        : _confirmOrder,
                    icon: orderController.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      orderController.isSubmitting
                          ? 'Envoi en cours...'
                          : 'Confirmer et envoyer',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMenuLine {
  final MenuItemModel item;
  final int quantity;

  const _SelectedMenuLine({required this.item, required this.quantity});

  double get totalPrice => item.price * quantity;
}
