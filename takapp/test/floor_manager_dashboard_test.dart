import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/floor_manager_shift_controller.dart';
import 'package:takapp/core/l10n/locale_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_service.dart';
import 'package:takapp/vues/floor_manager/floor_manager_home_page.dart';
import 'package:takapp/vues/floor_manager/floor_manager_servers_page.dart';

/// Service factice : le test pousse lui-même les états du service courant.
class _FakeShiftService implements ShiftService {
  final StreamController<FloorManagerShiftState> states =
      StreamController<FloorManagerShiftState>.broadcast();
  int watchCalls = 0;

  @override
  Stream<FloorManagerShiftState> watchFloorManagerShift({
    required String establishmentId,
    required UserModel currentUser,
  }) {
    watchCalls++;
    return states.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends ChangeNotifier implements AuthController {
  _FakeAuthController(this.currentUser);

  @override
  final UserModel? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserModel _user(String role, {bool isActive = true}) {
  return UserModel.fromMap({
    'role': role,
    'establishmentId': 'est-a',
    'establishmentName': 'Hôtel A',
    'name': 'Paul',
    'isActive': isActive,
  }, 'fm-a');
}

final _paul = _user('floor_manager');

ShiftModel _openShift(List<String> serverIds) {
  return ShiftModel(
    id: 'shift-1',
    establishmentId: 'est-a',
    floorManagerId: 'fm-a',
    floorManagerName: 'Paul',
    startsAt: DateTime(2026, 9, 30, 18),
    endsAt: DateTime(2026, 10, 1, 0),
    status: ShiftStatus.open,
    serverIds: serverIds,
    createdAt: null,
    createdBy: 'gerante',
    updatedAt: null,
  );
}

ShiftParticipantModel _server(String id, String name) {
  return ShiftParticipantModel(
    shiftId: 'shift-1',
    establishmentId: 'est-a',
    serverId: id,
    serverName: name,
    assignedAt: null,
    assignedBy: 'gerante',
    activeInShift: true,
  );
}

FloorManagerShiftState _stateWith(List<ShiftParticipantModel> servers) {
  return FloorManagerShiftState(
    openShift: _openShift(servers.map((s) => s.serverId).toList()),
    activeServers: servers,
  );
}

final _twoServers = _stateWith([
  _server('s1', 'Awa Diallo'),
  _server('s2', 'Koffi'),
]);

Future<_FakeShiftService> _pumpDashboard(
  WidgetTester tester, {
  FloorManagerShiftState? initial,
  UserModel? user,
}) async {
  final service = _FakeShiftService();
  final controller = FloorManagerShiftController(service)
    ..setCurrentUser(user ?? _paul);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(
          value: _FakeAuthController(user ?? _paul),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
        ),
        ChangeNotifierProvider<FloorManagerShiftController>.value(
          value: controller,
        ),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: LocaleController.supportedLocales,
        home: FloorManagerHomePage(),
      ),
    ),
  );

  if (initial != null) {
    service.states.add(initial);
    await tester.pumpAndSettle();
  }
  return service;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with an open shift: identity, shift and enabled sections', (
    tester,
  ) async {
    await _pumpDashboard(tester, initial: _twoServers);

    expect(find.text('Paul'), findsOneWidget);
    expect(find.text('Hôtel A'), findsOneWidget);
    expect(find.text('Service en cours'), findsOneWidget);
    expect(find.text('18:00 - 00:00'), findsOneWidget);
    expect(find.text('Serveurs actifs : 2'), findsOneWidget);
    expect(find.text('COMMANDES'), findsOneWidget);
    expect(find.text('ENCAISSEMENTS'), findsOneWidget);
    expect(find.text('Aucun service en cours'), findsNothing);
  });

  testWidgets('without shift: explicit empty state and disabled sections', (
    tester,
  ) async {
    await _pumpDashboard(tester, initial: FloorManagerShiftState.none);

    expect(find.text('Aucun service en cours'), findsOneWidget);
    expect(
      find.text("Vous n'êtes actuellement affecté à aucun service ouvert."),
      findsOneWidget,
    );

    await _tap(tester, find.byKey(const ValueKey('fm-section-orders')));
    expect(find.text('Commande directe'), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('fm-section-payments')));
    expect(find.text('Encaissement direct'), findsNothing);
  });

  testWidgets('shows a spinner until the first shift state arrives', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Aucun service en cours'), findsNothing);
  });

  testWidgets('Commandes: direct order prepared, Serveurs lists the shift', (
    tester,
  ) async {
    await _pumpDashboard(tester, initial: _twoServers);

    await _tap(tester, find.byKey(const ValueKey('fm-section-orders')));
    expect(find.text('COMMANDE DIRECTE'), findsOneWidget);
    expect(find.text('Bientôt disponible'), findsOneWidget);

    // Commande directe : préparée, pas encore active.
    await _tap(tester, find.byKey(const ValueKey('fm-direct-orders')));
    expect(find.byType(ActiveServerCard), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('fm-servers-orders')));
    expect(find.byType(ActiveServerCard), findsNWidgets(2));
    expect(find.text('Awa Diallo'), findsOneWidget);
    expect(find.text('Koffi'), findsOneWidget);
    expect(find.text('En service'), findsNWidgets(2));
    expect(find.text('AD'), findsOneWidget, reason: 'initials avatar');
  });

  testWidgets('Encaissements: same servers list component', (tester) async {
    await _pumpDashboard(tester, initial: _twoServers);

    await _tap(tester, find.byKey(const ValueKey('fm-section-payments')));
    expect(find.text('ENCAISSEMENT DIRECT'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('fm-servers-payments')));
    expect(find.byType(FloorManagerServersPage), findsOneWidget);
    expect(find.byType(ActiveServerCard), findsNWidgets(2));
  });

  testWidgets('tapping a server triggers no business action yet', (
    tester,
  ) async {
    await _pumpDashboard(tester, initial: _twoServers);
    await _tap(tester, find.byKey(const ValueKey('fm-section-orders')));
    await _tap(tester, find.byKey(const ValueKey('fm-servers-orders')));

    await tester.tap(find.byKey(const ValueKey('fm-server-s1')));
    await tester.pump();
    expect(find.text('Bientôt disponible'), findsWidgets);
    expect(find.byType(FloorManagerServersPage), findsOneWidget);
  });

  testWidgets('open shift without active server: explicit message', (
    tester,
  ) async {
    await _pumpDashboard(tester, initial: _stateWith(const []));
    expect(find.text('Serveurs actifs : 0'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('fm-section-orders')));
    await _tap(tester, find.byKey(const ValueKey('fm-servers-orders')));
    expect(find.text('Aucun serveur actif dans ce service.'), findsOneWidget);
  });

  testWidgets('real time: removal, deactivation and closing are reflected', (
    tester,
  ) async {
    final service = await _pumpDashboard(tester, initial: _twoServers);
    await _tap(tester, find.byKey(const ValueKey('fm-section-orders')));
    await _tap(tester, find.byKey(const ValueKey('fm-servers-orders')));
    expect(find.byType(ActiveServerCard), findsNWidgets(2));

    // Serveur retiré ou désactivé : le flux ne le renvoie plus.
    service.states.add(_stateWith([_server('s1', 'Awa Diallo')]));
    await tester.pumpAndSettle();
    expect(find.byType(ActiveServerCard), findsOneWidget);
    expect(find.text('Koffi'), findsNothing);

    // Service clôturé pendant que la page est ouverte.
    service.states.add(FloorManagerShiftState.none);
    await tester.pumpAndSettle();
    expect(find.byType(ActiveServerCard), findsNothing);
    expect(find.text('Aucun service en cours'), findsOneWidget);
  });

  testWidgets('dashboard reacts to a shift being opened', (tester) async {
    final service = await _pumpDashboard(
      tester,
      initial: FloorManagerShiftState.none,
    );
    expect(find.text('Aucun service en cours'), findsOneWidget);

    service.states.add(_twoServers);
    await tester.pumpAndSettle();
    expect(find.text('Service en cours'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('fm-section-orders')));
    expect(find.text('COMMANDE DIRECTE'), findsOneWidget);
  });

  group('FloorManagerShiftController', () {
    test('only an active floor_manager subscribes to the shift', () {
      for (final user in [
        _user('serveur'),
        _user('gerante'),
        _user('floor_manager', isActive: false),
      ]) {
        final service = _FakeShiftService();
        final controller = FloorManagerShiftController(service)
          ..setCurrentUser(user);

        expect(service.watchCalls, 0, reason: user.role);
        expect(controller.state.hasOpenShift, isFalse);
        expect(controller.isLoading, isFalse);
        controller.dispose();
      }

      final service = _FakeShiftService();
      final controller = FloorManagerShiftController(service)
        ..setCurrentUser(_paul);
      expect(service.watchCalls, 1);
      expect(controller.isLoading, isTrue);

      // Déconnexion : l'état est vidé.
      controller.setCurrentUser(null);
      expect(controller.state.hasOpenShift, isFalse);
      controller.dispose();
    });

    test('a stream error never leaves stale servers', () async {
      final service = _FakeShiftService();
      final controller = FloorManagerShiftController(service)
        ..setCurrentUser(_paul);

      service.states.add(_twoServers);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.activeServers, hasLength(2));

      service.states.addError(StateError('permission-denied'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.activeServers, isEmpty);
      expect(controller.hasError, isTrue);
      controller.dispose();
    });
  });
}
