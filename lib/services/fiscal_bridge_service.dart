import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modeles/fiscal_invoice_request_model.dart';
import '../modeles/fiscalization_result_model.dart';

class FiscalBridgeService {
  final String baseUrl;

  FiscalBridgeService({this.baseUrl = 'http://127.0.0.1:8787'});

  Future<FiscalizationResultModel> sendInvoice({
    required FiscalInvoiceRequestModel request,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/print-invoice'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toMap()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Bridge fiscal inaccessible: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du bridge fiscal');
    }

    return FiscalizationResultModel.fromMap(data);
  }
}
