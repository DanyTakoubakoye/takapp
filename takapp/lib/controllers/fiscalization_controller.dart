import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
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

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

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
    bool persistToInvoice = true,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return false;
    }

    if (invoiceId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.invoiceNotFound);
      notifyListeners();
      return false;
    }

    isLoading = true;
    _error = null;
    createResult = null;
    confirmResult = null;
    notifyListeners();

    try {
      if (persistToInvoice) {
        await _roomInvoiceService.markFiscalizationPending(
          establishmentId: establishmentId,
          invoiceId: invoiceId,
          requestSnapshot: {
            ...request.toMap(),
            'fiscalProvider': 'certilink',
            'source': 'takapp',
          },
        );
      }
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

      if (persistToInvoice) {
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
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e;

      /// Texte TECHNIQUE, destiné à Firestore et non à l'écran : il est
      /// persisté tel quel dans la facture, donc il ne doit pas dépendre
      /// de la langue active de l'utilisateur.
      final rawError = e.toString().replaceFirst('Exception: ', '').trim();

      final persistedError = rawError.isEmpty ? 'CertiLink error' : rawError;

      confirmResult = EmcfSecurityElementModel(
        dateTime: DateTime.now().toIso8601String(),
        qrCode: '',
        codeMECeFDGI: '',
        counters: '',
        nim: '',
        errorCode: 'certilink_error',
        errorDesc: persistedError,
        raw: {'error': persistedError, 'provider': 'certilink'},
      );

      if (persistToInvoice) {
        try {
          await _roomInvoiceService.markFiscalizationFailed(
            establishmentId: establishmentId,
            invoiceId: invoiceId,
            error: persistedError,
            rawResponse: jsonEncode(confirmResult?.raw ?? {}),
          );
        } catch (_) {
          // On ne masque pas l'erreur principale.
        }
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
    _error = null;
    createResult = null;
    confirmResult = null;
    notifyListeners();
  }
}
