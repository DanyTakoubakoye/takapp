import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuiviFacturesNonVerseesPage extends StatefulWidget {
  const SuiviFacturesNonVerseesPage({super.key});

  @override
  State<SuiviFacturesNonVerseesPage> createState() =>
      _SuiviFacturesNonVerseesPageState();
}

class _SuiviFacturesNonVerseesPageState
    extends State<SuiviFacturesNonVerseesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isRoomInvoiceStillUntransferred(Map<String, dynamic> data) {
    final transferStatus = (data['accountingTransferStatus'] ?? '')
        .toString()
        .trim();

    return transferStatus != 'declared' &&
        transferStatus != 'received' &&
        transferStatus != 'validated';
  }

  bool _isServerPaymentStillUntransferred(Map<String, dynamic> data) {
    final handoverStatus = (data['handoverStatus'] ?? '').toString().trim();
    final type = (data['type'] ?? '').toString().trim();

    // Exclure totalement les paiements de chambre créés par la gérante
    if (type == 'room') return false;

    return handoverStatus == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final invoicesStream = _firestore
        .collection('roomInvoices')
        .where('status', isEqualTo: 'paid')
        .orderBy('paidAt', descending: true)
        .snapshots();

    final paymentsStream = _firestore
        .collection('payments')
        .where('handoverStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi factures / encaissements non versés'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Factures chambres encaissées non versées',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: invoicesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${snapshot.error}'),
                              );
                            }

                            final docs = (snapshot.data?.docs ?? []).where((
                              doc,
                            ) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _isRoomInvoiceStillUntransferred(data);
                            }).toList();

                            if (docs.isEmpty) {
                              return const Center(
                                child: Text('Aucune facture non versée.'),
                              );
                            }

                            return ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final total = ((data['total'] ?? 0) as num)
                                    .toDouble();

                                return ListTile(
                                  title: Text(
                                    '${(data['clientName'] ?? '').toString()} • Chambre ${(data['roomNumber'] ?? '').toString()}',
                                  ),
                                  subtitle: Text(
                                    'Statut transfert : ${(data['accountingTransferStatus'] ?? 'non déclaré').toString()}',
                                  ),
                                  trailing: Text(
                                    '${total.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Encaissements serveurs non versés',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: paymentsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${snapshot.error}'),
                              );
                            }

                            final docs = (snapshot.data?.docs ?? []).where((
                              doc,
                            ) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _isServerPaymentStillUntransferred(data);
                            }).toList();

                            if (docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Aucun encaissement serveur non versé.',
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final amount = ((data['amount'] ?? 0) as num)
                                    .toDouble();

                                return ListTile(
                                  title: Text(
                                    '${(data['receivedByName'] ?? '').toString()} • ${(data['orderNumber'] ?? '').toString()}',
                                  ),
                                  subtitle: Text(
                                    'Mode : ${(data['method'] ?? '').toString()} • Statut : ${(data['handoverStatus'] ?? '').toString()}',
                                  ),
                                  trailing: Text(
                                    '${amount.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
