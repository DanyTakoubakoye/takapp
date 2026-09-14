import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/room_invoice_model.dart';
import 'package:takapp/services/room_invoice_service.dart';
import 'package:takapp/vues/gerante/detail_facture_chambre_page.dart';

class RechercheFactureChambrePage extends StatefulWidget {
  final String establishmentId;

  const RechercheFactureChambrePage({super.key, required this.establishmentId});

  @override
  State<RechercheFactureChambrePage> createState() =>
      _RechercheFactureChambrePageState();
}

class _RechercheFactureChambrePageState
    extends State<RechercheFactureChambrePage> {
  final RoomInvoiceService _service = RoomInvoiceService();

  final TextEditingController searchController = TextEditingController();

  bool searchByClient = true;
  bool isLoading = false;

  List<RoomInvoiceModel> results = [];

  String get establishmentId => widget.establishmentId.trim();

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _search() async {
    final l10n = AppLocalizations.of(context);
    final query = searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        results = [];
      });
      return;
    }

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errEstablishmentNotFound)));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final data = searchByClient
          ? await _service.searchInvoicesByClient(
              establishmentId: establishmentId,
              clientName: query,
            )
          : await _service.searchInvoicesByRoom(
              establishmentId: establishmentId,
              roomNumber: query,
            );

      if (!mounted) return;

      setState(() {
        results = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errSearchFailed('$e'))));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildPaymentChip(AppLocalizations l10n, RoomInvoiceModel invoice) {
    // `status` reste la valeur technique stockée : seul le rendu est localisé.
    final isPaid = invoice.status == 'paid';

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

  Widget _buildFiscalChip(AppLocalizations l10n, RoomInvoiceModel invoice) {
    final isFiscalized =
        invoice.isFiscalized && invoice.fiscalStatus == 'success';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isFiscalized
            ? Colors.blue.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFiscalized ? l10n.statusFiscalized : l10n.statusNotFiscalized,
        style: TextStyle(
          color: isFiscalized ? Colors.blue : Colors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSearchModeSelector(AppLocalizations l10n, bool isSmall) {
    if (isSmall) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: RadioGroup<bool>(
            groupValue: searchByClient,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                searchByClient = value;
                results = [];
              });
            },
            child: Column(
              children: [
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  title: Text(l10n.searchByClientOption),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  title: Text(l10n.searchByRoomOption),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: RadioGroup<bool>(
          groupValue: searchByClient,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              searchByClient = value;
              results = [];
            });
          },
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  value: true,
                  title: Text(l10n.searchByClientShort),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  value: false,
                  title: Text(l10n.searchByRoomShort),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: searchByClient
                ? l10n.labelClientName
                : l10n.labelRoomNumber,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _search,
            ),
          ),
          onSubmitted: (_) => _search(),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    AppLocalizations l10n,
    RoomInvoiceModel invoice,
    bool isSmall,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailFactureChambrePage(
                establishmentId: establishmentId,
                invoice: invoice,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                searchByClient
                    ? l10n.labelRoom(invoice.roomNumber)
                    : invoice.clientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              if (searchByClient)
                Text(l10n.clientLine(invoice.clientName))
              else
                Text(l10n.roomLine(invoice.roomNumber)),
              Text(l10n.arrivalLine(_formatDate(invoice.startDate))),
              Text(l10n.departureLine(_formatDate(invoice.endDate))),
              const SizedBox(height: 4),
              Text(
                l10n.amountLine(invoice.total.toStringAsFixed(0)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (isSmall) ...[
                _buildPaymentChip(l10n, invoice),
                const SizedBox(height: 8),
                _buildFiscalChip(l10n, invoice),
              ] else
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildPaymentChip(l10n, invoice),
                    _buildFiscalChip(l10n, invoice),
                  ],
                ),
              if (invoice.isFiscalized &&
                  invoice.fiscalMecefCode.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.mecefCodeLine(invoice.fiscalMecefCode),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.actionViewDetails,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, bool isSmall) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return Center(child: Text(l10n.noResult));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final invoice = results[index];

        return _buildInvoiceCard(l10n, invoice, isSmall);
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = _isSmallScreen(context);

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchRoomInvoicesTitle)),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          children: [
            _buildSearchModeSelector(l10n, isSmall),
            const SizedBox(height: 12),
            _buildSearchField(l10n),
            const SizedBox(height: 16),
            Expanded(child: _buildResults(l10n, isSmall)),
          ],
        ),
      ),
    );
  }
}
