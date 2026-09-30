import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/l10n/app_localizations_fr.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/modeles/stock_mode.dart';
import 'package:takapp/services/order_service.dart';
import 'package:takapp/services/order_stock_policy.dart';

/// Service factice : rejoue une issue prédéfinie de `createOrder`.
class _FakeOrderService implements OrderService {
  OrderCreationResult? result;
  Object? error;
  int createCalls = 0;
  OrderActorContext? lastActor;

  @override
  Future<OrderCreationResult> createOrder({
    required String establishmentId,
    required String clientType,
    required String? tableNumber,
    required String? roomNumber,
    String clientId = '',
    required OrderActorContext actor,
    required double subtotal,
    required double tax,
    required double total,
    required List<OrderItemModel> items,
  }) async {
    createCalls++;
    lastActor = actor;
    final failure = error;
    if (failure != null) throw failure;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _menuItem = MenuItemModel.fromMap({
  'name': 'Riz sauté',
  'price': 2500,
  'category': 'plat',
}, 'menu-rice');

final _serveur = UserModel.fromMap({
  'role': 'serveur',
  'establishmentId': 'est-1',
  'name': 'Serveur',
}, 'uid-1');

Future<bool> _submit(OrderController controller) {
  return controller.submitOrder(
    clientType: 'bar',
    tableNumber: null,
    roomNumber: null,
    actor: OrderActorContext.self(_serveur),
    establishmentId: 'est-1',
  );
}

void main() {
  final l10n = AppLocalizationsFr();

  test('accepted order clears the cart and confirms plainly', () async {
    final service = _FakeOrderService()
      ..result = const OrderCreationResult(
        orderId: 'o1',
        orderNumber: 'CMD-1',
        stockMode: StockMode.strict,
      );
    final controller = OrderController(service)..addMenuItem(_menuItem);

    expect(await _submit(controller), isTrue);
    expect(controller.items, isEmpty);
    expect(controller.hasStockWarnings, isFalse);
    expect(controller.submittedMessage(l10n), l10n.orderSentSuccess);

    // L'acteur est transmis tel quel au service (commande classique).
    expect(service.lastActor?.performedByUserId, 'uid-1');
    expect(service.lastActor?.assignedServerId, 'uid-1');
    expect(service.lastActor?.shiftId, isNull);
  });

  test('refused order (strict) keeps the cart and exposes the error', () async {
    final service = _FakeOrderService()
      ..error = const AppError(
        AppErrorCode.insufficientStockDetailed,
        name: 'Riz',
        params: {'available': '0.1 kg', 'required': '0.4 kg'},
      );
    final controller = OrderController(service)..addMenuItem(_menuItem);

    expect(await _submit(controller), isFalse);
    expect(controller.items, hasLength(1));
    expect(controller.hasError, isTrue);
    expect(controller.errorText(l10n), contains('Riz'));
    expect(controller.hasStockWarnings, isFalse);
  });

  test('warningOnly anomalies are surfaced, never hidden', () async {
    final service = _FakeOrderService()
      ..result = const OrderCreationResult(
        orderId: 'o1',
        orderNumber: 'CMD-1',
        stockMode: StockMode.warningOnly,
        stockWarnings: [
          StockAnomaly(
            type: StockAnomalyType.insufficientStock,
            itemName: 'Riz',
            store: 'restaurant',
            unit: 'kg',
            stockUnit: 'kg',
            required: 0.4,
            available: 0.1,
          ),
        ],
      );
    final controller = OrderController(service)..addMenuItem(_menuItem);

    expect(await _submit(controller), isTrue);
    expect(controller.items, isEmpty);
    expect(controller.hasStockWarnings, isTrue);

    final message = controller.submittedMessage(l10n);
    expect(message, isNot(l10n.orderSentSuccess));
    expect(message, contains('Riz'));
    expect(message, contains('0.4 kg'));
  });

  test('warnings from a previous order do not leak into the next', () async {
    final service = _FakeOrderService()
      ..result = const OrderCreationResult(
        orderId: 'o1',
        orderNumber: 'CMD-1',
        stockMode: StockMode.warningOnly,
        stockWarnings: [
          StockAnomaly(type: StockAnomalyType.missingRecipe, itemName: 'Riz'),
        ],
      );
    final controller = OrderController(service)..addMenuItem(_menuItem);
    await _submit(controller);
    expect(controller.hasStockWarnings, isTrue);

    service.result = const OrderCreationResult(
      orderId: 'o2',
      orderNumber: 'CMD-2',
      stockMode: StockMode.warningOnly,
    );
    controller.addMenuItem(_menuItem);
    await _submit(controller);

    expect(controller.hasStockWarnings, isFalse);
    expect(service.createCalls, 2);
  });
}
