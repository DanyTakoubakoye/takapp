import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/order_actor_policy.dart';

/// Contexte d'acteur vérifié : le service lu (Floor Manager) est exposé pour
/// les contrôles propres à l'opération (ex. serveurs de chaque commande
/// encaissée).
class VerifiedActor {
  final OrderActorContext actor;

  /// Service ouvert du Floor Manager ; `null` pour les autres rôles.
  final ShiftModel? shift;

  const VerifiedActor({required this.actor, required this.shift});
}

/// Lit ce qu'il faut pour vérifier un [OrderActorContext] (service, pointeur
/// et profil du serveur pour un Floor Manager), puis applique
/// [OrderActorPolicy]. Partagé par la prise de commande et l'encaissement :
/// UNE seule définition de « qui peut agir pour qui ».
///
/// Défense côté client ; l'autorité reste firestore.rules.
class OrderActorVerifier {
  final FirebaseFirestore _firestore;
  final String? Function() _currentUserId;

  OrderActorVerifier(this._firestore, this._currentUserId);

  Future<VerifiedActor> verify(
    String establishmentId,
    OrderActorContext actor,
  ) async {
    ShiftModel? shift;
    String? serverPointer;
    UserModel? assignedServer;

    final shiftId = actor.shiftId;
    if (actor.isFloorManager && shiftId != null && shiftId.isNotEmpty) {
      final establishment = _firestore
          .collection('establishments')
          .doc(establishmentId);
      try {
        final shiftSnap = await establishment
            .collection('shifts')
            .doc(shiftId)
            .get();
        final shiftData = shiftSnap.data();
        if (shiftSnap.exists && shiftData != null) {
          shift = ShiftModel.fromMap(shiftData, shiftSnap.id);
        }

        if (actor.isDelegated) {
          final pointer = await establishment
              .collection('serverCurrentShift')
              .doc(actor.assignedServerId)
              .get();
          serverPointer = pointer.data()?['openShiftId']?.toString();

          final userSnap = await _firestore
              .collection('users')
              .doc(actor.assignedServerId)
              .get();
          final userData = userSnap.data();
          if (userSnap.exists && userData != null) {
            assignedServer = UserModel.fromMap(userData, userSnap.id);
          }
        }
      } on FirebaseException catch (e) {
        // Lecture refusée par les règles = hors de son service : la
        // politique le refusera avec un message clair.
        if (e.code != 'permission-denied') rethrow;
      }
    }

    final AppError? error = OrderActorPolicy.validate(
      actor: actor,
      authenticatedUid: _currentUserId(),
      establishmentId: establishmentId,
      shift: shift,
      assignedServerPointer: serverPointer,
      assignedServer: assignedServer,
    );
    if (error != null) throw error;

    return VerifiedActor(actor: actor, shift: shift);
  }
}
