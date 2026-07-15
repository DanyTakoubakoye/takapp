import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modeles/fiscal_invoice_request_model.dart';
import '../modeles/fiscalization_result_model.dart';

class FiscalBridgeService {
  final String baseUrl;

  FiscalBridgeService({this.baseUrl = 'http://127.0.0.1:8787'});

  /// =========================
  /// SEND INVOICE
  /// =========================
  ///
  /// SaaS :
  /// chaque requête est liée
  /// à un établissement précis.
  ///

  Future<FiscalizationResultModel> sendInvoice({
    required String establishmentId,
    required FiscalInvoiceRequestModel request,
  }) async {
    print(
      '[FISCAL_BRIDGE]'
      '[$establishmentId] '
      'sendInvoice()',
    );

    final body = request.toMap();

    final response = await http.post(
      Uri.parse('$baseUrl/print-invoice'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode(body),
    );

    /// =========================
    /// HTTP ERROR
    /// =========================

    if (response.statusCode != 200) {
      throw Exception(
        'Bridge fiscal inaccessible '
        '[${response.statusCode}] '
        '${response.body}',
      );
    }

    /// =========================
    /// JSON PARSE
    /// =========================

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du bridge fiscal');
    }

    /// =========================
    /// AJOUT CONTEXTE SAAS
    /// =========================

    data['establishmentId'] = establishmentId;

    data['establishmentName'] = request.establishmentName;

    return FiscalizationResultModel.fromMap(data);
  }
}
