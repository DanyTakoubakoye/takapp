import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_policy.dart';

/// =========================
/// VALIDATION DE L'ACTEUR D'UNE COMMANDE
/// =========================
///
/// Moteur PUR, appelé par `OrderService.createOrder` avant toute écriture.
/// C'est une défense côté client : l'autorité réelle est dans
/// firestore.rules (`validOrderActor`), qui applique les mêmes invariants.
///
/// TODO(cloud-functions): quand la création de commande passera par une
/// Cloud Function, ces contrôles devront y être refaits avec l'UID du jeton.
class OrderActorPolicy {
  const OrderActorPolicy._();

  /// [authenticatedUid] : UID Firebase Auth de la session (jamais une valeur
  /// venant de l'interface).
  /// [shift] : le service désigné par `actor.shiftId` (lu par le service).
  /// [assignedServerPointer] : `serverCurrentShift/{serveur}.openShiftId`.
  /// [assignedServer] : profil `users/{serveur}`.
  static AppError? validate({
    required OrderActorContext actor,
    required String? authenticatedUid,
    required String establishmentId,
    ShiftModel? shift,
    String? assignedServerPointer,
    UserModel? assignedServer,
  }) {
    // L'auteur réel est TOUJOURS l'utilisateur authentifié.
    if (authenticatedUid == null ||
        authenticatedUid.isEmpty ||
        actor.performedByUserId != authenticatedUid) {
      return const AppError(AppErrorCode.orderActorMismatch);
    }

    if (actor.performedByEstablishmentId != establishmentId) {
      return const AppError(AppErrorCode.orderActorMismatch);
    }

    if (!actor.isFloorManager) {
      // Serveur, gérante, propriétaire : uniquement pour soi-même.
      return actor.isDelegated
          ? const AppError(AppErrorCode.orderAssignmentForbidden)
          : null;
    }

    // Floor Manager : toujours dans SON service ouvert, direct ou délégué.
    if (shift == null ||
        shift.id != actor.shiftId ||
        !shift.isOpen ||
        shift.floorManagerId != actor.performedByUserId ||
        shift.establishmentId != establishmentId) {
      return const AppError(AppErrorCode.orderNoOpenShift);
    }

    if (!actor.isDelegated) return null;

    // Pour un serveur : présent dans CE service, compte actif, même
    // établissement.
    final serverId = actor.assignedServerId;
    if (!shift.serverIds.contains(serverId) ||
        assignedServerPointer != shift.id ||
        assignedServer == null ||
        assignedServer.uid != serverId ||
        !ShiftPolicy.isEligibleServer(assignedServer, establishmentId)) {
      return AppError(
        AppErrorCode.orderServerNotInShift,
        name: actor.assignedServerName,
      );
    }

    return null;
  }
}
