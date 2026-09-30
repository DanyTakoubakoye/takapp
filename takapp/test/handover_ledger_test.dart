import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/services/handover_ledger.dart';

PaymentModel _payment(
  String id, {
  required String receivedBy,
  required double amount,
  String? shiftId = 'sh1',
  String handoverStatus = 'pending',
  String method = 'cash',
  String status = 'confirmed',
  String type = 'restaurant',
  String? responsible,
}) {
  return PaymentModel.fromMap({
    'receivedBy': receivedBy,
    'receivedByName': receivedBy == 'jean'
        ? 'Jean'
        : (receivedBy == 'marc' ? 'Marc' : receivedBy),
    'amount': amount,
    'shiftId': ?shiftId,
    'handoverStatus': handoverStatus,
    'method': method,
    'status': status,
    'type': type,
    'responsibleServerId': ?responsible,
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 30, 20)),
  }, id);
}

void main() {
  group('reste à remettre', () {
    test('Jean : encaissé 50 000, remis 30 000, reste 20 000', () {
      final balance = HandoverLedger.balanceFor(
        cashierId: 'jean',
        cashierName: 'Jean',
        shiftId: 'sh1',
        payments: [
          _payment(
            'p1',
            receivedBy: 'jean',
            amount: 30000,
            handoverStatus: 'validated',
          ),
          _payment('p2', receivedBy: 'jean', amount: 20000),
        ],
      );
      expect(balance.collected, 50000);
      expect(balance.validated, 30000);
      expect(balance.declared, 0);
      expect(balance.remaining, 20000);
      expect(balance.remainingPayments.map((p) => p.id), ['p2']);
    });

    test('Marc : tout remis => reste 0', () {
      final balance = HandoverLedger.balanceFor(
        cashierId: 'marc',
        cashierName: 'Marc',
        shiftId: 'sh1',
        payments: [
          _payment(
            'm1',
            receivedBy: 'marc',
            amount: 75000,
            handoverStatus: 'validated',
          ),
        ],
      );
      expect(balance.collected, 75000);
      expect(balance.remaining, 0);
    });

    test(
      'une remise en attente n’est plus « à remettre », mais pas encore validée',
      () {
        final balance = HandoverLedger.balanceFor(
          cashierId: 'jean',
          cashierName: 'Jean',
          shiftId: 'sh1',
          payments: [
            _payment(
              'p1',
              receivedBy: 'jean',
              amount: 10000,
              handoverStatus: 'declared',
            ),
            _payment('p2', receivedBy: 'jean', amount: 5000),
          ],
        );
        expect(balance.declared, 10000);
        expect(balance.validated, 0);
        expect(balance.remaining, 5000);
      },
    );

    test('remise rejetée : les paiements redeviennent « à remettre »', () {
      // Après un rejet, le paiement repasse en handoverStatus = pending.
      final balance = HandoverLedger.balanceFor(
        cashierId: 'jean',
        cashierName: 'Jean',
        shiftId: 'sh1',
        payments: [_payment('p1', receivedBy: 'jean', amount: 10000)],
      );
      expect(balance.remaining, 10000);
    });
  });

  group('l’argent appartient à celui qui l’a encaissé', () {
    final payments = [
      // Vente de Jean encaissée par Paul (Floor Manager).
      _payment(
        'byPaul',
        receivedBy: 'paul',
        amount: 12000,
        responsible: 'jean',
      ),
      _payment('byJean', receivedBy: 'jean', amount: 8000, responsible: 'jean'),
    ];

    test('Jean ne doit pas remettre ce que Paul détient déjà', () {
      final jean = HandoverLedger.balanceFor(
        cashierId: 'jean',
        cashierName: 'Jean',
        shiftId: 'sh1',
        payments: payments,
      );
      expect(jean.collected, 8000);
      expect(jean.remainingPayments.map((p) => p.id), ['byJean']);
    });

    test('le rapport exclut le Floor Manager lui-même', () {
      final rows = HandoverLedger.balancesForShift(
        shiftId: 'sh1',
        payments: payments,
        names: {'jean': 'Jean', 'marc': 'Marc'},
        excludeCashierIds: {'paul'},
      );
      expect(rows.map((r) => r.cashierId), ['jean', 'marc']);
      expect(rows.firstWhere((r) => r.cashierId == 'marc').collected, 0);
    });
  });

  group('périmètre d’un service', () {
    test('paiements historiques sans shiftId jamais rattachés', () {
      final balance = HandoverLedger.balanceFor(
        cashierId: 'jean',
        cashierName: 'Jean',
        shiftId: 'sh1',
        payments: [
          _payment('old', receivedBy: 'jean', amount: 9000, shiftId: null),
          _payment('other', receivedBy: 'jean', amount: 7000, shiftId: 'sh0'),
          _payment('now', receivedBy: 'jean', amount: 1000),
        ],
      );
      expect(balance.collected, 1000);
      expect(balance.remainingPayments.map((p) => p.id), ['now']);
    });

    test('notes de chambre et paiements non confirmés exclus', () {
      final balance = HandoverLedger.balanceFor(
        cashierId: 'jean',
        cashierName: 'Jean',
        shiftId: 'sh1',
        payments: [
          _payment(
            'room',
            receivedBy: 'jean',
            amount: 5000,
            type: 'room',
            method: 'room',
          ),
          _payment('ko', receivedBy: 'jean', amount: 5000, status: 'cancelled'),
          _payment('ok', receivedBy: 'jean', amount: 2000),
        ],
      );
      expect(balance.collected, 2000);
    });

    test('détail du reste par moyen de paiement', () {
      final balance = HandoverLedger.balanceFor(
        cashierId: 'jean',
        cashierName: 'Jean',
        shiftId: 'sh1',
        payments: [
          _payment('c1', receivedBy: 'jean', amount: 15000),
          _payment('c2', receivedBy: 'jean', amount: 5000),
          _payment(
            'm1',
            receivedBy: 'jean',
            amount: 10000,
            method: 'mobile_money',
          ),
        ],
      );
      expect(balance.remainingByMethod, {'cash': 20000, 'mobile_money': 10000});
    });
  });

  group('contrôle d’une nouvelle remise', () {
    test('uniquement ses paiements, de ce service, encore à remettre', () {
      AppErrorCode? check(List<PaymentModel> payments) =>
          HandoverLedger.validateHandover(
            senderId: 'jean',
            shiftId: 'sh1',
            payments: payments,
          )?.code;

      expect(check([_payment('p', receivedBy: 'jean', amount: 1)]), isNull);
      expect(check(const []), AppErrorCode.handoverNothingToHand);
      expect(
        check([_payment('p', receivedBy: 'paul', amount: 1)]),
        AppErrorCode.handoverNothingToHand,
        reason: 'argent encaissé par un autre',
      );
      expect(
        check([_payment('p', receivedBy: 'jean', amount: 1, shiftId: null)]),
        AppErrorCode.handoverNothingToHand,
        reason: 'paiement historique',
      );
      expect(
        check([
          _payment(
            'p',
            receivedBy: 'jean',
            amount: 1,
            handoverStatus: 'declared',
          ),
        ]),
        AppErrorCode.handoverNothingToHand,
        reason: 'déjà dans une remise : pas de double remise',
      );
    });
  });
}
