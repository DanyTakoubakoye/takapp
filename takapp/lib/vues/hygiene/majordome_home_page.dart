import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/vues/shared/create_stock_request_page.dart';
import 'package:takapp/vues/shared/store_request_history_page.dart';
import 'package:takapp/vues/hygiene/hygiene_daily_page.dart';
import 'package:takapp/vues/hygiene/hotel_stock_item_form_page.dart';

class MajordomeHomePage extends StatelessWidget {
  const MajordomeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hygieneServiceTitle),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.butlerHygieneLeadTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.butlerHygieneLeadSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HygieneDailyPage(
                              establishmentId: establishmentId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cleaning_services),
                      label: Text(l10n.actionDailyHygiene),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HotelStockItemFormPage(
                              establishmentId: establishmentId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_business_outlined),
                      label: Text(l10n.actionAddHotelItem),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateStockRequestPage(
                              establishmentId: establishmentId,
                              store: 'hotel',
                              requestedByRole: 'majordhomme',
                              title: l10n.supplyRequestHotelTitle,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.playlist_add_circle_outlined),
                      label: Text(l10n.actionRequestSupplyShort),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreRequestHistoryPage(
                              establishmentId: establishmentId,
                              store: 'hotel',
                              title: l10n.receptionsToConfirmHotelTitle,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l10n.actionValidateReception),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
