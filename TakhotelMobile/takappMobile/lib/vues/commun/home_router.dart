import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/vues/auth/login_page.dart';
import 'package:takapp/vues/commun/unauthorized_page.dart';
import 'package:takapp/vues/comptabilite/comptable_dashboard_page.dart';
import 'package:takapp/vues/cuisine/cuisine_home_page.dart';
import 'package:takapp/vues/gerante/gerante_dashboard_page.dart';
import 'package:takapp/vues/owner/owner_dashboard_page.dart';
import 'package:takapp/vues/serveur/serveur_home_page.dart';

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

    switch (user.role.trim()) {
      case AppRoles.serveur:
        return const ServeurHomePage();
      case AppRoles.chefCuisine:
        return const CuisineHomePage();
      case AppRoles.gerante:
        return const GeranteDashboardPage();
      case AppRoles.comptable:
        return const ComptableDashboardPage();
      case AppRoles.owner:
        return const OwnerDashboardPage();
      default:
        return const UnauthorizedPage();
    }
  }
}
