import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';

class PdfService {
  /// =========================
  /// HELPERS
  /// =========================

  String _formatAmount(double value) {
    return '${value.toStringAsFixed(0)} FCFA';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// =========================
  /// SAAS HEADER
  /// =========================

  pw.Widget _buildHeader({
    required String title,
    required String establishmentName,
    String? establishmentAddress,
    String? establishmentPhone,
    String? establishmentIfu,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          establishmentName.toUpperCase(),
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),

        if (establishmentAddress != null &&
            establishmentAddress.trim().isNotEmpty)
          pw.Text(establishmentAddress),

        if (establishmentPhone != null && establishmentPhone.trim().isNotEmpty)
          pw.Text('Tél : $establishmentPhone'),

        if (establishmentIfu != null && establishmentIfu.trim().isNotEmpty)
          pw.Text('IFU : $establishmentIfu'),

        pw.SizedBox(height: 6),

        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),

        pw.Divider(),
      ],
    );
  }

  Future<List<int>> buildConsumptionInvoicePdf({
    required String clientName,
    required String roomNumber,
    required List<Map<String, dynamic>> lines,
    required double total,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'FACTURE CONSOMMATIONS',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Client : $clientName'),
            pw.Text('Chambre : $roomNumber'),
            if (startDate != null && endDate != null)
              pw.Text(
                'Période : ${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}',
              ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['Article', 'Qté', 'Prix U.', 'Total'],
              data: lines.map((line) {
                final itemName = _safeString(line['itemName'] ?? line['name']);
                final quantity = line['quantity'] ?? 0;
                final unitPrice = line['unitPrice'] ?? 0;
                final lineTotal = line['total'] ?? 0;

                return [
                  itemName,
                  quantity.toString(),
                  _formatAmount((unitPrice is num) ? unitPrice.toDouble() : 0),
                  _formatAmount((lineTotal is num) ? lineTotal.toDouble() : 0),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 18),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL : ${_formatAmount(total)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> buildFiscalizedConsumptionInvoicePdf({
    required String sellerName,
    required String sellerIfu,
    required String clientName,
    required String clientIfu,
    required String clientAddress,
    required String clientPhone,
    required String roomNumber,
    required List<Map<String, dynamic>> lines,
    required double total,
    required String paymentMethodLabel,
    required String invoiceTypeLabel,
    required String codeMECeFDGI,
    required String qrCode,
    required String nim,
    required String counters,
    required String fiscalDateTime,
    required String fiscalStatusLabel,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              sellerName,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('IFU : $sellerIfu'),
            pw.SizedBox(height: 14),
            pw.Text(
              'FACTURE NORMALISÉE - CONSOMMATIONS',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Client : $clientName'),
            pw.Text('IFU Client : $clientIfu'),
            pw.Text('Téléphone : $clientPhone'),
            pw.Text('Adresse : $clientAddress'),
            pw.Text('Chambre : $roomNumber'),
            if (startDate != null && endDate != null)
              pw.Text(
                'Période : ${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}',
              ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['Article', 'Qté', 'Prix U.', 'Total'],
              data: lines.map((line) {
                final itemName = _safeString(line['itemName'] ?? line['name']);
                final quantity = line['quantity'] ?? 0;
                final unitPrice = line['unitPrice'] ?? 0;
                final lineTotal = line['total'] ?? 0;

                return [
                  itemName,
                  quantity.toString(),
                  _formatAmount((unitPrice is num) ? unitPrice.toDouble() : 0),
                  _formatAmount((lineTotal is num) ? lineTotal.toDouble() : 0),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 18),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL : ${_formatAmount(total)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Code MECeF : $codeMECeFDGI'),
            pw.Text('NIM : $nim'),
            pw.Text('Compteurs : $counters'),
            pw.Text('Date fiscale : $fiscalDateTime'),
            pw.Text('Mode paiement : $paymentMethodLabel'),
            pw.Text('Type facture : $invoiceTypeLabel'),
            pw.Text('Statut : $fiscalStatusLabel'),
            if (qrCode.trim().isNotEmpty) ...[
              pw.SizedBox(height: 12),

              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrCode.trim(),
                  width: 90,
                  height: 90,
                ),
              ),

              pw.SizedBox(height: 8),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> buildRoomInvoicePdf({
    required String clientName,
    required String room,
    required int nights,
    required double pricePerNight,
    required double extras,
    required double services,
    required double total,
    required DateTime start,
    required DateTime end,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FACTURE CHAMBRE',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text('Client : $clientName'),
              pw.Text('Chambre : $room'),
              pw.Text('Entrée : ${DateFormat('dd/MM/yyyy').format(start)}'),
              pw.Text('Sortie : ${DateFormat('dd/MM/yyyy').format(end)}'),
              pw.Text('Nuitées : $nights'),

              pw.SizedBox(height: 12),

              pw.Text('Prix / nuit : ${pricePerNight.toStringAsFixed(0)} FCFA'),
              pw.Text('Extras : ${extras.toStringAsFixed(0)} FCFA'),
              pw.Text('Services : ${services.toStringAsFixed(0)} FCFA'),

              pw.Divider(),

              pw.Text(
                'TOTAL : ${total.toStringAsFixed(0)} FCFA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> buildFiscalizedRoomInvoicePdf({
    required String sellerName,
    required String sellerIfu,
    required String clientName,
    required String clientIfu,
    required String clientAddress,
    required String clientPhone,
    required String room,
    required int nights,
    required double pricePerNight,
    required double extras,
    required double services,
    required double total,
    required DateTime start,
    required DateTime end,
    required String paymentMethodLabel,
    required String invoiceTypeLabel,
    required String codeMECeFDGI,
    required String qrCode,
    required String nim,
    required String counters,
    required String fiscalDateTime,
    required String fiscalStatusLabel,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                sellerName,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Text('IFU : $sellerIfu'),

              pw.SizedBox(height: 20),

              pw.Text('FACTURE NORMALISÉE'),

              pw.SizedBox(height: 16),

              pw.Text('Client : $clientName'),
              pw.Text('IFU Client : $clientIfu'),
              pw.Text('Téléphone : $clientPhone'),
              pw.Text('Adresse : $clientAddress'),

              pw.SizedBox(height: 16),

              pw.Text('Chambre : $room'),
              pw.Text('Nuitées : $nights'),

              pw.Text('Prix / nuit : ${pricePerNight.toStringAsFixed(0)} FCFA'),

              pw.Text('Extras : ${extras.toStringAsFixed(0)} FCFA'),

              pw.Text('Services : ${services.toStringAsFixed(0)} FCFA'),

              pw.Divider(),

              pw.Text(
                'TOTAL : ${total.toStringAsFixed(0)} FCFA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text('Code MECeF : $codeMECeFDGI'),
              pw.Text('NIM : $nim'),
              pw.Text('Compteurs : $counters'),
              pw.Text('Date fiscale : $fiscalDateTime'),
              pw.Text('Mode paiement : $paymentMethodLabel'),
              pw.Text('Type facture : $invoiceTypeLabel'),
              pw.Text('Statut : $fiscalStatusLabel'),
              if (qrCode.trim().isNotEmpty) ...[
                pw.SizedBox(height: 12),

                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrCode.trim(),
                    width: 90,
                    height: 90,
                  ),
                ),

                pw.SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> buildManagerValidationPdf({
    required ServerHandoverModel handover,
    required List<PaymentModel> payments,
  }) async {
    final pdf = pw.Document();

    final total = payments.fold<double>(0, (sum, p) => sum + p.amount);

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text(
              'VALIDATION DE VERSEMENT',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 20),

            pw.Text('Serveur : ${handover.serveurName}'),

            pw.Text(
              'Montant déclaré : '
              '${handover.declaredAmount.toStringAsFixed(0)} FCFA',
            ),

            pw.Text('Nombre de paiements : ${payments.length}'),

            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: const ['Commande', 'Méthode', 'Montant'],
              data: payments.map((payment) {
                return [
                  payment.orderNumber,
                  payment.method,
                  '${payment.amount.toStringAsFixed(0)} FCFA',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TOTAL : ${total.toStringAsFixed(0)} FCFA',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> buildSimpleAccountingReportPdf({
    required String establishmentId,
    required String establishmentName,
    required DateTime startDate,
    required DateTime endDate,
    required double totalEntries,
    required double totalExpenses,
    required double theoreticalBalance,
    String? establishmentAddress,
    String? establishmentPhone,
    String? establishmentIfu,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                title: 'RAPPORT COMPTABLE SIMPLE',
                establishmentName: establishmentName.trim().isEmpty
                    ? 'TAKAPP'
                    : establishmentName,
                establishmentAddress: establishmentAddress,
                establishmentPhone: establishmentPhone,
                establishmentIfu: establishmentIfu,
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'Période : ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
              ),

              pw.SizedBox(height: 16),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Entrées : ${_formatAmount(totalEntries)}'),
                    pw.SizedBox(height: 6),
                    pw.Text('Sorties : ${_formatAmount(totalExpenses)}'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Solde théorique : ${_formatAmount(theoreticalBalance)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'Établissement ID : $establishmentId',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// =========================
  /// ORDER TICKET PDF
  /// =========================

  Future<List<int>> buildOrderTicketPdf({
    required OrderModel order,
    required List<OrderItemModel> items,

    /// SAAS
    required String establishmentName,
    String? establishmentAddress,
    String? establishmentPhone,
    String? establishmentIfu,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                title: 'TICKET DE COMMANDE',
                establishmentName: establishmentName,
                establishmentAddress: establishmentAddress,
                establishmentPhone: establishmentPhone,
                establishmentIfu: establishmentIfu,
              ),

              pw.SizedBox(height: 8),

              pw.Text('Commande : ${order.orderNumber}'),
              pw.Text('Serveur : ${order.createdByName}'),
              pw.Text('Type client : ${order.clientType}'),

              if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
                pw.Text('Table : ${order.tableNumber}'),

              if (order.roomNumber != null && order.roomNumber!.isNotEmpty)
                pw.Text('Chambre : ${order.roomNumber}'),

              pw.Text('Date : ${_formatDate(order.createdAt)}'),

              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _tableHeader('Article'),
                      _tableHeader('Qté'),
                      _tableHeader('Total'),
                    ],
                  ),

                  ...items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.name),

                              if (item.note.trim().isNotEmpty)
                                pw.Text(
                                  'Note: ${item.note}',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                            ],
                          ),
                        ),

                        _tableCell('${item.quantity}'),

                        _tableCell(_formatAmount(item.totalPrice)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Sous-total : ${_formatAmount(order.subtotal)}'),

                    pw.Text('Total : ${_formatAmount(order.total)}'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// =========================
  /// PAYMENT RECEIPT
  /// =========================

  Future<List<int>> buildPaymentReceiptPdf({
    required OrderModel order,
    required PaymentModel payment,

    /// SAAS
    required String establishmentName,
    String? establishmentAddress,
    String? establishmentPhone,
    String? establishmentIfu,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                title: 'REÇU D’ENCAISSEMENT',
                establishmentName: establishmentName,
                establishmentAddress: establishmentAddress,
                establishmentPhone: establishmentPhone,
                establishmentIfu: establishmentIfu,
              ),

              pw.SizedBox(height: 8),

              pw.Text('Commande : ${order.orderNumber}'),

              pw.Text('Encaisseur : ${payment.receivedByName}'),

              pw.Text('Mode de paiement : ${payment.method}'),

              pw.Text('Date : ${_formatDate(payment.createdAt)}'),

              pw.SizedBox(height: 12),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Montant reçu'),

                    pw.SizedBox(height: 6),

                    pw.Text(
                      _formatAmount(payment.amount),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              pw.Text('Merci pour votre visite.'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// =========================
  /// SERVER HANDOVER PDF
  /// =========================

  Future<List<int>> buildServerHandoverPdf({
    required ServerHandoverModel handover,
    required List<PaymentModel> payments,

    /// SAAS
    required String establishmentName,
    String? establishmentAddress,
    String? establishmentPhone,
    String? establishmentIfu,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            _buildHeader(
              title: 'BORDEREAU DE VERSEMENT SERVEUR',
              establishmentName: establishmentName,
              establishmentAddress: establishmentAddress,
              establishmentPhone: establishmentPhone,
              establishmentIfu: establishmentIfu,
            ),

            pw.SizedBox(height: 8),

            pw.Text('Serveur : ${handover.serveurName}'),

            pw.Text('Date déclaration : ${_formatDate(handover.createdAt)}'),

            pw.Text('Statut : ${handover.status}'),

            pw.Text(
              'Montant déclaré : ${_formatAmount(handover.declaredAmount)}',
            ),

            pw.SizedBox(height: 12),

            pw.Text(
              'Paiements inclus',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _tableHeader('Commande'),
                    _tableHeader('Mode'),
                    _tableHeader('Montant'),
                  ],
                ),

                ...payments.map(
                  (payment) => pw.TableRow(
                    children: [
                      _tableCell(payment.orderNumber),

                      _tableCell(payment.method),

                      _tableCell(_formatAmount(payment.amount)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// =========================
  /// QUITUS PDF
  /// =========================

  Future<List<int>> buildQuitusPdf({
    required String establishmentId,
    required String accountType,
    required double theoreticalAmount,
    required double physicalAmount,
    required DateTime date,
    required String validatedByName,

    /// SAAS
    required String establishmentName,
    String? establishmentAddress,
    String? establishmentPhone,
    String? establishmentIfu,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                title: 'QUITUS DE VALIDATION',
                establishmentName: establishmentName,
                establishmentAddress: establishmentAddress,
                establishmentPhone: establishmentPhone,
                establishmentIfu: establishmentIfu,
              ),

              pw.SizedBox(height: 12),

              pw.Text('Compte : $accountType'),

              pw.Text(
                'Montant théorique : ${_formatAmount(theoreticalAmount)}',
              ),

              pw.Text('Montant physique : ${_formatAmount(physicalAmount)}'),

              pw.Text('Date : ${_formatDate(date)}'),

              pw.Text('Validé par : $validatedByName'),

              pw.SizedBox(height: 16),

              pw.Text(
                'Les montants théorique et physique ont été reconnus équivalents.',
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// =========================
  /// TABLE HELPERS
  /// =========================

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(_safeString(text)),
    );
  }
}
