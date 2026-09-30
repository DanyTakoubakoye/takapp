import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/services/handover_ledger.dart';
import 'package:takapp/services/shift_handover_service.dart';

PaymentModel _pay(
  String id,
  String receivedBy,
  double amount, {
  String handoverStatus = 'pending',
  String method = 'cash',
  String? shiftId = 'sh1',
}) {
  return PaymentModel.fromMap({
    'receivedBy': receivedBy,
    'receivedByName': receivedBy,
    'amount': amount,
    'shiftId': ?shiftId,
    'handoverStatus': handoverStatus,
    'method': method,
    'status': 'confirmed',
    'type': 'restaurant',
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30, 20)),
  }, id);
}

ServerHandoverModel _transfer(
  int seq,
  double amount, {
  String status = 'pending',
  Map<String, double>? breakdown,
  double? physical,
  String sender = 'paul',
  String shiftId = 'sh1',
}) {
  return ServerHandoverModel.fromMap({
    'serveurId': sender,
    'declaredAmount': amount,
    'status': status,
    'shiftId': shiftId,
    'senderUserId': sender,
    'senderRole': 'floor_manager',
    'receiverUserId': 'awa',
    'receiverRole': 'gerante',
    'paymentBreakdown': breakdown ?? {'cash': amount},
    'transferSequence': seq,
    'physicalAmount': ?physical,
    'difference': physical == null ? null : physical - amount,
  }, 'fmt_${shiftId}_${sender}_$seq');
}

// Paul (Floor Manager) : 80 000 encaissés directement ; Jean lui a remis
// 50 000 (validé), Marc 70 000 (validé).
final _payments = [
  _pay('p1', 'paul', 80000),
  _pay('j1', 'jean', 50000, handoverStatus: 'validated'),
  _pay(
    'm1',
    'marc',
    70000,
    handoverStatus: 'validated',
    method: 'mobile_money',
  ),
];

FloorManagerCash _cash(
  List<ServerHandoverModel> transfers, [
  List<PaymentModel>? payments,
]) => FloorManagerLedger.cashOf(
  floorManagerId: 'paul',
  shiftId: 'sh1',
  payments: payments ?? _payments,
  transfers: transfers,
);

void main() {
  group('fonds détenus par le Floor Manager', () {
    test('exemple : 80 000 + 50 000 + 70 000 − 150 000 remis = 50 000', () {
      final cash = _cash([
        _transfer(
          0,
          150000,
          status: 'validated',
          breakdown: {'cash': 130000, 'mobile_money': 20000},
        ),
      ]);
      expect(cash.direct, 80000);
      expect(cash.fromServers, 120000);
      expect(cash.transferValidated, 150000);
      expect(cash.remaining, 50000);
      expect(cash.remainingByMethod, {'mobile_money': 50000});
    });

    test(
      'encaissement direct inclus, vente de Jean encaissée par Jean non',
      () {
        final cash = _cash(const [], [
          _pay('p1', 'paul', 80000),
          // Encaissé par Jean, pas encore remis / en attente : chez Jean.
          _pay('j1', 'jean', 30000),
          _pay('j2', 'jean', 10000, handoverStatus: 'declared'),
        ]);
        expect(cash.direct, 80000);
        expect(cash.fromServers, 0);
        expect(cash.remaining, 80000);
      },
    );

    test(
      'remise serveur rejetée : paiement revenu à « pending », non inclus',
      () {
        final cash = _cash(const [], [_pay('j1', 'jean', 50000)]);
        expect(cash.held, 0);
      },
    );

    test('paiements historiques ou d’un autre service exclus', () {
      final cash = _cash(const [], [
        _pay('old', 'paul', 9000, shiftId: null),
        _pay('other', 'paul', 7000, shiftId: 'sh0'),
      ]);
      expect(cash.held, 0);
    });
  });

  group('remises à la gérante', () {
    test('remise partielle puis plusieurs remises partielles', () {
      final one = _cash([_transfer(0, 50000)]);
      expect(one.transferPending, 50000);
      expect(one.remaining, 150000);
      expect(one.nextSequence, 1);

      final three = _cash([
        _transfer(0, 50000, status: 'validated'),
        _transfer(1, 30000),
        _transfer(2, 20000, breakdown: {'mobile_money': 20000}),
      ]);
      expect(three.transferred, 100000);
      expect(three.remaining, 100000);
      expect(three.remainingByMethod, {'cash': 50000, 'mobile_money': 50000});
      expect(three.nextSequence, 3);
    });

    test('rejet : ne réduit pas le reste ; validation : le réduit', () {
      final rejected = _cash([_transfer(0, 50000, status: 'rejected')]);
      expect(rejected.remaining, 200000);
      // Le rang continue après un rejet (identifiant jamais réutilisé).
      expect(rejected.nextSequence, 1);

      final validated = _cash([_transfer(0, 50000, status: 'validated')]);
      expect(validated.remaining, 150000);
    });

    test('dépassement refusé, par moyen de paiement', () {
      final cash = _cash([_transfer(0, 100000, status: 'validated')]);
      // Reste : 30 000 espèces, 70 000 mobile money.
      AppErrorCode? check(Map<String, double> b) =>
          FloorManagerLedger.validateTransfer(cash: cash, breakdown: b)?.code;

      expect(check({'cash': 30000, 'mobile_money': 70000}), isNull);
      expect(check({'cash': 30001}), AppErrorCode.transferExceedsAvailable);
      expect(
        check({'mobile_money': 80000}),
        AppErrorCode.transferExceedsAvailable,
      );
      expect(check({'card': 1}), AppErrorCode.transferExceedsAvailable);
      expect(check({'bitcoin': 1}), AppErrorCode.transferExceedsAvailable);
      expect(check({'cash': 0}), AppErrorCode.amountMustBePositive);
      expect(
        check({'cash': 10, 'mobile_money': -5}),
        AppErrorCode.amountMustBePositive,
      );
    });

    test('double remise : une remise en attente réserve déjà le montant', () {
      final cash = _cash([
        _transfer(
          0,
          200000,
          breakdown: {'cash': 130000, 'mobile_money': 70000},
        ),
      ]);
      expect(cash.remaining, 0);
      expect(
        FloorManagerLedger.validateTransfer(
          cash: cash,
          breakdown: {'cash': 1},
        )?.code,
        AppErrorCode.transferExceedsAvailable,
      );
    });

    test(
      'seules les remises de CE Floor Manager et de CE service comptent',
      () {
        final cash = _cash([
          _transfer(0, 50000, sender: 'other'),
          _transfer(0, 50000, shiftId: 'sh0'),
        ]);
        expect(cash.remaining, 200000);
        expect(cash.nextSequence, 0);
      },
    );
  });

  group('rapprochement du service', () {
    test('théorique, détenu, physique et écarts', () {
      final recon = FloorManagerLedger.reconcile(
        floorManagerId: 'paul',
        shiftId: 'sh1',
        payments: [
          ..._payments,
          // Encore chez Marc : pas encore remis.
          _pay('m2', 'marc', 10000),
        ],
        transfers: [
          _transfer(0, 150000, status: 'validated', physical: 149000),
          _transfer(1, 20000),
          _transfer(2, 5000, status: 'rejected'),
        ],
      );
      expect(recon.floorManagerDirect, 80000);
      expect(recon.serversCollected, 130000);
      expect(recon.serversHandedOver, 120000);
      expect(recon.serversStillHeld, 10000);
      expect(recon.transfersValidated, 150000);
      expect(recon.transfersPending, 20000);
      expect(recon.floorManagerStillHeld, 30000);
      expect(recon.theoretical, 210000);
      expect(recon.stillHeld, 60000);
      expect(recon.physicalReceived, 149000);
      expect(recon.countingDifference, -1000);
      // 210 000 attendus = 149 000 comptés + 60 000 encore détenus + 1 000
      // manquants au comptage.
      expect(recon.difference, -61000);
    });
  });

  group('destinataire', () {
    ShiftModel shift({String by = 'awa', String role = 'gerante'}) =>
        ShiftModel.fromMap({
          'floorManagerId': 'paul',
          'createdBy': by,
          'createdByName': 'Awa',
          'createdByRole': role,
        }, 'sh1');

    test('créateur gérante ou propriétaire uniquement', () {
      expect(ShiftHandoverService.hasReceiver(shift()), isTrue);
      expect(
        ShiftHandoverService.hasReceiver(shift(role: 'proprietaire')),
        isTrue,
      );
      expect(
        ShiftHandoverService.hasReceiver(shift(role: 'comptable')),
        isFalse,
      );
      // Service créé avant 12B : gérante supposée (vérifiée par les règles).
      expect(ShiftHandoverService.hasReceiver(shift(role: '')), isTrue);
      expect(ShiftHandoverService.receiverRoleOf(shift(role: '')), 'gerante');
      expect(ShiftHandoverService.hasReceiver(shift(by: '')), isFalse);
      expect(shift().createdByName, 'Awa');
    });

    test('identifiant de remise déterministe', () {
      expect(
        ShiftHandoverService.transferId('sh1', 'paul', 2),
        'fmt_sh1_paul_2',
      );
    });
  });
}
