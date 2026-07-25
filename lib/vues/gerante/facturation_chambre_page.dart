import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/fiscalization_controller.dart';
import 'package:takapp/modeles/emcf_invoice_item_model.dart';
import 'package:takapp/modeles/emcf_invoice_request_model.dart';
import 'package:takapp/modeles/room_consumption_invoice_model.dart';
import 'package:takapp/modeles/room_invoice_model.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';
import 'package:takapp/services/room_consumption_service.dart';
import 'package:takapp/services/room_invoice_service.dart';
import 'package:takapp/vues/gerante/recherche_facture_chambre_page.dart';

import 'package:takapp/modeles/reservation_model.dart';

class FacturationChambrePage extends StatefulWidget {
  final String establishmentId;
  final ReservationModel? reservation;
  const FacturationChambrePage({
    super.key,
    required this.establishmentId,
    this.reservation,
  });
  @override
  State<FacturationChambrePage> createState() => _FacturationChambrePageState();
}

class _FacturationChambrePageState extends State<FacturationChambrePage> {
  final RoomInvoiceService _service = RoomInvoiceService();
  final RoomConsumptionService _consumptionService = RoomConsumptionService();

  String? currentInvoiceId;

  /// Fiche client héritée de la réservation (check-out).
  /// Vide si la facture est saisie à la main : comportement inchangé.
  String _clientId = '';

  String _sellerIfu = '';
  String _sellerName = "";
  String get establishmentId => widget.establishmentId.trim();

  final TextEditingController clientController = TextEditingController();
  final TextEditingController clientIfuController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();
  final TextEditingController clientPhoneController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController servicesController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = false;
  double consumptionTotal = 0;

  String paymentMethod = 'cash';
  String aibType = 'none';
  bool isCurrentInvoiceFiscalized = false;

  int get nights {
    if (startDate == null || endDate == null) return 0;
    final diff = endDate!.difference(startDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get roomTotal => nights * (double.tryParse(priceController.text) ?? 0);

  double get servicesTotal =>
      double.tryParse(servicesController.text.trim()) ?? 0;

  double get total => roomTotal + consumptionTotal + servicesTotal;

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;

  String _establishmentId(BuildContext context) {
    final user = context.read<AuthController>().currentUser;
    return user?.establishmentId.trim() ?? '';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _invalidateCurrentInvoice() {
    if (currentInvoiceId != null || isCurrentInvoiceFiscalized) {
      setState(() {
        currentInvoiceId = null;
        isCurrentInvoiceFiscalized = false;
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? startDate ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = startDate;
        }
      } else {
        endDate = picked;
        if (startDate != null && endDate!.isBefore(startDate!)) {
          endDate = startDate;
        }
      }
      currentInvoiceId = null;
      isCurrentInvoiceFiscalized = false;
    });

    await _loadConsumptionTotal();
  }

  Future<void> _printFiscalizedInvoice() async {
    final establishmentId = _establishmentId(context);

    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
      return;
    }

    if (currentInvoiceId == null) {
      _showSnack('Veuillez d’abord enregistrer la facture.');
      return;
    }

    final invoice = await _service.getInvoiceById(
      establishmentId: establishmentId,
      invoiceId: currentInvoiceId!,
    );

    if (!mounted) return;

    if (invoice == null) {
      _showSnack('Facture introuvable.');
      return;
    }

    if (!invoice.isFiscalized ||
        invoice.fiscalMecefCode.trim().isEmpty ||
        invoice.fiscalQrCode.trim().isEmpty) {
      _showSnack(
        'Cette facture n’est pas encore fiscalisée. Fiscalisez-la d’abord.',
      );
      return;
    }

    if (invoice.startDate == null || invoice.endDate == null) {
      _showSnack('Dates de facture invalides.');
      return;
    }

    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildFiscalizedRoomInvoicePdf(
      sellerName: _sellerName,
      sellerIfu: _sellerIfu,
      clientName: invoice.clientName,
      clientIfu: invoice.clientIfu,
      clientAddress: invoice.clientAddress,
      clientPhone: invoice.clientPhone,
      room: invoice.roomNumber,
      nights: invoice.nights,
      pricePerNight: invoice.pricePerNight,
      extras: invoice.extrasTotal,
      services: invoice.servicesTotal,
      total: invoice.total,
      start: invoice.startDate!,
      end: invoice.endDate!,
      paymentMethodLabel: invoice.paymentMethod,
      invoiceTypeLabel: invoice.fiscalInvoiceType,
      codeMECeFDGI: invoice.fiscalMecefCode,
      qrCode: invoice.fiscalQrCode,
      nim: invoice.fiscalNim,
      counters: invoice.fiscalCounter,
      fiscalDateTime: invoice.fiscalMachineDateTime,
      fiscalStatusLabel: invoice.fiscalStatus,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
  }

  Future<void> _loadConsumptionTotal() async {
    final establishmentId = _establishmentId(context);

    if (establishmentId.isEmpty ||
        roomController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      setState(() {
        consumptionTotal = 0;
      });
      return;
    }

    try {
      final invoice = await _consumptionService.getConsumption(
        establishmentId: establishmentId,
        roomNumber: roomController.text.trim(),
        startDate: startDate!,
        endDate: endDate!,
      );

      if (!mounted) return;

      setState(() {
        consumptionTotal = invoice.total;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        consumptionTotal = 0;
      });

      _showSnack('Erreur lors du chargement des consommations : $e');
    }
  }

  Future<void> _showConsumptionDetails() async {
    final establishmentId = _establishmentId(context);

    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
      return;
    }

    if (roomController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      _showSnack('Veuillez d’abord renseigner la chambre et la période.');
      return;
    }

    final isSmall = _isSmallScreen(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(isSmall ? 12 : 24),
          title: const Text('Détails Extras'),
          content: SizedBox(
            width: isSmall ? double.maxFinite : 700,
            child: FutureBuilder<RoomConsumptionInvoiceModel>(
              future: _consumptionService.getConsumption(
                establishmentId: establishmentId,
                roomNumber: roomController.text.trim(),
                startDate: startDate!,
                endDate: endDate!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SingleChildScrollView(
                    child: Text(
                      'Erreur : ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final invoice = snapshot.data;
                if (invoice == null || invoice.lines.isEmpty) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: Text('Aucune consommation trouvée.')),
                  );
                }

                return SizedBox(
                  width: double.maxFinite,
                  height: isSmall ? 420 : 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chambre ${invoice.roomNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Période : '
                        '${DateFormat('dd/MM/yyyy').format(invoice.startDate)}'
                        ' - '
                        '${DateFormat('dd/MM/yyyy').format(invoice.endDate)}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total extras : ${invoice.total.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: invoice.lines.length,
                          itemBuilder: (context, index) {
                            final line = invoice.lines[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                dense: isSmall,
                                title: Text(line.itemName),
                                subtitle: Text(
                                  '${line.quantity} x ${line.unitPrice.toStringAsFixed(0)} FCFA - ${line.source}\n'
                                  '${DateFormat('dd/MM/yyyy HH:mm').format(line.createdAt)}'
                                  '${line.serveur.isNotEmpty ? ' - ${line.serveur}' : ''}',
                                ),
                                trailing: Text(
                                  '${line.total.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveInvoice() async {
    final establishmentId = _establishmentId(context);

    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
      return;
    }

    if (clientController.text.trim().isEmpty ||
        roomController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null) {
      _showSnack('Champs obligatoires manquants');
      return;
    }

    if (startDate!.isAfter(endDate!)) {
      _showSnack(
        'La date d’entrée doit être antérieure ou égale à la date de sortie.',
      );
      return;
    }

    final pricePerNight = double.tryParse(priceController.text.trim());
    if (pricePerNight == null || pricePerNight <= 0) {
      _showSnack('Prix de nuitée invalide');
      return;
    }

    setState(() => isLoading = true);

    try {
      final alreadyExists = await _service.invoiceExists(
        establishmentId: establishmentId,
        roomNumber: roomController.text.trim(),
        startDate: startDate!,
        endDate: endDate!,
      );

      if (alreadyExists) {
        if (!mounted) return;
        _showSnack(
          'Une facture existe déjà pour cette chambre et cette période.',
        );
        return;
      }

      if (!mounted) return;

      final user = context.read<AuthController>().currentUser;

      if (user == null) {
        _showSnack('Utilisateur introuvable.');
        return;
      }

      final now = DateTime.now();

      final invoice = RoomInvoiceModel(
        id: '',
        establishmentId: establishmentId,
        clientId: _clientId,
        clientName: clientController.text.trim(),
        clientIfu: clientIfuController.text.trim(),
        clientAddress: clientAddressController.text.trim(),
        clientPhone: clientPhoneController.text.trim(),
        roomNumber: roomController.text.trim(),
        nights: nights,
        pricePerNight: pricePerNight,
        roomTotal: roomTotal,
        extrasTotal: consumptionTotal,
        servicesTotal: servicesTotal,
        total: total,
        status: 'unpaid',
        paymentMethod: paymentMethod,
        aibType: aibType,
        isFiscalized: false,
        fiscalStatus: 'pending',
        fiscalError: '',
        fiscalizedAt: null,
        fiscalInvoiceType: 'FV',
        fiscalEmcfUid: '',
        fiscalMecefCode: '',
        fiscalNim: '',
        fiscalCounter: '',
        fiscalMachineDateTime: '',
        fiscalQrCode: '',
        fiscalRawCreateResponse: '',
        fiscalRawConfirmResponse: '',
        fiscalRequestSnapshot: null,
        startDate: startDate,
        endDate: endDate,
        pendingSync: false,
        syncError: false,
        createdBy: user.uid,
        createdByName: user.name,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _service.createInvoice(
        establishmentId: establishmentId,
        invoice: invoice,
      );

      if (!mounted) return;

      setState(() {
        currentInvoiceId = docRef.id;
        isCurrentInvoiceFiscalized = false;
      });

      _showSnack(
        'Facture créée avec succès. Vous pouvez maintenant l’encaisser ou la fiscaliser.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur lors de l’enregistrement de la facture : $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  EmcfInvoiceRequestModel _buildEmcfRequest(String sellerName) {
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

    final int roomPrice = (double.tryParse(priceController.text.trim()) ?? 0)
        .round();
    final int extrasPrice = consumptionTotal.round();
    final int servicesPrice = servicesTotal.round();

    final items = <EmcfInvoiceItemModel>[
      EmcfInvoiceItemModel(
        code: 'ROOM_NIGHT',
        name: 'Nuitee chambre ${roomController.text.trim()}',
        price: roomPrice,
        quantity: nights.toDouble(),
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
      aib: mapAibType(aibType),
      type: 'FV',
      items: items,
      client: {
        'ifu': clientIfuController.text.trim(),
        'name': clientController.text.trim(),
        'contact': clientPhoneController.text.trim(),
        'address': clientAddressController.text.trim(),
      },
      operatorData: {
        'id': context.read<AuthController>().currentUser?.uid ?? '',
        'name': sellerName,
      },
      payment: [
        {'name': mapPaymentMethod(paymentMethod), 'amount': total.round()},
      ],
    );
  }

  Future<void> _fiscalizeInvoice() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      _showSnack('Utilisateur introuvable.');
      return;
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      _showSnack('Établissement introuvable.');
      return;
    }

    if (currentInvoiceId == null) {
      _showSnack('Veuillez d’abord enregistrer la facture.');
      return;
    }

    if (isCurrentInvoiceFiscalized) {
      _showSnack('Cette facture est déjà fiscalisée.');
      return;
    }

    final sellerName = user.name.isNotEmpty ? user.name : 'Operateur';

    final request = _buildEmcfRequest(sellerName);
    final fiscalController = context.read<FiscalizationController>();

    await fiscalController.fiscalizeInvoice(
      establishmentId: establishmentId,
      invoiceId: currentInvoiceId!,
      request: request,
    );

    if (!mounted) return;

    if (fiscalController.confirmResult != null &&
        !fiscalController.confirmResult!.hasError) {
      setState(() {
        isCurrentInvoiceFiscalized = true;
      });

      _showSnack(
        'Facture fiscalisée avec Certilink. Code MECeF : ${fiscalController.confirmResult!.codeMECeFDGI}',
      );
    } else {
      _showSnack(fiscalController.errorMessage ?? 'Échec de fiscalisation');
    }
  }

  void _resetForm() {
    clientController.clear();
    clientIfuController.clear();
    clientAddressController.clear();
    clientPhoneController.clear();
    roomController.clear();
    priceController.clear();
    servicesController.clear();

    setState(() {
      currentInvoiceId = null;
      startDate = null;
      endDate = null;
      consumptionTotal = 0;
      paymentMethod = 'cash';
      aibType = 'none';
      isCurrentInvoiceFiscalized = false;
    });
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Choisir';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _printInvoice() async {
    if (startDate == null || endDate == null) {
      _showSnack('Veuillez d’abord renseigner la facture.');
      return;
    }

    final pdfService = context.read<PdfService>();
    final printer = context.read<PrinterService>();

    final bytes = await pdfService.buildRoomInvoicePdf(
      clientName: clientController.text.trim(),
      room: roomController.text.trim(),
      nights: nights,
      pricePerNight: double.tryParse(priceController.text.trim()) ?? 0,
      extras: consumptionTotal,
      services: servicesTotal,
      total: total,
      start: startDate!,
      end: endDate!,
    );

    await printer.printPdf(Uint8List.fromList(bytes));
  }

  void _showPaymentDialog(BuildContext context, String invoiceId) {
    String method = paymentMethod;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Encaissement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(
                    value: 'mobile_money',
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(value: 'bank', child: Text('Banque')),
                  DropdownMenuItem(value: 'card', child: Text('Carte')),
                  DropdownMenuItem(value: 'credit', child: Text('Crédit')),
                  DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
                ],
                onChanged: (v) {
                  if (v != null) method = v;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = context.read<AuthController>().currentUser;

                if (user == null) {
                  Navigator.pop(context);
                  _showSnack('Utilisateur introuvable.');
                  return;
                }

                final establishmentId = user.establishmentId.trim();

                if (establishmentId.isEmpty) {
                  Navigator.pop(context);
                  _showSnack('Établissement introuvable.');
                  return;
                }

                final navigator = Navigator.of(context);

                await _service.payInvoice(
                  establishmentId: establishmentId,
                  invoiceId: invoiceId,
                  amount: total,
                  method: method,
                  receivedBy: user.uid,
                  receivedByName: user.name,
                );

                if (!mounted) return;

                setState(() {
                  paymentMethod = method;
                });

                navigator.pop();
                _showSnack('Paiement enregistré');
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSellerIfu();
    _loadSellerName();

    // Pré-remplissage depuis une réservation (check-out)
    final resa = widget.reservation;
    if (resa != null) {
      _clientId = resa.clientId;
      clientController.text = resa.clientName;
      clientIfuController.text = resa.clientIfu;
      clientAddressController.text = resa.clientAddress;
      clientPhoneController.text = resa.clientPhone;
      roomController.text = resa.assignedRoomNumber;
      priceController.text = resa.pricePerNight > 0
          ? resa.pricePerNight.toStringAsFixed(0)
          : '';
      startDate = resa.checkInDate;
      endDate = resa.checkOutDate;

      // Charger les consommations du séjour après le premier frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadConsumptionTotal();
        }
      });
    }
  }

  @override
  void dispose() {
    clientController.dispose();
    clientIfuController.dispose();
    clientAddressController.dispose();
    clientPhoneController.dispose();
    roomController.dispose();
    priceController.dispose();
    servicesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    final isSmall = _isSmallScreen(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Facturation Chambre')),
      body: isSmall
          ? _buildMobileLayout(establishmentId: establishmentId)
          : _buildDesktopLayout(establishmentId: establishmentId),
    );
  }

  Widget _buildMobileLayout({required String establishmentId}) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildForm(isMobile: true, establishmentId: establishmentId),
            const SizedBox(height: 12),
            _buildSummary(isMobile: true),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSellerIfu() async {
    final doc = await FirebaseFirestore.instance
        .collection('establishments')
        .doc(establishmentId) // adapter au nom exact de la variable dans la vue
        .get();
    _sellerIfu = (doc.data()?['ifu'] ?? '').toString().trim();
  }

  Future<void> _loadSellerName() async {
    final doc = await FirebaseFirestore.instance
        .collection('establishments')
        .doc(establishmentId) // adapter au nom exact de la variable dans la vue
        .get();
    _sellerName = (doc.data()?['name'] ?? '').toString().trim();
  }

  Widget _buildDesktopLayout({required String establishmentId}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildForm(
              isMobile: false,
              establishmentId: establishmentId,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _buildSummary(isMobile: false)),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isMobile, required String establishmentId}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: ListView(
          shrinkWrap: isMobile,
          physics: isMobile
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          children: [
            const Text(
              'Informations client',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clientController,
              decoration: const InputDecoration(labelText: 'Nom client'),
              onChanged: (_) => _invalidateCurrentInvoice(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clientIfuController,
              decoration: const InputDecoration(labelText: 'IFU client'),
              onChanged: (_) => _invalidateCurrentInvoice(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clientAddressController,
              decoration: const InputDecoration(labelText: 'Adresse client'),
              onChanged: (_) => _invalidateCurrentInvoice(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clientPhoneController,
              decoration: const InputDecoration(labelText: 'Téléphone client'),
              onChanged: (_) => _invalidateCurrentInvoice(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(labelText: 'Chambre'),
              onChanged: (_) async {
                _invalidateCurrentInvoice();
                await _loadConsumptionTotal();
              },
            ),
            const SizedBox(height: 10),
            if (isMobile) ...[
              OutlinedButton(
                onPressed: () => _pickDate(true),
                child: Text('Début : ${formatDate(startDate)}'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _pickDate(false),
                child: Text('Fin : ${formatDate(endDate)}'),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text('Début: ${formatDate(startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text('Fin: ${formatDate(endDate)}'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix / nuit'),
              onChanged: (_) {
                _invalidateCurrentInvoice();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: servicesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Autres services'),
              onChanged: (_) {
                _invalidateCurrentInvoice();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: const InputDecoration(labelText: 'Mode de paiement'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(
                  value: 'mobile_money',
                  child: Text('Mobile Money'),
                ),
                DropdownMenuItem(value: 'bank', child: Text('Banque')),
                DropdownMenuItem(value: 'card', child: Text('Carte')),
                DropdownMenuItem(
                  value: 'credit',
                  child: Text('Crédit / Vente à terme'),
                ),
                DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  paymentMethod = value;
                  _invalidateCurrentInvoice();
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: aibType,
              decoration: const InputDecoration(labelText: 'AIB'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Aucun AIB')),
                DropdownMenuItem(value: 'aib1', child: Text('AIB 1%')),
                DropdownMenuItem(value: 'aib5', child: Text('AIB 5%')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  aibType = value;
                  _invalidateCurrentInvoice();
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _saveInvoice,
                icon: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Enregistrer facture'),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.blueGrey.shade600, Colors.blueGrey.shade900],
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RechercheFactureChambrePage(
                        establishmentId: establishmentId,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Rechercher une facture',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.refresh),
                label: const Text('Nouvelle facture'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary({required bool isMobile}) {
    final actionSpacing = isMobile ? 8.0 : 10.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Résumé', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _row('Nuitées', '$nights'),
            _row('Chambre', '${roomTotal.toStringAsFixed(0)} FCFA'),
            _row(
              'Consommations bar/resto',
              '${consumptionTotal.toStringAsFixed(0)} FCFA',
            ),
            _row('Services', '${servicesTotal.toStringAsFixed(0)} FCFA'),
            const Divider(),
            _row('TOTAL', '${total.toStringAsFixed(0)} FCFA', isBold: true),
            const SizedBox(height: 12),
            _row(
              'Statut fiscal',
              isCurrentInvoiceFiscalized ? 'Fiscalisée' : 'Non fiscalisée',
              isBold: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (currentInvoiceId == null) {
                    _showSnack('Veuillez d’abord enregistrer la facture.');
                    return;
                  }

                  _showPaymentDialog(context, currentInvoiceId!);
                },
                icon: const Icon(Icons.payment),
                label: const Text('Encaisser'),
              ),
            ),
            SizedBox(height: actionSpacing),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showConsumptionDetails,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Détails Extras'),
              ),
            ),
            SizedBox(height: actionSpacing),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _printInvoice,
                icon: const Icon(Icons.print),
                label: const Text('Imprimer facture'),
              ),
            ),
            SizedBox(height: actionSpacing),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _printFiscalizedInvoice,
                icon: const Icon(Icons.verified),
                label: const Text('Imprimer facture normalisée'),
              ),
            ),
            SizedBox(height: actionSpacing),
            Consumer<FiscalizationController>(
              builder: (context, fiscalController, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: fiscalController.isLoading
                        ? null
                        : _fiscalizeInvoice,
                    icon: fiscalController.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified),
                    label: Text(
                      isCurrentInvoiceFiscalized
                          ? 'Facture déjà fiscalisée'
                          : 'Fiscaliser avec Certilink',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (currentInvoiceId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isCurrentInvoiceFiscalized
                      ? 'Facture enregistrée et fiscalisée.'
                      : 'Facture enregistrée. Prête à être encaissée ou fiscalisée.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
