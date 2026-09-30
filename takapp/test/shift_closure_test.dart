import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_discrepancy_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/services/shift_closure_policy.dart';

ShiftModel _shift({String status = 'closed', Map<String, dynamic>? extra}) =>
    ShiftModel.fromMap({
      'floorManagerId': 'paul',
      'floorManagerName': 'Paul',
      'status': status,
      ...?extra,
    }, 'sh1');

PaymentModel _pay(
  String id,
  String receivedBy,
  double amount, [
  String handoverStatus = 'pending',
]) => PaymentModel.fromMap({
  'receivedBy': receivedBy,
  'receivedByName': receivedBy,
  'amount': amount,
  'shiftId': 'sh1',
  'handoverStatus': handoverStatus,
  'method': 'cash',
  'status': 'confirmed',
  'type': 'restaurant',
  'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30, 20)),
}, id);

ServerHandoverModel _transfer(int seq, double amount, String status) =>
    ServerHandoverModel.fromMap({
      'declaredAmount': amount,
      'status': status,
      'shiftId': 'sh1',
      'senderUserId': 'paul',
      'senderRole': 'floor_manager',
      'paymentBreakdown': {'cash': amount},
      'transferSequence': seq,
      if (status == 'validated') 'physicalAmount': amount,
    }, 'fmt_sh1_paul_$seq');

ShiftDiscrepancyModel _gap(
  String id,
  String subject,
  double expected, {
  double physical = 0,
  String status = 'pending',
}) => ShiftDiscrepancyModel.fromMap({
  'shiftId': 'sh1',
  'subjectUserId': subject,
  'subjectName': subject,
  'subjectRole': subject == 'paul' ? 'floor_manager' : 'serveur',
  'expectedAmount': expected,
  'physicalAmount': physical,
  'difference': physical - expected,
  'reason': 'manquant',
  'status': status,
}, id);

// Exemple de la demande : Jean 50 000 remis ; Marc 70 000 dont 65 000 remis ;
// Paul 80 000 directs + 115 000 reçus = 195 000, 190 000 remis à la gérante.
final _payments = [
  _pay('j1', 'jean', 50000, 'validated'),
  _pay('m1', 'marc', 65000, 'validated'),
  _pay('m2', 'marc', 5000),
  _pay('p1', 'paul', 80000),
];
final _transfers = [_transfer(0, 190000, 'validated')];

ShiftClosureReview _review({
  ShiftModel? shift,
  List<PaymentModel>? payments,
  List<ServerHandoverModel>? transfers,
  List<ShiftDiscrepancyModel> discrepancies = const [],
}) => ShiftClosurePolicy.review(
  shift: shift ?? _shift(),
  payments: payments ?? _payments,
  transfers: transfers ?? _transfers,
  discrepancies: discrepancies,
  serverNames: const {'jean': 'Jean', 'marc': 'Marc'},
);

List<ClosureBlockerKind> _kinds(ShiftClosureReview r) =>
    r.blockers.map((b) => b.kind).toList();

void main() {
  group('résumé du service', () {
    test('exemple : serveurs, caisse du Floor Manager, restes', () {
      final r = _review();
      final jean = r.servers.firstWhere((s) => s.userId == 'jean');
      final marc = r.servers.firstWhere((s) => s.userId == 'marc');
      expect(
        [jean.collected, jean.handedOver, jean.remaining],
        [50000, 50000, 0],
      );
      expect(
        [marc.collected, marc.handedOver, marc.remaining],
        [70000, 65000, 5000],
      );
      expect(r.floorManagerCash.direct, 80000);
      expect(r.floorManagerCash.fromServers, 115000);
      expect(r.floorManager.collected, 195000);
      expect(r.floorManager.handedOver, 190000);
      expect(r.floorManager.remaining, 5000);
      expect(r.totalRemaining, 10000);
      expect(r.status, ShiftFinancialStatus.pending);
    });

    test('pourquoi la clôture est impossible (messages explicites)', () {
      final r = _review();
      expect(r.canClose, isFalse);
      expect(r.blockers.map((b) => b.toString()), [
        'ClosureBlockerKind.serverRemaining(Marc, 5000.0)',
        'ClosureBlockerKind.floorManagerRemaining(Paul, 5000.0)',
      ]);
    });
  });

  group('conditions de clôture', () {
    final settled = [
      _pay('j1', 'jean', 50000, 'validated'),
      _pay('p1', 'paul', 80000),
    ];
    final allHanded = [_transfer(0, 130000, 'validated')];

    test('tous les soldes à zéro, service terminé : prêt à clôturer', () {
      final r = _review(payments: settled, transfers: allHanded);
      expect(r.blockers, isEmpty);
      expect(r.canClose, isTrue);
      expect(r.status, ShiftFinancialStatus.ready);
    });

    test('service en cours ou planifié : jamais de clôture', () {
      for (final status in ['open', 'planned']) {
        final r = _review(
          shift: _shift(status: status),
          payments: settled,
          transfers: allHanded,
        );
        expect(_kinds(r), [ClosureBlockerKind.shiftNotClosed]);
        expect(r.canClose, isFalse);
      }
    });

    test('service terminé mais serveur avec reste : refus', () {
      final r = _review(
        payments: [...settled, _pay('j2', 'jean', 3000)],
        transfers: allHanded,
      );
      expect(r.blockers.single.kind, ClosureBlockerKind.serverRemaining);
      expect(r.blockers.single.name, 'Jean');
      expect(r.blockers.single.amount, 3000);
    });

    test('remise serveur en attente : refus', () {
      final r = _review(
        payments: [...settled, _pay('j2', 'jean', 3000, 'declared')],
        transfers: allHanded,
      );
      expect(_kinds(r), [ClosureBlockerKind.serverHandoverPending]);
    });

    test(
      'Floor Manager avec reste, ou remise en attente de la gérante : refus',
      () {
        final remaining = _review(
          payments: settled,
          transfers: [_transfer(0, 100000, 'validated')],
        );
        expect(_kinds(remaining), [ClosureBlockerKind.floorManagerRemaining]);
        expect(remaining.blockers.single.amount, 30000);

        final pending = _review(
          payments: settled,
          transfers: [_transfer(0, 130000, 'pending')],
        );
        expect(_kinds(pending), [
          ClosureBlockerKind.floorManagerTransferPending,
        ]);

        // Remise rejetée : le reste redevient à remettre.
        final rejected = _review(
          payments: settled,
          transfers: [_transfer(0, 130000, 'rejected')],
        );
        expect(_kinds(rejected), [ClosureBlockerKind.floorManagerRemaining]);
      },
    );
  });

  group('écarts', () {
    test('écart non validé : refus, statut « écart à traiter »', () {
      final r = _review(discrepancies: [_gap('d1', 'marc', 5000)]);
      expect(r.status, ShiftFinancialStatus.disputed);
      expect(_kinds(r), contains(ClosureBlockerKind.discrepancyPending));
      expect(r.canClose, isFalse);
    });

    test(
      'écarts approuvés couvrant exactement les restes : clôture possible',
      () {
        final r = _review(
          discrepancies: [
            _gap('d1', 'marc', 5000, status: 'approved'),
            _gap('d2', 'paul', 5000, status: 'approved'),
          ],
        );
        expect(r.blockers, isEmpty);
        expect(r.status, ShiftFinancialStatus.ready);
        expect(r.documentedShortage, 10000);
        // Les paiements et remises ne sont pas touchés : le reste reste visible.
        expect(r.totalRemaining, 10000);
      },
    );

    test(
      'écart partiel : le retrouvé est remis normalement, le manquant documenté',
      () {
        // Marc : 5 000 attendus, 2 000 retrouvés puis remis, 3 000 manquants.
        final r = _review(
          payments: [
            _pay('j1', 'jean', 50000, 'validated'),
            _pay('m1', 'marc', 65000, 'validated'),
            _pay('m2', 'marc', 2000, 'validated'),
            _pay('m3', 'marc', 3000),
            _pay('p1', 'paul', 80000),
          ],
          transfers: [_transfer(0, 197000, 'validated')],
          discrepancies: [
            _gap('d1', 'marc', 5000, physical: 2000, status: 'approved'),
          ],
        );
        expect(r.blockers, isEmpty);
      },
    );

    test('écart rejeté : ne couvre rien', () {
      final r = _review(
        discrepancies: [_gap('d1', 'marc', 5000, status: 'rejected')],
      );
      expect(
        _kinds(r),
        containsAll([
          ClosureBlockerKind.serverRemaining,
          ClosureBlockerKind.floorManagerRemaining,
        ]),
      );
    });

    test('écart approuvé devenu faux (remise faite depuis) : à retraiter', () {
      final r = _review(
        payments: [
          _pay('j1', 'jean', 50000, 'validated'),
          _pay('p1', 'paul', 80000),
        ],
        transfers: [_transfer(0, 130000, 'validated')],
        discrepancies: [_gap('d1', 'jean', 4000, status: 'approved')],
      );
      expect(_kinds(r), [ClosureBlockerKind.discrepancyMismatch]);
    });
  });

  group('statut stocké et compatibilité', () {
    test('ancien service sans champ : « à rapprocher », jamais soldé', () {
      final old = _shift();
      expect(old.financialStatus, ShiftFinancialStatus.pending);
      expect(old.financialRevision, 0);
      expect(old.isFinanciallyReconciled, isFalse);
      // Une valeur calculée ne fait jamais foi si elle est stockée.
      expect(
        ShiftFinancialStatus.fromStored('ready'),
        ShiftFinancialStatus.pending,
      );
      expect(
        ShiftFinancialStatus.fromStored(null),
        ShiftFinancialStatus.pending,
      );
    });

    test('service clôturé : statut figé, plus de clôture', () {
      final r = _review(
        shift: _shift(extra: {'financialStatus': 'reconciled'}),
      );
      expect(r.status, ShiftFinancialStatus.reconciled);
      expect(r.canClose, isFalse);
    });

    test('montants figés à la clôture', () {
      final r = _review(
        discrepancies: [
          _gap('d1', 'marc', 5000, status: 'approved'),
          _gap('d2', 'paul', 5000, status: 'approved'),
        ],
      );
      expect(r.frozenSummary['theoreticalAmount'], 200000);
      expect(r.frozenSummary['physicalReceived'], 190000);
      expect(r.frozenSummary['documentedShortage'], 10000);
      expect(r.frozenSummary['difference'], -10000);
    });
  });
}
