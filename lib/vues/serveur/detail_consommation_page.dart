import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/fiscalization_controller.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/modeles/emcf_invoice_item_model.dart';
import 'package:takapp/modeles/emcf_invoice_request_model.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';

class DetailConsommationPage extends StatefulWidget {
  final String establishmentId;
  final OrderModel order;

  const DetailConsommationPage({
    super.key,
    required this.establishmentId,
    required this.order,
  });

  @override
  State<DetailConsommationPage> createState() => _DetailConsommationPageState();
}

class _DetailConsommationPageState extends State<DetailConsommationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _sellerIfu = '';
  String _sellerName = "";

  final TextEditingController clientNameController = TextEditingController();

  final TextEditingController clientAddressController = TextEditingController();

  final TextEditingController clientIfuController = TextEditingController();

  String selectedPaymentMethod = AppPaymentMethods.cash;

  bool isPrintingOrPaying = false;

  bool get _isSmall => MediaQuery.of(context).size.width < 800;

  String get establishmentId => widget.establishmentId.trim();

  DocumentReference<Map<String, dynamic>> get _orderRef {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders')
        .doc(widget.order.id);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _loadSellerIfu() async {
    final doc = await _firestore
        .collection('establishments')
        .doc(establishmentId)
        .get();
    _sellerIfu = (doc.data()?['ifu'] ?? '').toString().trim();
  }

  Future<void> _loadSellerName() async {
    final doc = await _firestore
        .collection('establishments')
        .doc(establishmentId)
        .get();
    _sellerName = (doc.data()?['name'] ?? '').toString().trim();
  }

  String _clientLabel(OrderModel order) {
    switch (order.clientType) {
      case 'restaurant':
        return 'Table ${order.tableNumber ?? "-"}';

      case 'hotel':
        return 'Chambre ${order.roomNumber ?? "-"}';

      case 'bar':
        return 'Client Bar';

      default:
        return order.clientType;
    }
  }

  Future<List<Map<String, dynamic>>> _loadItems({
    bool includeCancelled = true,
  }) async {
    final snapshot = await _orderRef.collection('items').get();

    return snapshot.docs
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

  Future<Map<String, dynamic>?> _getOrderDoc() async {
    final doc = await _orderRef.get();

    return doc.data();
  }

  Future<void> _saveClientInfo() async {
    await _orderRef.update({
      'invoiceClientName': clientNameController.text.trim(),
      'invoiceClientAddress': clientAddressController.text.trim(),
      'invoiceClientIfu': clientIfuController.text.trim(),
      'establishmentId': establishmentId,
    });
  }

  Future<bool> _ensurePaymentRegistered() async {
    final orderDoc = await _getOrderDoc();

    final paymentStatus = orderDoc?['paymentStatus']?.toString() ?? '';

    if (paymentStatus == 'paid') {
      return true;
    }

    final auth = context.read<AuthController>();

    final paymentController = context.read<PaymentController>();

    final user = auth.currentUser;

    if (user == null) {
      if (!mounted) return false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));

      return false;
    }

    final success = await paymentController.registerPayment(
      establishmentId: establishmentId,
      orderId: widget.order.id,
      orderNumber: widget.order.orderNumber,
      receivedBy: user.uid,
      receivedByName: user.name,
      method: selectedPaymentMethod,
      amount: widget.order.total,
    );

    if (!mounted) return false;

    if (!success && paymentController.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(paymentController.errorMessage!)));
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

      final pdfService = context.read<PdfService>();

      final printer = context.read<PrinterService>();

      final bytes = await pdfService.buildConsumptionInvoicePdf(
        clientName: clientNameController.text.trim().isEmpty
            ? _clientLabel(widget.order)
            : clientNameController.text.trim(),
        roomNumber: widget.order.roomNumber ?? widget.order.tableNumber ?? '-',
        lines: items,
        total: widget.order.total,
      );

      await printer.printPdf(Uint8List.fromList(bytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facture simple imprimée et encaissement enregistré.'),
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
          'amount': widget.order.total.round(),
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
        const SnackBar(content: Text('Cette facture est déjà certifiée.')),
      );

      return;
    }

    setState(() {
      isPrintingOrPaying = true;
    });

    try {
      await _saveClientInfo();

      final auth = context.read<AuthController>();

      final fiscalController = context.read<FiscalizationController>();

      final user = auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur introuvable.')),
        );

        return;
      }

      if (_sellerIfu.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Renseignez d'abord l'IFU de l'établissement (console admin).",
            ),
          ),
        );
        return;
      }

      final request = _buildEmcfRequest(items, user.name, user.uid);

      await fiscalController.fiscalizeInvoice(
        establishmentId: establishmentId,
        invoiceId: widget.order.id,
        request: request,
      );

      if (!mounted) return;

      if (fiscalController.confirmResult != null &&
          !fiscalController.confirmResult!.hasError) {
        await _orderRef.update({
          'establishmentId': establishmentId,
          'isFiscalized': true,
          'fiscalStatus': 'success',
          'fiscalMecefCode': fiscalController.confirmResult!.codeMECeFDGI,
          'fiscalQrCode': fiscalController.confirmResult!.qrCode,
          'fiscalNim': fiscalController.confirmResult!.nim,
          'fiscalCounter': fiscalController.confirmResult!.counters,
          'fiscalMachineDateTime': fiscalController.confirmResult!.dateTime,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Facture fiscalisée avec certilink. Code MECeF : ${fiscalController.confirmResult!.codeMECeFDGI}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fiscalController.errorMessage ?? 'Échec de certification',
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
        const SnackBar(content: Text('Fiscalisez d’abord la facture.')),
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

      final pdfService = context.read<PdfService>();

      final printer = context.read<PrinterService>();

      final bytes = await pdfService.buildFiscalizedConsumptionInvoicePdf(
        sellerName: _sellerName,
        sellerIfu: _sellerIfu,
        clientName: clientNameController.text.trim().isEmpty
            ? _clientLabel(widget.order)
            : clientNameController.text.trim(),
        clientIfu: clientIfuController.text.trim(),
        clientAddress: clientAddressController.text.trim(),
        clientPhone: '',
        roomNumber: widget.order.roomNumber ?? widget.order.tableNumber ?? '-',
        lines: items,
        total: widget.order.total,
        paymentMethodLabel:
            AppPaymentMethods.labels[selectedPaymentMethod] ??
            selectedPaymentMethod,
        invoiceTypeLabel: 'FV',
        codeMECeFDGI: orderDoc?['fiscalMecefCode']?.toString() ?? '',
        qrCode: orderDoc?['fiscalQrCode']?.toString() ?? '',
        nim: orderDoc?['fiscalNim']?.toString() ?? '',
        counters: orderDoc?['fiscalCounter']?.toString() ?? '',
        fiscalDateTime: orderDoc?['fiscalMachineDateTime']?.toString() ?? '',
        fiscalStatusLabel: orderDoc?['fiscalStatus']?.toString() ?? 'success',
      );

      await printer.printPdf(Uint8List.fromList(bytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Facture normalisée imprimée et encaissement enregistré.',
          ),
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
    _loadSellerIfu();
    _loadSellerName();
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
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la Consommation')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _orderRef.snapshots(),
        builder: (context, orderSnapshot) {
          final orderDoc = orderSnapshot.data?.data();

          final isFiscalized =
              orderDoc?['isFiscalized'] == true &&
              (orderDoc?['fiscalStatus']?.toString() == 'success');

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadItems(),
            builder: (context, itemSnapshot) {
              if (itemSnapshot.connectionState == ConnectionState.waiting ||
                  orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = itemSnapshot.data ?? [];

              final activeItems = items
                  .where((item) => item['isCancelled'] != true)
                  .toList();

              return SingleChildScrollView(
                padding: EdgeInsets.all(_isSmall ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFiscalized)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'FACTURE CERTIFIEE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                            _sectionTitle('Informations générales'),
                            _infoRow(
                              'Commande',
                              widget.order.orderNumber,
                              bold: true,
                            ),
                            _infoRow(
                              'Date',
                              _formatDate(widget.order.createdAt),
                            ),
                            _infoRow('Client', _clientLabel(widget.order)),
                            _infoRow(
                              'Type',
                              widget.order.clientType.toUpperCase(),
                            ),
                            _infoRow(
                              'Montant',
                              '${widget.order.total.toStringAsFixed(0)} FCFA',
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
                            _sectionTitle('Informations client (facultatives)'),

                            TextField(
                              controller: clientNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nom du client',
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: clientAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse du client',
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: clientIfuController,
                              decoration: const InputDecoration(
                                labelText: 'IFU du client',
                              ),
                            ),

                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value: selectedPaymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Mode de paiement',
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
                            _sectionTitle('Articles consommés'),

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

                                      Text('Qté : $quantity'),

                                      Text(
                                        'P.U : ${unitPrice.toStringAsFixed(0)} FCFA',
                                      ),

                                      Text(
                                        'Total : ${total.toStringAsFixed(0)} FCFA',
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
                                ? 'Imprimer facture normalisée'
                                : 'Fiscaliser',
                          ),
                        ),
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
                                    ? 'Imprimer facture normalisée'
                                    : 'Fiscaliser',
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
                              label: const Text('Imprimer facture simple'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
