import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/core/l10n/locale_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/order_ticket_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/payment_service.dart';
import 'package:takapp/vues/commun/unpaid_tickets_page.dart';

/// Service factice : additions non encaissées fournies par le test,
/// encaissements enregistrés.
class _FakePaymentService implements PaymentService {
  final List<OrderModel> unpaid;
  final List<Map<String, dynamic>> payments = [];

  _FakePaymentService(this.unpaid);

  @override
  Stream<List<OrderModel>> streamUnpaidOrdersForEstablishment({
    required String establishmentId,
  }) => Stream.value(unpaid);

  @override
  Future<void> registerTicketPayment({
    required String establishmentId,
    required String ticketId,
    required List<String> orderIds,
    required OrderActorContext actor,
    required String method,
    required double amount,
  }) async {
    payments.add({
      'ticketId': ticketId,
      'orderIds': orderIds,
      'method': method,
      'amount': amount,
      ...PaymentService.paymentActorFields(
        actor: actor,
        primaryOrder: unpaid.firstWhere((o) => o.id == orderIds.first),
      ),
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _paul = UserModel.fromMap({
  'role': 'floor_manager',
  'establishmentId': 'est-a',
  'name': 'Paul',
}, 'paul');

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

const _jean = ShiftParticipantModel(
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
  server: _jean,
);

OrderModel _order(String id, String table, String owner, double total) {
  return OrderModel.fromMap({
    'establishmentId': 'est-a',
    'orderNumber': 'CMD-$id',
    'ticketId': 'TCK-$table',
    'clientType': 'restaurant',
    'tableNumber': table,
    'createdBy': owner,
    'createdByName': owner,
    'assignedServerId': owner,
    'assignedServerName': owner,
    'paymentStatus': 'unpaid',
    'status': 'ready',
    'total': total,
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30, 19)),
  }, id);
}

// Table 7 : Paul (direct). Table 8 : Jean. Table 9 : Koffi (hors service).
final _orders = [
  _order('o7', '7', 'paul', 5000),
  _order('o8', '8', 'jean', 3000),
  _order('o9', '9', 'koffi', 1000),
];

Future<_FakePaymentService> _pump(
  WidgetTester tester, {
  OrderActorContext? actor,
  String? serveurId,
  List<String>? addedFor,
}) async {
  final service = _FakePaymentService(_orders);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<PaymentService>.value(value: service),
        ChangeNotifierProvider<PaymentController>(
          create: (_) => PaymentController(service),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: LocaleController.supportedLocales,
        home: UnpaidTicketsPage(
          establishmentId: 'est-a',
          actor: actor,
          serveurId: serveurId,
          addOrderPageBuilder: (a, ticket) {
            addedFor?.add(
              '${a.performedByUserId}>${a.assignedServerId}@${ticket.primaryOrder.tableNumber}',
            );
            return const Scaffold(body: Text('ADD-ORDER'));
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('OrderTicket regroupe bien les commandes du test par table', () {
    expect(OrderTicket.group(_orders), hasLength(3));
  });

  group('listes d’additions', () {
    testWidgets('direct : uniquement les additions du Floor Manager', (
      tester,
    ) async {
      await _pump(tester, actor: _direct);
      expect(find.text('Mes additions'), findsOneWidget);
      expect(find.textContaining('7'), findsWidgets);
      expect(find.textContaining('Table 8'), findsNothing);
      expect(find.textContaining('Table 9'), findsNothing);
    });

    testWidgets('Jean : uniquement les additions de Jean', (tester) async {
      await _pump(tester, actor: _forJean);
      expect(find.text('Additions de Jean'), findsOneWidget);
      expect(find.textContaining('Table 8'), findsOneWidget);
      expect(find.textContaining('Table 7'), findsNothing);
      expect(find.textContaining('Table 9'), findsNothing);
    });
  });

  group('encaissement', () {
    testWidgets('vente de Jean : responsable = Jean, encaisseur = Paul', (
      tester,
    ) async {
      final service = await _pump(tester, actor: _forJean);

      await _tap(tester, find.textContaining('Table 8'));
      expect(find.text('Ajouter une commande'), findsOneWidget);
      expect(find.text('Encaisser'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('ticket-collect')));
      expect(find.text('Vente de Jean · encaissée par Paul'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('payment-confirm')));

      final payment = service.payments.single;
      expect(payment['responsibleServerId'], 'jean');
      expect(payment['responsibleServerName'], 'Jean');
      expect(payment['receivedBy'], 'paul');
      expect(payment['receivedByName'], 'Paul');
      expect(payment['shiftId'], 'sh1');
      expect(payment['amount'], 3000);
      expect(payment['orderIds'], ['o8']);
    });

    testWidgets('direct : responsable = encaisseur = Floor Manager', (
      tester,
    ) async {
      final service = await _pump(tester, actor: _direct);

      await _tap(tester, find.textContaining('Table 7'));
      await _tap(tester, find.byKey(const ValueKey('ticket-collect')));
      await _tap(tester, find.byKey(const ValueKey('payment-confirm')));

      final payment = service.payments.single;
      expect(payment['responsibleServerId'], 'paul');
      expect(payment['receivedBy'], 'paul');
      expect(payment['amount'], 5000);
    });

    testWidgets(
      'ajouter une commande sur la table de Jean : Jean reste responsable',
      (tester) async {
        final added = <String>[];
        await _pump(tester, actor: _forJean, addedFor: added);

        await _tap(tester, find.textContaining('Table 8'));
        await _tap(tester, find.byKey(const ValueKey('ticket-add-order')));

        expect(find.text('ADD-ORDER'), findsOneWidget);
        expect(added, ['paul>jean@8']);
      },
    );
  });

  group('non-régression serveur', () {
    testWidgets(
      'serveur classique : ses additions et les actions habituelles',
      (tester) async {
        await _pump(tester, serveurId: 'jean');
        expect(find.textContaining('Table 8'), findsOneWidget);
        expect(find.textContaining('Table 7'), findsNothing);

        await _tap(tester, find.textContaining('Table 8'));
        // Parcours historique : détail / impression et ajout.
        expect(find.byKey(const ValueKey('ticket-collect')), findsNothing);
        expect(find.byKey(const ValueKey('ticket-add-order')), findsNothing);
      },
    );

    test('champs d’un encaissement classique : responsable = commande', () {
      final jeanUser = UserModel.fromMap({
        'role': 'serveur',
        'establishmentId': 'est-a',
        'name': 'Jean',
      }, 'jean');
      final fields = PaymentService.paymentActorFields(
        actor: OrderActorContext.self(jeanUser),
        primaryOrder: _orders[1],
      );
      expect(fields['receivedBy'], 'jean');
      expect(fields['responsibleServerId'], 'jean');
      expect(fields['shiftId'], isNull);

      // 11B : Jean présent dans un service ouvert -> l'encaissement porte
      // ce service (remis ensuite au Floor Manager du service).
      final inShift = PaymentService.paymentActorFields(
        actor: OrderActorContext.self(jeanUser),
        primaryOrder: _orders[1],
        cashierShiftId: 'sh1',
      );
      expect(inShift['receivedBy'], 'jean');
      expect(inShift['shiftId'], 'sh1');

      // Gérante qui encaisse la table de Jean : vente attribuée à Jean.
      final gerante = UserModel.fromMap({
        'role': 'gerante',
        'establishmentId': 'est-a',
        'name': 'Awa',
      }, 'awa');
      final byManager = PaymentService.paymentActorFields(
        actor: OrderActorContext.self(gerante),
        primaryOrder: _orders[1],
      );
      expect(byManager['receivedBy'], 'awa');
      expect(byManager['responsibleServerId'], 'jean');
    });
  });
}
