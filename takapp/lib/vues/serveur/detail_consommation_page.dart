import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/fiscalization_controller.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/emcf_invoice_item_model.dart';
import 'package:takapp/modeles/emcf_invoice_request_model.dart';
import 'package:takapp/modeles/order_ticket_model.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';

class DetailConsommationPage extends StatefulWidget {
  final String establishmentId;

  /// Addition à facturer : une seule commande (facture historique) ou toutes
  /// les commandes non encaissées d'une même table / chambre.
  final OrderTicket ticket;

  const DetailConsommationPage({
    super.key,
    required this.establishmentId,
    required this.ticket,
  });

  @override
  State<DetailConsommationPage> createState() => _DetailConsommationPageState();
}

class _DetailConsommationPageState extends State<DetailConsommationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _sellerIfu = '';
  String _sellerName = "";
  String _sellerAddress = '';
  String _sellerLogo = '';

  final TextEditingController clientNameController = TextEditingController();

  final TextEditingController clientAddressController = TextEditingController();

  final TextEditingController clientIfuController = TextEditingController();

  String selectedPaymentMethod = AppPaymentMethods.cash;

  bool isPrintingOrPaying = false;

  bool get _isSmall => MediaQuery.of(context).size.width < 800;

  // Stream et future créés une seule fois : build() dépend de MediaQuery et de
  // plusieurs setState, les recréer remettrait Stream/FutureBuilder en attente
  // et détruirait les champs client (le clavier se refermait aussitôt).
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _orderStream;
  late final Future<List<Map<String, dynamic>>> _itemsFuture;

  String get establishmentId => widget.establishmentId.trim();

  OrderTicket get _ticket => widget.ticket;

  CollectionReference<Map<String, dynamic>> get _ordersRef {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders');
  }

  /// Commande principale de l'addition : elle porte les informations client et
  /// la certification de la facture.
  DocumentReference<Map<String, dynamic>> get _primaryOrderRef {
    return _ordersRef.doc(_ticket.primaryOrder.id);
  }

  List<DocumentReference<Map<String, dynamic>>> get _orderRefs {
    return _ticket.orderIds.map(_ordersRef.doc).toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _loadSellerInfo() async {
    final doc = await _firestore
        .collection('establishments')
        .doc(establishmentId)
        .get();
    final data = doc.data() ?? {};
    if (!mounted) return;
    setState(() {
      _sellerName = (data['name'] ?? '').toString().trim();
      _sellerIfu = (data['ifu'] ?? '').toString().trim();
      final address = (data['address'] ?? '').toString().trim();
      final city = (data['city'] ?? '').toString().trim();
      _sellerAddress = [address, city].where((e) => e.isNotEmpty).join(', ');
      _sellerLogo = (data['logo'] ?? '').toString().trim();
    });
  }

  /// Articles de toutes les commandes de l'addition, dans l'ordre où elles ont
  /// été lancées.
  Future<List<Map<String, dynamic>>> _loadItems({
    bool includeCancelled = true,
  }) async {
    final snapshots = await Future.wait(
      _orderRefs.map((ref) => ref.collection('items').get()),
    );

    final docs = snapshots.expand((snapshot) => snapshot.docs).toList();

    return docs
        .map((doc) {
          final data = doc.data();

          double toDouble(dynamic value) {
            if (value == null) return 0;

            if (value is num) {
              return value.toDouble();
            }

            return double.tryParse(value.toString()) ?? 0;
          }

          int toInt(dynamic value) {
            if (value == null) return 0;

            if (value is int) return value;

            if (value is num) {
              return value.toInt();
            }

            return int.tryParse(value.toString()) ?? 0;
          }

          final quantity = toInt(data['quantity']);

          final unitPrice = toDouble(
            data['unitPrice'] ?? data['price'] ?? data['prix'],
          );

          final total = data['totalPrice'] != null
              ? toDouble(data['totalPrice'])
              : data['total'] != null
              ? toDouble(data['total'])
              : quantity * unitPrice;

          return {
            'id': doc.id,
            'name': data['name']?.toString() ?? '',
            'quantity': quantity,
            'unitPrice': unitPrice,
            'total': total,
            'note': data['note']?.toString() ?? '',
            'taxGroup': data['taxGroup']?.toString() ?? 'B',
            'isCancelled': data['isCancelled'] == true,
            'cancelledByName': data['cancelledByName']?.toString() ?? '',
            'cancellationReason': data['cancellationReason']?.toString() ?? '',
          };
        })
        .where((item) => includeCancelled || item['isCancelled'] != true)
        .toList();
  }

  Future<void> _saveClientInfo() async {
    final batch = _firestore.batch();

    for (final ref in _orderRefs) {
      batch.update(ref, {
        'invoiceClientName': clientNameController.text.trim(),
        'invoiceClientAddress': clientAddressController.text.trim(),
        'invoiceClientIfu': clientIfuController.text.trim(),
        'establishmentId': establishmentId,
      });
    }

    await batch.commit();
  }

  Future<bool> _ensurePaymentRegistered() async {
    final orderDocs = await Future.wait(_orderRefs.map((ref) => ref.get()));

    // Encaissement de l'addition : on ne règle que les commandes qui ne le sont
    // pas déjà, pour ne jamais compter un montant deux fois en caisse.
    final unpaidDocs = orderDocs.where((doc) {
      return (doc.data()?['paymentStatus']?.toString() ?? '') != 'paid';
    }).toList();

    if (unpaidDocs.isEmpty) {
      return true;
    }

    final unpaidOrderIds = unpaidDocs.map((doc) => doc.id).toSet();

    final unpaidTotal = _ticket.orders
        .where((order) => unpaidOrderIds.contains(order.id))
        .fold<double>(0, (running, order) => running + order.total);

    if (!mounted) return false;

    final auth = context.read<AuthController>();

    final paymentController = context.read<PaymentController>();

    final user = auth.currentUser;

    if (user == null) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errUserNotFound),
        ),
      );

      return false;
    }

    final success = await paymentController.registerTicketPayment(
      establishmentId: establishmentId,
      ticketId: _ticket.ticketId,
      orderIds: unpaidOrderIds.toList(),
      receivedBy: user.uid,
      receivedByName: user.name,
      method: selectedPaymentMethod,
      amount: unpaidTotal,
    );

    if (!mounted) return false;

    if (!success && paymentController.hasError) {
      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(paymentController.errorText(l10n)!)),
      );
    }

    return success;
  }

  Future<void> _printNormalInvoice(
    List<Map<String, dynamic>> items,
    Map<String, dynamic>? orderDoc,
  ) async {
    setState(() {
      isPrintingOrPaying = true;
    });

    try {
      await _saveClientInfo();

      final paid = await _ensurePaymentRegistered();

      if (!paid) return;

      if (!mounted) return;

      final pdfService = context.read<PdfService>();

      final printer = context.read<PrinterService>();

      final bytes = await pdfService.buildConsumptionTicketV2(
        certified: false,
        sellerName: _sellerName,
        sellerIfu: _sellerIfu,
        sellerAddress: _sellerAddress,
        logo: _sellerLogo,
        clientName: clientNameController.text.trim().isEmpty
            ? _ticket.label
            : clientNameController.text.trim(),
        reference: _ticket.reference,
        lines: items,
        total: _ticket.total,
      );
      await printer.printPdf(Uint8List.fromList(bytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).simpleInvoicePrinted),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isPrintingOrPaying = false;
        });
      }
    }
  }

  EmcfInvoiceRequestModel _buildEmcfRequest(
    List<Map<String, dynamic>> items,
    String operatorName,
    String operatorId,
  ) {
    String mapPaymentMethod(String value) {
      switch (value) {
        case AppPaymentMethods.mobileMoney:
          return 'MOBILEMONEY';

        case AppPaymentMethods.bankTransfer:
          return 'VIREMENT';

        case AppPaymentMethods.card:
          return 'CARTEBANCAIRE';

        case AppPaymentMethods.credit:
          return 'CREDIT';

        case AppPaymentMethods.beninResto:
          return 'BENIN_RESTO';

        default:
          return 'ESPECES';
      }
    }

    final emcfItems = items.map((item) {
      return EmcfInvoiceItemModel(
        code: item['id']?.toString() ?? '',
        name: item['name']?.toString() ?? '',
        price: ((item['unitPrice'] ?? 0) as num).round(),
        quantity: ((item['quantity'] ?? 0) as num).toDouble(),
        taxGroup: item['taxGroup']?.toString() ?? 'B',
      );
    }).toList();

    return EmcfInvoiceRequestModel(
      ifu: _sellerIfu, // ← au lieu de EmcfConfig.sellerIfu
      type: 'FV',
      items: emcfItems,
      client: {
        'ifu': clientIfuController.text.trim(),
        'name': clientNameController.text.trim(),
        'contact': '',
        'address': clientAddressController.text.trim(),
      },
      operatorData: {'id': operatorId, 'name': operatorName},
      payment: [
        {
          'name': mapPaymentMethod(selectedPaymentMethod),
          'amount': _ticket.total.round(),
        },
      ],
    );
  }

  Future<void> _fiscalize(
    List<Map<String, dynamic>> items,
    Map<String, dynamic>? orderDoc,
  ) async {
    final isFiscalized =
        orderDoc?['isFiscalized'] == true &&
        (orderDoc?['fiscalStatus']?.toString() == 'success');

    if (isFiscalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invoiceAlreadyCertified),
        ),
      );

      return;
    }

    setState(() {
      isPrintingOrPaying = true;
    });

    try {
      await _saveClientInfo();

      if (!mounted) return;

      final auth = context.read<AuthController>();

      final fiscalController = context.read<FiscalizationController>();

      final user = auth.currentUser;

      final l10n = AppLocalizations.of(context);

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errUserNotFound)));

        return;
      }

      if (_sellerIfu.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fillEstablishmentIfuFirst)),
        );
        return;
      }

      final request = _buildEmcfRequest(items, user.name, user.uid);

      await fiscalController.fiscalizeInvoice(
        establishmentId: establishmentId,
        invoiceId: _ticket.primaryOrder.id,
        request: request,
        persistToInvoice: false,
      );

      if (!mounted) return;

      if (fiscalController.confirmResult != null &&
          !fiscalController.confirmResult!.hasError) {
        // La certification porte sur l'addition entière : on l'inscrit sur
        // chacune de ses commandes.
        final batch = _firestore.batch();

        for (final ref in _orderRefs) {
          batch.update(ref, {
            'establishmentId': establishmentId,
            'isFiscalized': true,
            'fiscalStatus': 'success',
            'fiscalTicketId': _ticket.ticketId,
            'fiscalMecefCode': fiscalController.confirmResult!.codeMECeFDGI,
            'fiscalQrCode': fiscalController.confirmResult!.qrCode,
            'fiscalNim': fiscalController.confirmResult!.nim,
            'fiscalCounter': fiscalController.confirmResult!.counters,
            'fiscalMachineDateTime': fiscalController.confirmResult!.dateTime,
          });
        }

        await batch.commit();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.invoiceFiscalizedWithCode(
                fiscalController.confirmResult!.codeMECeFDGI,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fiscalController.errorText(l10n) ?? l10n.errCertificationFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPrintingOrPaying = false;
        });
      }
    }
  }

  Future<void> _printFiscalizedInvoice(
    List<Map<String, dynamic>> items,
    Map<String, dynamic>? orderDoc,
  ) async {
    final isFiscalized =
        orderDoc?['isFiscalized'] == true &&
        (orderDoc?['fiscalStatus']?.toString() == 'success');

    if (!isFiscalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).fiscalizeInvoiceFirst),
        ),
      );

      return;
    }

    setState(() {
      isPrintingOrPaying = true;
    });

    try {
      await _saveClientInfo();

      final paid = await _ensurePaymentRegistered();

      if (!paid) return;

      if (!mounted) return;

      final pdfService = context.read<PdfService>();

      final printer = context.read<PrinterService>();

      final bytes = await pdfService.buildConsumptionTicketV2(
        certified: true,
        sellerName: _sellerName,
        sellerIfu: _sellerIfu,
        sellerAddress: _sellerAddress,
        logo: _sellerLogo,
        clientName: clientNameController.text.trim().isEmpty
            ? _ticket.label
            : clientNameController.text.trim(),
        clientIfu: clientIfuController.text.trim(),
        reference: _ticket.reference,
        lines: items,
        total: _ticket.total,
        paymentMethodLabel:
            AppPaymentMethods.labels[selectedPaymentMethod] ??
            selectedPaymentMethod,
        codeMECeFDGI: orderDoc?['fiscalMecefCode']?.toString() ?? '',
        qrCode: orderDoc?['fiscalQrCode']?.toString() ?? '',
        nim: orderDoc?['fiscalNim']?.toString() ?? '',
        counters: orderDoc?['fiscalCounter']?.toString() ?? '',
        fiscalDateTime: orderDoc?['fiscalMachineDateTime']?.toString() ?? '',
        fiscalRawCreateResponse:
            orderDoc?['fiscalRawConfirmResponse']?.toString() ?? '',
      );

      await printer.printPdf(Uint8List.fromList(bytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).normalizedInvoicePrinted),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isPrintingOrPaying = false;
        });
      }
    }
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _orderStream = _primaryOrderRef.snapshots();
    _itemsFuture = _loadItems();
    _loadSellerInfo();
  }

  @override
  void dispose() {
    clientNameController.dispose();
    clientAddressController.dispose();
    clientIfuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.consumptionDetailsTitle)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _orderStream,
        builder: (context, orderSnapshot) {
          final orderDoc = orderSnapshot.data?.data();

          final isFiscalized =
              orderDoc?['isFiscalized'] == true &&
              (orderDoc?['fiscalStatus']?.toString() == 'success');

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _itemsFuture,
            builder: (context, itemSnapshot) {
              if (itemSnapshot.connectionState == ConnectionState.waiting ||
                  orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = itemSnapshot.data ?? [];

              final activeItems = items
                  .where((item) => item['isCancelled'] != true)
                  .toList();

              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    _isSmall ? 12 : 16,
                    _isSmall ? 12 : 16,
                    _isSmall ? 12 : 16,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFiscalized)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            l10n.certifiedInvoiceBadge,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(l10n.generalInformation),
                              _infoRow(
                                l10n.clientFallback,
                                _ticket.labelFor(l10n),
                                bold: true,
                              ),
                              _infoRow(
                                _ticket.isMultiOrder
                                    ? l10n.labelOrders
                                    : l10n.labelOrder,
                                _ticket.orderNumbers.join('\n'),
                              ),
                              _infoRow(
                                l10n.labelDate,
                                _formatDate(_ticket.openedAt),
                              ),
                              _infoRow(
                                l10n.labelType,
                                _ticket.primaryOrder.clientType.toUpperCase(),
                              ),
                              _infoRow(
                                l10n.labelAmount,
                                '${_ticket.total.toStringAsFixed(0)} FCFA',
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(l10n.clientInfoOptional),

                              TextField(
                                controller: clientNameController,
                                decoration: InputDecoration(
                                  labelText: l10n.clientNameLabel,
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(
                                controller: clientAddressController,
                                decoration: InputDecoration(
                                  labelText: l10n.clientAddressLabel,
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(
                                controller: clientIfuController,
                                decoration: InputDecoration(
                                  labelText: l10n.clientIfuLabel,
                                ),
                              ),

                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                initialValue: selectedPaymentMethod,
                                decoration: InputDecoration(
                                  labelText: l10n.paymentMethodLabel,
                                ),
                                items: AppPaymentMethods.labels.entries
                                    .map(
                                      (entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    selectedPaymentMethod = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(l10n.consumedItems),

                              ...activeItems.map((item) {
                                final quantity = (item['quantity'] ?? 0) as int;

                                final unitPrice =
                                    (item['unitPrice'] ?? 0) as double;

                                final total = (item['total'] ?? 0) as double;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name']?.toString() ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(l10n.quantityLine('$quantity')),

                                        Text(
                                          l10n.unitPriceLine(
                                            unitPrice.toStringAsFixed(0),
                                          ),
                                        ),

                                        Text(
                                          l10n.totalLine(
                                            total.toStringAsFixed(0),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_isSmall)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: (isPrintingOrPaying)
                                    ? null
                                    : () {
                                        if (isFiscalized) {
                                          _printFiscalizedInvoice(
                                            activeItems,
                                            orderDoc,
                                          );
                                        } else {
                                          _fiscalize(activeItems, orderDoc);
                                        }
                                      },
                                icon: isPrintingOrPaying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        isFiscalized
                                            ? Icons.verified_outlined
                                            : Icons.verified,
                                      ),
                                label: Text(
                                  isFiscalized
                                      ? l10n.actionPrintNormalizedInvoice
                                      : l10n.actionFiscalize,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: (isPrintingOrPaying)
                                    ? null
                                    : () => _printNormalInvoice(
                                        activeItems,
                                        orderDoc,
                                      ),
                                icon: isPrintingOrPaying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.print_outlined),
                                label: Text(l10n.actionPrintSimpleInvoice),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (isPrintingOrPaying)
                                    ? null
                                    : () {
                                        if (isFiscalized) {
                                          _printFiscalizedInvoice(
                                            activeItems,
                                            orderDoc,
                                          );
                                        } else {
                                          _fiscalize(activeItems, orderDoc);
                                        }
                                      },
                                icon: isPrintingOrPaying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        isFiscalized
                                            ? Icons.verified_outlined
                                            : Icons.verified,
                                      ),
                                label: Text(
                                  isFiscalized
                                      ? l10n.actionPrintNormalizedInvoice
                                      : l10n.actionFiscalize,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: (isPrintingOrPaying)
                                    ? null
                                    : () => _printNormalInvoice(
                                        activeItems,
                                        orderDoc,
                                      ),
                                icon: isPrintingOrPaying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.print_outlined),
                                label: Text(l10n.actionPrintSimpleInvoice),
                              ),
                            ),
                          ],
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
