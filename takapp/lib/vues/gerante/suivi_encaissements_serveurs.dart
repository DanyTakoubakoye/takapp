import 'package:flutter/material.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/services/gerante_handover_service.dart';

class SuiviEncaissementsServeursPage extends StatelessWidget {
  final String establishmentId;

  const SuiviEncaissementsServeursPage({
    super.key,
    required this.establishmentId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final safeEstablishmentId = establishmentId.trim();

    if (safeEstablishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    final service = GeranteHandoverService();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.serverPaymentsNotHandedTitle)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.streamServerPaymentsNonVerses(
          establishmentId: safeEstablishmentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(l10n.errorPrefixed('${snapshot.error}')),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(child: Text(l10n.noPendingPayment));
          }

          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final item = data[index];
              final amount = ((item['amount'] ?? 0) as num).toDouble();

              return ListTile(
                title: Text(
                  '${item['receivedByName'] ?? ''} • ${item['orderNumber'] ?? ''}',
                ),
                // `method` est un code technique ('cash', 'mobile_money'…) :
                // on le rend via le libellé localisé partagé.
                subtitle: Text(
                  l10n.methodLine(
                    AppPaymentMethods.label(
                      l10n,
                      (item['method'] ?? '').toString(),
                    ),
                  ),
                ),
                trailing: Text(
                  '${amount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
