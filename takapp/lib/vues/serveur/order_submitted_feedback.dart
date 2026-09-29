import 'package:flutter/material.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';

/// Confirmation affichée après une commande réellement acceptée.
///
/// Point unique pour toutes les pages qui envoient une commande : le message
/// (succès simple ou succès avec anomalies de stock) vient du contrôleur ;
/// une anomalie reste affichée plus longtemps et doit être fermée à la main
/// pour ne pas passer inaperçue.
void showOrderSubmittedFeedback(
  BuildContext context,
  OrderController orderController,
) {
  final l10n = AppLocalizations.of(context);
  final hasWarnings = orderController.hasStockWarnings;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(orderController.submittedMessage(l10n)),
      backgroundColor: hasWarnings ? Colors.orange.shade800 : null,
      duration: hasWarnings
          ? const Duration(seconds: 12)
          : const Duration(seconds: 4),
      showCloseIcon: hasWarnings,
    ),
  );
}
