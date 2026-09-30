import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_discrepancy_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_closure_policy.dart';
import 'package:takapp/services/shift_handover_service.dart';

/// =========================
/// CLÔTURE FINANCIÈRE D'UN SERVICE (13B)
/// =========================
///
/// Trois notions distinctes :
/// - fermeture OPÉRATIONNELLE : `status == closed` (ShiftService) ;
/// - clôture FINANCIÈRE du service : `financialStatus == reconciled` (ici) ;
/// - clôture comptable de l'établissement : hors périmètre.
///
/// Les écarts sont des documents à part (`shiftDiscrepancies`) : aucun
/// paiement ni aucune remise n'est jamais modifié pour les absorber.
class ShiftClosureService {
  final FirebaseFirestore _firestore;
  final ShiftHandoverService _handovers;

  ShiftClosureService({
    FirebaseFirestore? firestore,
    required ShiftHandoverService handoverService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _handovers = handoverService;

  DocumentReference<Map<String, dynamic>> _establishment(String id) =>
      _firestore.collection('establishments').doc(id);

  CollectionReference<Map<String, dynamic>> _discrepancies(String e) =>
      _establishment(e).collection('shiftDiscrepancies');

  Stream<ShiftModel?> streamShift(String establishmentId, String shiftId) {
    return _handovers.shiftRef(establishmentId, shiftId).snapshots().map((s) {
      final data = s.data();
      return data == null ? null : ShiftModel.fromMap(data, s.id);
    });
  }

  Stream<List<ShiftDiscrepancyModel>> streamDiscrepancies({
    required String establishmentId,
    required String shiftId,
  }) {
    return _discrepancies(establishmentId)
        .where('shiftId', isEqualTo: shiftId)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => ShiftDiscrepancyModel.fromMap(d.data(), d.id))
                  .toList()
                ..sort(
                  (a, b) => (b.recordedAt ?? DateTime(0)).compareTo(
                    a.recordedAt ?? DateTime(0),
                  ),
                ),
        );
  }

  /// =========================
  /// ÉCARTS
  /// =========================

  /// Déclare un écart sur la caisse de [subjectUserId] (serveur du service
  /// ou son Floor Manager). Déclarable par le Floor Manager du service ou la
  /// gérante ; décidé par la gérante uniquement.
  Future<void> declareDiscrepancy({
    required String establishmentId,
    required ShiftModel shift,
    required String subjectUserId,
    required String subjectName,
    required String subjectRole,
    required double expectedAmount,
    required double physicalAmount,
    required String reason,
    required UserModel recordedBy,
  }) async {
    if (shift.isFinanciallyReconciled) {
      throw const AppError(AppErrorCode.shiftFinancialAlreadyClosed);
    }
    if (expectedAmount <= 0 ||
        physicalAmount < 0 ||
        physicalAmount > expectedAmount ||
        reason.trim().isEmpty) {
      throw const AppError(AppErrorCode.discrepancyInvalid);
    }

    final batch = _firestore.batch();
    batch.set(_discrepancies(establishmentId).doc(), {
      'establishmentId': establishmentId,
      'shiftId': shift.id,
      'subjectUserId': subjectUserId,
      'subjectName': subjectName,
      'subjectRole': subjectRole,
      'expectedAmount': expectedAmount,
      'physicalAmount': physicalAmount,
      'difference': physicalAmount - expectedAmount,
      'reason': reason.trim(),
      'recordedBy': recordedBy.uid,
      'recordedByName': recordedBy.name,
      'recordedByRole': recordedBy.role,
      'recordedAt': FieldValue.serverTimestamp(),
      'status': ShiftDiscrepancyModel.pendingStatus,
      'approvedBy': null,
      'approvedAt': null,
      'rejectedBy': null,
      'rejectedAt': null,
      'decidedByName': null,
      'decisionComment': null,
    });
    _handovers.bumpFinancialRevision(batch, establishmentId, shift.id);
    await batch.commit();
  }

  /// Décision de la gérante : un écart approuvé documente le manquant ; un
  /// écart rejeté ne couvre rien (le reste redevient à remettre / expliquer).
  Future<void> decideDiscrepancy({
    required String establishmentId,
    required ShiftDiscrepancyModel discrepancy,
    required bool approve,
    required UserModel decidedBy,
    String comment = '',
  }) async {
    if (!discrepancy.isPending) {
      throw const AppError(AppErrorCode.discrepancyInvalid);
    }
    final batch = _firestore.batch();
    batch.update(_discrepancies(establishmentId).doc(discrepancy.id), {
      'status': approve
          ? ShiftDiscrepancyModel.approvedStatus
          : ShiftDiscrepancyModel.rejectedStatus,
      if (approve) 'approvedBy': decidedBy.uid,
      if (approve) 'approvedAt': FieldValue.serverTimestamp(),
      if (!approve) 'rejectedBy': decidedBy.uid,
      if (!approve) 'rejectedAt': FieldValue.serverTimestamp(),
      'decidedByName': decidedBy.name,
      'decisionComment': comment.trim(),
    });
    _handovers.bumpFinancialRevision(
      batch,
      establishmentId,
      discrepancy.shiftId,
    );
    await batch.commit();
  }

  /// =========================
  /// REVUE ET CLÔTURE
  /// =========================

  /// Revue complète relue sur le serveur (vue gérante : toutes les remises
  /// du service sont lisibles).
  Future<ShiftClosureReview?> loadReview(
    String establishmentId,
    String shiftId,
  ) async {
    final shiftSnap = await _handovers.shiftRef(establishmentId, shiftId).get();
    final shiftData = shiftSnap.data();
    if (shiftData == null) return null;
    final shift = ShiftModel.fromMap(shiftData, shiftSnap.id);

    final e = _establishment(establishmentId);
    final results = await Future.wait([
      e.collection('payments').where('shiftId', isEqualTo: shiftId).get(),
      e
          .collection('serverHandovers')
          .where('shiftId', isEqualTo: shiftId)
          .get(),
      _discrepancies(
        establishmentId,
      ).where('shiftId', isEqualTo: shiftId).get(),
      e.collection('shifts').doc(shiftId).collection('participants').get(),
    ]);

    return ShiftClosurePolicy.review(
      shift: shift,
      payments: results[0].docs
          .map((d) => PaymentModel.fromMap(d.data(), d.id))
          .toList(),
      transfers: results[1].docs
          .map((d) => ServerHandoverModel.fromMap(d.data(), d.id))
          .where((t) => t.isFromFloorManager)
          .toList(),
      discrepancies: results[2].docs
          .map((d) => ShiftDiscrepancyModel.fromMap(d.data(), d.id))
          .toList(),
      serverNames: {
        for (final p in results[3].docs.map(
          (d) => ShiftParticipantModel.fromMap(d.data(), d.id),
        ))
          p.serverId: p.serverName,
      },
    );
  }

  /// Clôture financière (gérante / propriétaire). Relit toute la situation,
  /// refuse si un élément bloque, puis écrit dans une transaction qui
  /// échoue si un événement financier est survenu depuis la lecture
  /// (`financialRevision` a bougé) ou si le service a changé d'état.
  ///
  /// Idempotente : un service déjà clôturé est laissé tel quel.
  Future<void> closeFinancially({
    required String establishmentId,
    required String shiftId,
    required UserModel closedBy,
  }) async {
    final review = await loadReview(establishmentId, shiftId);
    if (review == null) throw const AppError(AppErrorCode.shiftNotFound);
    if (review.shift.isFinanciallyReconciled) return;
    if (!review.canClose) {
      throw const AppError(AppErrorCode.shiftFinancialNotReady);
    }
    final revisionRead = review.shift.financialRevision;

    AppError? failure;
    await _firestore.runTransaction((transaction) async {
      failure = null; // la transaction peut être rejouée
      final ref = _handovers.shiftRef(establishmentId, shiftId);
      final snap = await transaction.get(ref);
      final data = snap.data();
      if (data == null) {
        failure = const AppError(AppErrorCode.shiftNotFound);
        return;
      }
      final current = ShiftModel.fromMap(data, snap.id);
      if (current.isFinanciallyReconciled) return;
      if (current.financialRevision != revisionRead || !current.isClosed) {
        failure = const AppError(AppErrorCode.shiftFinancialChanged);
        return;
      }
      transaction.update(ref, {
        'financialStatus': ShiftFinancialStatus.reconciled.value,
        'financialClosedAt': FieldValue.serverTimestamp(),
        'financialClosedBy': closedBy.uid,
        'financialClosedByName': closedBy.name,
        'financialSummary': review.frozenSummary,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final error = failure;
    if (error != null) throw error;
  }
}
