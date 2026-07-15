import 'package:flutter/material.dart';

class AppTheme {
  /// =========================
  /// COULEURS PRINCIPALES
  /// =========================

  static const Color primaryBlue = Color(0xFF0D47A1);

  static const Color secondaryBlue = Color(0xFF1565C0);

  static const Color lightBlue = Color(0xFFE3F2FD);

  static const Color gold = Color(0xFFC9A227);

  static const Color darkText = Color(0xFF1F2937);

  static const Color softGrey = Color(0xFFF5F7FA);

  static const Color white = Colors.white;

  /// =========================
  /// COULEURS SAAS
  /// =========================

  static const Color success = Color(0xFF16A34A);

  static const Color warning = Color(0xFFF59E0B);

  static const Color danger = Color(0xFFDC2626);

  static const Color info = Color(0xFF0284C7);

  /// =========================
  /// MODULE COLORS
  /// =========================

  static const Map<String, Color> moduleColors = {
    'restaurant': Color(0xFFEF4444),

    'bar': Color(0xFF7C3AED),

    'hotel': Color(0xFF0EA5E9),

    'stock': Color(0xFF16A34A),

    'analytics': Color(0xFFF59E0B),

    'fiscalization': Color(0xFF1D4ED8),
  };

  /// =========================
  /// ROLE COLORS
  /// =========================

  static const Map<String, Color> roleColors = {
    'super_admin': Color(0xFF111827),

    'proprietaire': Color(0xFFC9A227),

    'gerante': Color(0xFF0D47A1),

    'comptable': Color(0xFF0F766E),

    'chef_cuisine': Color(0xFFB45309),

    'barman': Color(0xFF7C3AED),

    'serveur': Color(0xFF2563EB),

    'service_hygiene': Color(0xFF16A34A),

    'majordhomme': Color(0xFF0891B2),
  };

  /// =========================
  /// THEME PRINCIPAL
  /// =========================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: softGrey,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,

        primary: primaryBlue,

        secondary: gold,

        surface: white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,

        foregroundColor: white,

        centerTitle: true,

        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: white,

        elevation: 2,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: secondaryBlue, width: 1.4),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,

          foregroundColor: white,

          elevation: 0,

          minimumSize: const Size(140, 52),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,

          fontWeight: FontWeight.bold,

          color: darkText,
        ),

        titleLarge: TextStyle(
          fontSize: 20,

          fontWeight: FontWeight.w700,

          color: darkText,
        ),

        bodyLarge: TextStyle(fontSize: 16, color: darkText),

        bodyMedium: TextStyle(fontSize: 14, color: darkText),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,

        foregroundColor: white,
      ),

      dividerTheme: DividerThemeData(color: Colors.grey.shade300),
    );
  }

  /// =========================
  /// HELPERS SAAS
  /// =========================

  static Color getModuleColor(String module) {
    return moduleColors[module] ?? primaryBlue;
  }

  static Color getRoleColor(String role) {
    return roleColors[role] ?? primaryBlue;
  }
}
