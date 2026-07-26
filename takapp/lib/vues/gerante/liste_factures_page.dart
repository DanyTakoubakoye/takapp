import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/fiscalization_controller.dart';
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

  String statusFilter = 'all';

  String get establishmentId => widget.establishmentId.trim();
  String _sellerIfu = '';
  String _sellerName = "";
  String _sellerAddress = "";
  String _sellerLogo = '';

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  @override
  void initState() {
    super.initState();
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
    if (item.startDate == null || item.endDate == null) {
      _showSnack('Les dates de la facture sont invalides.');
      return;
    }

    if (!item.isFiscalized ||
        item.fiscalMecefCode.trim().isEmpty ||
        item.fiscalQrCode.trim().isEmpty) {
      _showSnack('Cette facture n’est pas encore fiscalisée.');
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
    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
      return;
    }

    if (_sellerIfu.isEmpty) {
      _showSnack(
        "Renseignez d'abord l'IFU de l'établissement (console admin).",
      );
      return;
    }

    if (item.isFiscalized) {
      _showSnack('Cette facture est déjà fiscalisée.');
      return;
    }

    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      _showSnack('Utilisateur introuvable.');
      return;
    }

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
        'Facture fiscalisée. Code MECeF : ${fiscalController.confirmResult!.codeMECeFDGI}',
      );
    } else {
      _showSnack(fiscalController.errorMessage ?? 'Échec de fiscalisation');
    }
  }

  Widget _buildStatusChip(RoomInvoiceModel item) {
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
        isPaid ? 'Payée' : 'Non payée',
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFiscalChip(RoomInvoiceModel item) {
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
        ok ? 'Fiscalisée' : 'Non fiscalisée',
        style: TextStyle(
          color: ok ? Colors.blue : Colors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFilters(bool isSmall) {
    if (isSmall) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Recherche client / chambre',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: statusFilter,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'paid', child: Text('Payées')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Non payées')),
                ],
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
                decoration: const InputDecoration(
                  labelText: 'Recherche client / chambre',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: statusFilter,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'paid', child: Text('Payées')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Non payées')),
                ],
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
            Text('Chambre : ${item.roomNumber}'),
            Text(
              'Période : '
              '${item.startDate == null ? "-" : dateFormat.format(item.startDate!)}'
              ' → '
              '${item.endDate == null ? "-" : dateFormat.format(item.endDate!)}',
            ),
            Text('Total : ${item.total.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 8),
            if (isSmall) ...[
              _buildStatusChip(item),
              const SizedBox(height: 8),
              _buildFiscalChip(item),
            ] else
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [_buildStatusChip(item), _buildFiscalChip(item)],
              ),
            const SizedBox(height: 12),
            if (item.isFiscalized &&
                item.fiscalMecefCode.trim().isNotEmpty) ...[
              Text(
                'Code MECeF : ${item.fiscalMecefCode}',
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
                      label: const Text('Marquer payée'),
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
                          label: const Text('Fiscaliser'),
                        );
                      },
                    ),
                  if (item.isFiscalized)
                    OutlinedButton.icon(
                      onPressed: () => _printFiscalizedInvoice(item),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Imprimer normalisée'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _printInvoice(item),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimer'),
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
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isSmall = _isSmallScreen(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Liste des factures chambres')),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          children: [
            _buildFilters(isSmall),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<RoomInvoiceModel>>(
                stream: _service.streamInvoices(
                  establishmentId: establishmentId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
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
                    return const Center(child: Text('Aucune facture trouvée.'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _buildInvoiceCard(
                        context,
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
