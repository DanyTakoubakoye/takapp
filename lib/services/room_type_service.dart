import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/room_type_model.dart';

class RoomTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String? establishmentId;

  RoomTypeService({this.establishmentId});

  /// =========================
  /// HELPERS SAAS
  /// =========================

  String _resolveEstablishmentId(String? id) {
    final resolved = (id ?? establishmentId ?? '').trim();

    if (resolved.isEmpty) {
      throw Exception('Établissement introuvable.');
    }

    return resolved;
  }

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('roomTypes');
  }

  List<RoomTypeModel> _sortTypes(List<RoomTypeModel> types) {
    types.sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return types;
  }

  /// =========================
  /// STREAM ALL TYPES
  /// =========================

  Stream<List<RoomTypeModel>> streamRoomTypes({String? establishmentId}) {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    return _col(establishmentId: resolvedEstablishmentId).snapshots().map((
      snapshot,
    ) {
      final types = snapshot.docs
          .map((doc) => RoomTypeModel.fromMap(doc.id, doc.data()))
          .where((type) => type.isActive)
          .toList();

      return _sortTypes(types);
    });
  }

  /// =========================
  /// CREATE TYPE
  /// =========================

  Future<void> createRoomType({
    String? establishmentId,
    required String name,
    required double basePrice,
    required int capacity,
    required String description,
    required List<String> amenities,
    required String createdBy,
    required String createdByName,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Nom du type invalide.');
    }

    if (basePrice <= 0) {
      throw Exception('Le prix par nuit doit être supérieur à 0.');
    }

    /// =========================
    /// CHECK DUPLICATE
    /// =========================

    final existing = await _col(
      establishmentId: resolvedEstablishmentId,
    ).where('name', isEqualTo: cleanName).limit(1).get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Ce type de chambre existe déjà.');
    }

    /// =========================
    /// CREATE
    /// =========================

    final docRef = _col(establishmentId: resolvedEstablishmentId).doc();

    await docRef.set({
      'establishmentId': resolvedEstablishmentId,
      'name': cleanName,
      'basePrice': basePrice,
      'capacity': capacity,
      'description': description.trim(),
      'amenities': amenities,
      'isActive': true,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// UPDATE TYPE
  /// =========================

  Future<void> updateRoomType({
    String? establishmentId,
    required String typeId,
    required String name,
    required double basePrice,
    required int capacity,
    required String description,
    required List<String> amenities,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(typeId).update({
      'name': name.trim(),
      'basePrice': basePrice,
      'capacity': capacity,
      'description': description.trim(),
      'amenities': amenities,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// DISABLE TYPE
  /// =========================

  Future<void> disableRoomType({
    String? establishmentId,
    required String typeId,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(typeId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
