import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_roles.dart';

import 'package:takapp/vues/auth/login_page.dart';
import 'package:takapp/vues/commun/unauthorized_page.dart';

import 'package:takapp/vues/comptabilite/comptable_dashboard_page.dart';
import 'package:takapp/vues/cuisine/cuisine_home_page.dart';
import 'package:takapp/vues/gerante/gerante_dashboard_page.dart';
import 'package:takapp/vues/global_admin/global_admin_dashboard_page.dart';
import 'package:takapp/vues/hygiene/hygiene_daily_page.dart';
import 'package:takapp/vues/hygiene/majordome_home_page.dart';
import 'package:takapp/vues/owner/owner_dashboard_page.dart';
import 'package:takapp/vues/serveur/serveur_home_page.dart';
import 'package:takapp/vues/bar/bar_home_page.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isInitialized || auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = auth.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    final role = user.role.trim();

    if (role == 'global_admin') {
      return const GlobalAdminDashboardPage();
    }

    if (role != AppRoles.superAdmin && user.establishmentId.trim().isEmpty) {
      return const UnauthorizedPage();
    }

    switch (role) {
      case AppRoles.superAdmin:
        return OwnerDashboardPage(establishmentId: user.establishmentId);

      case AppRoles.proprietaire:
        return OwnerDashboardPage(establishmentId: user.establishmentId);

      case AppRoles.gerante:
        return GeranteDashboardPage(establishmentId: user.establishmentId);

      case AppRoles.comptable:
        return ComptableDashboardPage(establishmentId: user.establishmentId);

      case AppRoles.chefCuisine:
        if (user.canAccessRestaurant || user.canAccessStock) {
          return CuisineHomePage(establishmentId: user.establishmentId);
        }
        return const UnauthorizedPage();

      case AppRoles.serveur:
        if (user.canAccessRestaurant) {
          return ServeurHomePage(establishmentId: user.establishmentId);
        }
        return const UnauthorizedPage();

      case AppRoles.barman:
        if (user.canAccessBar) {
          return BarHomePage(establishmentId: user.establishmentId);
        }
        return const UnauthorizedPage();

      case AppRoles.hygiene:
        if (user.canAccessHotel) {
          return HygieneDailyPage(establishmentId: user.establishmentId);
        }
        return const UnauthorizedPage();

      case AppRoles.majordhomme:
        if (user.canAccessHotel) {
          return const MajordomeHomePage();
        }
        return const UnauthorizedPage();

      default:
        return const UnauthorizedPage();
    }
  }
}
