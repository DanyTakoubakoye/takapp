import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/floor_manager_shift_controller.dart';
import 'package:takapp/core/l10n/language_selector.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/vues/floor_manager/floor_manager_action_page.dart';
import 'package:takapp/vues/floor_manager/floor_manager_widgets.dart';

/// Tableau de bord du Floor Manager : identité, service courant, et les deux
/// sections Commandes / Encaissements (désactivées sans service ouvert).
///
/// Données : `FloorManagerShiftController` (temps réel). Les règles Firestore
/// limitent de toute façon le Floor Manager à SON service et SES serveurs.
class FloorManagerHomePage extends StatelessWidget {
  /// Page de commande ouverte (injectable pour les tests).
  final OrderPageBuilder orderPageBuilder;

  const FloorManagerHomePage({
    super.key,
    this.orderPageBuilder = defaultOrderPage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthController>().currentUser;
    final controller = context.watch<FloorManagerShiftController>();
    final hasOpenShift = controller.state.hasOpenShift;

    void openSection(FloorManagerSection section) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FloorManagerActionPage(
            section: section,
            orderPageBuilder: orderPageBuilder,
          ),
        ),
      );
    }

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _IdentityCard(
              name: user?.name ?? '',
              establishmentName: user?.establishmentName ?? '',
            ),
            const SizedBox(height: 16),
            _ShiftStatusCard(controller: controller),
            const SizedBox(height: 16),
            for (final section in FloorManagerSection.values) ...[
              FloorManagerTile(
                key: ValueKey('fm-section-${section.name}'),
                title: section.title(l10n),
                subtitle: section.subtitle(l10n),
                icon: section.icon,
                color: section.color,
                onTap: hasOpenShift ? () => openSection(section) : null,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String establishmentName;

  const _IdentityCard({required this.name, required this.establishmentName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.supervisor_account),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.roleFloorManager,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (establishmentName.isNotEmpty) Text(establishmentName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftStatusCard extends StatelessWidget {
  final FloorManagerShiftController controller;

  const _ShiftStatusCard({required this.controller});

  static final DateFormat _time = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (controller.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (controller.hasError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(l10n.fmLoadError),
        ),
      );
    }

    final ShiftModel? shift = controller.state.openShift;
    if (shift == null) return const NoOpenShiftCard();

    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 36, color: Colors.green),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fmCurrentShiftTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_time.format(shift.startsAt)} - '
                    '${_time.format(shift.endsAt)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.fmActiveServersCount(
                      controller.state.activeServers.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
