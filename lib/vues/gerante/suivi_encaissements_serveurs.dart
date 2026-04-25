import 'package:flutter/material.dart';
import 'package:takapp/services/gerante_handover_service.dart';

class SuiviEncaissementsServeursPage extends StatelessWidget {
  const SuiviEncaissementsServeursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GeranteHandoverService();

    return Scaffold(
      appBar: AppBar(title: const Text('Encaissements serveurs non versés')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.streamServerPaymentsNonVerses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(child: Text('Aucun encaissement en attente'));
          }

          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = data[index];
              final amount = ((item['amount'] ?? 0) as num).toDouble();

              return ListTile(
                title: Text(
                  '${item['receivedByName'] ?? ''} • ${item['orderNumber'] ?? ''}',
                ),
                subtitle: Text('Mode: ${item['method'] ?? ''}'),
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
