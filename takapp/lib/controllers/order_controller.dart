import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/services/order_service.dart';
import 'package:uuid/uuid.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService;

  OrderController(this._orderService);

  final List<OrderItemModel> _items = [];

  bool _isSubmitting = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  List<OrderItemModel> get items => List.unmodifiable(_items);
  bool get isSubmitting => _isSubmitting;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  // =========================
  // CALCULS
  // =========================

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get tax => 0;

  double get total => subtotal + tax;

  // =========================
  // AJOUT ITEM
  // =========================

  void addMenuItem(MenuItemModel menuItem, {String accompanimentName = ''}) {
    final targetDepartment = menuItem.isForKitchen ? 'kitchen' : 'bar';
    const Uuid uuid = Uuid();

    // Plat avec accompagnement : chaque unité est une ligne individuelle
    // (jamais de regroupement), car chaque unité a son propre accompagnement.
    if (menuItem.allowsFreeAccompaniment) {
      _items.add(
        OrderItemModel(
          id: uuid.v4(),
          establishmentId: '',
          menuItemId: menuItem.id,
          name: menuItem.name,
          quantity: 1,
          unitPrice: menuItem.price,
          totalPrice: menuItem.price,
          note: '',
          targetDepartment: targetDepartment,
          accompanimentName: accompanimentName,
          isCancelled: false,
          cancelledAt: null,
          cancelledBy: '',
          cancelledByName: '',
          cancellationReason: '',
        ),
      );
      notifyListeners();
      return;
    }

    // Article normal (sans accompagnement) : comportement inchangé,
    // regroupement par menuItemId.
    final index = _items.indexWhere(
      (e) => e.menuItemId == menuItem.id && e.accompanimentName.isEmpty,
    );
    if (index >= 0) {
      final existing = _items[index];
      final newQuantity = existing.quantity + 1;
      _items[index] = existing.copyWith(
        quantity: newQuantity,
        totalPrice: newQuantity * existing.unitPrice,
      );
    } else {
      _items.add(
        OrderItemModel(
          id: uuid.v4(),
          establishmentId: '',
          menuItemId: menuItem.id,
          name: menuItem.name,
          quantity: 1,
          unitPrice: menuItem.price,
          totalPrice: menuItem.price,
          note: '',
          targetDepartment: targetDepartment,
          isCancelled: false,
          cancelledAt: null,
          cancelledBy: '',
          cancelledByName: '',
          cancellationReason: '',
        ),
      );
    }
    notifyListeners();
  }

  // =========================
  // INCREMENT
  // =========================

  void incrementItem(String menuItemId) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index == -1) return;

    final item = _items[index];
    final newQuantity = item.quantity + 1;

    _items[index] = item.copyWith(
      quantity: newQuantity,
      totalPrice: newQuantity * item.unitPrice,
    );

    notifyListeners();
  }

  // =========================
  // DECREMENT
  // =========================

  void decrementItem(String menuItemId) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index == -1) return;

    final item = _items[index];

    if (item.quantity <= 1) {
      _items.removeAt(index);
    } else {
      final newQuantity = item.quantity - 1;

      _items[index] = item.copyWith(
        quantity: newQuantity,
        totalPrice: newQuantity * item.unitPrice,
      );
    }

    notifyListeners();
  }

  // =========================
  // RESET
  // =========================

  void clearOrder() {
    _items.clear();
    _error = null;
    notifyListeners();
  }

  // =========================
  // INCREMENT / DECREMENT PAR LIGNE (lignes individuelles avec accompagnement)
  // =========================
  void removeLineById(String lineId) {
    _items.removeWhere((e) => e.id == lineId);
    notifyListeners();
  }

  /// Ajoute une nouvelle ligne pour le même plat avec un accompagnement donné.
  /// Utilisé pour "ajouter une autre unité" d'un plat à accompagnement.
  void addAccompaniedLine(MenuItemModel menuItem, String accompanimentName) {
    addMenuItem(menuItem, accompanimentName: accompanimentName);
  }

  /// Nombre total d'unités d'un plat (toutes lignes confondues).
  int quantityOfMenuItem(String menuItemId) {
    return _items
        .where((e) => e.menuItemId == menuItemId)
        .fold(0, (sum, e) => sum + e.quantity);
  }

  /// Les lignes individuelles d'un plat donné (pour les plats à accompagnement).
  List<OrderItemModel> linesOfMenuItem(String menuItemId) {
    return _items.where((e) => e.menuItemId == menuItemId).toList();
  }

  // =========================
  // SUBMIT
  // =========================

  Future<bool> submitOrder({
    required String clientType,
    required String? tableNumber,
    required String? roomNumber,
    required String createdBy,
    required String createdByName,
    required String establishmentId,

    /// Fiche client rattachée. Optionnel : chaîne vide = non rattachée.
    String clientId = '',
  }) async {
    if (_items.isEmpty) {
      _error = const AppError(AppErrorCode.addAtLeastOneItem);
      notifyListeners();
      return false;
    }

    if (clientType == 'restaurant' &&
        (tableNumber == null || tableNumber.trim().isEmpty)) {
      _error = const AppError(AppErrorCode.tableNumberRequired);
      notifyListeners();
      return false;
    }

    if (clientType == 'hotel' &&
        (roomNumber == null || roomNumber.trim().isEmpty)) {
      _error = const AppError(AppErrorCode.roomNumberRequired);
      notifyListeners();
      return false;
    }

    // Garde-fou : refuser si l'établissement n'est pas résolu
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFoundReconnect);
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      // On tamponne chaque item avec le vrai établissement au moment de l'envoi
      final itemsToSend = _items
          .map((item) => item.copyWith(establishmentId: establishmentId))
          .toList();

      await _orderService.createOrder(
        establishmentId: establishmentId,

        clientType: clientType,
        tableNumber: tableNumber?.trim(),
        roomNumber: roomNumber?.trim(),
        clientId: clientId.trim(),
        createdBy: createdBy,
        createdByName: createdByName,
        subtotal: subtotal,
        tax: tax,
        total: total,
        items: itemsToSend,
      );

      _items.clear();

      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
