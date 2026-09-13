import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:takapp/core/errors/app_error.dart';

class PrinterService {
  /// =========================
  /// PRINT PDF
  /// =========================

  Future<void> printPdf(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const AppError(AppErrorCode.emptyPdfDocument);
    }

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'takapp_document',
    );
  }

  /// =========================
  /// SHARE PDF
  /// =========================

  Future<void> sharePdf(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) {
      throw const AppError(AppErrorCode.emptyPdfDocument);
    }

    final safeFilename = filename.trim().isEmpty
        ? 'takapp_document.pdf'
        : filename;

    await Printing.sharePdf(bytes: bytes, filename: safeFilename);
  }

  /// =========================
  /// PREVIEW PDF
  /// =========================

  Future<void> previewPdf(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const AppError(AppErrorCode.emptyPdfDocument);
    }

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'takapp_preview',
    );
  }

  /// =========================
  /// AVAILABLE PRINTERS
  /// =========================

  Future<List<Printer>> getAvailablePrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (_) {
      return [];
    }
  }

  /// =========================
  /// PRINT DIRECTLY TO PRINTER
  /// =========================

  Future<void> printToPrinter({
    required Printer printer,
    required Uint8List bytes,
    String documentName = 'takapp_document',
  }) async {
    if (bytes.isEmpty) {
      throw const AppError(AppErrorCode.emptyPdfDocument);
    }

    await Printing.directPrintPdf(
      printer: printer,
      name: documentName,
      onLayout: (format) async => bytes,
    );
  }
}
