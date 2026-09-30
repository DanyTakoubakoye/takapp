import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/l10n/app_localizations_en.dart';
import 'package:takapp/l10n/app_localizations_fr.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/vues/commun/home_router.dart';
import 'package:takapp/vues/commun/unauthorized_page.dart';
import 'package:takapp/vues/floor_manager/floor_manager_home_page.dart';
import 'package:takapp/vues/gerante/gerante_dashboard_page.dart';
import 'package:takapp/vues/serveur/serveur_home_page.dart';

/// Contrôleur factice : HomeRouter ne lit que `isInitialized` et
/// `currentUser`. Aucun accès Firebase.
class _FakeAuthController extends ChangeNotifier implements AuthController {
  _FakeAuthController(this.currentUser);

  @override
  final UserModel? currentUser;

  @override
  bool get isInitialized => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserModel _user(
  String role, {
  String establishmentId = 'est-a',
  Map<String, dynamic>? modules,
}) {
  return UserModel.fromMap({
    'role': role,
    'establishmentId': establishmentId,
    'name': 'Test',
    'email': 'test@example.com',
    'isActive': true,
    'modules': ?modules,
  }, 'uid-1');
}

/// Widget choisi par HomeRouter, SANS l'afficher : les pages métier des
/// autres rôles dépendent de Firebase, seule la décision de routage est
/// vérifiée ici.
Future<Widget> _routeFor(WidgetTester tester, UserModel user) async {
  late Widget routed;
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthController>.value(
      value: _FakeAuthController(user),
      child: Builder(
        builder: (context) {
          routed = const HomeRouter().build(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return routed;
}

void main() {
  group('AppRoles', () {
    test('floor_manager is the single canonical value', () {
      expect(AppRoles.floorManager, 'floor_manager');
      expect(AppRoles.exists('floor_manager'), isTrue);
      expect(AppRoles.all, contains('floor_manager'));
      expect(AppRoles.normalizeRole(' FLOOR_MANAGER '), 'floor_manager');
    });

    test('label is localized, the stored value is not', () {
      expect(
        AppRoles.label(AppLocalizationsFr(), 'floor_manager'),
        'Floor Manager',
      );
      expect(
        AppRoles.label(AppLocalizationsEn(), 'floor_manager'),
        'Floor Manager',
      );
      expect(AppRoles.getLabel('floor_manager'), 'Floor Manager');
    });

    test('least privilege: no module, no admin or stock helper', () {
      expect(AppRoles.getModules('floor_manager'), isEmpty);
      for (final module in [
        'restaurant',
        'bar',
        'hotel',
        'stock',
        'fiscalization',
        'analytics',
        'settings',
      ]) {
        expect(
          AppRoles.canAccessModule(role: 'floor_manager', module: module),
          isFalse,
          reason: module,
        );
      }
      expect(AppRoles.isAdmin('floor_manager'), isFalse);
      expect(AppRoles.isStockManager('floor_manager'), isFalse);
      expect(AppRoles.canEditStockMode('floor_manager'), isFalse);
    });

    test('existing roles are unchanged', () {
      expect(AppRoles.all, hasLength(12));
      expect(AppRoles.normalizeRole('hygiene'), AppRoles.hygiene);
      expect(AppRoles.getModules('serveur'), [
        'restaurant',
        'bar',
        'hotel',
        'fiscalization',
      ]);
      expect(AppRoles.getModules('gerante'), [
        'restaurant',
        'bar',
        'hotel',
        'stock',
        'analytics',
      ]);
    });
  });

  group('UserModel', () {
    test('loads a floor_manager profile created by createTenantUser', () {
      final user = UserModel.fromMap(
        {
          'uid': 'fm-1',
          'role': 'floor_manager',
          'establishmentId': 'est-a',
          'establishmentName': 'Hôtel A',
          'name': 'Awa',
          'email': 'awa@example.com',
          'phone': '',
          'isActive': true,
          'modules': {
            'restaurant': false,
            'bar': false,
            'hotel': false,
            'stock': false,
            'fiscalization': false,
          },
          'mustChangePassword': true,
        },
        'fm-1',
        establishmentModules: {'restaurant': true, 'bar': true},
      );

      expect(user.role, 'floor_manager');
      expect(user.establishmentId, 'est-a');
      expect(user.isActive, isTrue);
      expect(user.canAccessRestaurant, isFalse);
      expect(user.canAccessBar, isFalse);
      expect(user.canAccessHotel, isFalse);
      expect(user.canAccessStock, isFalse);
      expect(user.canAccessFiscalization, isFalse);
    });

    test('profile without modules falls back to the (empty) role defaults', () {
      final user = _user(' Floor_Manager ');

      expect(user.role, 'floor_manager');
      expect(user.canAccessRestaurant, isFalse);
      expect(user.canAccessStock, isFalse);
    });

    test('serialization keeps the canonical value', () {
      final map = _user('floor_manager').toMap();

      expect(map['role'], 'floor_manager');
      expect(UserModel.fromMap(map, 'uid-1').role, 'floor_manager');
    });
  });

  group('HomeRouter', () {
    testWidgets('floor_manager goes to FloorManagerHomePage', (tester) async {
      final routed = await _routeFor(tester, _user('floor_manager'));

      expect(routed, isA<FloorManagerHomePage>());
      expect(routed, isNot(isA<UnauthorizedPage>()));
    });

    testWidgets('floor_manager without establishment is refused', (
      tester,
    ) async {
      final routed = await _routeFor(
        tester,
        _user('floor_manager', establishmentId: ''),
      );

      expect(routed, isA<UnauthorizedPage>());
    });

    testWidgets('serveur and gerante keep their dashboards', (tester) async {
      expect(await _routeFor(tester, _user('serveur')), isA<ServeurHomePage>());
      expect(
        await _routeFor(tester, _user('gerante')),
        isA<GeranteDashboardPage>(),
      );
    });

    testWidgets('an unknown role is still refused', (tester) async {
      expect(
        await _routeFor(tester, _user('manager_floor')),
        isA<UnauthorizedPage>(),
      );
    });
  });

  // L'affichage de FloorManagerHomePage est couvert par
  // floor_manager_dashboard_test.dart.
}
