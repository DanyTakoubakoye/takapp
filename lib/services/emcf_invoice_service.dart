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

  /// =========================
  /// HEADERS
  /// =========================

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',

    'Accept': 'application/json',

    'Authorization': 'Bearer $bearerToken',
  };

  /// =========================
  /// STATUS
  /// =========================

  Future<EmcfStatusModel> getStatus({required String establishmentId}) async {
    print(
      '[EMCF][$establishmentId] '
      'getStatus()',
    );

    final response = await http.get(
      Uri.parse(invoiceBaseUrl),
      headers: _headers,
    );

    _checkUnauthorized(response);

    _checkHttpError(response: response, operation: 'getStatus');

    final data = _decodeMap(response.body, operation: 'getStatus');

    return EmcfStatusModel.fromMap(data);
  }

  /// =========================
  /// CREATE INVOICE
  /// =========================

  Future<EmcfInvoiceCreateResponseModel> createInvoice({
    required String establishmentId,
    required EmcfInvoiceRequestModel request,
  }) async {
    print(
      '[EMCF][$establishmentId] '
      'createInvoice()',
    );

    final body = request.toMap();

    final response = await http.post(
      Uri.parse(invoiceBaseUrl),
      headers: _headers,
      body: jsonEncode(body),
    );

    _checkUnauthorized(response);

    _checkHttpError(response: response, operation: 'createInvoice');

    final data = _decodeMap(response.body, operation: 'createInvoice');

    return EmcfInvoiceCreateResponseModel.fromMap(data);
  }

  /// =========================
  /// CONFIRM INVOICE
  /// =========================

  Future<EmcfSecurityElementModel> confirmInvoice({
    required String establishmentId,
    required String uid,
  }) async {
    print(
      '[EMCF][$establishmentId] '
      'confirmInvoice($uid)',
    );

    final putResponse = await http.put(
      Uri.parse('$invoiceBaseUrl/$uid/confirm'),
      headers: _headers,
    );

    if (_isSuccess(putResponse)) {
      final data = _decodeMap(putResponse.body, operation: 'confirmInvoice');

      return EmcfSecurityElementModel.fromMap(data);
    }

    final postResponse = await http.post(
      Uri.parse('$invoiceBaseUrl/$uid/confirm'),
      headers: _headers,
    );

    _checkUnauthorized(postResponse);

    _checkHttpError(
      response: postResponse,
      operation: 'confirmInvoice',
      extra: 'PUT=${putResponse.statusCode}',
    );

    final data = _decodeMap(postResponse.body, operation: 'confirmInvoice');

    return EmcfSecurityElementModel.fromMap(data);
  }

  /// =========================
  /// CANCEL INVOICE
  /// =========================

  Future<EmcfSecurityElementModel> cancelInvoice({
    required String establishmentId,
    required String uid,
  }) async {
    print(
      '[EMCF][$establishmentId] '
      'cancelInvoice($uid)',
    );

    final putResponse = await http.put(
      Uri.parse('$invoiceBaseUrl/$uid/cancel'),
      headers: _headers,
    );

    if (_isSuccess(putResponse)) {
      final data = _decodeMap(putResponse.body, operation: 'cancelInvoice');

      return EmcfSecurityElementModel.fromMap(data);
    }

    final postResponse = await http.post(
      Uri.parse('$invoiceBaseUrl/$uid/cancel'),
      headers: _headers,
    );

    _checkUnauthorized(postResponse);

    _checkHttpError(
      response: postResponse,
      operation: 'cancelInvoice',
      extra: 'PUT=${putResponse.statusCode}',
    );

    final data = _decodeMap(postResponse.body, operation: 'cancelInvoice');

    return EmcfSecurityElementModel.fromMap(data);
  }

  /// =========================
  /// GET PENDING INVOICE
  /// =========================

  Future<Map<String, dynamic>> getPendingInvoiceDetails({
    required String establishmentId,
    required String uid,
  }) async {
    print(
      '[EMCF][$establishmentId] '
      'getPendingInvoiceDetails($uid)',
    );

    final response = await http.get(
      Uri.parse('$invoiceBaseUrl/$uid'),
      headers: _headers,
    );

    _checkUnauthorized(response);

    _checkHttpError(response: response, operation: 'getPendingInvoiceDetails');

    return _decodeMap(response.body, operation: 'getPendingInvoiceDetails');
  }

  /// =========================
  /// HELPERS
  /// =========================

  bool _isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('Token JWT invalide ou expiré');
    }
  }

  void _checkHttpError({
    required http.Response response,
    required String operation,
    String extra = '',
  }) {
    if (!_isSuccess(response)) {
      throw Exception(
        'Erreur $operation '
        '$extra '
        '[${response.statusCode}] '
        ': ${response.body}',
      );
    }
  }

  Map<String, dynamic> _decodeMap(String body, {required String operation}) {
    final data = jsonDecode(body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Réponse invalide de $operation');
    }

    return data;
  }
}
