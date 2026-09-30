import 'package:flutter/material.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/order_actor_context.dart';

/// Rappelle, pendant la prise de commande, POUR QUI et PAR QUI la commande
/// est saisie. Rien n'est affiché pour une commande classique de serveur.
class OrderActorBanner extends StatelessWidget {
  final OrderActorContext? actor;

  const OrderActorBanner({super.key, required this.actor});

  @override
  Widget build(BuildContext context) {
    final current = actor;
    if (current == null || !current.isFloorManager) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final text = current.isDelegated
        ? l10n.fmOrderContextForServer(
            current.assignedServerName,
            current.performedByUserName,
          )
        : l10n.fmOrderContextDirect(current.performedByUserName);

    return Container(
      key: const ValueKey('order-actor-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: current.isDelegated ? Colors.blue.shade50 : Colors.teal.shade50,
      child: Row(
        children: [
          Icon(
            current.isDelegated ? Icons.person_pin : Icons.supervisor_account,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
