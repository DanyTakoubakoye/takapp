import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/core/l10n/locale_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';

/// =========================
/// SELECTEUR DE LANGUE
/// =========================
///
/// Widget réutilisable : à placer dans les `actions` d'une `AppBar`
/// (à côté du bouton de déconnexion) ou directement dans un écran
/// comme la page de connexion.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = context.watch<LocaleController>().locale;

    return PopupMenuButton<Locale>(
      tooltip: l10n.languageLabel,
      icon: const Icon(Icons.translate),
      onSelected: (locale) {
        context.read<LocaleController>().setLocale(locale);
      },
      itemBuilder: (context) {
        return LocaleController.supportedLocales.map((locale) {
          final isSelected = locale.languageCode == currentLocale.languageCode;

          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check : null,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _labelFor(l10n, locale),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  static String _labelFor(AppLocalizations l10n, Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'fr':
      default:
        return l10n.languageFrench;
    }
  }
}
