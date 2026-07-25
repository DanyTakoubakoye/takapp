import 'dart:convert';

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
            pw.TableHelper.fromTextArray(
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
            pw.TableHelper.fromTextArray(
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

            pw.TableHelper.fromTextArray(
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
  /// FACTURE CHAMBRE — VERSION SOIGNÉE (V2)
  /// =========================
  /// Une seule méthode pour les deux cas (fiscalisée ou non), format A4,
  /// pensée pour tenir sur une seule page.
  ///
  /// Le détail fiscal (HT / TVA / TTC) est lu depuis la réponse CertiLink
  /// [fiscalRawCreateResponse] quand elle est fournie (source DGI) ; sinon
  /// il est décomposé depuis le total TTC (TVA 18% incluse).
  Future<List<int>> buildRoomInvoicePdfV2({
    // Vendeur (tenant)
    required String sellerName,
    String sellerIfu = '',
    String sellerAddress = '',
    String sellerPhone = '',

    // Client
    required String clientName,
    String clientIfu = '',
    String clientAddress = '',
    String clientPhone = '',

    // Séjour
    required String room,
    required int nights,
    required double pricePerNight,
    required double extras,
    required double services,
    required double total,
    DateTime? start,
    DateTime? end,

    // Fiscalisation (optionnelle)
    bool certified = false,
    String paymentMethodLabel = '',
    String invoiceTypeLabel = '',
    String codeMECeFDGI = '',
    String qrCode = '',
    String nim = '',
    String counters = '',
    String fiscalDateTime = '',
    // Réponse brute CertiLink (JSON) : source du détail fiscal si présente.
    String fiscalRawCreateResponse = '',
  }) async {
    final pdf = pw.Document();

    // ---- Détail fiscal : CertiLink d'abord, sinon décomposition TTC 18% ----
    double ht;
    double tva;
    double ttc = total;
    double specificTax = 0;
    int vatRatePct = 18;

    final fiscalMap = _tryParseJson(fiscalRawCreateResponse);
    if (fiscalMap != null) {
      // rawCreateResponse peut être imbriqué OU être la racine.
      final raw = fiscalMap['rawCreateResponse'] is Map
          ? Map<String, dynamic>.from(fiscalMap['rawCreateResponse'] as Map)
          : fiscalMap;
      final num? habN = raw['hab'] is num ? raw['hab'] as num : null;
      final num? vabN = raw['vab'] is num ? raw['vab'] as num : null;
      final num? totN = raw['total'] is num ? raw['total'] as num : null;
      final num? tsN = raw['ts'] is num ? raw['ts'] as num : null;
      final num? tbN = raw['tb'] is num ? raw['tb'] as num : null;
      if (habN != null && vabN != null) {
        ht = habN.toDouble();
        tva = vabN.toDouble();
        ttc = (totN ?? total).toDouble();
        specificTax = (tsN ?? 0).toDouble();
        if (tbN != null && tbN > 0) vatRatePct = tbN.toInt();
      } else {
        // JSON présent mais sans les montants attendus → décomposition.
        ht = total / 1.18;
        tva = total - ht;
      }
    } else {
      // Pas de réponse fiscale → décomposition du TTC (TVA 18% incluse).
      ht = total / 1.18;
      tva = total - ht;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ---------- EN-TÊTE ----------
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bloc initiales (repli logo)
                  pw.Container(
                    width: 60,
                    height: 60,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blueGrey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      _initials(sellerName),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          sellerName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (sellerAddress.trim().isNotEmpty)
                          pw.Text(
                            sellerAddress,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        if (sellerPhone.trim().isNotEmpty)
                          pw.Text(
                            'Tél : $sellerPhone',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        if (sellerIfu.trim().isNotEmpty)
                          pw.Text(
                            'IFU : $sellerIfu',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  // Badge certifié / non certifié
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: certified
                          ? PdfColors.green100
                          : PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      certified ? 'FACTURE CERTIFIÉE' : 'FACTURE',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: certified
                            ? PdfColors.green800
                            : PdfColors.orange800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.grey400),

              // ---------- TITRE + DATES ----------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FACTURE DE CHAMBRE',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (start != null && end != null)
                    pw.Text(
                      'Séjour : ${_formatShortDate(start)} → ${_formatShortDate(end)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
              pw.SizedBox(height: 14),

              // ---------- CLIENT ----------
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLIENT',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      clientName.isEmpty ? '-' : clientName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (clientIfu.trim().isNotEmpty)
                      pw.Text(
                        'IFU : $clientIfu',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (clientPhone.trim().isNotEmpty)
                      pw.Text(
                        'Tél : $clientPhone',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (clientAddress.trim().isNotEmpty)
                      pw.Text(
                        'Adresse : $clientAddress',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // ---------- DÉTAIL SÉJOUR ----------
              pw.TableHelper.fromTextArray(
                headers: const ['Désignation', 'Qté', 'P.U.', 'Montant'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignments: {
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                border: pw.TableBorder.all(color: PdfColors.grey300),
                data: [
                  [
                    'Nuitée chambre $room',
                    '$nights',
                    _formatAmount(pricePerNight),
                    _formatAmount(nights * pricePerNight),
                  ],
                  if (extras > 0)
                    ['Consommations / extras', '', '', _formatAmount(extras)],
                  if (services > 0)
                    ['Services', '', '', _formatAmount(services)],
                ],
              ),
              pw.SizedBox(height: 16),

              // ---------- RÉCAPITULATIF FISCAL ----------
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 260,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      _sumLine('Total H.T.', _formatAmount(ht)),
                      _sumLine('TVA ($vatRatePct%)', _formatAmount(tva)),
                      if (specificTax > 0)
                        _sumLine('Taxe spécifique', _formatAmount(specificTax)),
                      pw.Divider(color: PdfColors.grey400),
                      _sumLine('TOTAL TTC', _formatAmount(ttc), bold: true),
                    ],
                  ),
                ),
              ),

              // ---------- BLOC FISCAL (si certifiée) ----------
              if (certified) ...[
                pw.SizedBox(height: 18),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (qrCode.trim().isNotEmpty)
                        pw.Container(
                          width: 80,
                          height: 80,
                          padding: const pw.EdgeInsets.all(3),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.white,
                          ),
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrCode.trim(),
                          ),
                        ),
                      if (qrCode.trim().isNotEmpty) pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Éléments de sécurité fiscale',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Code MECeF/DGI : $codeMECeFDGI',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'NIM : $nim',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Compteurs : $counters',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            if (fiscalDateTime.trim().isNotEmpty)
                              pw.Text(
                                'Date fiscale : $fiscalDateTime',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (paymentMethodLabel.trim().isNotEmpty)
                              pw.Text(
                                'Paiement : $paymentMethodLabel',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (invoiceTypeLabel.trim().isNotEmpty)
                              pw.Text(
                                'Type : $invoiceTypeLabel',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Merci de votre confiance.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
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
  /// TICKET DE CAISSE BAR/RESTO (80mm) — V2
  /// =========================
  /// Format rouleau étroit ~80mm, hauteur auto. Gère le cas simple et
  /// fiscalisé. Détail HT/TVA lu depuis CertiLink si fourni, sinon décomposé
  /// du total TTC (TVA 18% incluse).
  Future<List<int>> buildConsumptionTicketV2({
    required String sellerName,
    String sellerIfu = '',
    String sellerAddress = '',
    required String clientName,
    String clientIfu = '',
    required String reference, // n° table ou chambre
    required List<Map<String, dynamic>> lines,
    required double total,
    bool certified = false,
    String paymentMethodLabel = '',
    String codeMECeFDGI = '',
    String qrCode = '',
    String nim = '',
    String counters = '',
    String fiscalDateTime = '',
    String fiscalRawCreateResponse = '',
  }) async {
    final pdf = pw.Document();

    // Détail fiscal
    double ht;
    double tva;
    double ttc = total;
    int vatRatePct = 18;
    final fiscalMap = _tryParseJson(fiscalRawCreateResponse);
    if (fiscalMap != null) {
      final raw = fiscalMap['rawCreateResponse'] is Map
          ? Map<String, dynamic>.from(fiscalMap['rawCreateResponse'] as Map)
          : fiscalMap;
      final num? habN = raw['hab'] is num ? raw['hab'] as num : null;
      final num? vabN = raw['vab'] is num ? raw['vab'] as num : null;
      final num? totN = raw['total'] is num ? raw['total'] as num : null;
      final num? tbN = raw['tb'] is num ? raw['tb'] as num : null;
      if (habN != null && vabN != null) {
        ht = habN.toDouble();
        tva = vabN.toDouble();
        ttc = (totN ?? total).toDouble();
        if (tbN != null && tbN > 0) vatRatePct = tbN.toInt();
      } else {
        ht = total / 1.18;
        tva = total - ht;
      }
    } else {
      ht = total / 1.18;
      tva = total - ht;
    }

    // Format 80mm de large, hauteur généreuse (le contenu court remonte).
    const double mm = PdfPageFormat.mm;
    final format = PdfPageFormat(80 * mm, 297 * mm, marginAll: 4 * mm);

    pw.Widget divider() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(
        '------------------------------',
        style: const pw.TextStyle(fontSize: 8),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // En-tête
              pw.Center(
                child: pw.Text(
                  sellerName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (sellerAddress.trim().isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    sellerAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              if (sellerIfu.trim().isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'IFU : $sellerIfu',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              divider(),
              pw.Center(
                child: pw.Text(
                  certified ? 'FACTURE NORMALISÉE' : 'TICKET',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Réf : $reference',
                style: const pw.TextStyle(fontSize: 8),
              ),
              if (clientName.trim().isNotEmpty)
                pw.Text(
                  'Client : $clientName',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              if (clientIfu.trim().isNotEmpty)
                pw.Text(
                  'IFU cl. : $clientIfu',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.Text(
                'Date : ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              divider(),

              // Articles
              ...lines.map((line) {
                final name = _safeString(line['itemName'] ?? line['name']);
                final qty = line['quantity'] ?? 0;
                final lineTotal = line['total'] ?? 0;
                final lt = (lineTotal is num) ? lineTotal.toDouble() : 0.0;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text(name, style: const pw.TextStyle(fontSize: 8)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '  x$qty',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            _formatAmount(lt),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              divider(),

              // Récap fiscal
              _ticketLine('Total H.T.', _formatAmount(ht)),
              _ticketLine('TVA ($vatRatePct%)', _formatAmount(tva)),
              pw.SizedBox(height: 2),
              _ticketLine('TOTAL TTC', _formatAmount(ttc), bold: true),
              if (paymentMethodLabel.trim().isNotEmpty) ...[
                pw.SizedBox(height: 2),
                _ticketLine('Paiement', paymentMethodLabel),
              ],

              // Bloc fiscal
              if (certified) ...[
                divider(),
                pw.Text(
                  'Code MECeF : $codeMECeFDGI',
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.Text('NIM : $nim', style: const pw.TextStyle(fontSize: 7)),
                if (counters.trim().isNotEmpty)
                  pw.Text(
                    'Compteurs : $counters',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                if (fiscalDateTime.trim().isNotEmpty)
                  pw.Text(
                    'Date fisc. : $fiscalDateTime',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                if (qrCode.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrCode.trim(),
                      width: 70,
                      height: 70,
                    ),
                  ),
                ],
              ],

              divider(),
              pw.Center(
                child: pw.Text(
                  'Merci de votre visite',
                  style: const pw.TextStyle(fontSize: 8),
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
  /// TABLE HELPERS
  /// =========================
  Map<String, dynamic>? _tryParseJson(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  /// Initiales de repli quand aucun logo n'est disponible.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'TK';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Ligne du récapitulatif fiscal (libellé à gauche, montant à droite).
  pw.Widget _sumLine(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: bold ? 12 : 10,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: bold ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _ticketLine(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: bold ? 10 : 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: bold ? 10 : 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(_safeString(text)),
    );
  }
}
