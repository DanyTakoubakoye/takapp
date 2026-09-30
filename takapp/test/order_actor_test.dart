import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/order_actor_context.dart';
import 'package:takapp/modeles/order_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/modeles/shift_participant_model.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/order_actor_policy.dart';

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
    'name': uid == 'jean' ? 'Jean' : (uid == 'paul' ? 'Paul' : uid),
    'isActive': isActive,
  }, uid);
}

final _jean = _user('jean', 'serveur');
final _paul = _user('paul', 'floor_manager');

ShiftModel _shift({
  String id = 'sh1',
  String floorManagerId = 'paul',
  String establishmentId = _estA,
  ShiftStatus status = ShiftStatus.open,
  List<String> serverIds = const ['jean'],
}) {
  return ShiftModel(
    id: id,
    establishmentId: establishmentId,
    floorManagerId: floorManagerId,
    floorManagerName: 'Paul',
    startsAt: DateTime(2026, 9, 30, 18),
    endsAt: DateTime(2026, 9, 30, 23),
    status: status,
    serverIds: serverIds,
    createdAt: null,
    createdBy: 'gerante',
    updatedAt: null,
  );
}

ShiftParticipantModel _participant(String serverId, String name) {
  return ShiftParticipantModel(
    shiftId: 'sh1',
    establishmentId: _estA,
    serverId: serverId,
    serverName: name,
    assignedAt: null,
    assignedBy: 'gerante',
    activeInShift: true,
  );
}

Map<String, dynamic> _orderMap(Map<String, dynamic> actorFields) {
  return {
    'establishmentId': _estA,
    'orderNumber': 'CMD-1',
    'clientType': 'restaurant',
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30)),
    ...actorFields,
  };
}

void main() {
  group('OrderActorContext : les trois cas', () {
    test('cas 1 : serveur Jean, sa propre commande', () {
      final fields = OrderActorContext.self(_jean).toOrderFields();

      expect(fields['performedByUserId'], 'jean');
      expect(fields['performedByUserName'], 'Jean');
      expect(fields['assignedServerId'], 'jean');
      expect(fields['assignedServerName'], 'Jean');
      expect(fields['shiftId'], isNull);
      // Transition : createdBy = serveur responsable.
      expect(fields['createdBy'], 'jean');
      expect(fields['createdByName'], 'Jean');
    });

    test('cas 2 : Floor Manager Paul en direct', () {
      final actor = OrderActorContext.self(_paul, shiftId: 'sh1');
      final fields = actor.toOrderFields();

      expect(actor.isDelegated, isFalse);
      expect(fields['performedByUserId'], 'paul');
      expect(fields['assignedServerId'], 'paul');
      expect(fields['createdBy'], 'paul');
      expect(fields['shiftId'], 'sh1');
    });

    test('cas 3 : Floor Manager Paul pour Jean', () {
      final actor = OrderActorContext.forShiftServer(
        floorManager: _paul,
        shift: _shift(),
        server: _participant('jean', 'Jean'),
      );
      final fields = actor.toOrderFields();

      expect(actor.isDelegated, isTrue);
      expect(fields['performedByUserId'], 'paul');
      expect(fields['performedByUserName'], 'Paul');
      expect(fields['assignedServerId'], 'jean');
      expect(fields['assignedServerName'], 'Jean');
      expect(fields['createdBy'], 'jean', reason: 'la vente appartient à Jean');
      expect(fields['shiftId'], 'sh1');
    });
  });

  group('OrderModel : lecture rétrocompatible', () {
    test('ancienne commande sans nouveaux champs : repli sur createdBy', () {
      final order = OrderModel.fromMap(
        _orderMap({'createdBy': 'jean', 'createdByName': 'Jean'}),
        'o1',
      );

      expect(order.assignedServerId, isNull);
      expect(order.performedByUserId, isNull);
      expect(order.shiftId, isNull);
      expect(order.effectiveAssignedServerId, 'jean');
      expect(order.effectiveAssignedServerName, 'Jean');
      expect(order.effectivePerformedByUserId, 'jean');
      expect(order.effectivePerformedByUserName, 'Jean');
      expect(order.isDelegated, isFalse);

      // Relue puis réécrite : aucun champ vide ajouté.
      final map = order.toMap();
      expect(map.containsKey('assignedServerId'), isFalse);
      expect(map.containsKey('performedByUserId'), isFalse);
      expect(map.containsKey('shiftId'), isFalse);
    });

    test('champs vides traités comme absents', () {
      final order = OrderModel.fromMap(
        _orderMap({
          'createdBy': 'jean',
          'createdByName': 'Jean',
          'assignedServerId': '',
          'performedByUserId': '  ',
        }),
        'o1',
      );
      expect(order.effectiveAssignedServerId, 'jean');
      expect(order.effectivePerformedByUserId, 'jean');
    });

    test('commande déléguée : auteur et responsable distincts', () {
      final fields = OrderActorContext.forShiftServer(
        floorManager: _paul,
        shift: _shift(),
        server: _participant('jean', 'Jean'),
      ).toOrderFields();
      final order = OrderModel.fromMap(_orderMap(fields), 'o2');

      expect(order.effectiveAssignedServerId, 'jean');
      expect(order.effectivePerformedByUserId, 'paul');
      expect(order.effectivePerformedByUserName, 'Paul');
      expect(order.shiftId, 'sh1');
      expect(order.isDelegated, isTrue);

      // copyWith ne peut pas modifier les acteurs.
      final copy = order.copyWith(status: 'ready');
      expect(copy.assignedServerId, 'jean');
      expect(copy.performedByUserId, 'paul');
      expect(copy.shiftId, 'sh1');
    });
  });

  group('OrderActorPolicy', () {
    AppError? validate(
      OrderActorContext actor, {
      String? authUid,
      String establishmentId = _estA,
      ShiftModel? shift,
      String? pointer,
      UserModel? server,
    }) {
      return OrderActorPolicy.validate(
        actor: actor,
        authenticatedUid: authUid ?? actor.performedByUserId,
        establishmentId: establishmentId,
        shift: shift,
        assignedServerPointer: pointer,
        assignedServer: server,
      );
    }

    OrderActorContext forJean({ShiftModel? shift}) {
      return OrderActorContext.forShiftServer(
        floorManager: _paul,
        shift: shift ?? _shift(),
        server: _participant('jean', 'Jean'),
      );
    }

    test('serveur : sa propre commande est acceptée', () {
      expect(validate(OrderActorContext.self(_jean)), isNull);
    });

    test('auteur réel = utilisateur authentifié, sinon refus', () {
      final actor = OrderActorContext.self(_jean);
      expect(
        validate(actor, authUid: 'quelqu-un-d-autre')?.code,
        AppErrorCode.orderActorMismatch,
      );
      expect(
        OrderActorPolicy.validate(
          actor: actor,
          authenticatedUid: null,
          establishmentId: _estA,
        )?.code,
        AppErrorCode.orderActorMismatch,
      );
    });

    test('un serveur normal ne peut pas attribuer à un autre serveur', () {
      final actor = OrderActorContext.forShiftServer(
        floorManager: _jean, // un serveur qui tenterait la délégation
        shift: _shift(),
        server: _participant('koffi', 'Koffi'),
      );
      expect(validate(actor)?.code, AppErrorCode.orderAssignmentForbidden);
    });

    test('Floor Manager direct : exige SON service ouvert', () {
      expect(
        validate(
          OrderActorContext.self(_paul, shiftId: 'sh1'),
          shift: _shift(),
        ),
        isNull,
      );
      expect(
        validate(OrderActorContext.self(_paul))?.code,
        AppErrorCode.orderNoOpenShift,
      );
      expect(
        validate(
          OrderActorContext.self(_paul, shiftId: 'sh1'),
          shift: _shift(status: ShiftStatus.closed),
        )?.code,
        AppErrorCode.orderNoOpenShift,
      );
      expect(
        validate(
          OrderActorContext.self(_paul, shiftId: 'sh1'),
          shift: _shift(floorManagerId: 'autre-fm'),
        )?.code,
        AppErrorCode.orderNoOpenShift,
      );
    });

    test('Floor Manager pour Jean : accepté si Jean est présent', () {
      expect(
        validate(forJean(), shift: _shift(), pointer: 'sh1', server: _jean),
        isNull,
      );
    });

    test('Floor Manager : refus d’un serveur hors de son service', () {
      AppErrorCode? code({
        ShiftModel? shift,
        String? pointer = 'sh1',
        UserModel? server,
      }) {
        return validate(
          forJean(),
          shift: shift ?? _shift(),
          pointer: pointer,
          server: server,
        )?.code;
      }

      const refused = AppErrorCode.orderServerNotInShift;
      expect(
        code(shift: _shift(serverIds: const [])),
        refused,
        reason: 'non affecté',
      );
      expect(
        code(pointer: 'autre-shift', server: _jean),
        refused,
        reason: 'pointeur ailleurs',
      );
      expect(code(server: null), refused, reason: 'profil illisible');
      expect(
        code(server: _user('jean', 'serveur', isActive: false)),
        refused,
        reason: 'compte désactivé',
      );
      expect(
        code(server: _user('jean', 'barman')),
        refused,
        reason: 'rôle non serveur',
      );
    });

    test('isolation multi-tenant', () {
      // Établissement de la commande différent de celui de l'auteur.
      expect(
        validate(OrderActorContext.self(_jean), establishmentId: _estB)?.code,
        AppErrorCode.orderActorMismatch,
      );
      // Service d'un autre établissement.
      expect(
        validate(
          forJean(),
          shift: _shift(establishmentId: _estB),
          pointer: 'sh1',
          server: _jean,
        )?.code,
        AppErrorCode.orderNoOpenShift,
      );
      // Serveur d'un autre établissement.
      expect(
        validate(
          forJean(),
          shift: _shift(),
          pointer: 'sh1',
          server: _user('jean', 'serveur', establishmentId: _estB),
        )?.code,
        AppErrorCode.orderServerNotInShift,
      );
    });
  });
}
