import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/stock_request_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/stock_request_model.dart';
import 'package:takapp/services/stock_request_service.dart';

class StoreRequestHistoryPage extends StatelessWidget {
  final String establishmentId;
  final String store;
  final String title;

  const StoreRequestHistoryPage({
    super.key,
    required this.establishmentId,
    required this.store,
    required this.title,
  });

  Color _storeColor() {
    switch (store) {
      case 'restaurant':
        return Colors.deepOrange;
      case 'bar':
        return Colors.indigo;
      case 'hotel':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = StockRequestService();
    final controller = context.watch<StockRequestController>();
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final color = _storeColor();
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<StockRequestModel>>(
        stream: service.streamRequestsForReceiver(
          establishmentId: establishmentId,
          store: store,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.commonError('${snapshot.error}')));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Text(l10n.noDeliveredRequestAwaitingReception),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = requests[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.requestedByName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.roleLine(item.requestedByRole)),
                      Text(l10n.storeNameLine(item.store)),
                      Text(
                        l10n.requestedOnLine(
                          item.createdAt == null
                              ? '-'
                              : DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(item.createdAt!),
                        ),
                      ),
                      Text(
                        l10n.deliveredOnLine(
                          item.deliveredAt == null
                              ? '-'
                              : DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(item.deliveredAt!),
                        ),
                      ),
                      if (item.note.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(l10n.noteLine(item.note)),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: (controller.isSubmitting || user == null)
                              ? null
                              : () async {
                                  final success = await controller
                                      .confirmReception(
                                        establishmentId: establishmentId,
                                        requestId: item.id,
                                        receivedBy: user.uid,
                                        receivedByName: user.name,
                                      );

                                  if (!context.mounted) return;

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.receptionConfirmedSuccess,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          controller.errorText(
                                                AppLocalizations.of(context),
                                              ) ??
                                              AppLocalizations.of(
                                                context,
                                              ).errUnknown,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: controller.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(l10n.actionConfirmTheReception),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
