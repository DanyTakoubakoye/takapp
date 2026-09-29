import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/l10n/language_selector.dart';
import 'package:takapp/l10n/app_localizations.dart';

/// Accueil temporaire du rôle `floor_manager`.
///
/// Volontairement vide de toute fonction métier (services, affectation des
/// serveurs, commandes ou encaissements délégués, remises) : ces écrans
/// seront ajoutés dans des étapes dédiées. Seules la langue et la
/// déconnexion sont proposées, comme sur les autres accueils.
class FloorManagerHomePage extends StatelessWidget {
  const FloorManagerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.floorManagerHomeTitle),
        actions: [
          const LanguageSelector(),
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text(l10n.floorManagerHomeBody)),
    );
  }
}
