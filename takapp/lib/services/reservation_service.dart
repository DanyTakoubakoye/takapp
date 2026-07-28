import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/reservation_model.dart';
import '../modeles/room_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String? establishmentId;

  ReservationService({this.establishmentId});

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
        .collection('reservations');
  }

  CollectionReference<Map<String, dynamic>> _roomsCol({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('rooms');
  }

  /// Deux périodes [aStart, aEnd) et [bStart, bEnd) se chevauchent
  /// si aStart < bEnd ET bStart < aEnd.
  /// (Le jour de départ n'est pas compté : on peut réserver le jour où un autre part.)
  bool _periodsOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  /// =========================
  /// DISPONIBILITÉ PAR TYPE
  /// =========================
  /// Compte combien de chambres de ce type sont disponibles sur la période.
  /// = (nb de chambres actives du type) - (nb de réservations actives qui chevauchent)
  Future<int> availableCountForType({
    String? establishmentId,
    required String roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeReservationId,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    // 1. Nombre de chambres de ce type (actives)
    final roomsSnap = await _roomsCol(
      establishmentId: resolved,
    ).where('roomTypeId', isEqualTo: roomTypeId).get();

    final totalRooms = roomsSnap.docs
        .map((d) => RoomModel.fromMap(d.id, d.data()))
        .where((r) => r.isActive)
        .length;

    if (totalRooms == 0) return 0;

    // 2. Réservations actives de ce type qui chevauchent la période
    final resaSnap = await _col(
      establishmentId: resolved,
    ).where('roomTypeId', isEqualTo: roomTypeId).get();

    int overlapping = 0;

    for (final doc in resaSnap.docs) {
      if (excludeReservationId != null && doc.id == excludeReservationId) {
        continue;
      }

      final r = ReservationModel.fromMap(doc.id, doc.data());

      // On ne compte que les réservations qui occupent réellement la chambre
      if (r.status != 'confirmed' && r.status != 'checked_in') continue;

      final rIn = r.checkInDate;
      final rOut = r.checkOutDate;
      if (rIn == null || rOut == null) continue;

      if (_periodsOverlap(checkIn, checkOut, rIn, rOut)) {
        overlapping++;
      }
    }

    final available = totalRooms - overlapping;
    return available < 0 ? 0 : available;
  }

  /// =========================
  /// CHAMBRES LIBRES D'UN TYPE
  /// =========================
  /// Retourne les chambres actives, du type donné, actuellement 'available'.
  Future<List<RoomModel>> availableRoomsOfType({
    String? establishmentId,
    required String roomTypeId,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    final snap = await _roomsCol(
      establishmentId: resolved,
    ).where('roomTypeId', isEqualTo: roomTypeId).get();

    final rooms = snap.docs
        .map((d) => RoomModel.fromMap(d.id, d.data()))
        .where((r) => r.isActive && r.status == 'available')
        .toList();

    rooms.sort((a, b) {
      final an = int.tryParse(a.number);
      final bn = int.tryParse(b.number);
      if (an != null && bn != null) return an.compareTo(bn);
      return a.number.toLowerCase().compareTo(b.number.toLowerCase());
    });

    return rooms;
  }

  /// =========================
  /// CHECK-IN
  /// =========================
  /// Assigne une chambre précise à la réservation et marque le séjour actif.
  /// - réservation -> checked_in + assignedRoom
  /// - chambre      -> occupied
  /// Atomique via WriteBatch.
  Future<void> checkIn({
    String? establishmentId,
    required String reservationId,
    required String roomId,
    required String roomNumber,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    final resaRef = _col(establishmentId: resolved).doc(reservationId);
    final roomRef = _roomsCol(establishmentId: resolved).doc(roomId);

    // Vérifications de cohérence
    final resaSnap = await resaRef.get();
    if (!resaSnap.exists) {
      throw Exception('Réservation introuvable.');
    }
    final resa = ReservationModel.fromMap(resaSnap.id, resaSnap.data()!);
    if (resa.status != 'confirmed') {
      throw Exception('Cette réservation n\'est pas en attente d\'arrivée.');
    }

    final roomSnap = await roomRef.get();
    if (!roomSnap.exists) {
      throw Exception('Chambre introuvable.');
    }
    final room = RoomModel.fromMap(roomSnap.id, roomSnap.data()!);
    if (room.status != 'available') {
      throw Exception('Cette chambre n\'est plus disponible.');
    }
    if (room.roomTypeId != resa.roomTypeId) {
      throw Exception('Cette chambre n\'est pas du type réservé.');
    }

    final batch = _firestore.batch();

    batch.update(resaRef, {
      'status': 'checked_in',
      'assignedRoomId': roomId,
      'assignedRoomNumber': roomNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(roomRef, {
      'status': 'occupied',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// =========================
  /// CHECK-OUT
  /// =========================
  /// - réservation -> checked_out
  /// - chambre assignée -> cleaning
  /// Atomique via WriteBatch.
  Future<void> checkOut({
    String? establishmentId,
    required String reservationId,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    final resaRef = _col(establishmentId: resolved).doc(reservationId);

    final resaSnap = await resaRef.get();
    if (!resaSnap.exists) {
      throw Exception('Réservation introuvable.');
    }
    final resa = ReservationModel.fromMap(resaSnap.id, resaSnap.data()!);
    if (resa.status != 'checked_in') {
      throw Exception('Cette réservation n\'est pas en cours de séjour.');
    }

    final batch = _firestore.batch();

    batch.update(resaRef, {
      'status': 'checked_out',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Libère la chambre assignée (si encore renseignée)
    if (resa.assignedRoomId.isNotEmpty) {
      final roomRef = _roomsCol(
        establishmentId: resolved,
      ).doc(resa.assignedRoomId);
      batch.update(roomRef, {
        'status': 'cleaning',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// =========================
  /// STREAM RESERVATIONS
  /// =========================

  Stream<List<ReservationModel>> streamReservations({String? establishmentId}) {
    final resolved = _resolveEstablishmentId(establishmentId);

    return _col(establishmentId: resolved).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.id, doc.data()))
          // a. Masquer les réservations annulées et terminées (checked_out)
          .where((r) => r.status != 'cancelled' && r.status != 'checked_out')
          .toList();

      // b. Tri par date de création décroissante (récentes en haut,
      //    anciennes en bas). Repli sur checkInDate si createdAt absent.
      list.sort((a, b) {
        final ad = a.createdAt ?? a.checkInDate;
        final bd = b.createdAt ?? b.checkInDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad); // décroissant
      });

      return list;
    });
  }

  /// =========================
  /// HISTORIQUE D'UN CLIENT
  /// =========================
  /// Réservations rattachées à une fiche client via le champ `clientId`.
  ///
  /// Égalité sur un seul champ + tri côté client sur checkInDate :
  /// pas de where + orderBy, donc aucun index composite requis.
  /// On ne rapproche jamais par nom : les réservations créées sans fiche
  /// (clientId vide) n'apparaissent volontairement dans aucun historique.
  Future<List<ReservationModel>> reservationsForClient({
    String? establishmentId,
    required String clientId,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    final cleanClientId = clientId.trim();

    if (cleanClientId.isEmpty) {
      return <ReservationModel>[];
    }

    final snap = await _col(
      establishmentId: resolved,
    ).where('clientId', isEqualTo: cleanClientId).get();

    final list = snap.docs
        .map((doc) => ReservationModel.fromMap(doc.id, doc.data()))
        .toList();

    // Tri par date d'arrivée (séjour le plus récent d'abord)
    list.sort((a, b) {
      final ad = a.checkInDate;
      final bd = b.checkInDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return list;
  }

  /// =========================
  /// CREATE RESERVATION
  /// =========================

  Future<void> createReservation({
    String? establishmentId,

    /// Référence optionnelle vers une fiche client.
    /// Vide = réservation à la volée, comportement inchangé.
    String clientId = '',
    required String clientName,
    required String clientPhone,
    required String clientIfu,
    required String clientAddress,
    required String roomTypeId,
    required String roomTypeName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfGuests,
    required double pricePerNight,
    required String note,
    required String createdBy,
    required String createdByName,
    bool force = false,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    final cleanName = clientName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Nom du client obligatoire.');
    }
    if (roomTypeId.trim().isEmpty) {
      throw Exception('Type de chambre obligatoire.');
    }
    if (!checkOut.isAfter(checkIn)) {
      throw Exception('La date de départ doit être après la date d\'arrivée.');
    }

    // Vérification de disponibilité (sauf si on force)
    if (!force) {
      final available = await availableCountForType(
        establishmentId: resolved,
        roomTypeId: roomTypeId,
        checkIn: checkIn,
        checkOut: checkOut,
      );

      if (available <= 0) {
        throw Exception(
          'Aucune chambre de ce type disponible sur cette période. '
          'Vous pouvez forcer la réservation si nécessaire.',
        );
      }
    }

    final nights = checkOut.difference(checkIn).inDays;
    final roomTotal = pricePerNight * nights;

    final docRef = _col(establishmentId: resolved).doc();

    await docRef.set({
      'establishmentId': resolved,
      'clientId': clientId.trim(),
      'clientName': cleanName,
      'clientPhone': clientPhone.trim(),
      'clientIfu': clientIfu.trim(),
      'clientAddress': clientAddress.trim(),
      'roomTypeId': roomTypeId.trim(),
      'roomTypeName': roomTypeName.trim(),
      'assignedRoomId': '',
      'assignedRoomNumber': '',
      'checkInDate': Timestamp.fromDate(checkIn),
      'checkOutDate': Timestamp.fromDate(checkOut),
      'numberOfGuests': numberOfGuests,
      'pricePerNight': pricePerNight,
      'numberOfNights': nights,
      'roomTotal': roomTotal,
      'status': 'confirmed',
      'note': note.trim(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// CANCEL RESERVATION
  /// =========================

  Future<void> cancelReservation({
    String? establishmentId,
    required String reservationId,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolved).doc(reservationId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// RÉSERVATION ACTIVE D'UNE CHAMBRE
  /// =========================
  /// Retourne la réservation 'checked_in' assignée à cette chambre, ou null.
  Future<ReservationModel?> activeReservationForRoom({
    String? establishmentId,
    required String roomId,
  }) async {
    final resolved = _resolveEstablishmentId(establishmentId);

    final snap = await _col(establishmentId: resolved)
        .where('assignedRoomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'checked_in')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    return ReservationModel.fromMap(doc.id, doc.data());
  }
}
