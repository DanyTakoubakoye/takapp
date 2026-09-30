import 'package:cloud_firestore/cloud_firestore.dart';

/// Participation d'un serveur à un service :
/// `establishments/{id}/shifts/{shiftId}/participants/{serverId}`.
///
/// [serverId] est TOUJOURS l'UID Firebase Auth du profil `users/{uid}` :
/// aucune identité n'est dupliquée, [serverName] n'est qu'un libellé figé
/// au moment de l'affectation.
class ShiftParticipantModel {
  final String shiftId;
  final String establishmentId;
  final String serverId;
  final String serverName;
  final DateTime? assignedAt;
  final String assignedBy;

  /// Faux quand le serveur a été retiré du service (historique conservé).
  final bool activeInShift;

  const ShiftParticipantModel({
    required this.shiftId,
    required this.establishmentId,
    required this.serverId,
    required this.serverName,
    required this.assignedAt,
    required this.assignedBy,
    required this.activeInShift,
  });

  factory ShiftParticipantModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final assignedAt = map['assignedAt'];

    return ShiftParticipantModel(
      shiftId: (map['shiftId'] ?? '').toString(),
      establishmentId: (map['establishmentId'] ?? '').toString(),
      // L'identifiant du document fait foi : un seul document par serveur.
      serverId: documentId,
      serverName: (map['serverName'] ?? '').toString(),
      assignedAt: assignedAt is Timestamp ? assignedAt.toDate() : null,
      assignedBy: (map['assignedBy'] ?? '').toString(),
      activeInShift: map['activeInShift'] == true,
    );
  }
}
