import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final query = searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        results = [];
      });
      return;
    }

    if (establishmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement introuvable.')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildPaymentChip(RoomInvoiceModel invoice) {
    final isPaid = invoice.status == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withOpacity(0.12)
            : Colors.orange.withOpacity(0.12),
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

  Widget _buildFiscalChip(RoomInvoiceModel invoice) {
    final isFiscalized =
        invoice.isFiscalized && invoice.fiscalStatus == 'success';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isFiscalized
            ? Colors.blue.withOpacity(0.12)
            : Colors.red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFiscalized ? 'Fiscalisée' : 'Non fiscalisée',
        style: TextStyle(
          color: isFiscalized ? Colors.blue : Colors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSearchModeSelector(bool isSmall) {
    if (isSmall) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                value: true,
                groupValue: searchByClient,
                title: const Text('Recherche par client'),
                onChanged: (value) {
                  setState(() {
                    searchByClient = true;
                    results = [];
                  });
                },
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                value: false,
                groupValue: searchByClient,
                title: const Text('Recherche par chambre'),
                onChanged: (value) {
                  setState(() {
                    searchByClient = false;
                    results = [];
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                value: true,
                groupValue: searchByClient,
                title: const Text('Par client'),
                onChanged: (value) {
                  setState(() {
                    searchByClient = true;
                    results = [];
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                value: false,
                groupValue: searchByClient,
                title: const Text('Par chambre'),
                onChanged: (value) {
                  setState(() {
                    searchByClient = false;
                    results = [];
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: searchByClient ? 'Nom du client' : 'Numéro de chambre',
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

  Widget _buildInvoiceCard(RoomInvoiceModel invoice, bool isSmall) {
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
                    ? 'Chambre ${invoice.roomNumber}'
                    : invoice.clientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              if (searchByClient)
                Text('Client : ${invoice.clientName}')
              else
                Text('Chambre : ${invoice.roomNumber}'),
              Text('Entrée : ${_formatDate(invoice.startDate)}'),
              Text('Sortie : ${_formatDate(invoice.endDate)}'),
              const SizedBox(height: 4),
              Text(
                'Montant : ${invoice.total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (isSmall) ...[
                _buildPaymentChip(invoice),
                const SizedBox(height: 8),
                _buildFiscalChip(invoice),
              ] else
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildPaymentChip(invoice),
                    _buildFiscalChip(invoice),
                  ],
                ),
              if (invoice.isFiscalized &&
                  invoice.fiscalMecefCode.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Code MECeF : ${invoice.fiscalMecefCode}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Voir détails',
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

  Widget _buildResults(bool isSmall) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return const Center(child: Text('Aucun résultat'));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final invoice = results[index];

        return _buildInvoiceCard(invoice, isSmall);
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
    final isSmall = _isSmallScreen(context);

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recherche factures chambre')),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          children: [
            _buildSearchModeSelector(isSmall),
            const SizedBox(height: 12),
            _buildSearchField(),
            const SizedBox(height: 16),
            Expanded(child: _buildResults(isSmall)),
          ],
        ),
      ),
    );
  }
}
