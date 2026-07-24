import 'package:flutter/material.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/services/order_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService;

  OrderController(this._orderService);

  final List<OrderItemModel> _items = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  List<OrderItemModel> get items => List.unmodifiable(_items);
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get tax => 0;

  double get total => subtotal + tax;

  void addMenuItem(MenuItemModel menuItem) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItem.id);

    final targetDepartment = menuItem.isForKitchen ? 'kitchen' : 'bar';

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
          menuItemId: menuItem.id,
          name: menuItem.name,
          quantity: 1,
          unitPrice: menuItem.price,
          totalPrice: menuItem.price,
          note: '',
          targetDepartment: targetDepartment,
        ),
      );
    }

    notifyListeners();
  }

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

  void clearOrder() {
    _items.clear();
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submitOrder({
    required String clientType,
    required String? tableNumber,
    required String? roomNumber,
    required String createdBy,
    required String createdByName,
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

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.createOrder(
        clientType: clientType,
        tableNumber: tableNumber?.trim(),
        roomNumber: roomNumber?.trim(),
        createdBy: createdBy,
        createdByName: createdByName,
        subtotal: subtotal,
        tax: tax,
        total: total,
        items: _items,
      );

      _items.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
