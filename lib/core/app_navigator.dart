import 'package:flutter/material.dart';

/// =========================
/// GLOBAL NAVIGATOR
/// =========================
///
/// Utilisé pour :
/// - navigation globale
/// - redirections SaaS
/// - logout global
/// - changement d’établissement
/// - gestion session expirée
///

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// =========================
/// HELPERS NAVIGATION
/// =========================

class AppNavigator {
  static NavigatorState? get navigator {
    return appNavigatorKey.currentState;
  }

  static BuildContext? get context {
    return appNavigatorKey.currentContext;
  }

  /// =========================
  /// PUSH
  /// =========================

  static Future<T?> push<T>(Widget page) {
    return navigator!.push<T>(MaterialPageRoute(builder: (_) => page));
  }

  /// =========================
  /// PUSH REPLACEMENT
  /// =========================

  static Future<T?> pushReplacement<T>(Widget page) {
    return navigator!.pushReplacement<T, T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// =========================
  /// RESET STACK
  /// =========================
  ///
  /// Très utile en SaaS :
  /// - logout
  /// - changement établissement
  /// - expiration abonnement
  /// - désactivation compte
  ///

  static Future<void> resetTo(Widget page) async {
    navigator!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  /// =========================
  /// POP
  /// =========================

  static void pop<T>([T? result]) {
    navigator?.pop(result);
  }
}
