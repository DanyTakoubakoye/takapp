import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/stock_request_controller.dart';
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
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text('Aucune demande livrée en attente de réception.'),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                      Text('Rôle : ${item.requestedByRole}'),
                      Text('Magasin : ${item.store}'),
                      Text(
                        'Demandé le : ${item.createdAt == null ? "-" : DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!)}',
                      ),
                      Text(
                        'Livré le : ${item.deliveredAt == null ? "-" : DateFormat('dd/MM/yyyy HH:mm').format(item.deliveredAt!)}',
                      ),
                      if (item.note.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Note : ${item.note}'),
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
                                      const SnackBar(
                                        content: Text(
                                          'Réception confirmée avec succès.',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          controller.errorMessage ??
                                              'Erreur inconnue.',
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
                          label: const Text('Confirmer la réception'),
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
