import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/l10n/app_localizations_fr.dart';
import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/stock_mode.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/order_service.dart';
import 'package:takapp/services/order_stock_policy.dart';

/// Service factice : enregistre ce qui est envoyé, rejoue une issue donnée.
class _FakeOrderService implements OrderService {
  OrderCreationResult result = const OrderCreationResult(
    orderId: 'o1',
    orderNumber: 'CMD-1',
    stockMode: StockMode.strict,
  );
  Object? error;
  final List<OrderActorContext> actors = [];
  final List<List<String>> itemNames = [];

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
    actors.add(actor);
    itemNames.add(items.map((i) => i.name).toList());
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _paul = UserModel.fromMap({
  'role': 'floor_manager',
  'establishmentId': 'est-a',
  'name': 'Paul',
}, 'paul');

final _jean = UserModel.fromMap({
  'role': 'serveur',
  'establishmentId': 'est-a',
  'name': 'Jean',
}, 'jean');

final _shift = ShiftModel(
  id: 'sh1',
  establishmentId: 'est-a',
  floorManagerId: 'paul',
  floorManagerName: 'Paul',
  startsAt: DateTime(2026, 9, 30, 18),
  endsAt: DateTime(2026, 9, 30, 23),
  status: ShiftStatus.open,
  serverIds: const ['jean'],
  createdAt: null,
  createdBy: 'gerante',
  updatedAt: null,
);

const _jeanInShift = ShiftParticipantModel(
  shiftId: 'sh1',
  establishmentId: 'est-a',
  serverId: 'jean',
  serverName: 'Jean',
  assignedAt: null,
  assignedBy: 'gerante',
  activeInShift: true,
);

final _direct = OrderActorContext.self(_paul, shiftId: 'sh1');
final _forJean = OrderActorContext.forShiftServer(
  floorManager: _paul,
  shift: _shift,
  server: _jeanInShift,
);

MenuItemModel _item(String id, String name) =>
    MenuItemModel.fromMap({'name': name, 'price': 1000}, id);

Future<bool> _submit(OrderController controller, OrderActorContext actor) {
  return controller.submitOrder(
    clientType: 'restaurant',
    tableNumber: '7',
    roomNumber: null,
    actor: actor,
    establishmentId: 'est-a',
  );
}

void main() {
  group('panier et contexte d’acteur', () {
    test('changer de contexte vide le panier (direct → Jean)', () {
      final controller = OrderController(_FakeOrderService())
        ..bindActor(_direct)
        ..addMenuItem(_item('m1', 'Riz'));
      expect(controller.items, hasLength(1));

      controller.bindActor(_forJean);
      expect(controller.items, isEmpty, reason: 'rien n’est transféré à Jean');
      expect(controller.cartActorKey, _forJean.cartKey);
    });

    test('même contexte : le panier est conservé', () {
      final controller = OrderController(_FakeOrderService())
        ..bindActor(OrderActorContext.self(_jean))
        ..addMenuItem(_item('m1', 'Riz'))
        ..bindActor(OrderActorContext.self(_jean));
      expect(controller.items, hasLength(1));
    });

    test(
      'un panier rempli pour un contexte ne part jamais sous un autre',
      () async {
        final service = _FakeOrderService();
        final controller = OrderController(service)
          ..bindActor(_direct)
          ..addMenuItem(_item('m1', 'Riz'));

        final ok = await _submit(controller, _forJean);

        expect(ok, isFalse);
        expect(service.actors, isEmpty, reason: 'rien n’est envoyé');
        expect(controller.items, isEmpty);
        expect(controller.errorText(AppLocalizationsFr()), contains('panier'));
      },
    );

    test(
      'commande directe puis commande pour Jean : paniers distincts',
      () async {
        final service = _FakeOrderService();
        final controller = OrderController(service);

        controller
          ..bindActor(_direct)
          ..addMenuItem(_item('m1', 'Riz'));
        expect(await _submit(controller, _direct), isTrue);

        controller
          ..bindActor(_forJean)
          ..addMenuItem(_item('m2', 'Bière'));
        expect(await _submit(controller, _forJean), isTrue);

        expect(service.itemNames, [
          ['Riz'],
          ['Bière'],
        ]);
        expect(service.actors[0].assignedServerId, 'paul');
        expect(service.actors[1].assignedServerId, 'jean');
        expect(service.actors[1].performedByUserId, 'paul');
        expect(service.actors[1].shiftId, 'sh1');
      },
    );

    test('serveur classique : aucun changement de comportement', () async {
      final service = _FakeOrderService();
      final controller = OrderController(service)
        ..addMenuItem(_item('m1', 'Riz'));

      expect(await _submit(controller, OrderActorContext.self(_jean)), isTrue);
      expect(service.actors.single.performedByUserId, 'jean');
      expect(service.actors.single.assignedServerId, 'jean');
      expect(service.actors.single.shiftId, isNull);
    });
  });

  group('stockMode : même traitement pour le Floor Manager', () {
    test('disabled : acceptée, sans avertissement', () async {
      final service = _FakeOrderService()
        ..result = const OrderCreationResult(
          orderId: 'o1',
          orderNumber: 'CMD-1',
          stockMode: StockMode.disabled,
        );
      final controller = OrderController(service)
        ..bindActor(_forJean)
        ..addMenuItem(_item('m1', 'Riz'));

      expect(await _submit(controller, _forJean), isTrue);
      expect(controller.hasStockWarnings, isFalse);
    });

    test('warningOnly : acceptée avec avertissement visible', () async {
      final service = _FakeOrderService()
        ..result = const OrderCreationResult(
          orderId: 'o1',
          orderNumber: 'CMD-1',
          stockMode: StockMode.warningOnly,
          stockWarnings: [
            StockAnomaly(
              type: StockAnomalyType.insufficientStock,
              itemName: 'Riz',
              unit: 'kg',
              stockUnit: 'kg',
              required: 0.4,
              available: 0.1,
            ),
          ],
        );
      final controller = OrderController(service)
        ..bindActor(_direct)
        ..addMenuItem(_item('m1', 'Riz'));

      expect(await _submit(controller, _direct), isTrue);
      expect(controller.hasStockWarnings, isTrue);
      expect(
        controller.submittedMessage(AppLocalizationsFr()),
        contains('Riz'),
      );
    });

    test('strict : refusée, le panier est conservé', () async {
      final service = _FakeOrderService()
        ..error = const AppError(
          AppErrorCode.insufficientStockDetailed,
          name: 'Riz',
          params: {'available': '0.1 kg', 'required': '0.4 kg'},
        );
      final controller = OrderController(service)
        ..bindActor(_forJean)
        ..addMenuItem(_item('m1', 'Riz'));

      expect(await _submit(controller, _forJean), isFalse);
      expect(controller.items, hasLength(1));
      expect(controller.errorText(AppLocalizationsFr()), contains('Riz'));
    });
  });
}
