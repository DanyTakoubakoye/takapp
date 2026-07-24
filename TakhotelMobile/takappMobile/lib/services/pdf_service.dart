import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:takapp/modeles/order_item_model.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';

class PdfService {
  String _formatAmount(double value) {
    return '${value.toStringAsFixed(0)} FCFA';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TAKHOTEL',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Divider(),
      ],
    );
  }

  Future<List<int>> buildOrderTicketPdf({
    required OrderModel order,
    required List<OrderItemModel> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('TICKET DE COMMANDE'),
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
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Article',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Qté',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
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
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${item.quantity}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(_formatAmount(item.totalPrice)),
                        ),
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

  Future<List<int>> buildPaymentReceiptPdf({
    required OrderModel order,
    required PaymentModel payment,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('REÇU D’ENCAISSEMENT'),
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
              pw.Text('Merci pour votre visite à TAKHOTEL.'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> buildServerHandoverPdf({
    required ServerHandoverModel handover,
    required List<PaymentModel> payments,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            _buildHeader('BORDEREAU DE VERSEMENT SERVEUR'),
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
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Commande',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Mode',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Montant',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...payments.map(
                  (payment) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(payment.orderNumber),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(payment.method),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(_formatAmount(payment.amount)),
                      ),
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

  Future<List<int>> buildManagerValidationPdf({
    required ServerHandoverModel handover,
    required List<PaymentModel> payments,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            _buildHeader('BORDEREAU DE VALIDATION GÉRANTE'),
            pw.SizedBox(height: 8),
            pw.Text('Serveur : ${handover.serveurName}'),
            pw.Text(
              'Montant déclaré : ${_formatAmount(handover.declaredAmount)}',
            ),
            pw.Text(
              'Montant validé : ${_formatAmount(handover.validatedAmount ?? 0)}',
            ),
            pw.Text('Statut : ${handover.status}'),
            pw.Text('Reçu par : ${handover.receivedByManagerName ?? "-"}'),
            pw.Text('Date validation : ${_formatDate(handover.validatedAt)}'),
            pw.SizedBox(height: 12),
            pw.Text(
              'Paiements concernés',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            ...payments.map(
              (payment) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(payment.orderNumber),
                    pw.Text(payment.method),
                    pw.Text(_formatAmount(payment.amount)),
                  ],
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
    required DateTime startDate,
    required DateTime endDate,
    required double totalEntries,
    required double totalExpenses,
    required double theoreticalBalance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('RAPPORT COMPTABLE SIMPLE'),
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
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> buildQuitusPdf({
    required String accountType,
    required double theoreticalAmount,
    required double physicalAmount,
    required DateTime date,
    required String validatedByName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('QUITUS DE VALIDATION'),
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
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('FACTURE HÉBERGEMENT'),

              pw.SizedBox(height: 10),

              pw.Text('Client: $clientName'),
              pw.Text('Chambre: $room'),
              pw.Text('Séjour: ${_formatDate(start)} → ${_formatDate(end)}'),

              pw.SizedBox(height: 10),

              pw.Text('Nuitées: $nights'),
              pw.Text('Prix nuit: ${_formatAmount(pricePerNight)}'),

              pw.Divider(),

              pw.Text('Chambre: ${_formatAmount(nights * pricePerNight)}'),
              pw.Text('Extras: ${_formatAmount(extras)}'),
              pw.Text('Services: ${_formatAmount(services)}'),

              pw.Divider(),

              pw.Text(
                'TOTAL: ${_formatAmount(total)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
