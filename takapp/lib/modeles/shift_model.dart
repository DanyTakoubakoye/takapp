import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'un service (shift). Valeurs techniques stockées dans Firestore ;
/// seuls les libellés affichés sont traduits.
enum ShiftStatus {
  planned('planned'),
  open('open'),
  closed('closed');

  const ShiftStatus(this.value);

  final String value;

  /// Valeur absente ou inconnue => [closed] : un service illisible ne doit
  /// jamais être considéré comme ouvert.
  static ShiftStatus fromValue(Object? value) {
    return ShiftStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ShiftStatus.closed,
    );
  }
}

/// Situation FINANCIÈRE d'un service (13B), distincte de son état
/// opérationnel ([ShiftStatus]) : un service `closed` n'est PAS soldé.
///
/// Seules [pending] et [reconciled] sont stockées (`financialStatus`).
/// [ready] et [disputed] sont calculées à la lecture (voir
/// `ShiftClosurePolicy`) : stockées, elles deviendraient fausses à la
/// moindre remise.
enum ShiftFinancialStatus {
  /// À rapprocher (valeur par défaut, et de tout ancien service).
  pending('pending'),

  /// Prêt à clôturer : toutes les conditions sont réunies.
  ready('ready'),

  /// Clôturé financièrement par la gérante : figé.
  reconciled('reconciled'),

  /// Écart de caisse en attente de décision.
  disputed('disputed');

  const ShiftFinancialStatus(this.value);

  final String value;

  /// Absent ou inconnu => [pending] : un ancien service n'est jamais
  /// considéré comme soldé. Seule la valeur stockée `reconciled` compte.
  static ShiftFinancialStatus fromStored(Object? value) =>
      value == reconciled.value ? reconciled : pending;
}

/// Service de travail d'un Floor Manager : `establishments/{id}/shifts/{id}`.
///
/// La présence d'un serveur est portée par sa participation
/// (`shifts/{id}/participants/{serverId}`), jamais par `users.isActive`.
class ShiftModel {
  /// Plafond de serveurs par service : garde les écritures d'ouverture sous
  /// la limite d'accès des règles Firestore (20 lectures par lot).
  static const int maxServers = 12;

  final String id;
  final String establishmentId;
  final String floorManagerId;
  final String floorManagerName;
  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftStatus status;

  /// UID des serveurs ACTIFS du service (miroir des participations actives),
  /// utilisé par les règles et par la requête `array-contains` du serveur.
  final List<String> serverIds;

  final DateTime? createdAt;
  final String createdBy;

  /// Nom du créateur (gérante) : destinataire des remises du Floor
  /// Manager (12B). Vide sur les services créés avant 12B.
  final String createdByName;

  /// Rôle du créateur (gerante | proprietaire) : rôle du destinataire.
  final String createdByRole;

  /// Destinataire des remises du Floor Manager (14A) quand le service est
  /// créé par le Floor Manager lui-même : gérante ou propriétaire de
  /// l'établissement, choisi à la création. Vide : le créateur (gérante).
  final String cashReceiverId;
  final String cashReceiverName;
  final String cashReceiverRole;

  /// =========================
  /// CLÔTURE FINANCIÈRE (13B)
  /// =========================

  /// Stocké : `pending` (ou absent) / `reconciled`.
  final ShiftFinancialStatus financialStatus;

  /// Incrémenté par chaque événement financier du service (remise,
  /// validation, écart) dans le même lot : la clôture échoue s'il a bougé
  /// depuis la lecture de la situation.
  final int financialRevision;

  final DateTime? financialClosedAt;
  final String financialClosedBy;
  final String financialClosedByName;

  /// Montants figés à la clôture.
  final Map<String, double> financialSummary;
  final DateTime? updatedAt;

  const ShiftModel({
    required this.id,
    required this.establishmentId,
    required this.floorManagerId,
    required this.floorManagerName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.serverIds,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    this.createdByName = '',
    this.createdByRole = '',
    this.cashReceiverId = '',
    this.cashReceiverName = '',
    this.cashReceiverRole = '',
    this.financialStatus = ShiftFinancialStatus.pending,
    this.financialRevision = 0,
    this.financialClosedAt,
    this.financialClosedBy = '',
    this.financialClosedByName = '',
    this.financialSummary = const {},
  });

  bool get isOpen => status == ShiftStatus.open;
  bool get isClosed => status == ShiftStatus.closed;
  bool get isFinanciallyReconciled =>
      financialStatus == ShiftFinancialStatus.reconciled;

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map, String documentId) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    return ShiftModel(
      id: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString(),
      floorManagerId: (map['floorManagerId'] ?? '').toString(),
      floorManagerName: (map['floorManagerName'] ?? '').toString(),
      startsAt: _toDate(map['startsAt']) ?? epoch,
      endsAt: _toDate(map['endsAt']) ?? epoch,
      status: ShiftStatus.fromValue(map['status']),
      serverIds: ((map['serverIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: _toDate(map['createdAt']),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
      createdByRole: (map['createdByRole'] ?? '').toString(),
      cashReceiverId: (map['cashReceiverId'] ?? '').toString(),
      cashReceiverName: (map['cashReceiverName'] ?? '').toString(),
      cashReceiverRole: (map['cashReceiverRole'] ?? '').toString(),
      financialStatus: ShiftFinancialStatus.fromStored(map['financialStatus']),
      financialRevision: (map['financialRevision'] as num?)?.toInt() ?? 0,
      financialClosedAt: _toDate(map['financialClosedAt']),
      financialClosedBy: (map['financialClosedBy'] ?? '').toString(),
      financialClosedByName: (map['financialClosedByName'] ?? '').toString(),
      financialSummary: {
        for (final entry
            in ((map['financialSummary'] as Map?) ?? const {}).entries)
          entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0,
      },
      updatedAt: _toDate(map['updatedAt']),
    );
  }
}
