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

class ListeFacturesPage extends StatefulWidget {
  final String establishmentId;

  const ListeFacturesPage({super.key, required this.establishmentId});

  @override
  State<ListeFacturesPage> createState() => _ListeFacturesPageState();
}

class _ListeFacturesPageState extends State<ListeFacturesPage> {
  final RoomInvoiceService _service = RoomInvoiceService();
  final TextEditingController searchController = TextEditingController();

  // Valeur technique : comparée au `status` tel qu'il est stocké.
  String statusFilter = 'all';

  String get establishmentId => widget.establishmentId.trim();

  // Créé une seule fois : chaque frappe dans la recherche déclenche un
  // setState, et un stream recréé remettrait la liste en chargement.
  late final Stream<List<RoomInvoiceModel>> _invoicesStream;

  String _sellerIfu = '';
  String _sellerName = "";
  String _sellerAddress = "";
  String _sellerLogo = '';

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  @override
  void initState() {
    super.initState();
    _invoicesStream = _service.streamInvoices(establishmentId: establishmentId);
    _loadSellerInfo();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _printInvoice(RoomInvoiceModel item) async {
    if (item.startDate == null || item.endDate == null) return;

    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildRoomInvoicePdfV2(
      certified: false,
      sellerName: _sellerName,
      sellerIfu: _sellerIfu,
      sellerAddress: _sellerAddress,
      logo: _sellerLogo,
      clientName: item.clientName,
      clientIfu: item.clientIfu,
      clientAddress: item.clientAddress,
      clientPhone: item.clientPhone,
      room: item.roomNumber,
      nights: item.nights,
      pricePerNight: item.pricePerNight,
      extras: item.extrasTotal,
      services: item.servicesTotal,
      total: item.total,
      start: item.startDate,
      end: item.endDate,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
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

  Future<void> _printFiscalizedInvoice(RoomInvoiceModel item) async {
    final l10n = AppLocalizations.of(context);

    if (item.startDate == null || item.endDate == null) {
      _showSnack(l10n.errInvoiceDatesInvalid);
      return;
    }

    if (!item.isFiscalized ||
        item.fiscalMecefCode.trim().isEmpty ||
        item.fiscalQrCode.trim().isEmpty) {
      _showSnack(l10n.errInvoiceNotFiscalizedYet);
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
      clientName: item.clientName,
      clientIfu: item.clientIfu,
      clientAddress: item.clientAddress,
      clientPhone: item.clientPhone,
      room: item.roomNumber,
      nights: item.nights,
      pricePerNight: item.pricePerNight,
      extras: item.extrasTotal,
      services: item.servicesTotal,
      total: item.total,
      start: item.startDate,
      end: item.endDate,
      paymentMethodLabel: item.paymentMethod,
      invoiceTypeLabel: item.fiscalInvoiceType,
      codeMECeFDGI: item.fiscalMecefCode,
      qrCode: item.fiscalQrCode,
      nim: item.fiscalNim,
      counters: item.fiscalCounter,
      fiscalDateTime: item.fiscalMachineDateTime,
      fiscalRawCreateResponse: item.fiscalRawConfirmResponse,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
  }

  // Les valeurs envoyées à CertiLink sont des codes de l'API fiscale :
  // elles ne sont jamais traduites.
  EmcfInvoiceRequestModel _buildEmcfRequestForItem(
    RoomInvoiceModel item,
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

    final int roomPrice = item.pricePerNight.round();
    final int extrasPrice = item.extrasTotal.round();
    final int servicesPrice = item.servicesTotal.round();

    final items = <EmcfInvoiceItemModel>[
      EmcfInvoiceItemModel(
        code: 'ROOM_NIGHT',
        name: 'Nuitee chambre ${item.roomNumber}',
        price: roomPrice,
        quantity: item.nights.toDouble(),
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
      aib: mapAibType(item.aibType),
      type: item.fiscalInvoiceType.isNotEmpty ? item.fiscalInvoiceType : 'FV',
      items: items,
      client: {
        'ifu': item.clientIfu,
        'name': item.clientName,
        'contact': item.clientPhone,
        'address': item.clientAddress,
      },
      operatorData: {'id': operatorId, 'name': sellerName},
      payment: [
        {
          'name': mapPaymentMethod(item.paymentMethod),
          'amount': item.total.round(),
        },
      ],
    );
  }

  Future<void> _fiscalizeExistingInvoice(RoomInvoiceModel item) async {
    final l10n = AppLocalizations.of(context);

    if (establishmentId.isEmpty) {
      _showSnack(l10n.errEstablishmentNotFound);
      return;
    }

    if (_sellerIfu.isEmpty) {
      _showSnack(l10n.errSetIfuFirst);
      return;
    }

    if (item.isFiscalized) {
      _showSnack(l10n.errInvoiceAlreadyFiscalized);
      return;
    }

    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      _showSnack(l10n.errUserNotFound);
      return;
    }

    // Valeur transmise à CertiLink en cas de nom manquant : non traduite.
    final sellerName = user.name.isNotEmpty ? user.name : 'Operateur';
    final operatorId = user.uid;

    final request = _buildEmcfRequestForItem(item, sellerName, operatorId);

    final fiscalController = context.read<FiscalizationController>();

    await fiscalController.fiscalizeInvoice(
      establishmentId: establishmentId,
      invoiceId: item.id,
      request: request,
    );

    if (!mounted) return;

    if (fiscalController.confirmResult != null &&
        !fiscalController.confirmResult!.hasError) {
      _showSnack(
        l10n.invoiceFiscalizedWithCode(
          fiscalController.confirmResult!.codeMECeFDGI,
        ),
      );
    } else {
      _showSnack(
        fiscalController.errorText(l10n) ?? l10n.errFiscalizationFailed,
      );
    }
  }

  Widget _buildStatusChip(AppLocalizations l10n, RoomInvoiceModel item) {
    // `status` reste la valeur technique stockée : seul le rendu est localisé.
    final isPaid = item.status == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? l10n.statusPaidShort : l10n.statusUnpaidShort,
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFiscalChip(AppLocalizations l10n, RoomInvoiceModel item) {
    final bool ok = item.isFiscalized && item.fiscalStatus == 'success';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok
            ? Colors.blue.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ok ? l10n.statusFiscalized : l10n.statusNotFiscalized,
        style: TextStyle(
          color: ok ? Colors.blue : Colors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Les `value` des options restent techniques : seul le libellé est traduit.
  List<DropdownMenuItem<String>> _statusFilterItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem(value: 'all', child: Text(l10n.filterAllInvoices)),
      DropdownMenuItem(value: 'paid', child: Text(l10n.filterPaid)),
      DropdownMenuItem(value: 'unpaid', child: Text(l10n.filterUnpaid)),
    ];
  }

  Widget _buildFilters(AppLocalizations l10n, bool isSmall) {
    if (isSmall) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: l10n.searchClientOrRoom,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: statusFilter,
                decoration: InputDecoration(labelText: l10n.labelStatus),
                items: _statusFilterItems(l10n),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    statusFilter = value;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: l10n.searchClientOrRoom,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: statusFilter,
                decoration: InputDecoration(labelText: l10n.labelStatus),
                items: _statusFilterItems(l10n),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    statusFilter = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    AppLocalizations l10n,
    RoomInvoiceModel item,
    DateFormat dateFormat,
    bool isSmall,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.clientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(l10n.roomLine(item.roomNumber)),
            Text(
              l10n.periodLine(
                item.startDate == null
                    ? '-'
                    : dateFormat.format(item.startDate!),
                item.endDate == null ? '-' : dateFormat.format(item.endDate!),
              ),
            ),
            Text(l10n.totalLine(item.total.toStringAsFixed(0))),
            const SizedBox(height: 8),
            if (isSmall) ...[
              _buildStatusChip(l10n, item),
              const SizedBox(height: 8),
              _buildFiscalChip(l10n, item),
            ] else
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildStatusChip(l10n, item),
                  _buildFiscalChip(l10n, item),
                ],
              ),
            const SizedBox(height: 12),
            if (item.isFiscalized &&
                item.fiscalMecefCode.trim().isNotEmpty) ...[
              Text(
                l10n.mecefCodeLine(item.fiscalMecefCode),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (item.status != 'paid')
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _service.markAsPaid(
                          establishmentId: establishmentId,
                          invoiceId: item.id,
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l10n.actionMarkPaid),
                    ),
                  if (!item.isFiscalized)
                    Consumer<FiscalizationController>(
                      builder: (context, fiscalController, _) {
                        return ElevatedButton.icon(
                          onPressed: fiscalController.isLoading
                              ? null
                              : () => _fiscalizeExistingInvoice(item),
                          icon: fiscalController.isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.verified),
                          label: Text(l10n.actionFiscalize),
                        );
                      },
                    ),
                  if (item.isFiscalized)
                    OutlinedButton.icon(
                      onPressed: () => _printFiscalizedInvoice(item),
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(l10n.actionPrintNormalized),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _printInvoice(item),
                    icon: const Icon(Icons.print_outlined),
                    label: Text(l10n.actionPrint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isSmall = _isSmallScreen(context);

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.errUserNotFound)));
    }

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.roomInvoicesListTitle)),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          children: [
            _buildFilters(l10n, isSmall),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<RoomInvoiceModel>>(
                stream: _invoicesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l10n.errorPrefixed('${snapshot.error}')),
                    );
                  }

                  final allItems = snapshot.data ?? [];
                  final query = searchController.text.trim().toLowerCase();

                  final items = allItems.where((item) {
                    final matchSearch =
                        item.clientName.toLowerCase().contains(query) ||
                        item.roomNumber.toLowerCase().contains(query);

                    final matchStatus = statusFilter == 'all'
                        ? true
                        : item.status == statusFilter;

                    return matchSearch && matchStatus;
                  }).toList();

                  if (items.isEmpty) {
                    return Center(child: Text(l10n.noInvoiceFound));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _buildInvoiceCard(
                        context,
                        l10n,
                        item,
                        dateFormat,
                        isSmall,
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
