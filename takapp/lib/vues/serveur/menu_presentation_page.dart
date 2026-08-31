import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/modeles/client_model.dart';
import 'package:takapp/core/constants/bar_categories.dart';
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

  /// Articles SANS accompagnement : regroupés par quantité (comportement d'origine).
  final Map<String, int> selectedQuantities = {};

  /// Plats AVEC accompagnement : une entrée par unité, chacune avec son
  /// accompagnement gratuit choisi. Les portions payantes sont, elles,
  /// ajoutées comme des articles normaux dans selectedQuantities.
  final List<_AccompaniedUnit> accompaniedUnits = [];

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Normalise pour comparer les catégories (minuscules + espaces compactés).
  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Clé de tri des catégories : une sous-catégorie est triée juste après sa
  /// catégorie parente (« Cocktails », puis « Cocktails alcoolisés », puis
  /// « Sans alcool ») au lieu d'être dispersée dans l'ordre alphabétique.
  String _categorySortKey(String category) {
    final parent = BarCategories.parentOf(category);

    if (parent == null) return _norm(category);

    return '${_norm(parent)} ~ ${_norm(category)}';
  }

  /// Un item est un accompagnement si sa catégorie est "Accompagnements"
  /// (singulier ou pluriel, insensible casse/espaces).
  bool _isAccompaniment(MenuItemModel item) {
    final c = _norm(item.category);
    return c == 'accompagnements' || c == 'accompagnement';
  }

  // =========================
  // SÉLECTION — ARTICLES NORMAUX (inchangé)
  // =========================
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

  // =========================
  // SÉLECTION — PLATS À ACCOMPAGNEMENT
  // =========================

  /// Ouvre le sélecteur d'accompagnement pour une unité du plat.
  /// [accompaniments] = liste des menuItems catégorie Accompagnements du même
  /// département (cuisine ici).
  Future<void> _openAccompanimentSheet(
    MenuItemModel dish,
    List<MenuItemModel> accompaniments,
  ) async {
    if (accompaniments.isEmpty) {
      // Aucun accompagnement disponible : on ajoute quand même l'unité,
      // sans accompagnement (le plat reste commandable).
      setState(() {
        accompaniedUnits.add(
          _AccompaniedUnit(dish: dish, accompanimentName: ''),
        );
        activeItemId = dish.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun accompagnement disponible. Plat ajouté sans accompagnement.',
          ),
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<_AccompanimentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) =>
          _AccompanimentSheet(dish: dish, accompaniments: accompaniments),
    );

    if (!mounted) return;
    if (result == null) return; // annulé

    setState(() {
      // 1. L'unité du plat avec son accompagnement gratuit
      accompaniedUnits.add(
        _AccompaniedUnit(
          dish: dish,
          accompanimentName: result.freeAccompanimentName,
        ),
      );
      // 2. Les portions payantes = articles normaux ajoutés au panier
      result.paidExtras.forEach((extraId, qty) {
        if (qty > 0) {
          selectedQuantities[extraId] =
              (selectedQuantities[extraId] ?? 0) + qty;
        }
      });
      activeItemId = dish.id;
    });
  }

  /// Retire la dernière unité d'un plat à accompagnement.
  void _removeLastAccompaniedUnit(MenuItemModel dish) {
    setState(() {
      final index = accompaniedUnits.lastIndexWhere(
        (u) => u.dish.id == dish.id,
      );
      if (index >= 0) {
        accompaniedUnits.removeAt(index);
      }
      if (!accompaniedUnits.any((u) => u.dish.id == dish.id) &&
          activeItemId == dish.id) {
        activeItemId = null;
      }
    });
  }

  int _accompaniedCountOf(MenuItemModel dish) =>
      accompaniedUnits.where((u) => u.dish.id == dish.id).length;

  // =========================
  // COMPTAGE / SÉLECTION COMBINÉS
  // =========================
  int _quantityOf(MenuItemModel item) {
    if (item.allowsFreeAccompaniment) {
      return _accompaniedCountOf(item);
    }
    return selectedQuantities[item.id] ?? 0;
  }

  bool _isSelected(MenuItemModel item) {
    if (item.allowsFreeAccompaniment) {
      return _accompaniedCountOf(item) > 0;
    }
    return selectedQuantities.containsKey(item.id);
  }

  bool get _hasAnySelection =>
      selectedQuantities.isNotEmpty || accompaniedUnits.isNotEmpty;

  double _totalAmount(List<MenuItemModel> allItems) {
    double total = 0;
    // Articles normaux + portions payantes (dans selectedQuantities)
    for (final item in allItems) {
      final qty = selectedQuantities[item.id] ?? 0;
      if (qty > 0) total += item.price * qty;
    }
    // Plats à accompagnement (chaque unité au prix du plat)
    for (final unit in accompaniedUnits) {
      total += unit.dish.price;
    }
    return total;
  }

  int get _totalSelectedCount {
    final normals = selectedQuantities.values.fold<int>(
      0,
      (sum, qty) => sum + qty,
    );
    return normals + accompaniedUnits.length;
  }

  List<_SelectedMenuLine> _buildSelectedLines(List<MenuItemModel> allItems) {
    final lines = <_SelectedMenuLine>[];

    // Articles normaux + portions payantes
    for (final item in allItems) {
      final qty = selectedQuantities[item.id] ?? 0;
      if (qty > 0) {
        lines.add(_SelectedMenuLine(item: item, quantity: qty));
      }
    }

    // Plats à accompagnement : une ligne par unité (avec accompagnement)
    for (final unit in accompaniedUnits) {
      lines.add(
        _SelectedMenuLine(
          item: unit.dish,
          quantity: 1,
          accompanimentName: unit.accompanimentName,
        ),
      );
    }

    return lines;
  }

  void _clearAllSelection() {
    selectedQuantities.clear();
    accompaniedUnits.clear();
    activeItemId = null;
  }

  // =========================
  // COULEURS DU THÈME (luxe & paix : crème + bleu nuit + or)
  // =========================
  static const Color _navy = Color(0xFF1B3A5B); // bleu nuit
  static const Color _gold = Color(0xFFB8935A); // or / laiton
  static const Color _bg = Color(0xFFF5F1E8); // crème / ivoire
  static const Color _cardBg = Color(0xFFFDFBF6); // blanc cassé
  static const Color _imageBg = Color(0xFFECE6D8); // fond vignette
  static const Color _border = Color(0xFFE4DECF); // hairline
  static const Color _textSecondary = Color(0xFF8A8578);
  static const Color _textMuted = Color(0xFFB0AA9A);

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
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Notre menu'),
          backgroundColor: _bg,
          foregroundColor: _navy,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: StreamBuilder<List<MenuItemModel>>(
            stream: _menuItemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: [
                    _buildTopSearchZone(),
                    _buildCategoryPills(const ['Toutes']),
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
                    _buildCategoryPills(const ['Toutes']),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Erreur : ${snapshot.error}',
                          style: const TextStyle(color: _textSecondary),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final rawItems =
                  List<MenuItemModel>.from(
                    user.visibleMenuItems(snapshot.data ?? []),
                  )..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );

              final kitchenAccompaniments = rawItems
                  .where((it) => _isAccompaniment(it) && it.isForKitchen)
                  .toList();

              // Les sous-catégories (ex. « Cocktails alcoolisés », « Sans
              // alcool ») font aussi apparaître leur catégorie parente
              // (« Cocktails »), qui regroupe alors les deux.
              final availableCategories =
                  <String>{
                    'Toutes',
                    for (final item in rawItems) ...[
                      if (item.category.trim().isNotEmpty) item.category.trim(),
                      ?BarCategories.parentOf(item.category),
                    ],
                  }.toList()..sort((a, b) {
                    if (a == 'Toutes') return -1;
                    if (b == 'Toutes') return 1;
                    return _categorySortKey(a).compareTo(_categorySortKey(b));
                  });

              if (!availableCategories.contains(selectedCategory)) {
                selectedCategory = 'Toutes';
              }

              if (rawItems.isEmpty) {
                return Column(
                  children: [
                    _buildTopSearchZone(),
                    _buildCategoryPills(availableCategories),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Aucun article disponible.',
                          style: TextStyle(color: _textSecondary),
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
                        BarCategories.belongsTo(
                          item.category,
                          selectedCategory,
                        );
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
                  _buildCategoryPills(availableCategories),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView(
                          key: _menuListKey,
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          children: [
                            ...groupedItems.entries.map(
                              (entry) => _buildCategorySection(
                                entry.key,
                                entry.value,
                                kitchenAccompaniments,
                              ),
                            ),
                          ],
                        ),
                        if (_hasAnySelection)
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      color: _bg,
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchText = value),
        style: const TextStyle(color: _navy, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher un plat…',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          filled: true,
          fillColor: _cardBg,
          prefixIcon: const Icon(Icons.search, color: _textMuted, size: 19),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _navy, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Onglets de catégories en pills défilant horizontalement.
  Widget _buildCategoryPills(List<String> categories) {
    return Container(
      width: double.infinity,
      color: _bg,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((category) {
            final isActive = category == selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => selectedCategory = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? _navy : _cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? _navy : _border),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isActive ? _bg : _textSecondary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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

  Widget _buildCategorySection(
    String category,
    List<MenuItemModel> items,
    List<MenuItemModel> kitchenAccompaniments,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 2 cartes par ligne sur mobile ; davantage sur grand écran.
    final crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 1000
        ? 3
        : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          BarCategories.displayLabel(category).toUpperCase(),
          style: const TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.70,
          ),
          itemBuilder: (context, index) {
            return _buildItemCard(items[index], kitchenAccompaniments);
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

  Widget _buildItemCard(
    MenuItemModel item,
    List<MenuItemModel> kitchenAccompaniments,
  ) {
    final selected = _isSelected(item);
    final showQuantityBox = activeItemId == item.id;
    final composition = item.displayComposition;
    final hasComposition = composition.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _navy : _border,
          width: selected ? 2 : 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.allowsFreeAccompaniment) {
            _openAccompanimentSheet(item, kitchenAccompaniments);
          } else {
            _toggleItem(item);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grande photo en haut, avec pastille de sélection
            Stack(
              children: [
                Container(
                  height: 96,
                  width: double.infinity,
                  color: _imageBg,
                  child: _buildMenuImage(item, true),
                ),
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.check, size: 14, color: _bg),
                    ),
                  ),
              ],
            ),
            // Texte
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (hasComposition) ...[
                      const SizedBox(height: 2),
                      Text(
                        composition,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (item.allowsFreeAccompaniment) ...[
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.rice_bowl_outlined,
                            size: 11,
                            color: _gold,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Accompagnement offert',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    // Prix + bouton d'ajout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              item.price.toStringAsFixed(0),
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'FCFA',
                              style: TextStyle(
                                color: Color(0xFFC4A878),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selected ? _navy : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: selected ? _navy : const Color(0xFFC9C0AC),
                            ),
                          ),
                          child: Icon(
                            selected ? Icons.check : Icons.add,
                            size: 14,
                            color: selected ? _bg : _textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Boîte quantité (si carte active)
                    if (showQuantityBox) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (item.allowsFreeAccompaniment) {
                                  _removeLastAccompaniedUnit(item);
                                } else {
                                  _decreaseQuantity(item);
                                }
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: _cardBg,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(28, 28),
                              ),
                              icon: const Icon(
                                Icons.remove,
                                size: 15,
                                color: _navy,
                              ),
                            ),
                            Text(
                              '${_quantityOf(item)}',
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (item.allowsFreeAccompaniment) {
                                  _openAccompanimentSheet(
                                    item,
                                    kitchenAccompaniments,
                                  );
                                } else {
                                  _increaseQuantity(item);
                                }
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: _navy,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(28, 28),
                              ),
                              icon: const Icon(Icons.add, size: 15, color: _bg),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapButton({
    required String establishmentId,
    required List<MenuItemModel> allItems,
  }) {
    final totalSelected = _totalSelectedCount;
    final totalAmount = _totalAmount(allItems);
    return Material(
      color: _navy,
      borderRadius: BorderRadius.circular(14),
      elevation: 6,
      shadowColor: _navy.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final lines = _buildSelectedLines(allItems);
          final orderConfirmed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => _OrderRecapPage(
                establishmentId: establishmentId,
                lines: lines,
              ),
            ),
          );
          if (orderConfirmed == true && mounted) {
            setState(() {
              _clearAllSelection();
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: _bg, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Récapitulatif ($totalSelected)',
                    style: const TextStyle(
                      color: _bg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${totalAmount.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: Color(0xFFD9B87A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccompaniedUnit {
  final MenuItemModel dish;
  final String accompanimentName;
  _AccompaniedUnit({required this.dish, required this.accompanimentName});
}

/// Résultat du sélecteur d'accompagnement.
class _AccompanimentResult {
  final String freeAccompanimentName;
  final Map<String, int> paidExtras; // menuItemId accompagnement -> quantité
  _AccompanimentResult({
    required this.freeAccompanimentName,
    required this.paidExtras,
  });
}

/// Feuille modale de choix d'accompagnement.
class _AccompanimentSheet extends StatefulWidget {
  final MenuItemModel dish;
  final List<MenuItemModel> accompaniments;

  const _AccompanimentSheet({required this.dish, required this.accompaniments});

  @override
  State<_AccompanimentSheet> createState() => _AccompanimentSheetState();
}

class _AccompanimentSheetState extends State<_AccompanimentSheet> {
  String? _freeChoiceId;
  final Map<String, int> _paidExtras = {};

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: media.viewInsets.bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.dish.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Choisissez 1 accompagnement offert',
              style: TextStyle(color: Colors.brown.shade400, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Accompagnement offert (choix unique) ---
                    ...widget.accompaniments.map((acc) {
                      final isSelected = _freeChoiceId == acc.id;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFBF7B30)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        color: isSelected
                            ? const Color(0xFFFFF3E0)
                            : Colors.white,
                        child: ListTile(
                          onTap: () {
                            setState(() => _freeChoiceId = acc.id);
                          },
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? const Color(0xFFBF7B30)
                                : Colors.grey,
                          ),
                          title: Text(acc.name),
                          subtitle: const Text(
                            'Offert',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Portions supplémentaires (payantes)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- Portions payantes (+/- par accompagnement) ---
                    ...widget.accompaniments.map((acc) {
                      final qty = _paidExtras[acc.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(acc.name),
                                  Text(
                                    '${acc.price.toStringAsFixed(0)} FCFA / portion',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: qty > 0
                                  ? () => setState(() {
                                      _paidExtras[acc.id] = qty - 1;
                                    })
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() {
                                _paidExtras[acc.id] = qty + 1;
                              }),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3A5B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // L'accompagnement gratuit est optionnel : si rien n'est
                      // choisi, on valide quand même (accompagnement vide).
                      String freeName = '';
                      if (_freeChoiceId != null) {
                        freeName = widget.accompaniments
                            .firstWhere((a) => a.id == _freeChoiceId)
                            .name;
                      }
                      Navigator.pop(
                        context,
                        _AccompanimentResult(
                          freeAccompanimentName: freeName,
                          paidExtras: Map<String, int>.from(_paidExtras),
                        ),
                      );
                    },
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  String _selectedClientId = '';
  String _selectedClientName = '';

  String get establishmentId => widget.establishmentId.trim();

  @override
  void dispose() {
    tableController.dispose();
    roomController.dispose();
    super.dispose();
  }

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
        orderController.addMenuItem(
          line.item,
          accompanimentName: line.accompanimentName,
        );
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
                      final hasAcc = line.accompanimentName.trim().isNotEmpty;
                      return ListTile(
                        title: Text(
                          line.item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${line.item.category} • ${line.item.price.toStringAsFixed(0)} FCFA x ${line.quantity}',
                            ),
                            if (hasAcc)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.rice_bowl_outlined,
                                      size: 13,
                                      color: Color(0xFF8D6E63),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Accompagnement : ${line.accompanimentName} (offert)',
                                      style: TextStyle(
                                        color: Colors.brown.shade400,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
  final String accompanimentName;
  const _SelectedMenuLine({
    required this.item,
    required this.quantity,
    this.accompanimentName = '',
  });
  double get totalPrice => item.price * quantity;
}
