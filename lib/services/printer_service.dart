import 'dart:typed_data';
import 'package:printing/printing.dart';

class PrinterService {
  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> previewPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<List<Printer>> getAvailablePrinters() async {
    return await Printing.listPrinters();
  }
}
