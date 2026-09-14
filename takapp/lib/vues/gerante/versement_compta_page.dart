import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';

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

  // `status` reste la valeur technique stockée : seul le rendu est localisé,
  // et une valeur inconnue est affichée telle quelle.
  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.statusPending;
      case 'declared':
        return l10n.statusDeclared;
      case 'received':
        return l10n.statusReceived;
      default:
        return status;
    }
  }

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
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));
      return;
    }

    if (selectedHandoverIds.isEmpty && selectedRoomInvoiceIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noElementSelected)));
      return;
    }

    final auth = context.read<AuthController>();

    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errUserNotFound)));
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
        SnackBar(content: Text(l10n.transferDeclaredToAccounting)),
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
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
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
      appBar: AppBar(title: Text(l10n.managerToAccountingTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildSummaryCard(l10n),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        SizedBox(
                          height: 340,
                          child: _buildHandoversCard(l10n, handoversStream),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 340,
                          child: _buildInvoicesCard(l10n, invoicesStream),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 360,
                          child: _buildHistoryCard(l10n, transfersStream),
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
                      Expanded(
                        child: _buildHandoversCard(l10n, handoversStream),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildInvoicesCard(l10n, invoicesStream),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSummaryCard(l10n),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildHistoryCard(l10n, transfersStream),
                      ),
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

  Widget _buildHandoversCard(
    AppLocalizations l10n,
    Stream<QuerySnapshot<Object?>> handoversStream,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.validatedServerHandovers,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
                    return Center(
                      child: Text(l10n.errorPrefixed('${snapshot.error}')),
                    );
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return (data['accountingTransferStatus'] ?? '') !=
                        'declared';
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(l10n.noServerHandoverAvailable),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(),
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
                            l10n.amountLine(amount.toStringAsFixed(0)),
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

  Widget _buildInvoicesCard(
    AppLocalizations l10n,
    Stream<QuerySnapshot<Object?>> invoicesStream,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.paidRoomInvoicesNotTransferred,
                style: const TextStyle(
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l10n.errorPrefixed('${snapshot.error}')),
                    );
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return (data['accountingTransferStatus'] ?? '') !=
                        'declared';
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(child: Text(l10n.noRoomInvoiceAvailable));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(),
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
                            '${(data['clientName'] ?? '').toString()} • ${l10n.labelRoom((data['roomNumber'] ?? '').toString())}',
                          ),
                          subtitle: Text(
                            l10n.amountLine(amount.toStringAsFixed(0)),
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

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.transferSummary,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _line(
              l10n.serverHandoversLabel,
              '${selectedServerTotal.toStringAsFixed(0)} FCFA',
            ),
            _line(
              l10n.roomInvoicesLabel,
              '${selectedRoomTotal.toStringAsFixed(0)} FCFA',
            ),
            const Divider(),
            _line(
              l10n.labelTotalCaps,
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
                    : Text(l10n.actionDeclareToAccounting),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    AppLocalizations l10n,
    Stream<QuerySnapshot<Object?>> transfersStream,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.managerTransferHistory,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
                    return Center(
                      child: Text(l10n.errorPrefixed('${snapshot.error}')),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(child: Text(l10n.noTransferRecorded));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      final amount = ((data['amount'] ?? 0) as num).toDouble();

                      final status = (data['status'] ?? '').toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${amount.toStringAsFixed(0)} FCFA'),
                        subtitle: Text(
                          l10n.statusLine(_statusLabel(l10n, status)),
                        ),
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
