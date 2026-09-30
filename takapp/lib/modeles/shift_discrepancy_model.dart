import 'package:cloud_firestore/cloud_firestore.dart';

/// Écart de caisse d'un service (13B) :
/// `establishments/{id}/shiftDiscrepancies/{id}`.
///
/// Documente un reste qui ne sera PAS remis (manquant) par un serveur ou le
/// Floor Manager, sans jamais modifier un paiement ou une remise :
/// - [expectedAmount] : reste à remettre au moment de la déclaration ;
/// - [physicalAmount] : ce qui a réellement été retrouvé (à remettre par
///   une remise normale) ;
/// - [difference] = physique − attendu (≤ 0 : manquant).
///
/// Cycle : pending -> approved | rejected. Seule la gérante (ou le
/// propriétaire) décide ; le Floor Manager peut seulement déclarer.
class ShiftDiscrepancyModel {
  final String id;
  final String establishmentId;
  final String shiftId;

  /// Personne dont la caisse présente l'écart.
  final String subjectUserId;
  final String subjectName;

  /// `serveur` | `floor_manager`.
  final String subjectRole;

  final double expectedAmount;
  final double physicalAmount;
  final double difference;
  final String reason;

  final String recordedBy;
  final String recordedByName;
  final String recordedByRole;
  final DateTime? recordedAt;

  /// pending | approved | rejected
  final String status;

  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? decidedByName;
  final String? decisionComment;

  const ShiftDiscrepancyModel({
    required this.id,
    required this.establishmentId,
    required this.shiftId,
    required this.subjectUserId,
    required this.subjectName,
    required this.subjectRole,
    required this.expectedAmount,
    required this.physicalAmount,
    required this.difference,
    required this.reason,
    required this.recordedBy,
    required this.recordedByName,
    required this.recordedByRole,
    required this.recordedAt,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.decidedByName,
    this.decisionComment,
  });

  static const String pendingStatus = 'pending';
  static const String approvedStatus = 'approved';
  static const String rejectedStatus = 'rejected';

  bool get isPending => status == pendingStatus;
  bool get isApproved => status == approvedStatus;

  /// Montant qui ne sera pas remis (manquant accepté une fois approuvé).
  double get uncoveredAmount => expectedAmount - physicalAmount;

  factory ShiftDiscrepancyModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    double toDouble(dynamic v) => v is num ? v.toDouble() : 0;
    DateTime? toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

    return ShiftDiscrepancyModel(
      id: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString(),
      shiftId: (map['shiftId'] ?? '').toString(),
      subjectUserId: (map['subjectUserId'] ?? '').toString(),
      subjectName: (map['subjectName'] ?? '').toString(),
      subjectRole: (map['subjectRole'] ?? '').toString(),
      expectedAmount: toDouble(map['expectedAmount']),
      physicalAmount: toDouble(map['physicalAmount']),
      difference: toDouble(map['difference']),
      reason: (map['reason'] ?? '').toString(),
      recordedBy: (map['recordedBy'] ?? '').toString(),
      recordedByName: (map['recordedByName'] ?? '').toString(),
      recordedByRole: (map['recordedByRole'] ?? '').toString(),
      recordedAt: toDate(map['recordedAt']),
      status: (map['status'] ?? pendingStatus).toString(),
      approvedBy: map['approvedBy']?.toString(),
      approvedAt: toDate(map['approvedAt']),
      rejectedBy: map['rejectedBy']?.toString(),
      rejectedAt: toDate(map['rejectedAt']),
      decidedByName: map['decidedByName']?.toString(),
      decisionComment: map['decisionComment']?.toString(),
    );
  }
}
