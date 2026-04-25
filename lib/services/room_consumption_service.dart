import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/room_consumption_line_model.dart';
import '../modeles/room_consumption_invoice_model.dart';

class RoomConsumptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<RoomConsumptionInvoiceModel> getConsumption({
    required String roomNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
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

      final query = await _firestore
          .collection('orders')
          .where('clientType', isEqualTo: 'hotel')
          .where('roomNumber', isEqualTo: roomNumber)
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
                : quantity * unitPrice;

            final line = RoomConsumptionLineModel(
              itemName: item['name']?.toString() ?? '',
              quantity: quantity,
              unitPrice: unitPrice,
              total: lineTotal,
              source: data['isForBar'] == true ? 'Bar' : 'Restaurant',
              createdAt: _toDateTime(data['createdAt']),
              serveur: data['createdByName']?.toString() ?? '',
            );

            total += line.total;
            lines.add(line);
          } catch (itemError) {
            // Ignore seulement l'item défectueux au lieu de bloquer toute la facture
            // Tu peux aussi logger l'id si besoin :
            // debugPrint('Item ignoré (${itemDoc.id}) : $itemError');
          }
        }
      }

      lines.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return RoomConsumptionInvoiceModel(
        roomNumber: roomNumber,
        startDate: start,
        endDate: end,
        lines: lines,
        total: total,
      );
    } on FirebaseException catch (e) {
      throw Exception('Erreur Firestore: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Erreur lors du chargement des consommations: $e');
    }
  }
}
