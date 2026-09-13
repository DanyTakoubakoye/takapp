import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';

import '../services/store_stock_service.dart';

import '../services/room_service.dart';

class HygieneDailyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreStockService _stockService = StoreStockService();
  final RoomService _roomService = RoomService();

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('hygiene_daily_entries');
  }

  /// =========================
  /// CREATE DAILY ENTRY
  /// =========================

  Future<void> createDailyEntry({
    required String establishmentId,
    required String roomNumber,
    required String preparedBy,
    required String preparedByName,
    required String note,
    required List<Map<String, dynamic>> usedItems,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    if (roomNumber.trim().isEmpty) {
      throw const AppError(AppErrorCode.roomNumberRequired);
    }

    if (usedItems.isEmpty) {
      throw const AppError(AppErrorCode.addAtLeastOneUsedItem);
    }

    final docRef = await _col(establishmentId: establishmentId).add({
      'establishmentId': establishmentId,
      'roomNumber': roomNumber.trim(),
      'preparedBy': preparedBy,
      'preparedByName': preparedByName,
      'note': note.trim(),
      'preparedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final item in usedItems) {
      final itemId = item['itemId']?.toString() ?? '';
      final itemName = item['itemName']?.toString() ?? '';
      final unit = item['unit']?.toString() ?? '';
      final quantityUsed = _toDouble(item['quantityUsed']);

      if (itemId.isEmpty) {
        throw const AppError(AppErrorCode.invalidStockItemMissingId);
      }

      if (quantityUsed <= 0) {
        throw AppError(AppErrorCode.invalidQuantityForItem, name: itemName);
      }

      await docRef.collection('items').add({
        'establishmentId': establishmentId,
        'itemId': itemId,
        'itemName': itemName,
        'unit': unit,
        'quantityUsed': quantityUsed,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _stockService.removeStock(
        establishmentId: establishmentId,
        store: 'hotel',
        itemId: itemId,
        itemName: itemName,
        unit: unit,
        quantity: quantityUsed,
        performedBy: preparedBy,
        performedByName: preparedByName,
        reason: 'Préparation chambre $roomNumber',
        allowNegative: true,
      );
    }

    // Libération automatique de la chambre.
    // Si la chambre est "à nettoyer" (cleaning) — donc après un check-out —
    // le ménage déclaré la remet "disponible" (available).
    // Si elle est occupée (ménage en cours de séjour), on ne touche pas au statut.
    // La libération est un bonus : si la chambre n'existe pas ou échoue,
    // on ne fait pas échouer l'enregistrement du ménage.
    try {
      final room = await _roomService.findRoomByNumber(
        establishmentId: establishmentId,
        number: roomNumber,
      );
      if (room != null && room.status == 'cleaning') {
        await _roomService.updateRoomStatus(
          establishmentId: establishmentId,
          roomId: room.id,
          status: 'available',
        );
      }
    } catch (_) {
      // Libération ignorée en cas d'erreur : le ménage reste enregistré.
    }
  }

  /// =========================
  /// STREAM DAILY ENTRIES
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDailyEntries({
    required String establishmentId,
  }) {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    return _col(
      establishmentId: establishmentId,
    ).orderBy('preparedAt', descending: true).snapshots();
  }

  /// =========================
  /// HELPERS
  /// =========================

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
