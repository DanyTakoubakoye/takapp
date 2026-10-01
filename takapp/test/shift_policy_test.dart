import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_policy.dart';

const _estA = 'est-a';
const _estB = 'est-b';

UserModel _user(
  String uid,
  String role, {
  String establishmentId = _estA,
  bool isActive = true,
}) {
  return UserModel.fromMap({
    'role': role,
    'establishmentId': establishmentId,
    'name': 'Nom $uid',
    'isActive': isActive,
  }, uid);
}

final _start = DateTime(2026, 9, 30, 18);
final _end = DateTime(2026, 9, 30, 23);

ShiftModel _shift({
  String id = 'shift-1',
  String establishmentId = _estA,
  String floorManagerId = 'fm-a',
  ShiftStatus status = ShiftStatus.open,
  List<String> serverIds = const ['s1', 's2'],
}) {
  return ShiftModel(
    id: id,
    establishmentId: establishmentId,
    floorManagerId: floorManagerId,
    floorManagerName: 'FM',
    startsAt: _start,
    endsAt: _end,
    status: status,
    serverIds: serverIds,
    createdAt: null,
    createdBy: 'gerante',
    updatedAt: null,
  );
}

ShiftParticipantModel _participant(
  String serverId, {
  String shiftId = 'shift-1',
  String establishmentId = _estA,
  bool active = true,
}) {
  return ShiftParticipantModel(
    shiftId: shiftId,
    establishmentId: establishmentId,
    serverId: serverId,
    serverName: 'Nom $serverId',
    assignedAt: null,
    assignedBy: 'gerante',
    activeInShift: active,
  );
}

void main() {
  group('validateDraft', () {
    AppError? validate({
      UserModel? floorManager,
      List<UserModel>? servers,
      DateTime? startsAt,
      DateTime? endsAt,
    }) {
      return ShiftPolicy.validateDraft(
        establishmentId: _estA,
        floorManager: floorManager ?? _user('fm-a', AppRoles.floorManager),
        servers: servers ?? [_user('s1', AppRoles.serveur)],
        startsAt: startsAt ?? _start,
        endsAt: endsAt ?? _end,
      );
    }

    test('valid shift is accepted', () {
      expect(validate(), isNull);
    });

    test('endsAt must be after startsAt', () {
      expect(validate(endsAt: _start)?.code, AppErrorCode.shiftInvalidDates);
      expect(
        validate(endsAt: _start.subtract(const Duration(hours: 1)))?.code,
        AppErrorCode.shiftInvalidDates,
      );
    });

    test('floor manager from another establishment is refused', () {
      final error = validate(
        floorManager: _user(
          'fm-b',
          AppRoles.floorManager,
          establishmentId: _estB,
        ),
      );
      expect(error?.code, AppErrorCode.shiftInvalidFloorManager);
    });

    test('floor manager must have the floor_manager role and be active', () {
      expect(
        validate(floorManager: _user('g', AppRoles.gerante))?.code,
        AppErrorCode.shiftInvalidFloorManager,
      );
      expect(
        validate(
          floorManager: _user('fm', AppRoles.floorManager, isActive: false),
        )?.code,
        AppErrorCode.shiftInvalidFloorManager,
      );
      expect(
        ShiftPolicy.validateDraft(
          establishmentId: _estA,
          floorManager: null,
          servers: const [],
          startsAt: _start,
          endsAt: _end,
        )?.code,
        AppErrorCode.shiftInvalidFloorManager,
      );
    });

    test('server from another establishment is refused', () {
      final error = validate(
        servers: [_user('s9', AppRoles.serveur, establishmentId: _estB)],
      );
      expect(error?.code, AppErrorCode.shiftInvalidServer);
      expect(error?.name, 'Nom s9');
    });

    test('only active serveurs can be assigned', () {
      expect(
        validate(servers: [_user('b', AppRoles.barman)])?.code,
        AppErrorCode.shiftInvalidServer,
      );
      expect(
        validate(
          servers: [_user('s', AppRoles.serveur, isActive: false)],
        )?.code,
        AppErrorCode.shiftInvalidServer,
      );
      expect(
        validate(servers: [_user('fm-a', AppRoles.serveur)])?.code,
        AppErrorCode.shiftInvalidServer,
        reason: 'the floor manager cannot be one of his own servers',
      );
    });

    test('server count is capped', () {
      final servers = List.generate(
        ShiftModel.maxServers + 1,
        (i) => _user('s$i', AppRoles.serveur),
      );
      expect(
        validate(servers: servers)?.code,
        AppErrorCode.shiftTooManyServers,
      );
    });
  });

  group('transitions', () {
    test('allowed and refused status changes', () {
      expect(
        ShiftPolicy.canTransition(ShiftStatus.planned, ShiftStatus.open),
        isTrue,
      );
      expect(
        ShiftPolicy.canTransition(ShiftStatus.open, ShiftStatus.closed),
        isTrue,
      );
      expect(
        ShiftPolicy.canTransition(ShiftStatus.closed, ShiftStatus.open),
        isTrue,
        reason: 'explicit reopening',
      );
      expect(
        ShiftPolicy.canTransition(ShiftStatus.open, ShiftStatus.planned),
        isFalse,
      );
      expect(
        ShiftPolicy.canTransition(ShiftStatus.open, ShiftStatus.open),
        isFalse,
      );
    });

    test('unknown stored status is never treated as open', () {
      expect(ShiftStatus.fromValue('running'), ShiftStatus.closed);
      expect(ShiftStatus.fromValue(null), ShiftStatus.closed);
    });
  });

  group('open-shift conflicts', () {
    test('a floor manager cannot hold two open shifts', () {
      expect(
        ShiftPolicy.isHeldByAnotherOpenShift(
          shiftId: 'shift-2',
          pointedShift: _shift(id: 'shift-1'),
        ),
        isTrue,
      );
    });

    test('a pointer to a closed shift or to the same shift is free', () {
      expect(
        ShiftPolicy.isHeldByAnotherOpenShift(
          shiftId: 'shift-2',
          pointedShift: _shift(status: ShiftStatus.closed),
        ),
        isFalse,
      );
      expect(
        ShiftPolicy.isHeldByAnotherOpenShift(
          shiftId: 'shift-1',
          pointedShift: _shift(),
        ),
        isFalse,
      );
      expect(
        ShiftPolicy.isHeldByAnotherOpenShift(
          shiftId: 'shift-2',
          pointedShift: null,
        ),
        isFalse,
      );
    });

    test('a server in another open shift is refused, a removed one is not', () {
      expect(
        ShiftPolicy.isHeldByAnotherOpenShift(
          shiftId: 'shift-2',
          pointedShift: _shift(serverIds: ['s1']),
          serverId: 's1',
        ),
        isTrue,
      );
      expect(
        ShiftPolicy.isHeldByAnotherOpenShift(
          shiftId: 'shift-2',
          pointedShift: _shift(serverIds: ['s2']),
          serverId: 's1',
        ),
        isFalse,
      );
    });
  });

  group('selectActiveServers', () {
    final users = {
      's1': _user('s1', AppRoles.serveur),
      's2': _user('s2', AppRoles.serveur),
      's3': _user('s3', AppRoles.serveur),
      'off': _user('off', AppRoles.serveur, isActive: false),
    };

    List<String> select({
      ShiftModel? shift,
      List<ShiftParticipantModel>? participants,
      Map<String, String?>? pointers,
      String floorManagerId = 'fm-a',
      String establishmentId = _estA,
    }) {
      return ShiftPolicy.selectActiveServers(
        establishmentId: establishmentId,
        floorManagerId: floorManagerId,
        shift: shift,
        participants: participants ?? [_participant('s1'), _participant('s2')],
        serverPointers: pointers ?? {'s1': 'shift-1', 's2': 'shift-1'},
        users: users,
      ).map((p) => p.serverId).toList();
    }

    test('returns the servers of the current open shift', () {
      expect(select(shift: _shift()), ['s1', 's2']);
    });

    test('an active account outside the shift is not returned', () {
      // s3 est serveur, actif, du même établissement, mais non affecté.
      final result = select(shift: _shift());
      expect(result, isNot(contains('s3')));
      expect(result, hasLength(2));
    });

    test('a removed participation is not returned', () {
      final result = select(
        shift: _shift(serverIds: ['s1']),
        participants: [_participant('s1'), _participant('s2', active: false)],
      );
      expect(result, ['s1']);
    });

    test('a deactivated account is not returned', () {
      final result = select(
        shift: _shift(serverIds: ['s1', 'off']),
        participants: [_participant('s1'), _participant('off')],
        pointers: {'s1': 'shift-1', 'off': 'shift-1'},
      );
      expect(result, ['s1']);
    });

    test('closed or planned shift => no active server', () {
      expect(select(shift: _shift(status: ShiftStatus.closed)), isEmpty);
      expect(select(shift: _shift(status: ShiftStatus.planned)), isEmpty);
      expect(select(shift: null), isEmpty);
    });

    test('floor manager A never sees the servers of floor manager B', () {
      expect(
        select(
          shift: _shift(floorManagerId: 'fm-b'),
          floorManagerId: 'fm-a',
        ),
        isEmpty,
      );
    });

    test('multi-tenant isolation', () {
      expect(
        select(shift: _shift(establishmentId: _estB)),
        isEmpty,
        reason: 'shift from another establishment',
      );
      expect(
        select(
          shift: _shift(),
          participants: [_participant('s1', establishmentId: _estB)],
        ),
        isEmpty,
        reason: 'participation from another establishment',
      );
      final foreignUsers = {
        's1': _user('s1', AppRoles.serveur, establishmentId: _estB),
      };
      expect(
        ShiftPolicy.selectActiveServers(
          establishmentId: _estA,
          floorManagerId: 'fm-a',
          shift: _shift(serverIds: ['s1']),
          participants: [_participant('s1')],
          serverPointers: {'s1': 'shift-1'},
          users: foreignUsers,
        ),
        isEmpty,
        reason: 'server account moved to another establishment',
      );
    });

    test('a server whose pointer targets another shift is excluded', () {
      final result = select(
        shift: _shift(),
        pointers: {'s1': 'shift-1', 's2': 'shift-other'},
      );
      expect(result, ['s1']);
    });
  });

  group('14A : service géré par son Floor Manager', () {
    test('service passant minuit : 18:00 -> 02:00 = le lendemain', () {
      final start = DateTime(2026, 9, 30, 18);
      expect(
        ShiftPolicy.normalizeEnd(start, DateTime(2026, 9, 30, 2)),
        DateTime(2026, 10, 1, 2),
      );
      // Fin à la même heure : 24 h plus tard, jamais une durée nulle.
      expect(
        ShiftPolicy.normalizeEnd(start, DateTime(2026, 9, 30, 18)),
        DateTime(2026, 10, 1, 18),
      );
      // Fin déjà postérieure : conservée.
      expect(
        ShiftPolicy.normalizeEnd(start, DateTime(2026, 9, 30, 23, 30)),
        DateTime(2026, 9, 30, 23, 30),
      );
      expect(
        ShiftPolicy.normalizeEnd(start, DateTime(2026, 10, 1, 1)),
        DateTime(2026, 10, 1, 1),
      );
      // Fin de mois.
      expect(
        ShiftPolicy.normalizeEnd(
          DateTime(2026, 12, 31, 20),
          DateTime(2026, 12, 31, 3),
        ),
        DateTime(2027, 1, 1, 3),
      );
      // Le service normalisé passe la validation.
      expect(
        ShiftPolicy.validateDraft(
          establishmentId: _estA,
          floorManager: _user('fm-a', AppRoles.floorManager),
          servers: [_user('s1', AppRoles.serveur)],
          startsAt: start,
          endsAt: ShiftPolicy.normalizeEnd(start, DateTime(2026, 9, 30, 2)),
        ),
        isNull,
      );
    });

    test(
      'planifié : horaires et serveurs ; en cours : serveurs ; terminé : rien',
      () {
        final planned = _shift(status: ShiftStatus.planned);
        final open = _shift(status: ShiftStatus.open);
        final closed = _shift(status: ShiftStatus.closed);
        expect(ShiftPolicy.canEditSchedule(planned), isTrue);
        expect(ShiftPolicy.canEditSchedule(open), isFalse);
        expect(ShiftPolicy.canEditSchedule(closed), isFalse);
        expect(ShiftPolicy.canEditServers(planned), isTrue);
        expect(ShiftPolicy.canEditServers(open), isTrue);
        expect(ShiftPolicy.canEditServers(closed), isFalse);
      },
    );

    test('le Floor Manager ne rouvre jamais un service terminé', () {
      expect(
        ShiftPolicy.canFloorManagerTransition(
          ShiftStatus.planned,
          ShiftStatus.open,
        ),
        isTrue,
      );
      expect(
        ShiftPolicy.canFloorManagerTransition(
          ShiftStatus.open,
          ShiftStatus.closed,
        ),
        isTrue,
      );
      expect(
        ShiftPolicy.canFloorManagerTransition(
          ShiftStatus.closed,
          ShiftStatus.open,
        ),
        isFalse,
      );
      // La gérante garde la réouverture explicite.
      expect(
        ShiftPolicy.canTransition(ShiftStatus.closed, ShiftStatus.open),
        isTrue,
      );
    });

    test('sélection : serveurs actifs de son établissement uniquement', () {
      bool eligible(UserModel u) => ShiftPolicy.isEligibleServer(u, _estA);
      expect(eligible(_user('s1', AppRoles.serveur)), isTrue);
      expect(
        eligible(_user('s2', AppRoles.serveur, establishmentId: _estB)),
        isFalse,
      );
      expect(eligible(_user('s3', AppRoles.serveur, isActive: false)), isFalse);
      expect(eligible(_user('b1', AppRoles.barman)), isFalse);
      expect(eligible(_user('g1', AppRoles.gerante)), isFalse);
      // Jamais un autre Floor Manager comme serveur, ni lui-même.
      expect(
        ShiftPolicy.validateServers(
          establishmentId: _estA,
          floorManagerId: 'fm-a',
          servers: [_user('fm-a', AppRoles.serveur)],
        )?.code,
        AppErrorCode.shiftInvalidServer,
      );
    });
  });
}
