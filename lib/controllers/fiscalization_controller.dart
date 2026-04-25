import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../modeles/emcf_invoice_create_response_model.dart';
import '../modeles/emcf_invoice_request_model.dart';
import '../modeles/emcf_security_element_model.dart';
import '../services/emcf_invoice_service.dart';
import '../services/room_invoice_service.dart';

class FiscalizationController extends ChangeNotifier {
  final EmcfInvoiceService _emcfService;
  final RoomInvoiceService _roomInvoiceService;

  FiscalizationController({
    EmcfInvoiceService? emcfService,
    RoomInvoiceService? roomInvoiceService,
  }) : _emcfService = emcfService ?? EmcfInvoiceService(),
       _roomInvoiceService = roomInvoiceService ?? RoomInvoiceService();

  bool isLoading = false;
  String? errorMessage;
  EmcfInvoiceCreateResponseModel? createResult;
  EmcfSecurityElementModel? confirmResult;

  Future<void> fiscalizeInvoice({
    required String invoiceId,
    required EmcfInvoiceRequestModel request,
  }) async {
    isLoading = true;
    errorMessage = null;
    createResult = null;
    confirmResult = null;
    notifyListeners();

    try {
      await _roomInvoiceService.markFiscalizationPending(
        invoiceId: invoiceId,
        requestSnapshot: request.toMap(),
      );

      final created = await _emcfService.createInvoice(request);
      createResult = created;

      if (created.hasError) {
        final err = created.errorDesc.isNotEmpty
            ? created.errorDesc
            : 'Erreur lors de la création e-MCF';
        errorMessage = err;

        await _roomInvoiceService.markFiscalizationFailed(
          invoiceId: invoiceId,
          error: err,
          rawResponse: jsonEncode(created.raw),
        );
        return;
      }

      final confirmed = await _emcfService.confirmInvoice(created.uid);
      confirmResult = confirmed;

      if (confirmed.hasError) {
        final err = confirmed.errorDesc.isNotEmpty
            ? confirmed.errorDesc
            : 'Erreur lors de la confirmation e-MCF';
        errorMessage = err;

        await _roomInvoiceService.markFiscalizationFailed(
          invoiceId: invoiceId,
          error: err,
          rawResponse: jsonEncode(confirmed.raw),
        );
        return;
      }

      await _roomInvoiceService.markFiscalizationSuccess(
        invoiceId: invoiceId,
        emcfUid: created.uid,
        mecefCode: confirmed.codeMECeFDGI,
        nim: confirmed.nim,
        counter: confirmed.counters,
        machineDateTime: confirmed.dateTime,
        qrCode: confirmed.qrCode,
        rawCreateResponse: jsonEncode(created.raw),
        rawConfirmResponse: jsonEncode(confirmed.raw),
      );
    } catch (e) {
      errorMessage = e.toString();

      await _roomInvoiceService.markFiscalizationFailed(
        invoiceId: invoiceId,
        error: errorMessage!,
        rawResponse: '',
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
