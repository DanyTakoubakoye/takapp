import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';

/// =========================
/// RÈGLES MÉTIER DES SERVICES (SHIFTS)
/// =========================
///
/// Moteur PUR (aucune dépendance Firebase), appelé par `ShiftService` avant
/// toute écriture et testable sans émulateur. Les règles Firestore
/// appliquent les mêmes invariants côté serveur (voir firestore.rules).
class ShiftPolicy {
  const ShiftPolicy._();

  /// Validation d'un service à créer ou de sa nouvelle liste de serveurs.
  ///
  /// Un compte `isActive` n'est PAS une présence : il n'est qu'une condition
  /// nécessaire pour être affecté.
  static AppError? validateDraft({
    required String establishmentId,
    required UserModel? floorManager,
    required List<UserModel> servers,
    required DateTime startsAt,
    required DateTime endsAt,
  }) {
    if (!endsAt.isAfter(startsAt)) {
      return const AppError(AppErrorCode.shiftInvalidDates);
    }

    if (floorManager == null ||
        !isEligibleFloorManager(floorManager, establishmentId)) {
      return const AppError(AppErrorCode.shiftInvalidFloorManager);
    }

    return validateServers(
      establishmentId: establishmentId,
      floorManagerId: floorManager.uid,
      servers: servers,
    );
  }

  static AppError? validateServers({
    required String establishmentId,
    required String floorManagerId,
    required List<UserModel> servers,
  }) {
    if (servers.length > ShiftModel.maxServers) {
      return AppError(
        AppErrorCode.shiftTooManyServers,
        params: {'max': '${ShiftModel.maxServers}'},
      );
    }

    for (final server in servers) {
      if (server.uid == floorManagerId ||
          !isEligibleServer(server, establishmentId)) {
        return AppError(
          AppErrorCode.shiftInvalidServer,
          name: server.name.isEmpty ? server.uid : server.name,
        );
      }
    }

    return null;
  }

  static bool isEligibleFloorManager(UserModel user, String establishmentId) {
    return user.role == AppRoles.floorManager &&
        user.isActive &&
        user.establishmentId == establishmentId;
  }

  /// Seul le rôle `serveur` est affectable pour l'instant : aucun autre rôle
  /// n'a été déclaré compatible.
  static bool isEligibleServer(UserModel user, String establishmentId) {
    return user.role == AppRoles.serveur &&
        user.isActive &&
        user.establishmentId == establishmentId;
  }

  /// Transitions autorisées. `closed -> open` est la réouverture explicite ;
  /// `planned -> closed` annule un service jamais ouvert.
  static bool canTransition(ShiftStatus from, ShiftStatus to) {
    switch (from) {
      case ShiftStatus.planned:
        return to == ShiftStatus.open || to == ShiftStatus.closed;
      case ShiftStatus.open:
        return to == ShiftStatus.closed;
      case ShiftStatus.closed:
        return to == ShiftStatus.open;
    }
  }

  /// Conflit à l'ouverture (ou à l'ajout d'un serveur dans un service ouvert).
  ///
  /// [pointedShift] : le service désigné par le pointeur « service courant »
  /// du Floor Manager ou du serveur, ou `null` s'il n'y en a pas. Un pointeur
  /// vers un service clôturé, ou dont le serveur a été retiré, est libre.
  static bool isHeldByAnotherOpenShift({
    required String shiftId,
    required ShiftModel? pointedShift,
    String? serverId,
  }) {
    if (pointedShift == null || pointedShift.id == shiftId) return false;
    if (!pointedShift.isOpen) return false;
    if (serverId != null && !pointedShift.serverIds.contains(serverId)) {
      return false;
    }
    return true;
  }

  /// Serveurs réellement présents dans le service ouvert d'un Floor Manager.
  ///
  /// Un serveur est retenu seulement si TOUT est vrai :
  /// - le service est ouvert, appartient à ce Floor Manager et à cet
  ///   établissement ;
  /// - sa participation est active et il figure dans `serverIds` ;
  /// - son pointeur « service courant » désigne bien CE service (garde-fou
  ///   contre un double service ouvert) ;
  /// - son compte est actif, de rôle serveur, dans le même établissement.
  ///
  /// Jamais « tous les serveurs de l'établissement ».
  static List<ShiftParticipantModel> selectActiveServers({
    required String establishmentId,
    required String floorManagerId,
    required ShiftModel? shift,
    required List<ShiftParticipantModel> participants,
    required Map<String, String?> serverPointers,
    required Map<String, UserModel> users,
  }) {
    if (shift == null ||
        !shift.isOpen ||
        shift.floorManagerId != floorManagerId ||
        shift.establishmentId != establishmentId) {
      return const [];
    }

    return participants.where((participant) {
      final user = users[participant.serverId];

      return participant.activeInShift &&
          participant.shiftId == shift.id &&
          participant.establishmentId == establishmentId &&
          shift.serverIds.contains(participant.serverId) &&
          serverPointers[participant.serverId] == shift.id &&
          user != null &&
          isEligibleServer(user, establishmentId);
    }).toList();
  }
}
