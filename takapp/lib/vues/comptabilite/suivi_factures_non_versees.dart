import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/l10n/app_localizations.dart';

class SuiviFacturesNonVerseesPage extends StatefulWidget {
  const SuiviFacturesNonVerseesPage({super.key});

  @override
  State<SuiviFacturesNonVerseesPage> createState() =>
      _SuiviFacturesNonVerseesPageState();
}

class _SuiviFacturesNonVerseesPageState
    extends State<SuiviFacturesNonVerseesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// SAAS HELPERS
  /// =========================

  String get establishmentId {
    final auth = context.read<AuthController>();
    return auth.currentUser?.establishmentId ?? '';
  }

  String get establishmentName {
    final auth = context.read<AuthController>();
    return auth.currentUser?.establishmentName ?? '';
  }

  CollectionReference<Map<String, dynamic>> get _roomInvoicesCol {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('roomInvoices');
  }

  CollectionReference<Map<String, dynamic>> get _paymentsCol {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('payments');
  }

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

  // Les statuts restent des valeurs techniques en base : seul leur rendu est
  // localisé. Un statut absent s'affiche « non déclaré », un statut inconnu
  // est affiché tel quel.
  String _transferStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case '':
        return l10n.statusNotDeclared;
      case 'declared':
        return l10n.statusDeclared;
      case 'received':
        return l10n.statusReceived;
      case 'validated':
        return l10n.statusValidated;
      default:
        return status;
    }
  }

  String _handoverStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.statusPending;
      case 'validated':
        return l10n.statusValidated;
      case 'received':
        return l10n.statusReceived;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    if (user.establishmentId.trim().isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    final invoicesStream = _roomInvoicesCol
        .where('status', isEqualTo: 'paid')
        .orderBy('paidAt', descending: true)
        .snapshots();

    final paymentsStream = _paymentsCol
        .where('handoverStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.establishmentName.trim().isNotEmpty
              ? '${user.establishmentName} - ${l10n.actionTrackUntransferred}'
              : l10n.untransferredFullTitle,
        ),
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
    Stream<QuerySnapshot<Map<String, dynamic>>> invoicesStream, {
    required bool isMobile,
  }) {
    final l10n = AppLocalizations.of(context);

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
                l10n.paidRoomInvoicesNotTransferred,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                    return _isRoomInvoiceStillUntransferred(doc.data());
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(child: Text(l10n.noUntransferredInvoice));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final total = ((data['total'] ?? 0) as num).toDouble();

                      final transferStatus =
                          (data['accountingTransferStatus'] ?? '')
                              .toString()
                              .trim();

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
                                    '${(data['clientName'] ?? '').toString()}'
                                    ' • ${l10n.labelRoom((data['roomNumber'] ?? '').toString())}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.transferStatusLine(
                                      _transferStatusLabel(
                                        l10n,
                                        transferStatus,
                                      ),
                                    ),
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
                                          '${(data['clientName'] ?? '').toString()}'
                                          ' • ${l10n.labelRoom((data['roomNumber'] ?? '').toString())}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n.transferStatusLine(
                                            _transferStatusLabel(
                                              l10n,
                                              transferStatus,
                                            ),
                                          ),
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
    Stream<QuerySnapshot<Map<String, dynamic>>> paymentsStream, {
    required bool isMobile,
  }) {
    final l10n = AppLocalizations.of(context);

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
                l10n.untransferredServerCollections,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: paymentsStream,
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
                    return _isServerPaymentStillUntransferred(doc.data());
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(l10n.noUntransferredServerCollection),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final amount = ((data['amount'] ?? 0) as num).toDouble();

                      // `method` et `handoverStatus` sont des codes techniques.
                      final methodStatusLine =
                          '${l10n.methodLine(AppPaymentMethods.label(l10n, (data['method'] ?? '').toString()))}'
                          ' • ${l10n.statusLine(_handoverStatusLabel(l10n, (data['handoverStatus'] ?? '').toString().trim()))}';

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
                                  Text(methodStatusLine),
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
                                        Text(methodStatusLine),
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
