import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';

class VersementComptaPage extends StatefulWidget {
  final String establishmentId;

  const VersementComptaPage({super.key, required this.establishmentId});

  @override
  State<VersementComptaPage> createState() => _VersementComptaPageState();
}

class _VersementComptaPageState extends State<VersementComptaPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Set<String> selectedHandoverIds = {};

  final Set<String> selectedRoomInvoiceIds = {};

  double selectedServerTotal = 0;
  double selectedRoomTotal = 0;

  bool isSubmitting = false;

  String get establishmentId => widget.establishmentId.trim();

  double get totalSelected => selectedServerTotal + selectedRoomTotal;

  void _toggleHandover(String id, double amount, bool selected) {
    setState(() {
      if (selected) {
        selectedHandoverIds.add(id);
        selectedServerTotal += amount;
      } else {
        selectedHandoverIds.remove(id);
        selectedServerTotal -= amount;
      }
    });
  }

  void _toggleRoomInvoice(String id, double amount, bool selected) {
    setState(() {
      if (selected) {
        selectedRoomInvoiceIds.add(id);
        selectedRoomTotal += amount;
      } else {
        selectedRoomInvoiceIds.remove(id);
        selectedRoomTotal -= amount;
      }
    });
  }

  Future<void> _submitTransfer() async {
    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    if (selectedHandoverIds.isEmpty && selectedRoomInvoiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun élément sélectionné.')),
      );
      return;
    }

    final auth = context.read<AuthController>();

    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final transferRef = _firestore
          .collection('establishments')
          .doc(establishmentId)
          .collection('managerToAccountingTransfers')
          .doc();

      final batch = _firestore.batch();

      batch.set(transferRef, {
        'establishmentId': establishmentId,
        'amount': totalSelected,
        'source': 'manager_mixed',
        'status': 'pending',
        'handoverIds': selectedHandoverIds.toList(),
        'roomInvoiceIds': selectedRoomInvoiceIds.toList(),
        'createdBy': user.uid,
        'createdByName': user.name,
        'createdAt': FieldValue.serverTimestamp(),
        'receivedAt': null,
      });

      for (final id in selectedHandoverIds) {
        final ref = _firestore
            .collection('establishments')
            .doc(establishmentId)
            .collection('serverHandovers')
            .doc(id);

        batch.update(ref, {
          'accountingTransferStatus': 'declared',
          'accountingTransferId': transferRef.id,
        });
      }

      for (final id in selectedRoomInvoiceIds) {
        final ref = _firestore
            .collection('establishments')
            .doc(establishmentId)
            .collection('roomInvoices')
            .doc(id);

        batch.update(ref, {
          'accountingTransferStatus': 'declared',
          'accountingTransferId': transferRef.id,
        });
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        selectedHandoverIds.clear();

        selectedRoomInvoiceIds.clear();

        selectedServerTotal = 0;
        selectedRoomTotal = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Versement déclaré à la comptabilité.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    final handoversStream = _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('serverHandovers')
        .where('status', isEqualTo: 'validated')
        .snapshots();

    final invoicesStream = _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('roomInvoices')
        .where('status', isEqualTo: 'paid')
        .snapshots();

    final transfersStream = _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('managerToAccountingTransfers')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Versement gérante → comptabilité')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        SizedBox(
                          height: 340,
                          child: _buildHandoversCard(handoversStream),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 340,
                          child: _buildInvoicesCard(invoicesStream),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 360,
                          child: _buildHistoryCard(transfersStream),
                        ),
                      ],
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
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(child: _buildHandoversCard(handoversStream)),
                      const SizedBox(height: 16),
                      Expanded(child: _buildInvoicesCard(invoicesStream)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      Expanded(child: _buildHistoryCard(transfersStream)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandoversCard(Stream<QuerySnapshot<Object?>> handoversStream) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Versements serveurs validés',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: handoversStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return (data['accountingTransferStatus'] ?? '') !=
                        'declared';
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Aucun versement serveur disponible.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = docs[index];

                      final data = doc.data() as Map<String, dynamic>;

                      final amount = ((data['validatedAmount'] ?? 0) as num)
                          .toDouble();

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: CheckboxListTile(
                          value: selectedHandoverIds.contains(doc.id),
                          onChanged: (value) {
                            _toggleHandover(doc.id, amount, value ?? false);
                          },
                          title: Text((data['serveurName'] ?? '').toString()),
                          subtitle: Text(
                            'Montant : ${amount.toStringAsFixed(0)} FCFA',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
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

  Widget _buildInvoicesCard(Stream<QuerySnapshot<Object?>> invoicesStream) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Factures chambres encaissées non versées',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

                    return (data['accountingTransferStatus'] ?? '') !=
                        'declared';
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Aucune facture chambre disponible.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = docs[index];

                      final data = doc.data() as Map<String, dynamic>;

                      final amount = ((data['total'] ?? 0) as num).toDouble();

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: CheckboxListTile(
                          value: selectedRoomInvoiceIds.contains(doc.id),
                          onChanged: (value) {
                            _toggleRoomInvoice(doc.id, amount, value ?? false);
                          },
                          title: Text(
                            '${(data['clientName'] ?? '').toString()} • Chambre ${(data['roomNumber'] ?? '').toString()}',
                          ),
                          subtitle: Text(
                            'Montant : ${amount.toStringAsFixed(0)} FCFA',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
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

  Widget _buildSummaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Résumé du versement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            _line(
              'Versements serveurs',
              '${selectedServerTotal.toStringAsFixed(0)} FCFA',
            ),
            _line(
              'Factures chambres',
              '${selectedRoomTotal.toStringAsFixed(0)} FCFA',
            ),
            const Divider(),
            _line(
              'TOTAL',
              '${totalSelected.toStringAsFixed(0)} FCFA',
              isBold: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : _submitTransfer,
                icon: const Icon(Icons.send),
                label: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Déclarer à la comptabilité'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Stream<QuerySnapshot<Object?>> transfersStream) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historique versements gérante',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: transfersStream,
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
                      child: Text('Aucun versement enregistré.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      final amount = ((data['amount'] ?? 0) as num).toDouble();

                      final status = (data['status'] ?? '').toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${amount.toStringAsFixed(0)} FCFA'),
                        subtitle: Text('Statut : $status'),
                        leading: CircleAvatar(
                          radius: 18,
                          child: Text('${index + 1}'),
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

  Widget _line(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
