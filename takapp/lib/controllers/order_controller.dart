import 'package:flutter/material.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/services/order_service.dart';
import 'package:uuid/uuid.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService;

  OrderController(this._orderService);

  final List<OrderItemModel> _items = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  List<OrderItemModel> get items => List.unmodifiable(_items);
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // =========================
  // CALCULS
  // =========================

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get tax => 0;

  double get total => subtotal + tax;

  // =========================
  // AJOUT ITEM
  // =========================

  void addMenuItem(MenuItemModel menuItem) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItem.id);

    final targetDepartment = menuItem.isForKitchen ? 'kitchen' : 'bar';
    const Uuid uuid = Uuid();

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

          /// establishmentId renseigné au submitOrder (le panier est un brouillon local)
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
    _errorMessage = null;
    notifyListeners();
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
      _errorMessage = 'Ajoutez au moins un article.';
      notifyListeners();
      return false;
    }

    if (clientType == 'restaurant' &&
        (tableNumber == null || tableNumber.trim().isEmpty)) {
      _errorMessage = 'Veuillez préciser le numéro de table.';
      notifyListeners();
      return false;
    }

    if (clientType == 'hotel' &&
        (roomNumber == null || roomNumber.trim().isEmpty)) {
      _errorMessage = 'Veuillez préciser le numéro de chambre.';
      notifyListeners();
      return false;
    }

    // Garde-fou : refuser si l'établissement n'est pas résolu
    if (establishmentId.trim().isEmpty) {
      _errorMessage = 'Établissement introuvable. Reconnectez-vous.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
