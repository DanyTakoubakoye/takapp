import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';

class ReceptionGerantePage extends StatefulWidget {
  const ReceptionGerantePage({super.key});

  @override
  State<ReceptionGerantePage> createState() => _ReceptionGerantePageState();
}

class _ReceptionGerantePageState extends State<ReceptionGerantePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _confirmReception(DocumentSnapshot doc) async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    final data = doc.data() as Map<String, dynamic>;
    final handoverIds = List<String>.from(data['handoverIds'] ?? []);
    final roomInvoiceIds = List<String>.from(data['roomInvoiceIds'] ?? []);
    final amount = ((data['amount'] ?? 0) as num).toDouble();

    final batch = _firestore.batch();
    final transferRef = _firestore
        .collection('managerToAccountingTransfers')
        .doc(doc.id);

    batch.update(transferRef, {
      'status': 'received',
      'receivedAt': FieldValue.serverTimestamp(),
      'receivedByAccountingId': user.uid,
      'receivedByAccountingName': user.name,
    });

    for (final id in handoverIds) {
      final handoverRef = _firestore.collection('serverHandovers').doc(id);
      batch.update(handoverRef, {'accountingTransferStatus': 'received'});
    }

    for (final id in roomInvoiceIds) {
      final roomInvoiceRef = _firestore.collection('roomInvoices').doc(id);
      batch.update(roomInvoiceRef, {'accountingTransferStatus': 'received'});
    }

    for (final handoverId in handoverIds) {
      final handoverSnap = await _firestore
          .collection('serverHandovers')
          .doc(handoverId)
          .get();

      if (!handoverSnap.exists || handoverSnap.data() == null) continue;

      final handoverData = handoverSnap.data()!;
      final paymentIds = List<String>.from(handoverData['paymentIds'] ?? []);

      for (final paymentId in paymentIds) {
        final paymentRef = _firestore.collection('payments').doc(paymentId);
        batch.update(paymentRef, {'handoverStatus': 'validated'});
      }
    }

    await batch.commit();

    if (!mounted) return;

    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildQuitusPdf(
      accountType: 'Versement gérante',
      theoreticalAmount: amount,
      physicalAmount: amount,
      date: DateTime.now(),
      validatedByName: user.name,
    );

    await printer.printPdf(Uint8List.fromList(bytes));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réception validée et quitus imprimé.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingStream = _firestore
        .collection('managerToAccountingTransfers')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final receivedStream = _firestore
        .collection('managerToAccountingTransfers')
        .where('status', isEqualTo: 'received')
        .orderBy('receivedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Réception versements gérante')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: _buildPendingCard(pendingStream, isMobile: true),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildReceivedCard(receivedStream, isMobile: true),
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
                  child: _buildPendingCard(pendingStream, isMobile: false),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildReceivedCard(receivedStream, isMobile: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingCard(
    Stream<QuerySnapshot<Object?>> pendingStream, {
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
                'Versements en attente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: pendingStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Aucun versement en attente.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
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
                                    '${amount.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Serveurs: ${(data['handoverIds'] as List<dynamic>? ?? []).length} • Chambres: ${(data['roomInvoiceIds'] as List<dynamic>? ?? []).length}',
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _confirmReception(doc),
                                      child: const Text('Valider'),
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
                                          '${amount.toStringAsFixed(0)} FCFA',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Serveurs: ${(data['handoverIds'] as List<dynamic>? ?? []).length} • Chambres: ${(data['roomInvoiceIds'] as List<dynamic>? ?? []).length}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () => _confirmReception(doc),
                                    child: const Text('Valider'),
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

  Widget _buildReceivedCard(
    Stream<QuerySnapshot<Object?>> receivedStream, {
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
                'Versements reçus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: receivedStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(child: Text('Aucun versement reçu.'));
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${amount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Reçu par : ${(data['receivedByAccountingName'] ?? '').toString()}',
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
