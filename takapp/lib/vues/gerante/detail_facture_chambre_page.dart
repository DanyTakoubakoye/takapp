import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/fiscalization_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/emcf_invoice_item_model.dart';
import 'package:takapp/modeles/emcf_invoice_request_model.dart';
import 'package:takapp/modeles/room_invoice_model.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';
import 'package:takapp/services/room_invoice_service.dart';

class DetailFactureChambrePage extends StatefulWidget {
  final RoomInvoiceModel invoice;
  final String establishmentId;

  const DetailFactureChambrePage({
    super.key,
    required this.establishmentId,
    required this.invoice,
  });

  @override
  State<DetailFactureChambrePage> createState() =>
      _DetailFactureChambrePageState();
}

class _DetailFactureChambrePageState extends State<DetailFactureChambrePage> {
  final RoomInvoiceService _service = RoomInvoiceService();
  String _sellerIfu = '';
  String _sellerName = "";
  String _sellerAddress = '';
  String _sellerLogo = '';
  String get establishmentId => widget.establishmentId.trim();

  late RoomInvoiceModel currentInvoice;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    currentInvoice = widget.invoice;
    _loadSellerInfo();
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  bool get isFiscalized =>
      currentInvoice.isFiscalized &&
      currentInvoice.fiscalStatus == 'success' &&
      currentInvoice.fiscalMecefCode.trim().isNotEmpty;

  String _establishmentId(BuildContext context) {
    final user = context.read<AuthController>().currentUser;
    return user?.establishmentId.trim() ?? '';
  }

  Future<void> _loadSellerInfo() async {
    final doc = await FirebaseFirestore.instance
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

  Future<void> _reloadInvoice(BuildContext context) async {
    final establishmentId = _establishmentId(context);

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final updated = await _service.getInvoiceById(
        establishmentId: establishmentId,
        invoiceId: currentInvoice.id,
      );

      if (!mounted) return;

      if (updated != null) {
        setState(() {
          currentInvoice = updated;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _printClassic(BuildContext context) async {
    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildRoomInvoicePdfV2(
      certified: false,
      sellerName: _sellerName,
      sellerIfu: _sellerIfu,
      sellerAddress: _sellerAddress,
      logo: _sellerLogo,
      clientName: currentInvoice.clientName,
      clientIfu: currentInvoice.clientIfu,
      clientAddress: currentInvoice.clientAddress,
      clientPhone: currentInvoice.clientPhone,
      room: currentInvoice.roomNumber,
      nights: currentInvoice.nights,
      pricePerNight: currentInvoice.pricePerNight,
      extras: currentInvoice.extrasTotal,
      services: currentInvoice.servicesTotal,
      total: currentInvoice.total,
      start: currentInvoice.startDate,
      end: currentInvoice.endDate,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
  }

  Future<void> _printFiscalized(BuildContext context) async {
    if (!isFiscalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette facture n’est pas encore certifiée.'),
        ),
      );
      return;
    }

    if (currentInvoice.startDate == null || currentInvoice.endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dates de facture invalides.')),
      );
      return;
    }

    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildRoomInvoicePdfV2(
      certified: true,
      sellerName: _sellerName,
      sellerIfu: _sellerIfu,
      sellerAddress: _sellerAddress,
      logo: _sellerLogo,
      clientName: currentInvoice.clientName,
      clientIfu: currentInvoice.clientIfu,
      clientAddress: currentInvoice.clientAddress,
      clientPhone: currentInvoice.clientPhone,
      room: currentInvoice.roomNumber,
      nights: currentInvoice.nights,
      pricePerNight: currentInvoice.pricePerNight,
      extras: currentInvoice.extrasTotal,
      services: currentInvoice.servicesTotal,
      total: currentInvoice.total,
      start: currentInvoice.startDate,
      end: currentInvoice.endDate,
      paymentMethodLabel: currentInvoice.paymentMethod,
      invoiceTypeLabel: currentInvoice.fiscalInvoiceType,
      codeMECeFDGI: currentInvoice.fiscalMecefCode,
      qrCode: currentInvoice.fiscalQrCode,
      nim: currentInvoice.fiscalNim,
      counters: currentInvoice.fiscalCounter,
      fiscalDateTime: currentInvoice.fiscalMachineDateTime,
      fiscalRawCreateResponse: currentInvoice.fiscalRawConfirmResponse,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
  }

  EmcfInvoiceRequestModel _buildEmcfRequest(
    String sellerName,
    String operatorId,
  ) {
    String? mapAibType(String value) {
      switch (value) {
        case 'aib1':
          return 'A';
        case 'aib5':
          return 'B';
        default:
          return null;
      }
    }

    String mapPaymentMethod(String value) {
      switch (value) {
        case 'mobile_money':
          return 'MOBILEMONEY';
        case 'bank':
          return 'VIREMENT';
        case 'card':
          return 'CARTEBANCAIRE';
        case 'credit':
          return 'CREDIT';
        case 'cheque':
          return 'CHEQUES';
        default:
          return 'ESPECES';
      }
    }

    final int roomPrice = currentInvoice.pricePerNight.round();
    final int extrasPrice = currentInvoice.extrasTotal.round();
    final int servicesPrice = currentInvoice.servicesTotal.round();

    final items = <EmcfInvoiceItemModel>[
      EmcfInvoiceItemModel(
        code: 'ROOM_NIGHT',
        name: 'Nuitee chambre ${currentInvoice.roomNumber}',
        price: roomPrice,
        quantity: currentInvoice.nights.toDouble(),
        taxGroup: 'B',
      ),
      if (extrasPrice > 0)
        EmcfInvoiceItemModel(
          code: 'HOTEL_EXTRAS',
          name: 'Consommations bar/resto',
          price: extrasPrice,
          quantity: 1,
          taxGroup: 'B',
        ),
      if (servicesPrice > 0)
        EmcfInvoiceItemModel(
          code: 'HOTEL_SERVICES',
          name: 'Autres services',
          price: servicesPrice,
          quantity: 1,
          taxGroup: 'B',
        ),
    ];

    return EmcfInvoiceRequestModel(
      ifu: _sellerIfu,
      aib: mapAibType(currentInvoice.aibType),
      type: currentInvoice.fiscalInvoiceType.isNotEmpty
          ? currentInvoice.fiscalInvoiceType
          : 'FV',
      items: items,
      client: {
        'ifu': currentInvoice.clientIfu,
        'name': currentInvoice.clientName,
        'contact': currentInvoice.clientPhone,
        'address': currentInvoice.clientAddress,
      },
      operatorData: {'id': operatorId, 'name': sellerName},
      payment: [
        {
          'name': mapPaymentMethod(currentInvoice.paymentMethod),
          'amount': currentInvoice.total.round(),
        },
      ],
    );
  }

  Future<void> _fiscalizeInvoice(BuildContext context) async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
      return;
    }

    if (isFiscalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette facture est déjà certifiée.')),
      );
      return;
    }

    final sellerName = user.name.isNotEmpty ? user.name : 'Operateur';
    final operatorId = user.uid;

    final request = _buildEmcfRequest(sellerName, operatorId);

    final fiscalController = context.read<FiscalizationController>();

    await fiscalController.fiscalizeInvoice(
      establishmentId: establishmentId,
      invoiceId: currentInvoice.id,
      request: request,
    );

    if (!mounted) return;

    if (fiscalController.confirmResult != null &&
        !fiscalController.confirmResult!.hasError) {
      await _reloadInvoice(this.context);

      if (!mounted) return;

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            'Facture certifiée avec Certilink Code MECeF : ${fiscalController.confirmResult!.codeMECeFDGI}',
          ),
        ),
      );
    } else {
      final l10n = AppLocalizations.of(this.context);

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            fiscalController.errorText(l10n) ?? l10n.errFiscalizationFailed,
          ),
        ),
      );
    }
  }

  Widget row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fiscalController = context.watch<FiscalizationController>();
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    if (user.establishmentId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail facture chambre'),
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : () => _reloadInvoice(context),
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _printClassic(context),
            icon: const Icon(Icons.print),
            tooltip: 'Impression classique',
          ),
          if (isFiscalized)
            IconButton(
              onPressed: () => _printFiscalized(context),
              icon: const Icon(Icons.verified),
              tooltip: 'Impression normalisée',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                row('Client', currentInvoice.clientName, bold: true),
                row(
                  'IFU client',
                  currentInvoice.clientIfu.isEmpty
                      ? '-'
                      : currentInvoice.clientIfu,
                ),
                row(
                  'Adresse',
                  currentInvoice.clientAddress.isEmpty
                      ? '-'
                      : currentInvoice.clientAddress,
                ),
                row(
                  'Téléphone',
                  currentInvoice.clientPhone.isEmpty
                      ? '-'
                      : currentInvoice.clientPhone,
                ),
                row('Chambre', currentInvoice.roomNumber),
                row('Entrée', formatDate(currentInvoice.startDate)),
                row('Sortie', formatDate(currentInvoice.endDate)),
                row('Nuitées', '${currentInvoice.nights}'),
                row(
                  'Prix / nuit',
                  '${currentInvoice.pricePerNight.toStringAsFixed(0)} FCFA',
                ),
                row(
                  'Chambre',
                  '${currentInvoice.roomTotal.toStringAsFixed(0)} FCFA',
                ),
                row(
                  'Extras',
                  '${currentInvoice.extrasTotal.toStringAsFixed(0)} FCFA',
                ),
                row(
                  'Services',
                  '${currentInvoice.servicesTotal.toStringAsFixed(0)} FCFA',
                ),
                const Divider(),
                row(
                  'TOTAL',
                  '${currentInvoice.total.toStringAsFixed(0)} FCFA',
                  bold: true,
                ),
                row('Statut paiement', currentInvoice.status),
                row(
                  'Statut fiscal',
                  isFiscalized ? 'Certifiée' : 'Non certifiée',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildStatusChip(
                      currentInvoice.status == 'paid' ? 'Payée' : 'Non payée',
                      currentInvoice.status == 'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    _buildStatusChip(
                      isFiscalized ? 'Certifiée' : 'Non certifiée',
                      isFiscalized ? Colors.blue : Colors.red,
                    ),
                  ],
                ),
                if (isFiscalized) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  row('Code MECeF', currentInvoice.fiscalMecefCode),
                  row('NIM', currentInvoice.fiscalNim),
                  row('Compteurs', currentInvoice.fiscalCounter),
                  row(
                    'Date fiscale',
                    currentInvoice.fiscalMachineDateTime.isEmpty
                        ? '-'
                        : currentInvoice.fiscalMachineDateTime,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _printClassic(context),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimer en mode classique'),
                  ),
                ),
                const SizedBox(height: 10),
                if (isFiscalized)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _printFiscalized(context),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Imprimer en mode normalisé'),
                    ),
                  ),
                if (!isFiscalized) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: fiscalController.isLoading
                          ? null
                          : () => _fiscalizeInvoice(context),
                      icon: fiscalController.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified),
                      label: const Text('Fiscaliser avec Certilink'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
