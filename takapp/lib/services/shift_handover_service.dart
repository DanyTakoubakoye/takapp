import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/gerante_handover_service.dart';
import 'package:takapp/services/handover_ledger.dart';

/// =========================
/// REMISES SERVEUR -> FLOOR MANAGER (11B)
/// =========================
///
/// Aucune collection nouvelle : même `serverHandovers` et même cycle de
/// paiement (`pending` -> `declared` -> `validated`, retour à `pending` en cas
/// de rejet) que le circuit serveur -> gérante. Une remise vers un Floor
/// Manager porte en plus `receiverRole == floor_manager`, son destinataire
/// et son `shiftId`.
///
/// Une vente et une remise sont deux événements distincts : une remise ne
/// modifie jamais le paiement client, seulement son statut de remise.
///
/// Double remise : un paiement ne passe de `pending` à `declared` qu'une
/// fois (règle Firestore). Deux remises concurrentes des mêmes paiements :
/// la seconde échoue côté serveur.
class ShiftHandoverService {
  final FirebaseFirestore _firestore;
  final GeranteHandoverService _validationService;

  ShiftHandoverService({
    FirebaseFirestore? firestore,
    GeranteHandoverService? validationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _validationService = validationService ?? GeranteHandoverService();

  DocumentReference<Map<String, dynamic>> _establishment(String id) =>
      _firestore.collection('establishments').doc(id);

  CollectionReference<Map<String, dynamic>> _payments(String e) =>
      _establishment(e).collection('payments');

  DocumentReference<Map<String, dynamic>> shiftRef(String e, String id) =>
      _establishment(e).collection('shifts').doc(id);

  /// Événement financier du service (13B) : `financialRevision` + 1 dans
  /// le même lot. Une clôture financière lancée entre-temps échoue ; après
  /// clôture, les règles refusent l'incrément, donc l'événement.
  void bumpFinancialRevision(WriteBatch batch, String e, String shiftId) {
    batch.update(shiftRef(e, shiftId), {
      'financialRevision': FieldValue.increment(1),
    });
  }

  CollectionReference<Map<String, dynamic>> _handovers(String e) =>
      _establishment(e).collection('serverHandovers');

  Future<ShiftModel?> _shiftFromPointer(
    String establishmentId,
    String pointerCollection,
    String uid,
  ) async {
    final pointer = await _establishment(
      establishmentId,
    ).collection(pointerCollection).doc(uid).get();
    final shiftId = pointer.data()?['openShiftId']?.toString() ?? '';
    if (shiftId.isEmpty) return null;

    final snap = await _establishment(
      establishmentId,
    ).collection('shifts').doc(shiftId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return ShiftModel.fromMap(data, snap.id);
  }

  /// =========================
  /// CÔTÉ SERVEUR
  /// =========================

  /// Dernier service du serveur (ouvert OU clôturé) : on peut encore en
  /// remettre les encaissements après sa clôture.
  Future<ShiftModel?> lastShiftOfServer(
    String establishmentId,
    String serverId,
  ) async {
    try {
      return await _shiftFromPointer(
        establishmentId,
        'serverCurrentShift',
        serverId,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  /// Encaissements du serveur pour ce service (receivedBy + shiftId).
  Stream<List<PaymentModel>> streamServerShiftPayments({
    required String establishmentId,
    required String serverId,
    required String shiftId,
  }) {
    return _payments(establishmentId)
        .where('receivedBy', isEqualTo: serverId)
        .where('shiftId', isEqualTo: shiftId)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Remet au Floor Manager du service TOUS les encaissements encore à
  /// remettre de ce service. Le destinataire vient du service, jamais d'un
  /// choix libre.
  Future<void> handOverToFloorManager({
    required String establishmentId,
    required UserModel sender,
    required ShiftModel shift,
    required List<PaymentModel> payments,
    String comment = '',
  }) async {
    if (sender.role != AppRoles.serveur ||
        shift.establishmentId != establishmentId) {
      throw const AppError(AppErrorCode.handoverNoShift);
    }

    final toHand = payments
        .where(
          (p) =>
              p.receivedBy == sender.uid &&
              HandoverLedger.isShiftCash(p, shift.id) &&
              p.handoverStatus == 'pending',
        )
        .toList();

    final error = HandoverLedger.validateHandover(
      senderId: sender.uid,
      shiftId: shift.id,
      payments: toHand,
    );
    if (error != null) throw error;

    final amount = toHand.fold<double>(0, (running, p) => running + p.amount);
    final handoverRef = _handovers(establishmentId).doc();
    final batch = _firestore.batch();

    batch.set(handoverRef, {
      'establishmentId': establishmentId,
      // Champs historiques (écrans et PDF existants).
      'serveurId': sender.uid,
      'serveurName': sender.name,
      'declaredAmount': amount,
      'validatedAmount': null,
      'status': 'pending',
      'receivedByManagerId': null,
      'receivedByManagerName': null,
      'paymentIds': toHand.map((p) => p.id).toList(),
      'validatedPaymentIds': <String>[],
      'rejectedPaymentIds': <String>[],
      // Circuit Floor Manager.
      'shiftId': shift.id,
      'senderUserId': sender.uid,
      'senderUserName': sender.name,
      'senderRole': AppRoles.serveur,
      'receiverUserId': shift.floorManagerId,
      'receiverUserName': shift.floorManagerName,
      'receiverRole': ServerHandoverModel.floorManagerReceiver,
      'paymentBreakdown': HandoverLedger.byMethod(toHand),
      'comment': comment.trim(),
      'createdBy': sender.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'validatedAt': null,
      'pendingSync': false,
      'syncError': false,
    });

    for (final payment in toHand) {
      batch.update(_payments(establishmentId).doc(payment.id), {
        'handoverStatus': 'declared',
        'handoverId': handoverRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
        'pendingSync': false,
        'syncError': false,
      });
    }

    bumpFinancialRevision(batch, establishmentId, shift.id);
    await batch.commit();
  }

  /// =========================
  /// CÔTÉ FLOOR MANAGER
  /// =========================

  /// Dernier service du Floor Manager (ouvert ou clôturé).
  Future<ShiftModel?> lastShiftOfFloorManager(
    String establishmentId,
    String floorManagerId,
  ) {
    return _shiftFromPointer(
      establishmentId,
      'floorManagerCurrentShift',
      floorManagerId,
    );
  }

  /// Tous les encaissements du service (serveurs et Floor Manager).
  Stream<List<PaymentModel>> streamShiftPayments({
    required String establishmentId,
    required String shiftId,
  }) {
    return _payments(establishmentId)
        .where('shiftId', isEqualTo: shiftId)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Serveurs du service (même retirés : leurs encaissements restent à
  /// remettre).
  Future<List<ShiftParticipantModel>> shiftParticipants({
    required String establishmentId,
    required String shiftId,
  }) async {
    final snap = await _establishment(
      establishmentId,
    ).collection('shifts').doc(shiftId).collection('participants').get();
    return snap.docs
        .map((d) => ShiftParticipantModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Remises destinées à ce Floor Manager pour ce service.
  Stream<List<ServerHandoverModel>> streamHandoversForFloorManager({
    required String establishmentId,
    required String floorManagerId,
    required String shiftId,
  }) {
    return _handovers(establishmentId)
        .where('receiverUserId', isEqualTo: floorManagerId)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => ServerHandoverModel.fromMap(d.data(), d.id))
                  .where((h) => h.isForFloorManager && h.shiftId == shiftId)
                  .toList()
                ..sort(
                  (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                    a.createdAt ?? DateTime(0),
                  ),
                ),
        );
  }

  /// Valide toute la remise (tous ses paiements). Même mécanisme que la
  /// gérante ; les règles réservent l'opération au destinataire.
  Future<void> validate({
    required String establishmentId,
    required ServerHandoverModel handover,
    required UserModel floorManager,
  }) {
    _checkReceiver(handover, floorManager);
    return _validationService.validateSelectedPayments(
      establishmentId: establishmentId,
      handoverId: handover.id,
      selectedPaymentIds: handover.paymentIds,
      validatedAmount: handover.declaredAmount,
      managerId: floorManager.uid,
      managerName: floorManager.name,
      shiftRevisionRef: shiftRef(establishmentId, handover.shiftId ?? ''),
    );
  }

  /// Rejette toute la remise : ses paiements redeviennent « à remettre »,
  /// le reste à remettre du serveur remonte d'autant.
  Future<void> reject({
    required String establishmentId,
    required ServerHandoverModel handover,
    required UserModel floorManager,
  }) {
    _checkReceiver(handover, floorManager);
    return _validationService.rejectSelectedPayments(
      establishmentId: establishmentId,
      handoverId: handover.id,
      selectedPaymentIds: handover.paymentIds,
      validatedAmount: 0,
      managerId: floorManager.uid,
      managerName: floorManager.name,
      shiftRevisionRef: shiftRef(establishmentId, handover.shiftId ?? ''),
    );
  }

  void _checkReceiver(ServerHandoverModel handover, UserModel floorManager) {
    if (!handover.isForFloorManager ||
        handover.receiverUserId != floorManager.uid ||
        !handover.isOpen) {
      throw const AppError(AppErrorCode.handoverNotFound);
    }
  }

  /// =========================
  /// REMISES FLOOR MANAGER -> GÉRANTE (12B)
  /// =========================
  ///
  /// Même collection `serverHandovers`, émetteur `floor_manager`. Remise
  /// d'un MONTANT (partielle possible) détaillé par moyen de paiement : le
  /// paiement client n'est jamais modifié.
  ///
  /// Destinataire : le créateur du service (gérante, ou propriétaire faisant
  /// office de caisse centrale) — jamais un choix libre.
  ///
  /// Double remise : l'identifiant est fixé par le rang de la remise
  /// (`fmt_{service}_{floorManager}_{rang}`) ; deux envois calculés sur la
  /// même situation visent le même document, le second est refusé.

  static String transferId(String shiftId, String floorManagerId, int seq) =>
      'fmt_${shiftId}_${floorManagerId}_$seq';

  /// Services du Floor Manager, du plus récent au plus ancien (ouverts ou
  /// clôturés : la finalisation financière survit à la clôture).
  Stream<List<ShiftModel>> streamFloorManagerShifts({
    required String establishmentId,
    required String floorManagerId,
  }) {
    return _establishment(establishmentId)
        .collection('shifts')
        .where('floorManagerId', isEqualTo: floorManagerId)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ShiftModel.fromMap(d.data(), d.id)).toList()
                ..sort((a, b) => b.startsAt.compareTo(a.startsAt)),
        );
  }

  /// Remises du Floor Manager pour ce service (tous statuts).
  Stream<List<ServerHandoverModel>> streamTransfersOfFloorManager({
    required String establishmentId,
    required String floorManagerId,
    required String shiftId,
  }) {
    return _handovers(establishmentId)
        .where('senderUserId', isEqualTo: floorManagerId)
        .snapshots()
        .map(
          (s) => _sorted(
            s.docs
                .map((d) => ServerHandoverModel.fromMap(d.data(), d.id))
                .where((t) => t.isFromFloorManager && t.shiftId == shiftId),
          ),
        );
  }

  /// Remises des Floor Managers d'un service (vue gérante).
  Stream<List<ServerHandoverModel>> streamTransfersOfShift({
    required String establishmentId,
    required String shiftId,
  }) {
    return _handovers(establishmentId)
        .where('shiftId', isEqualTo: shiftId)
        .snapshots()
        .map(
          (s) => _sorted(
            s.docs
                .map((d) => ServerHandoverModel.fromMap(d.data(), d.id))
                .where((t) => t.isFromFloorManager),
          ),
        );
  }

  /// Toutes les remises de Floor Managers de l'établissement (vue gérante).
  Stream<List<ServerHandoverModel>> streamAllFloorManagerTransfers({
    required String establishmentId,
  }) {
    return _handovers(establishmentId)
        .where('senderRole', isEqualTo: ServerHandoverModel.floorManagerSender)
        .snapshots()
        .map(
          (s) => _sorted(
            s.docs.map((d) => ServerHandoverModel.fromMap(d.data(), d.id)),
          ),
        );
  }

  /// Remises de Floor Managers adressées à ce destinataire.
  Stream<List<ServerHandoverModel>> streamTransfersForReceiver({
    required String establishmentId,
    required String receiverId,
  }) {
    return _handovers(establishmentId)
        .where('receiverUserId', isEqualTo: receiverId)
        .snapshots()
        .map(
          (s) => _sorted(
            s.docs
                .map((d) => ServerHandoverModel.fromMap(d.data(), d.id))
                .where((t) => t.isFromFloorManager),
          ),
        );
  }

  Future<ShiftModel?> shiftById(String establishmentId, String shiftId) async {
    final snap = await _establishment(
      establishmentId,
    ).collection('shifts').doc(shiftId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return ShiftModel.fromMap(data, snap.id);
  }

  static List<ServerHandoverModel> _sorted(
    Iterable<ServerHandoverModel> list,
  ) => list.toList()
    ..sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );

  /// Rôle du destinataire : celui du créateur du service. Un service créé
  /// avant 12B n'a pas ce champ : gérante supposée (seul rôle qui crée des
  /// services au quotidien), les règles vérifiant le vrai compte.
  /// Un service créé par le Floor Manager (14A) désigne explicitement son
  /// destinataire (cashReceiver*).
  static String receiverRoleOf(ShiftModel shift) {
    if (shift.cashReceiverId.isNotEmpty) return shift.cashReceiverRole;
    return shift.createdByRole.isEmpty ? AppRoles.gerante : shift.createdByRole;
  }

  static String receiverIdOf(ShiftModel shift) =>
      shift.cashReceiverId.isNotEmpty ? shift.cashReceiverId : shift.createdBy;

  static String receiverNameOf(ShiftModel shift) =>
      shift.cashReceiverId.isNotEmpty
      ? shift.cashReceiverName
      : shift.createdByName;

  /// Destinataire autorisé : créateur du service, gérante ou propriétaire.
  static bool hasReceiver(ShiftModel shift) =>
      receiverIdOf(shift).isNotEmpty &&
      (receiverRoleOf(shift) == AppRoles.gerante ||
          receiverRoleOf(shift) == AppRoles.proprietaire);

  /// Remet [breakdown] (montant par moyen de paiement) au destinataire du
  /// service. [cash] est la situation sur laquelle l'utilisateur a décidé.
  Future<String> transferToReceiver({
    required String establishmentId,
    required UserModel sender,
    required ShiftModel shift,
    required FloorManagerCash cash,
    required Map<String, double> breakdown,
    String comment = '',
  }) async {
    if (sender.role != AppRoles.floorManager ||
        shift.floorManagerId != sender.uid ||
        shift.establishmentId != establishmentId) {
      throw const AppError(AppErrorCode.handoverNoShift);
    }
    if (!hasReceiver(shift)) {
      throw const AppError(AppErrorCode.transferNoReceiver);
    }

    // Ordre fixe (celui des règles) : même somme au centime près.
    final cleaned = <String, double>{
      for (final method in AppPaymentMethods.all)
        if ((breakdown[method] ?? 0) > 0) method: breakdown[method]!,
    };
    final error = FloorManagerLedger.validateTransfer(
      cash: cash,
      breakdown: {...breakdown}..removeWhere((_, v) => v == 0),
    );
    if (error != null) throw error;
    final amount = cleaned.values.fold<double>(0, (a, b) => a + b);

    final seq = cash.nextSequence;
    final id = transferId(shift.id, sender.uid, seq);

    try {
      final batch = _firestore.batch();
      batch.set(_handovers(establishmentId).doc(id), {
        'establishmentId': establishmentId,
        // Champs historiques : affichage dans le circuit gérante ->
        // comptabilité existant (l'émetteur tient lieu de « serveur »).
        'serveurId': sender.uid,
        'serveurName': sender.name,
        'declaredAmount': amount,
        'amount': amount,
        'validatedAmount': null,
        'status': 'pending',
        'receivedByManagerId': null,
        'receivedByManagerName': null,
        'paymentIds': <String>[],
        'validatedPaymentIds': <String>[],
        'rejectedPaymentIds': <String>[],
        'shiftId': shift.id,
        'senderUserId': sender.uid,
        'senderUserName': sender.name,
        'senderRole': ServerHandoverModel.floorManagerSender,
        'receiverUserId': receiverIdOf(shift),
        'receiverUserName': receiverNameOf(shift),
        'receiverRole': receiverRoleOf(shift),
        'paymentBreakdown': cleaned,
        'transferSequence': seq,
        'comment': comment.trim(),
        'createdBy': sender.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'validatedAt': null,
        'validatedBy': null,
        'physicalAmount': null,
        'difference': null,
        'rejectedAt': null,
        'rejectedBy': null,
        'rejectedByName': null,
        'decisionComment': null,
        'pendingSync': false,
        'syncError': false,
      });
      bumpFinancialRevision(batch, establishmentId, shift.id);
      await batch.commit();
    } on FirebaseException catch (e) {
      // Document déjà créé (double envoi, autre appareil) : la situation a
      // changé, l'utilisateur doit la relire avant de remettre à nouveau.
      if (e.code == 'permission-denied') {
        throw const AppError(AppErrorCode.transferAlreadyChanged);
      }
      rethrow;
    }
    return id;
  }

  void _checkTransferReceiver(ServerHandoverModel transfer, UserModel user) {
    if (!transfer.isFromFloorManager ||
        transfer.receiverUserId != user.uid ||
        transfer.status != 'pending') {
      throw const AppError(AppErrorCode.handoverNotFound);
    }
  }

  /// Validation par le destinataire, avec le montant physiquement compté.
  /// Le montant déclaré ne change jamais ; l'écart est tracé à part.
  Future<void> validateTransfer({
    required String establishmentId,
    required ServerHandoverModel transfer,
    required UserModel receiver,
    required double physicalAmount,
    String comment = '',
  }) async {
    _checkTransferReceiver(transfer, receiver);
    if (physicalAmount < 0) {
      throw const AppError(AppErrorCode.amountMustBePositive);
    }
    final batch = _firestore.batch();
    batch.update(_handovers(establishmentId).doc(transfer.id), {
      'status': 'validated',
      'validatedAmount': transfer.declaredAmount,
      'physicalAmount': physicalAmount,
      'difference': physicalAmount - transfer.declaredAmount,
      'validatedBy': receiver.uid,
      'receivedByManagerId': receiver.uid,
      'receivedByManagerName': receiver.name,
      'validatedAt': FieldValue.serverTimestamp(),
      'decisionComment': comment.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    bumpFinancialRevision(batch, establishmentId, transfer.shiftId ?? '');
    await batch.commit();
  }

  /// Rejet : le montant redevient « à remettre » pour le Floor Manager.
  Future<void> rejectTransfer({
    required String establishmentId,
    required ServerHandoverModel transfer,
    required UserModel receiver,
    String comment = '',
  }) async {
    _checkTransferReceiver(transfer, receiver);
    final batch = _firestore.batch();
    batch.update(_handovers(establishmentId).doc(transfer.id), {
      'status': 'rejected',
      'rejectedBy': receiver.uid,
      'rejectedByName': receiver.name,
      'rejectedAt': FieldValue.serverTimestamp(),
      'decisionComment': comment.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    bumpFinancialRevision(batch, establishmentId, transfer.shiftId ?? '');
    await batch.commit();
  }

  /// Rapprochement du service enregistré dans `accountClosures` (même
  /// principe théorique / physique / écart que la clôture par compte),
  /// avec `scope: shift`. Aucun paiement n'est modifié pour absorber
  /// l'écart.
  Future<void> recordShiftReconciliation({
    required String establishmentId,
    required ShiftModel shift,
    required ShiftReconciliation reconciliation,
    required double physicalAmount,
    required UserModel user,
    String comment = '',
  }) async {
    await _establishment(establishmentId).collection('accountClosures').add({
      'establishmentId': establishmentId,
      'scope': 'shift',
      'accountType': 'shift',
      'shiftId': shift.id,
      'floorManagerId': shift.floorManagerId,
      'floorManagerName': shift.floorManagerName,
      'theoreticalAmount': reconciliation.theoretical,
      'physicalAmount': physicalAmount,
      'difference': physicalAmount - reconciliation.theoretical,
      'stillHeldAmount': reconciliation.stillHeld,
      'countingDifference': reconciliation.countingDifference,
      'validated': physicalAmount == reconciliation.theoretical,
      'validatedById': user.uid,
      'validatedByName': user.name,
      'comment': comment.trim(),
      'date': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }
}
