import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/emcf_config.dart';
import '../modeles/emcf_invoice_create_response_model.dart';
import '../modeles/emcf_invoice_request_model.dart';
import '../modeles/emcf_security_element_model.dart';
import '../modeles/emcf_status_model.dart';

class EmcfInvoiceService {
  final String invoiceBaseUrl;
  final String infoBaseUrl;
  final String bearerToken;

  EmcfInvoiceService({
    String? invoiceBaseUrl,
    String? infoBaseUrl,
    String? bearerToken,
  }) : invoiceBaseUrl = invoiceBaseUrl ?? EmcfConfig.invoiceBaseUrl,
       infoBaseUrl = infoBaseUrl ?? EmcfConfig.infoBaseUrl,
       bearerToken = bearerToken ?? EmcfConfig.bearerToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $bearerToken',
  };

  Future<EmcfStatusModel> getStatus() async {
    final response = await http.get(
      Uri.parse(invoiceBaseUrl),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw Exception('Token JWT invalide ou expiré');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur getStatus [${response.statusCode}] : ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide de getStatus');
    }

    return EmcfStatusModel.fromMap(data);
  }

  Future<EmcfInvoiceCreateResponseModel> createInvoice(
    EmcfInvoiceRequestModel request,
  ) async {
    final response = await http.post(
      Uri.parse(invoiceBaseUrl),
      headers: _headers,
      body: jsonEncode(request.toMap()),
    );

    if (response.statusCode == 401) {
      throw Exception('Token JWT invalide ou expiré');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur createInvoice [${response.statusCode}] : ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide de createInvoice');
    }

    return EmcfInvoiceCreateResponseModel.fromMap(data);
  }

  Future<EmcfSecurityElementModel> confirmInvoice(String uid) async {
    final putResponse = await http.put(
      Uri.parse('$invoiceBaseUrl/$uid/confirm'),
      headers: _headers,
    );

    if (putResponse.statusCode >= 200 && putResponse.statusCode < 300) {
      final data = jsonDecode(putResponse.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Réponse invalide de confirmInvoice');
      }
      return EmcfSecurityElementModel.fromMap(data);
    }

    final postResponse = await http.post(
      Uri.parse('$invoiceBaseUrl/$uid/confirm'),
      headers: _headers,
    );

    if (postResponse.statusCode == 401) {
      throw Exception('Token JWT invalide ou expiré');
    }

    if (postResponse.statusCode < 200 || postResponse.statusCode >= 300) {
      throw Exception(
        'Erreur confirmInvoice [PUT=${putResponse.statusCode}, POST=${postResponse.statusCode}] : ${postResponse.body}',
      );
    }

    final data = jsonDecode(postResponse.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide de confirmInvoice');
    }

    return EmcfSecurityElementModel.fromMap(data);
  }

  Future<EmcfSecurityElementModel> cancelInvoice(String uid) async {
    final putResponse = await http.put(
      Uri.parse('$invoiceBaseUrl/$uid/cancel'),
      headers: _headers,
    );

    if (putResponse.statusCode >= 200 && putResponse.statusCode < 300) {
      final data = jsonDecode(putResponse.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Réponse invalide de cancelInvoice');
      }
      return EmcfSecurityElementModel.fromMap(data);
    }

    final postResponse = await http.post(
      Uri.parse('$invoiceBaseUrl/$uid/cancel'),
      headers: _headers,
    );

    if (postResponse.statusCode == 401) {
      throw Exception('Token JWT invalide ou expiré');
    }

    if (postResponse.statusCode < 200 || postResponse.statusCode >= 300) {
      throw Exception(
        'Erreur cancelInvoice [PUT=${putResponse.statusCode}, POST=${postResponse.statusCode}] : ${postResponse.body}',
      );
    }

    final data = jsonDecode(postResponse.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide de cancelInvoice');
    }

    return EmcfSecurityElementModel.fromMap(data);
  }

  Future<Map<String, dynamic>> getPendingInvoiceDetails(String uid) async {
    final response = await http.get(
      Uri.parse('$invoiceBaseUrl/$uid'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw Exception('Token JWT invalide ou expiré');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur getPendingInvoiceDetails [${response.statusCode}] : ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide de getPendingInvoiceDetails');
    }

    return data;
  }
}
