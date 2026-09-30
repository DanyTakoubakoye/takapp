import 'package:cloud_firestore/cloud_firestore.dart';

class ServerHandoverModel {
  final String id;

  /// SaaS
  final String establishmentId;

  final String serveurId;
  final String serveurName;

  final double declaredAmount;
  final double? validatedAmount;

  /// pending | partially_validated | validated | rejected
  final String status;

  final String? receivedByManagerId;
  final String? receivedByManagerName;

  final DateTime? createdAt;
  final DateTime? validatedAt;

  final List<String> paymentIds;
  final List<String> validatedPaymentIds;
  final List<String> rejectedPaymentIds;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  /// =========================
  /// REMISE VERS UN FLOOR MANAGER (11B)
  /// =========================
  ///
  /// Absents des remises historiques : elles restent des remises
  /// serveur -> gérante (`receiverRole == null`).

  /// Service dont proviennent TOUS les paiements de la remise.
  final String? shiftId;

  final String? senderUserId;
  final String? senderUserName;
  final String? senderRole;

  final String? receiverUserId;
  final String? receiverUserName;

  /// `floor_manager` pour ce circuit ; `null` pour le circuit historique.
  final String? receiverRole;

  /// Montant par moyen de paiement (espèces, mobile money…) : ce qui doit
  /// être compté en caisse et ce qui est seulement confirmé.
  final Map<String, double> paymentBreakdown;

  final String? comment;

  /// =========================
  /// REMISE FLOOR MANAGER -> GÉRANTE (12B)
  /// =========================
  ///
  /// `senderRole == floor_manager`, `receiverRole` = rôle du destinataire
  /// (gérante ou propriétaire créateur du service). Remise d'un MONTANT
  /// (partielle possible), sans paiement : `paymentIds` reste vide.
  /// Statuts : pending -> validated | rejected.

  /// Rang de la remise pour ce Floor Manager et ce service (0, 1, 2…) :
  /// fixe l'identifiant du document, ce qui rend la création idempotente.
  final int? transferSequence;

  /// Montant physiquement compté par le destinataire à la validation.
  final double? physicalAmount;

  /// physicalAmount − declaredAmount : écart de caisse tracé, jamais absorbé.
  final double? difference;

  final String? rejectedBy;
  final String? rejectedByName;
  final DateTime? rejectedAt;

  /// Commentaire du destinataire (validation ou rejet).
  final String? decisionComment;

  const ServerHandoverModel({
    required this.id,
    required this.establishmentId,
    required this.serveurId,
    required this.serveurName,
    required this.declaredAmount,
    required this.validatedAmount,
    required this.status,
    required this.receivedByManagerId,
    required this.receivedByManagerName,
    required this.createdAt,
    required this.validatedAt,
    required this.paymentIds,
    required this.validatedPaymentIds,
    required this.rejectedPaymentIds,
    required this.pendingSync,
    required this.syncError,
    this.shiftId,
    this.senderUserId,
    this.senderUserName,
    this.senderRole,
    this.receiverUserId,
    this.receiverUserName,
    this.receiverRole,
    this.paymentBreakdown = const {},
    this.comment,
    this.transferSequence,
    this.physicalAmount,
    this.difference,
    this.rejectedBy,
    this.rejectedByName,
    this.rejectedAt,
    this.decisionComment,
  });

  static const String floorManagerReceiver = 'floor_manager';

  static const String floorManagerSender = 'floor_manager';

  /// Remise d'un Floor Manager à la gérante (12B).
  bool get isFromFloorManager => senderRole == floorManagerSender;

  /// Remise destinée à un Floor Manager (et non au circuit gérante).
  bool get isForFloorManager => receiverRole == floorManagerReceiver;

  /// Remise encore modifiable par son destinataire.
  bool get isOpen => status == 'pending' || status == 'partially_validated';

  factory ServerHandoverModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    double? toNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    List<String> toStringList(dynamic value) {
      return (value as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    }

    return ServerHandoverModel(
      id: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString(),
      serveurId: (map['serveurId'] ?? '').toString(),
      serveurName: (map['serveurName'] ?? '').toString(),
      declaredAmount: toDouble(map['declaredAmount']),
      validatedAmount: toNullableDouble(map['validatedAmount']),
      status: (map['status'] ?? 'pending').toString(),
      receivedByManagerId: map['receivedByManagerId']?.toString(),
      receivedByManagerName: map['receivedByManagerName']?.toString(),
      createdAt: toDate(map['createdAt']),
      validatedAt: toDate(map['validatedAt']),
      paymentIds: toStringList(map['paymentIds']),
      validatedPaymentIds: toStringList(map['validatedPaymentIds']),
      rejectedPaymentIds: toStringList(map['rejectedPaymentIds']),
      pendingSync: map['pendingSync'] == true,
      syncError: map['syncError'] == true,
      shiftId: map['shiftId']?.toString(),
      senderUserId: map['senderUserId']?.toString(),
      senderUserName: map['senderUserName']?.toString(),
      senderRole: map['senderRole']?.toString(),
      receiverUserId: map['receiverUserId']?.toString(),
      receiverUserName: map['receiverUserName']?.toString(),
      receiverRole: map['receiverRole']?.toString(),
      paymentBreakdown: {
        for (final entry
            in ((map['paymentBreakdown'] as Map?) ?? const {}).entries)
          entry.key.toString(): toDouble(entry.value),
      },
      comment: map['comment']?.toString(),
      transferSequence: (map['transferSequence'] as num?)?.toInt(),
      physicalAmount: toNullableDouble(map['physicalAmount']),
      difference: toNullableDouble(map['difference']),
      rejectedBy: map['rejectedBy']?.toString(),
      rejectedByName: map['rejectedByName']?.toString(),
      rejectedAt: toDate(map['rejectedAt']),
      decisionComment: map['decisionComment']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
      'serveurId': serveurId,
      'serveurName': serveurName,
      'declaredAmount': declaredAmount,
      'validatedAmount': validatedAmount,
      'status': status,
      'receivedByManagerId': receivedByManagerId,
      'receivedByManagerName': receivedByManagerName,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'validatedAt': validatedAt == null
          ? null
          : Timestamp.fromDate(validatedAt!),
      'paymentIds': paymentIds,
      'validatedPaymentIds': validatedPaymentIds,
      'rejectedPaymentIds': rejectedPaymentIds,
      'pendingSync': pendingSync,
      'syncError': syncError,
    };
  }

  ServerHandoverModel copyWith({
    String? id,
    String? establishmentId,
    String? serveurId,
    String? serveurName,
    double? declaredAmount,
    double? validatedAmount,
    String? status,
    String? receivedByManagerId,
    String? receivedByManagerName,
    DateTime? createdAt,
    DateTime? validatedAt,
    List<String>? paymentIds,
    List<String>? validatedPaymentIds,
    List<String>? rejectedPaymentIds,
    bool? pendingSync,
    bool? syncError,
  }) {
    return ServerHandoverModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      serveurId: serveurId ?? this.serveurId,
      serveurName: serveurName ?? this.serveurName,
      declaredAmount: declaredAmount ?? this.declaredAmount,
      validatedAmount: validatedAmount ?? this.validatedAmount,
      status: status ?? this.status,
      receivedByManagerId: receivedByManagerId ?? this.receivedByManagerId,
      receivedByManagerName:
          receivedByManagerName ?? this.receivedByManagerName,
      createdAt: createdAt ?? this.createdAt,
      validatedAt: validatedAt ?? this.validatedAt,
      paymentIds: paymentIds ?? this.paymentIds,
      validatedPaymentIds: validatedPaymentIds ?? this.validatedPaymentIds,
      rejectedPaymentIds: rejectedPaymentIds ?? this.rejectedPaymentIds,
      pendingSync: pendingSync ?? this.pendingSync,
      syncError: syncError ?? this.syncError,
      // Émetteur, destinataire et service sont figés à la création.
      shiftId: shiftId,
      senderUserId: senderUserId,
      senderUserName: senderUserName,
      senderRole: senderRole,
      receiverUserId: receiverUserId,
      receiverUserName: receiverUserName,
      receiverRole: receiverRole,
      paymentBreakdown: paymentBreakdown,
      comment: comment,
      transferSequence: transferSequence,
      physicalAmount: physicalAmount,
      difference: difference,
      rejectedBy: rejectedBy,
      rejectedByName: rejectedByName,
      rejectedAt: rejectedAt,
      decisionComment: decisionComment,
    );
  }
}
