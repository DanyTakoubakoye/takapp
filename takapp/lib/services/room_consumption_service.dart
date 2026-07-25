import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/room_consumption_line_model.dart';
import '../modeles/room_consumption_invoice_model.dart';

class RoomConsumptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _ordersRef({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('orders');
  }

  /// =========================
  /// PARSERS
  /// =========================

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString().trim()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is num) return value.toDouble();

    final cleaned = value.toString().trim().replaceAll(',', '.');

    return double.tryParse(cleaned) ?? 0.0;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();

    if (value is DateTime) return value;

    return DateTime.now();
  }

  /// =========================
  /// GET ROOM CONSUMPTION
  /// =========================

  Future<RoomConsumptionInvoiceModel> getConsumption({
    required String establishmentId,
    required String roomNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }

    if (roomNumber.trim().isEmpty) {
      throw Exception('Veuillez préciser le numéro de chambre.');
    }

    try {
      final DateTime start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );

      final DateTime end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );

      final query = await _ordersRef(establishmentId: establishmentId)
          .where('clientType', isEqualTo: 'hotel')
          .where('roomNumber', isEqualTo: roomNumber.trim())
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final List<RoomConsumptionLineModel> lines = [];

      double total = 0.0;

      for (final doc in query.docs) {
        final data = doc.data();

        final itemsSnapshot = await doc.reference.collection('items').get();

        for (final itemDoc in itemsSnapshot.docs) {
          try {
            final item = itemDoc.data();

            final int quantity = _toInt(item['quantity']);

            final double unitPrice = _toDouble(
              item['price'] ?? item['unitPrice'] ?? item['prix'],
            );

            final double lineTotal = item['total'] != null
                ? _toDouble(item['total'])
                : item['totalPrice'] != null
                ? _toDouble(item['totalPrice'])
                : quantity * unitPrice;

            final line = RoomConsumptionLineModel(
              establishmentId: establishmentId,
              orderId: doc.id,
              paymentId: (data['paymentId'] ?? '').toString(),
              menuItemId: (item['menuItemId'] ?? '').toString(),
              itemName: item['name']?.toString() ?? '',
              quantity: quantity,
              unitPrice: unitPrice,
              total: lineTotal,
              source: data['isForBar'] == true ? 'bar' : 'restaurant',
              serveurId: data['createdBy']?.toString() ?? '',
              serveur: data['createdByName']?.toString() ?? '',
              createdAt: _toDateTime(data['createdAt']),
              isFiscalized: data['isFiscalized'] == true,
              pendingSync: data['pendingSync'] == true,
              syncError: data['syncError'] == true,
            );

            total += line.total;
            lines.add(line);
          } catch (_) {
            // On ignore uniquement l'item défectueux pour ne pas bloquer
            // la génération de la facture de consommation chambre.
          }
        }
      }

      lines.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return RoomConsumptionInvoiceModel(
        establishmentId: establishmentId,
        roomNumber: roomNumber.trim(),
        startDate: start,
        endDate: end,
        lines: lines,
        total: total,
        isFiscalized: false,
        fiscalUid: '',
        qrCode: '',
        nim: '',
        status: 'pending',
        pendingSync: false,
        syncError: false,
      );
    } on FirebaseException catch (e) {
      throw Exception('Erreur Firestore: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Erreur lors du chargement des consommations: $e');
    }
  }
}
