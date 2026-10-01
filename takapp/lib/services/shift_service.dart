import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_policy.dart';

/// Service ouvert d'un Floor Manager et serveurs réellement présents.
class FloorManagerShiftState {
  /// `null` : aucun service ouvert pour ce Floor Manager.
  final ShiftModel? openShift;
  final List<ShiftParticipantModel> activeServers;

  const FloorManagerShiftState({
    required this.openShift,
    required this.activeServers,
  });

  static const none = FloorManagerShiftState(
    openShift: null,
    activeServers: [],
  );

  bool get hasOpenShift => openShift != null;
}

/// =========================
/// SERVICES (SHIFTS)
/// =========================
///
/// Données (toutes sous `establishments/{id}`, donc un service n'appartient
/// qu'à un seul établissement) :
/// - `shifts/{shiftId}` : le service ;
/// - `shifts/{shiftId}/participants/{serverId}` : l'affectation d'un serveur ;
/// - `floorManagerCurrentShift/{uid}` et `serverCurrentShift/{uid}` :
///   pointeurs vers le dernier service OUVERT. Leur identifiant étant l'UID,
///   les règles Firestore garantissent qu'un pointeur ne peut quitter un
///   service encore ouvert : un Floor Manager n'a qu'un service ouvert, un
///   serveur n'est jamais présent dans deux services ouverts.
///
/// Les écritures multi-documents passent par un lot ou une transaction.
/// TODO(cloud-functions): la cohérence entre `serverIds`, participations et
/// pointeurs est assurée ici (client) ; les règles empêchent les conflits de
/// pointeurs mais ne peuvent pas parcourir `serverIds`. Une Cloud Function
/// pourrait porter ces opérations de bout en bout.
class ShiftService {
  final FirebaseFirestore _firestore;

  ShiftService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _establishment(String id) {
    return _firestore.collection('establishments').doc(id);
  }

  CollectionReference<Map<String, dynamic>> _shifts(String establishmentId) {
    return _establishment(establishmentId).collection('shifts');
  }

  CollectionReference<Map<String, dynamic>> _participants(
    String establishmentId,
    String shiftId,
  ) {
    return _shifts(establishmentId).doc(shiftId).collection('participants');
  }

  DocumentReference<Map<String, dynamic>> _floorManagerPointer(
    String establishmentId,
    String floorManagerId,
  ) {
    return _establishment(
      establishmentId,
    ).collection('floorManagerCurrentShift').doc(floorManagerId);
  }

  DocumentReference<Map<String, dynamic>> _serverPointer(
    String establishmentId,
    String serverId,
  ) {
    return _establishment(
      establishmentId,
    ).collection('serverCurrentShift').doc(serverId);
  }

  /// =========================
  /// LECTURES (GÉRANTE)
  /// =========================

  /// Personnel de l'établissement (requête sur un seul champ, filtrage du
  /// rôle côté client : aucun index composite).
  Future<List<UserModel>> fetchStaff(String establishmentId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('establishmentId', isEqualTo: establishmentId)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Serveurs affectables par un Floor Manager (14A) : il ne lit que les
  /// profils serveur de son établissement (requête filtrée par rôle, seule
  /// forme admise par les règles).
  Future<List<UserModel>> fetchServers(String establishmentId) =>
      _usersWithRole(establishmentId, AppRoles.serveur);

  /// Destinataires possibles des remises d'un service créé par un Floor
  /// Manager : gérantes et propriétaires actifs de l'établissement.
  Future<List<UserModel>> fetchCashReceivers(String establishmentId) async {
    final lists = await Future.wait([
      _usersWithRole(establishmentId, AppRoles.gerante),
      _usersWithRole(establishmentId, AppRoles.proprietaire),
    ]);
    return [...lists[0], ...lists[1]].where((u) => u.isActive).toList();
  }

  Future<List<UserModel>> _usersWithRole(
    String establishmentId,
    String role,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .where('establishmentId', isEqualTo: establishmentId)
        .where('role', isEqualTo: role)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Services d'un Floor Manager (les siens uniquement), plus récents
  /// d'abord.
  Stream<List<ShiftModel>> streamShiftsOfFloorManager({
    required String establishmentId,
    required String floorManagerId,
  }) {
    return _shifts(establishmentId)
        .where('floorManagerId', isEqualTo: floorManagerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
                  .toList()
                ..sort((a, b) => b.startsAt.compareTo(a.startsAt)),
        );
  }

  Stream<List<ShiftModel>> streamShifts(String establishmentId) {
    return _shifts(establishmentId)
        .orderBy('startsAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// =========================
  /// CRÉATION
  /// =========================

  /// Crée un service `planned` et ses participations, en un seul lot.
  Future<String> createShift({
    required String establishmentId,
    required UserModel? floorManager,
    required List<UserModel> servers,
    required DateTime startsAt,
    required DateTime endsAt,
    required String createdBy,
    String createdByName = '',
    String createdByRole = '',
    UserModel? cashReceiver,
  }) async {
    final error = ShiftPolicy.validateDraft(
      establishmentId: establishmentId,
      floorManager: floorManager,
      servers: servers,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    if (error != null) throw error;

    final shiftRef = _shifts(establishmentId).doc();
    final batch = _firestore.batch();

    batch.set(shiftRef, {
      'establishmentId': establishmentId,
      'floorManagerId': floorManager!.uid,
      'floorManagerName': floorManager.name,
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'status': ShiftStatus.planned.value,
      'serverIds': servers.map((s) => s.uid).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      if (cashReceiver != null) ...{
        'cashReceiverId': cashReceiver.uid,
        'cashReceiverName': cashReceiver.name,
        'cashReceiverRole': cashReceiver.role,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final server in servers) {
      batch.set(
        _participants(establishmentId, shiftRef.id).doc(server.uid),
        _activeParticipant(
          establishmentId: establishmentId,
          shiftId: shiftRef.id,
          server: server,
          assignedBy: createdBy,
        ),
      );
    }

    await batch.commit();
    return shiftRef.id;
  }

  Map<String, dynamic> _activeParticipant({
    required String establishmentId,
    required String shiftId,
    required UserModel server,
    required String assignedBy,
  }) {
    return {
      'shiftId': shiftId,
      'establishmentId': establishmentId,
      'serverId': server.uid,
      'serverName': server.name,
      'assignedAt': FieldValue.serverTimestamp(),
      'assignedBy': assignedBy,
      'activeInShift': true,
      'removedAt': null,
      'removedBy': null,
    };
  }

  /// =========================
  /// OUVERTURE / CLÔTURE
  /// =========================

  /// Ouvre (ou rouvre explicitement) un service.
  ///
  /// Refusé si le Floor Manager a déjà un autre service ouvert, ou si l'un
  /// des serveurs est présent dans un autre service ouvert. Les pointeurs
  /// « service courant » sont posés dans la même transaction.
  Future<void> openShift({
    required String establishmentId,
    required String shiftId,
    required String openedBy,
    String? actingFloorManagerId,
  }) async {
    AppError? failure;

    final done = _firestore.runTransaction((transaction) async {
      failure = null; // la transaction peut être rejouée

      final shiftSnap = await transaction.get(
        _shifts(establishmentId).doc(shiftId),
      );
      if (!shiftSnap.exists || shiftSnap.data() == null) {
        failure = const AppError(AppErrorCode.shiftNotFound);
        return;
      }

      final shift = ShiftModel.fromMap(shiftSnap.data()!, shiftSnap.id);

      // Un service clôturé financièrement (13B) ne rouvre jamais : aucune
      // nouvelle vente ne peut plus lui être rattachée.
      if (!ShiftPolicy.canTransition(shift.status, ShiftStatus.open) ||
          shift.isFinanciallyReconciled) {
        failure = const AppError(AppErrorCode.shiftInvalidTransition);
        return;
      }

      final fmPointerRef = _floorManagerPointer(
        establishmentId,
        shift.floorManagerId,
      );
      final fmHeldBy = await _pointedShift(
        transaction,
        fmPointerRef,
        actingFloorManagerId,
      );

      if (ShiftPolicy.isHeldByAnotherOpenShift(
        shiftId: shiftId,
        pointedShift: fmHeldBy,
      )) {
        failure = const AppError(AppErrorCode.shiftFloorManagerAlreadyOpen);
        return;
      }

      for (final serverId in shift.serverIds) {
        final heldBy = await _pointedShift(
          transaction,
          _serverPointer(establishmentId, serverId),
          actingFloorManagerId,
        );

        if (ShiftPolicy.isHeldByAnotherOpenShift(
          shiftId: shiftId,
          pointedShift: heldBy,
          serverId: serverId,
        )) {
          failure = AppError(
            AppErrorCode.shiftServerAlreadyInOpenShift,
            name: await _serverName(
              transaction,
              establishmentId,
              shiftId,
              serverId,
            ),
          );
          return;
        }
      }

      transaction.update(shiftSnap.reference, {
        'status': ShiftStatus.open.value,
        'openedAt': FieldValue.serverTimestamp(),
        'openedBy': openedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(fmPointerRef, {
        'floorManagerId': shift.floorManagerId,
        'openShiftId': shiftId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': openedBy,
      });

      for (final serverId in shift.serverIds) {
        transaction.set(
          _serverPointer(establishmentId, serverId),
          _serverPointerData(serverId, shift, openedBy),
        );
      }
    });
    await _guardFloorManager(actingFloorManagerId, done);

    // Levée hors transaction : sur le web, une exception levée dedans perd
    // son message.
    final error = failure;
    if (error != null) throw error;
  }

  /// Clôture. Les pointeurs ne sont pas effacés : un pointeur vers un
  /// service clôturé est considéré libre par les règles et par la politique.
  Future<void> closeShift({
    required String establishmentId,
    required String shiftId,
    required String closedBy,
  }) async {
    AppError? failure;

    await _firestore.runTransaction((transaction) async {
      failure = null;

      final shiftSnap = await transaction.get(
        _shifts(establishmentId).doc(shiftId),
      );
      if (!shiftSnap.exists || shiftSnap.data() == null) {
        failure = const AppError(AppErrorCode.shiftNotFound);
        return;
      }

      final shift = ShiftModel.fromMap(shiftSnap.data()!, shiftSnap.id);

      if (!ShiftPolicy.canTransition(shift.status, ShiftStatus.closed)) {
        failure = const AppError(AppErrorCode.shiftInvalidTransition);
        return;
      }

      transaction.update(shiftSnap.reference, {
        'status': ShiftStatus.closed.value,
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': closedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final error = failure;
    if (error != null) throw error;
  }

  /// =========================
  /// AFFECTATIONS
  /// =========================

  /// Remplace la liste des serveurs d'un service non clôturé.
  ///
  /// Serveur retiré : participation conservée avec `activeInShift = false`
  /// (historique). Serveur ajouté à un service ouvert : même contrôle de
  /// double présence qu'à l'ouverture, et pose de son pointeur.
  Future<void> updateServers({
    required String establishmentId,
    required String shiftId,
    required List<UserModel> servers,
    required String updatedBy,
    String? actingFloorManagerId,
  }) async {
    AppError? failure;

    final done = _firestore.runTransaction((transaction) async {
      failure = null;

      final shiftSnap = await transaction.get(
        _shifts(establishmentId).doc(shiftId),
      );
      if (!shiftSnap.exists || shiftSnap.data() == null) {
        failure = const AppError(AppErrorCode.shiftNotFound);
        return;
      }

      final shift = ShiftModel.fromMap(shiftSnap.data()!, shiftSnap.id);

      // Un service clôturé n'accepte plus d'affectation sans réouverture.
      if (shift.isClosed) {
        failure = const AppError(AppErrorCode.shiftClosed);
        return;
      }

      failure = ShiftPolicy.validateServers(
        establishmentId: establishmentId,
        floorManagerId: shift.floorManagerId,
        servers: servers,
      );
      if (failure != null) return;

      final newIds = servers.map((s) => s.uid).toSet();
      final added = servers.where((s) => !shift.serverIds.contains(s.uid));
      final removed = shift.serverIds.where((id) => !newIds.contains(id));

      if (shift.isOpen) {
        for (final server in added) {
          final heldBy = await _pointedShift(
            transaction,
            _serverPointer(establishmentId, server.uid),
            actingFloorManagerId,
          );
          if (ShiftPolicy.isHeldByAnotherOpenShift(
            shiftId: shiftId,
            pointedShift: heldBy,
            serverId: server.uid,
          )) {
            failure = AppError(
              AppErrorCode.shiftServerAlreadyInOpenShift,
              name: server.name,
            );
            return;
          }
        }
      }

      final updatedShift = ShiftModel(
        id: shift.id,
        establishmentId: shift.establishmentId,
        floorManagerId: shift.floorManagerId,
        floorManagerName: shift.floorManagerName,
        startsAt: shift.startsAt,
        endsAt: shift.endsAt,
        status: shift.status,
        serverIds: newIds.toList(),
        createdAt: shift.createdAt,
        createdBy: shift.createdBy,
        createdByName: shift.createdByName,
        createdByRole: shift.createdByRole,
        updatedAt: shift.updatedAt,
      );

      transaction.update(shiftSnap.reference, {
        'serverIds': updatedShift.serverIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final server in added) {
        transaction.set(
          _participants(establishmentId, shiftId).doc(server.uid),
          _activeParticipant(
            establishmentId: establishmentId,
            shiftId: shiftId,
            server: server,
            assignedBy: updatedBy,
          ),
        );
        if (shift.isOpen) {
          transaction.set(
            _serverPointer(establishmentId, server.uid),
            _serverPointerData(server.uid, updatedShift, updatedBy),
          );
        }
      }

      for (final serverId in removed) {
        transaction
            .update(_participants(establishmentId, shiftId).doc(serverId), {
              'activeInShift': false,
              'removedAt': FieldValue.serverTimestamp(),
              'removedBy': updatedBy,
            });
      }
    });
    await _guardFloorManager(actingFloorManagerId, done);

    final error = failure;
    if (error != null) throw error;
  }

  /// Horaires d'un service PLANIFIÉ (14A). Un service en cours ou terminé
  /// garde ses horaires.
  Future<void> updateSchedule({
    required String establishmentId,
    required String shiftId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    AppError? failure;

    await _firestore.runTransaction((transaction) async {
      failure = null;
      final shiftSnap = await transaction.get(
        _shifts(establishmentId).doc(shiftId),
      );
      if (!shiftSnap.exists || shiftSnap.data() == null) {
        failure = const AppError(AppErrorCode.shiftNotFound);
        return;
      }
      final shift = ShiftModel.fromMap(shiftSnap.data()!, shiftSnap.id);
      if (!ShiftPolicy.canEditSchedule(shift)) {
        failure = const AppError(AppErrorCode.shiftInvalidTransition);
        return;
      }
      if (!endsAt.isAfter(startsAt)) {
        failure = const AppError(AppErrorCode.shiftInvalidDates);
        return;
      }
      transaction.update(shiftSnap.reference, {
        'startsAt': Timestamp.fromDate(startsAt),
        'endsAt': Timestamp.fromDate(endsAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final error = failure;
    if (error != null) throw error;
  }

  /// Floor Manager (14A) : il ne lit pas le service d'un autre Floor
  /// Manager ; le contrôle « serveur déjà dans un service ouvert » est alors
  /// fait par les règles (refus de l'écriture), traduit ici.
  Future<void> _guardFloorManager(
    String? actingFloorManagerId,
    Future<void> transaction,
  ) async {
    try {
      await transaction;
    } on FirebaseException catch (e) {
      if (actingFloorManagerId != null && e.code == 'permission-denied') {
        throw const AppError(AppErrorCode.shiftServerUnavailable);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _serverPointerData(
    String serverId,
    ShiftModel shift,
    String updatedBy,
  ) {
    return {
      'serverId': serverId,
      'openShiftId': shift.id,
      'floorManagerId': shift.floorManagerId,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  /// Service désigné par un pointeur « service courant », lu dans la
  /// transaction ; `null` si aucun.
  Future<ShiftModel?> _pointedShift(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> pointerRef, [
    String? actingFloorManagerId,
  ]) async {
    final pointer = await transaction.get(pointerRef);
    final openShiftId = pointer.data()?['openShiftId'];
    if (openShiftId is! String || openShiftId.isEmpty) return null;
    // Floor Manager : le service d'un autre Floor Manager ne lui est pas
    // lisible. Les règles refusent l'affectation s'il est encore ouvert
    // (serverPointerReleased).
    if (actingFloorManagerId != null &&
        pointer.data()?['floorManagerId'] != actingFloorManagerId) {
      return null;
    }

    final establishmentRef = pointerRef.parent.parent!;
    final shiftSnap = await transaction.get(
      establishmentRef.collection('shifts').doc(openShiftId),
    );
    final data = shiftSnap.data();
    if (!shiftSnap.exists || data == null) return null;

    return ShiftModel.fromMap(data, shiftSnap.id);
  }

  Future<String> _serverName(
    Transaction transaction,
    String establishmentId,
    String shiftId,
    String serverId,
  ) async {
    final snap = await transaction.get(
      _participants(establishmentId, shiftId).doc(serverId),
    );
    final name = (snap.data()?['serverName'] ?? '').toString();
    return name.isEmpty ? serverId : name;
  }

  /// =========================
  /// FLOOR MANAGER
  /// =========================

  /// Serveurs réellement présents dans le service OUVERT du Floor Manager.
  ///
  /// Aucun service ouvert => [FloorManagerShiftState.none]. Ne renvoie
  /// jamais la liste de tous les serveurs de l'établissement. Lectures :
  /// 1. `floorManagerCurrentShift/{uid}` puis `shifts/{openShiftId}` ;
  /// 2. `participants` où `activeInShift == true` (un seul champ) ;
  /// 3. pour chacun, `serverCurrentShift/{id}` et `users/{id}` (compte actif).
  Future<FloorManagerShiftState> getActiveServersForCurrentFloorManager({
    required String establishmentId,
    required UserModel currentUser,
  }) async {
    if (currentUser.role != AppRoles.floorManager ||
        currentUser.establishmentId != establishmentId) {
      return FloorManagerShiftState.none;
    }

    final pointer = await _floorManagerPointer(
      establishmentId,
      currentUser.uid,
    ).get();
    final openShiftId = pointer.data()?['openShiftId'];
    if (openShiftId is! String || openShiftId.isEmpty) {
      return FloorManagerShiftState.none;
    }

    final shiftSnap = await _shifts(establishmentId).doc(openShiftId).get();
    final shiftData = shiftSnap.data();
    if (!shiftSnap.exists || shiftData == null) {
      return FloorManagerShiftState.none;
    }

    final shift = ShiftModel.fromMap(shiftData, shiftSnap.id);
    if (!shift.isOpen || shift.floorManagerId != currentUser.uid) {
      return FloorManagerShiftState.none;
    }

    final participantsSnap = await _participants(
      establishmentId,
      shift.id,
    ).where('activeInShift', isEqualTo: true).get();

    final participants = participantsSnap.docs
        .map((doc) => ShiftParticipantModel.fromMap(doc.data(), doc.id))
        .toList();

    final Map<String, String?> serverPointers = {};
    final Map<String, UserModel> users = {};

    for (final participant in participants) {
      final serverId = participant.serverId;
      try {
        final serverPointer = await _serverPointer(
          establishmentId,
          serverId,
        ).get();
        serverPointers[serverId] = serverPointer
            .data()?['openShiftId']
            ?.toString();

        final userSnap = await _firestore
            .collection('users')
            .doc(serverId)
            .get();
        final userData = userSnap.data();
        if (userSnap.exists && userData != null) {
          users[serverId] = UserModel.fromMap(userData, userSnap.id);
        }
      } on FirebaseException catch (e) {
        // Refus des règles (serveur plus rattaché à ce service) : absent de
        // la liste, jamais une erreur bloquante pour le Floor Manager.
        if (e.code != 'permission-denied') rethrow;
      }
    }

    return FloorManagerShiftState(
      openShift: shift,
      activeServers: ShiftPolicy.selectActiveServers(
        establishmentId: establishmentId,
        floorManagerId: currentUser.uid,
        shift: shift,
        participants: participants,
        serverPointers: serverPointers,
        users: users,
      ),
    );
  }

  /// Version TEMPS RÉEL de [getActiveServersForCurrentFloorManager], pour le
  /// tableau de bord du Floor Manager.
  ///
  /// Écoute, en cascade :
  /// 1. `floorManagerCurrentShift/{uid}` : ouverture d'un (autre) service ;
  /// 2. `shifts/{openShiftId}` : clôture / réouverture ;
  /// 3. `participants` où `activeInShift == true` : ajout / retrait ;
  /// 4. `users/{serverId}` de chaque participant : désactivation d'un compte.
  ///
  /// Chaque événement relance le même filtre ([ShiftPolicy.selectActiveServers]).
  /// Un refus des règles (serveur retiré entre-temps) exclut le serveur, il
  /// n'interrompt pas le flux.
  Stream<FloorManagerShiftState> watchFloorManagerShift({
    required String establishmentId,
    required UserModel currentUser,
  }) {
    if (currentUser.role != AppRoles.floorManager ||
        currentUser.establishmentId != establishmentId) {
      return Stream.value(FloorManagerShiftState.none);
    }

    final uid = currentUser.uid;
    late final StreamController<FloorManagerShiftState> out;

    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? pointerSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? shiftSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? participantsSub;
    final userSubs =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};

    String? watchedShiftId;
    ShiftModel? shift;
    var participants = <ShiftParticipantModel>[];
    final users = <String, UserModel>{};
    var generation = 0;

    Future<void> emit() async {
      final current = generation;
      final currentShift = shift;

      if (currentShift == null ||
          !currentShift.isOpen ||
          currentShift.floorManagerId != uid) {
        if (!out.isClosed) out.add(FloorManagerShiftState.none);
        return;
      }

      final pointers = <String, String?>{};
      for (final participant in participants) {
        try {
          final pointer = await _serverPointer(
            establishmentId,
            participant.serverId,
          ).get();
          pointers[participant.serverId] = pointer
              .data()?['openShiftId']
              ?.toString();
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
        }
      }

      // Un événement plus récent a déjà relancé le calcul.
      if (current != generation || out.isClosed) return;

      out.add(
        FloorManagerShiftState(
          openShift: currentShift,
          activeServers: ShiftPolicy.selectActiveServers(
            establishmentId: establishmentId,
            floorManagerId: uid,
            shift: currentShift,
            participants: participants,
            serverPointers: pointers,
            users: users,
          ),
        ),
      );
    }

    void refresh() {
      generation++;
      emit().catchError((Object e) {
        if (!out.isClosed) out.addError(e);
      });
    }

    void cancelUserSubs() {
      for (final sub in userSubs.values) {
        sub.cancel();
      }
      userSubs.clear();
      users.clear();
    }

    void syncUserListeners() {
      final ids = participants.map((p) => p.serverId).toSet();

      for (final id in userSubs.keys.toList()) {
        if (!ids.contains(id)) {
          userSubs.remove(id)?.cancel();
          users.remove(id);
        }
      }

      for (final id in ids) {
        if (userSubs.containsKey(id)) continue;
        userSubs[id] = _firestore
            .collection('users')
            .doc(id)
            .snapshots()
            .listen(
              (snap) {
                final data = snap.data();
                if (snap.exists && data != null) {
                  users[id] = UserModel.fromMap(data, snap.id);
                } else {
                  users.remove(id);
                }
                refresh();
              },
              onError: (Object _) {
                // Lecture refusée : le serveur n'est plus dans ce service.
                users.remove(id);
                refresh();
              },
            );
      }
    }

    void watchShift(String? shiftId) {
      if (shiftId == watchedShiftId) return;
      watchedShiftId = shiftId;

      shiftSub?.cancel();
      participantsSub?.cancel();
      cancelUserSubs();
      shift = null;
      participants = [];

      if (shiftId == null) {
        refresh();
        return;
      }

      shiftSub = _shifts(establishmentId)
          .doc(shiftId)
          .snapshots()
          .listen(
            (snap) {
              final data = snap.data();
              shift = snap.exists && data != null
                  ? ShiftModel.fromMap(data, snap.id)
                  : null;
              refresh();
            },
            onError: (Object _) {
              shift = null;
              refresh();
            },
          );

      participantsSub = _participants(establishmentId, shiftId)
          .where('activeInShift', isEqualTo: true)
          .snapshots()
          .listen(
            (snapshot) {
              participants = snapshot.docs
                  .map(
                    (doc) => ShiftParticipantModel.fromMap(doc.data(), doc.id),
                  )
                  .toList();
              syncUserListeners();
              refresh();
            },
            onError: (Object _) {
              participants = [];
              syncUserListeners();
              refresh();
            },
          );
    }

    out = StreamController<FloorManagerShiftState>(
      onListen: () {
        pointerSub = _floorManagerPointer(establishmentId, uid)
            .snapshots()
            .listen(
              (snap) {
                final openShiftId = snap.data()?['openShiftId'];
                watchShift(
                  openShiftId is String && openShiftId.isNotEmpty
                      ? openShiftId
                      : null,
                );
              },
              onError: (Object e) {
                if (!out.isClosed) out.addError(e);
              },
            );
      },
      onCancel: () async {
        generation++;
        await pointerSub?.cancel();
        await shiftSub?.cancel();
        await participantsSub?.cancel();
        cancelUserSubs();
        await out.close();
      },
    );

    return out.stream;
  }
}
