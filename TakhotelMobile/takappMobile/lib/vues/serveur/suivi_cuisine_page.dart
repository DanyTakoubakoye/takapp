import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/services/cuisine_service.dart';

class SuiviCuisinePage extends StatelessWidget {
  const SuiviCuisinePage({super.key});

  Color _color(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey.shade300;
      case 'preparing':
        return Colors.orange.shade200;
      case 'ready':
        return Colors.green.shade200;
      default:
        return Colors.white;
    }
  }

  Widget _buildColumn(String title, List<QueryDocumentSnapshot> orders) {
    final cuisineService = CuisineService();

    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: orders.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Card(
                  color: _color(data['kitchenStatus']),
                  child: ListTile(
                    title: Text(data['orderNumber'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['clientType'] ?? ''),
                        const SizedBox(height: 6),

                        if (data['kitchenStatus'] == 'ready')
                          ElevatedButton(
                            onPressed: () async {
                              await cuisineService.updateKitchenStatus(
                                orderId: doc.id,
                                newKitchenStatus: 'served',
                              );
                            },
                            child: const Text('Récupéré'),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi Cuisine')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('createdBy', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final pending = docs
              .where(
                (d) =>
                    d['kitchenStatus'] == 'pending' &&
                    d['kitchenStatus'] != 'served',
              )
              .toList();

          final preparing = docs
              .where(
                (d) =>
                    d['kitchenStatus'] == 'preparing' &&
                    d['kitchenStatus'] != 'served',
              )
              .toList();

          final ready = docs
              .where(
                (d) =>
                    d['kitchenStatus'] == 'ready' &&
                    d['kitchenStatus'] != 'served',
              )
              .toList();

          return Row(
            children: [
              _buildColumn('En attente', pending),
              _buildColumn('Préparation', preparing),
              _buildColumn('Prête', ready),
            ],
          );
        },
      ),
    );
  }
}
