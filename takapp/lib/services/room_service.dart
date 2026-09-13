import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';

import '../modeles/room_model.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String? establishmentId;

  RoomService({this.establishmentId});

  /// =========================
  /// HELPERS SAAS
  /// =========================

  String _resolveEstablishmentId(String? id) {
    final resolved = (id ?? establishmentId ?? '').trim();

    if (resolved.isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    return resolved;
  }

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('rooms');
  }

  List<RoomModel> _sortRooms(List<RoomModel> rooms) {
    rooms.sort((a, b) {
      // Tri naturel par numéro : essaie numérique, sinon alphabétique
      final an = int.tryParse(a.number);
      final bn = int.tryParse(b.number);
      if (an != null && bn != null) return an.compareTo(bn);
      return a.number.toLowerCase().compareTo(b.number.toLowerCase());
    });

    return rooms;
  }

  /// =========================
  /// STREAM ALL ROOMS
  /// =========================

  Stream<List<RoomModel>> streamRooms({String? establishmentId}) {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    return _col(establishmentId: resolvedEstablishmentId).snapshots().map((
      snapshot,
    ) {
      final rooms = snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.id, doc.data()))
          .where((room) => room.isActive)
          .toList();

      return _sortRooms(rooms);
    });
  }

  /// =========================
  /// CREATE ROOM
  /// =========================

  Future<void> createRoom({
    String? establishmentId,
    required String number,
    required String roomTypeId,
    required String roomTypeName,
    double? priceOverride,
    required String floor,
    required String createdBy,
    required String createdByName,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    final cleanNumber = number.trim();

    if (cleanNumber.isEmpty) {
      throw const AppError(AppErrorCode.invalidRoomNumber);
    }

    if (roomTypeId.trim().isEmpty) {
      throw const AppError(AppErrorCode.roomTypeRequired);
    }

    /// =========================
    /// CHECK DUPLICATE
    /// =========================

    final existing = await _col(
      establishmentId: resolvedEstablishmentId,
    ).where('number', isEqualTo: cleanNumber).limit(1).get();

    if (existing.docs.isNotEmpty) {
      throw const AppError(AppErrorCode.roomNumberAlreadyExists);
    }

    /// =========================
    /// CREATE
    /// =========================

    final docRef = _col(establishmentId: resolvedEstablishmentId).doc();

    await docRef.set({
      'establishmentId': resolvedEstablishmentId,
      'number': cleanNumber,
      'roomTypeId': roomTypeId.trim(),
      'roomTypeName': roomTypeName.trim(),
      'priceOverride': priceOverride,
      'status': 'available',
      'floor': floor.trim(),
      'isActive': true,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// UPDATE ROOM
  /// =========================

  Future<void> updateRoom({
    String? establishmentId,
    required String roomId,
    required String number,
    required String roomTypeId,
    required String roomTypeName,
    double? priceOverride,
    required String floor,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(roomId).update({
      'number': number.trim(),
      'roomTypeId': roomTypeId.trim(),
      'roomTypeName': roomTypeName.trim(),
      'priceOverride': priceOverride,
      'floor': floor.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// UPDATE STATUS
  /// =========================

  Future<void> updateRoomStatus({
    String? establishmentId,
    required String roomId,
    required String status,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    const allowed = ['available', 'occupied', 'cleaning', 'maintenance'];
    if (!allowed.contains(status)) {
      throw const AppError(AppErrorCode.invalidRoomStatus);
    }

    await _col(establishmentId: resolvedEstablishmentId).doc(roomId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// DISABLE ROOM
  /// =========================

  Future<void> disableRoom({
    String? establishmentId,
    required String roomId,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(roomId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  /// =========================
  /// FIND ROOM BY NUMBER
  /// =========================
  /// Retrouve une chambre active à partir de son numéro (texte).
  /// Renvoie null si aucune chambre ne correspond.
  Future<RoomModel?> findRoomByNumber({
    String? establishmentId,
    required String number,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    final cleanNumber = number.trim();
    if (cleanNumber.isEmpty) return null;

    final snap = await _col(
      establishmentId: resolved,
    ).where('number', isEqualTo: cleanNumber).limit(1).get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final room = RoomModel.fromMap(doc.id, doc.data());

    // On ne considère que les chambres actives
    if (!room.isActive) return null;

    return room;
  }
}
