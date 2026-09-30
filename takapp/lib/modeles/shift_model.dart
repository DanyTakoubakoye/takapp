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
  });

  bool get isOpen => status == ShiftStatus.open;
  bool get isClosed => status == ShiftStatus.closed;

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
      updatedAt: _toDate(map['updatedAt']),
    );
  }
}
