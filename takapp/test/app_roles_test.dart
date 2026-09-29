import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/modeles/user_model.dart';

void main() {
  test('legacy hygiene role normalizes to the canonical role', () {
    expect(AppRoles.normalizeRole('hygiene'), AppRoles.hygiene);
    expect(AppRoles.normalizeRole(' SERVICE_HYGIENE '), AppRoles.hygiene);
    expect(AppRoles.exists('hygiene'), isFalse);
  });

  test('legacy hygiene profiles keep their existing module access', () {
    final user = UserModel.fromMap({'role': 'hygiene'}, 'legacy-user');

    expect(user.role, AppRoles.hygiene);
    expect(user.canAccessHotel, isTrue);
    expect(user.canAccessStock, isTrue);
    expect(
      AppRoles.getModules('hygiene'),
      AppRoles.getModules(AppRoles.hygiene),
    );
  });
}
