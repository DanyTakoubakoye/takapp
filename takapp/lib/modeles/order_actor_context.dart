import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';

/// Qui agit, et pour qui, lors de la création d'une commande.
///
/// - AUTEUR RÉEL ([performedByUserId]) : toujours l'utilisateur authentifié.
///   Il ne se saisit jamais librement : les seules façons de construire un
///   contexte partent du `UserModel` connecté.
/// - SERVEUR RESPONSABLE ([assignedServerId]) : à qui la vente appartient
///   (ses listes, ses impayés, sa notification « prêt »).
///
/// | Cas                              | performedBy | assignedServer |
/// |----------------------------------|-------------|----------------|
/// | Serveur Jean, sa commande        | Jean        | Jean           |
/// | Floor Manager Paul, en direct    | Paul        | Paul           |
/// | Floor Manager Paul, pour Jean    | Paul        | Jean           |
class OrderActorContext {
  final String performedByUserId;
  final String performedByUserName;
  final String performedByRole;
  final String performedByEstablishmentId;

  final String assignedServerId;
  final String assignedServerName;

  /// Service (shift) pendant lequel la commande est saisie. Obligatoire pour
  /// le Floor Manager ; `null` pour un serveur hors système de shift.
  final String? shiftId;

  const OrderActorContext._({
    required this.performedByUserId,
    required this.performedByUserName,
    required this.performedByRole,
    required this.performedByEstablishmentId,
    required this.assignedServerId,
    required this.assignedServerName,
    required this.shiftId,
  });

  /// L'utilisateur connecté commande pour lui-même : serveur (cas 1),
  /// gérante, propriétaire, ou Floor Manager en direct (cas 2, [shiftId]
  /// requis pour lui).
  factory OrderActorContext.self(UserModel user, {String? shiftId}) {
    return OrderActorContext._(
      performedByUserId: user.uid,
      performedByUserName: user.name,
      performedByRole: user.role,
      performedByEstablishmentId: user.establishmentId,
      assignedServerId: user.uid,
      assignedServerName: user.name,
      shiftId: shiftId,
    );
  }

  /// Le Floor Manager connecté commande pour un serveur de son service
  /// (cas 3). La validation complète est faite par `OrderActorPolicy`.
  factory OrderActorContext.forShiftServer({
    required UserModel floorManager,
    required ShiftModel shift,
    required ShiftParticipantModel server,
  }) {
    return OrderActorContext._(
      performedByUserId: floorManager.uid,
      performedByUserName: floorManager.name,
      performedByRole: floorManager.role,
      performedByEstablishmentId: floorManager.establishmentId,
      assignedServerId: server.serverId,
      assignedServerName: server.serverName,
      shiftId: shift.id,
    );
  }

  bool get isDelegated => assignedServerId != performedByUserId;

  /// Identité du contexte (auteur, serveur responsable, service). Le panier
  /// d'`OrderController` y est lié : changer de contexte vide le panier, il
  /// ne peut jamais être attribué à un autre serveur par accident.
  String get cartKey => '$performedByUserId|$assignedServerId|${shiftId ?? ''}';

  bool get isFloorManager => performedByRole == AppRoles.floorManager;

  /// Champs d'acteur écrits sur la commande.
  ///
  /// TRANSITION : `createdBy` / `createdByName` = SERVEUR RESPONSABLE (c'est
  /// ce que lisent déjà tous les écrans, requêtes, index et notifications).
  /// L'auteur réel est dans `performedByUserId`.
  Map<String, dynamic> toOrderFields() {
    return {
      'createdBy': assignedServerId,
      'createdByName': assignedServerName,
      'performedByUserId': performedByUserId,
      'performedByUserName': performedByUserName,
      'assignedServerId': assignedServerId,
      'assignedServerName': assignedServerName,
      'shiftId': shiftId,
    };
  }
}
