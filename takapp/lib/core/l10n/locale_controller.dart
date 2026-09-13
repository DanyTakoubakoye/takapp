import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =========================
/// LANGUE DE L'APPLICATION
/// =========================
///
/// Conserve la langue choisie par l'utilisateur et la persiste sur
/// l'appareil, afin qu'elle soit restaurée au prochain lancement.
///
/// Le français reste la langue par défaut : un utilisateur existant qui
/// n'a jamais fait de choix retrouve l'application exactement comme avant.
class LocaleController extends ChangeNotifier {
  static const String _storageKey = 'takapp_locale';

  /// Langues proposées dans l'application.
  static const List<Locale> supportedLocales = [Locale('fr'), Locale('en')];

  static const Locale fallbackLocale = Locale('fr');

  Locale _locale = fallbackLocale;

  Locale get locale => _locale;

  static bool _isSupported(String languageCode) {
    return supportedLocales.any((l) => l.languageCode == languageCode);
  }

  /// Charge la langue enregistrée. À appeler avant `runApp()`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);

    if (code != null && _isSupported(code)) {
      _locale = Locale(code);
    }
  }

  /// Change la langue et l'enregistre.
  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;

    if (!_isSupported(code)) return;
    if (code == _locale.languageCode) return;

    _locale = Locale(code);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, code);
  }
}
