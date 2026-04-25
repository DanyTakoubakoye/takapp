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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: _buildRoomInvoicesCard(
                      invoicesStream,
                      isMobile: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildServerPaymentsCard(
                      paymentsStream,
                      isMobile: true,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildRoomInvoicesCard(
                    invoicesStream,
                    isMobile: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildServerPaymentsCard(
                    paymentsStream,
                    isMobile: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomInvoicesCard(
    Stream<QuerySnapshot<Object?>> invoicesStream, {
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Factures chambres encaissées non versées',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: invoicesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final total = ((data['total'] ?? 0) as num).toDouble();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(data['clientName'] ?? '').toString()} • Chambre ${(data['roomNumber'] ?? '').toString()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Statut transfert : ${(data['accountingTransferStatus'] ?? 'non déclaré').toString()}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${total.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${(data['clientName'] ?? '').toString()} • Chambre ${(data['roomNumber'] ?? '').toString()}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Statut transfert : ${(data['accountingTransferStatus'] ?? 'non déclaré').toString()}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${total.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
    );
  }

  Widget _buildServerPaymentsCard(
    Stream<QuerySnapshot<Object?>> paymentsStream, {
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Encaissements serveurs non versés',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: paymentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _isServerPaymentStillUntransferred(data);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Aucun encaissement serveur non versé.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final amount = ((data['amount'] ?? 0) as num).toDouble();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(data['receivedByName'] ?? '').toString()} • ${(data['orderNumber'] ?? '').toString()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Mode : ${(data['method'] ?? '').toString()} • Statut : ${(data['handoverStatus'] ?? '').toString()}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${amount.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${(data['receivedByName'] ?? '').toString()} • ${(data['orderNumber'] ?? '').toString()}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Mode : ${(data['method'] ?? '').toString()} • Statut : ${(data['handoverStatus'] ?? '').toString()}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${amount.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
    );
  }
}
