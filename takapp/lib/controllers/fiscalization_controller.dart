import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:takapp/certilink/services/certilink_certification_service.dart';
import 'package:takapp/certilink/services/certilink_config_service.dart';

import '../modeles/emcf_invoice_create_response_model.dart';
import '../modeles/emcf_invoice_request_model.dart';
import '../modeles/emcf_security_element_model.dart';

import '../services/room_invoice_service.dart';

class FiscalizationController extends ChangeNotifier {
  final CertilinkConfigService _certilinkConfigService;
  final CertilinkCertificationService _certilinkCertificationService;
  final RoomInvoiceService _roomInvoiceService;

  FiscalizationController({
    CertilinkConfigService? certilinkConfigService,
    CertilinkCertificationService? certilinkCertificationService,
    RoomInvoiceService? roomInvoiceService,
  }) : _certilinkConfigService =
           certilinkConfigService ?? CertilinkConfigService(),
       _certilinkCertificationService =
           certilinkCertificationService ?? CertilinkCertificationService(),
       _roomInvoiceService = roomInvoiceService ?? RoomInvoiceService();

  bool isLoading = false;
  String? errorMessage;

  /// Conservé pour compatibilité avec les anciennes vues.
  EmcfInvoiceCreateResponseModel? createResult;

  /// Conservé pour compatibilité avec les anciennes vues.
  EmcfSecurityElementModel? confirmResult;

  /// =========================
  /// FISCALIZE INVOICE VIA CERTILINK
  /// =========================
  ///
  /// Cette méthode garde l'ancienne signature pour ne pas casser :
  /// - FacturationChambrePage
  /// - DetailFactureChambrePage
  /// - ListeFacturesPage
  ///
  /// Mais elle n'appelle plus directement e-MECeF.
  /// Elle appelle maintenant CertiLink via le SDK Flutter.
  ///

  Future<bool> fiscalizeInvoice({
    required String establishmentId,
    required String invoiceId,
    required EmcfInvoiceRequestModel request,
  }) async {
    if (establishmentId.trim().isEmpty) {
      errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return false;
    }

    if (invoiceId.trim().isEmpty) {
      errorMessage = 'Facture introuvable.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    createResult = null;
    confirmResult = null;
    notifyListeners();

    try {
      await _roomInvoiceService.markFiscalizationPending(
        establishmentId: establishmentId,
        invoiceId: invoiceId,
        requestSnapshot: {
          ...request.toMap(),
          'fiscalProvider': 'certilink',
          'source': 'takapp',
        },
      );

      final config = await _certilinkConfigService.getConfig(establishmentId);

      if (!config.enabled) {
        throw Exception('CertiLink est désactivé pour cet établissement.');
      }

      if (config.tenantId.trim().isEmpty || config.apiKey.trim().isEmpty) {
        throw Exception(
          'Configuration CertiLink incomplète : tenantId ou apiKey manquant.',
        );
      }

      final response = await _certilinkCertificationService.certifyInvoice(
        config: config,
        externalInvoiceId: invoiceId,
        externalInvoiceNumber: 'TAKAPP-$invoiceId',
        invoiceType: request.type.toLowerCase(),
        client: _mapClient(request.client),
        items: _mapItems(request),
        invoiceDate: DateTime.now(),
      );

      confirmResult = EmcfSecurityElementModel(
        dateTime:
            response.certificationDate?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        qrCode: response.qrCode,
        codeMECeFDGI: response.mecefCode,
        counters: response.counters,
        nim: response.nim,
        errorCode: '',
        errorDesc: '',
        raw: response.raw,
      );

      await _roomInvoiceService.markFiscalizationSuccess(
        establishmentId: establishmentId,
        invoiceId: invoiceId,
        emcfUid: response.certilinkInvoiceId,
        mecefCode: response.mecefCode,
        nim: response.nim,
        counter: response.counters,
        machineDateTime:
            response.certificationDate?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        qrCode: response.qrCode,
        rawCreateResponse: '',
        rawConfirmResponse: jsonEncode(response.raw),
      );

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');

      confirmResult = EmcfSecurityElementModel(
        dateTime: DateTime.now().toIso8601String(),
        qrCode: '',
        codeMECeFDGI: '',
        counters: '',
        nim: '',
        errorCode: 'certilink_error',
        errorDesc: errorMessage ?? 'Erreur CertiLink',
        raw: {
          'error': errorMessage ?? 'Erreur CertiLink',
          'provider': 'certilink',
        },
      );

      try {
        await _roomInvoiceService.markFiscalizationFailed(
          establishmentId: establishmentId,
          invoiceId: invoiceId,
          error: errorMessage ?? 'Erreur CertiLink',
          rawResponse: jsonEncode(confirmResult?.raw ?? {}),
        );
      } catch (_) {
        // On ne masque pas l'erreur principale.
      }

      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =========================
  /// MAPPERS
  /// =========================

  Map<String, dynamic> _mapClient(Map<String, dynamic>? client) {
    final data = client ?? {};

    return {
      'name': data['name']?.toString() ?? '',
      'ifu': data['ifu']?.toString() ?? '',
      'phone': data['phone']?.toString() ?? data['contact']?.toString() ?? '',
      'email': data['email']?.toString() ?? '',
      'address': data['address']?.toString() ?? '',
    };
  }

  List<Map<String, dynamic>> _mapItems(EmcfInvoiceRequestModel request) {
    return request.items.map((item) {
      return {
        'itemId': item.code,
        'ref': item.code,
        'name': item.name,
        'description': item.name,
        'quantity': item.quantity,
        'unit': 'Unité',
        'unitPrice': item.price,
        'discountAmount': 0,
        'taxGroup': item.taxGroup,
        'specificTaxAmount': item.taxSpecific,
      };
    }).toList();
  }

  /// =========================
  /// CLEAR STATE
  /// =========================

  void clearState() {
    isLoading = false;
    errorMessage = null;
    createResult = null;
    confirmResult = null;
    notifyListeners();
  }
}
