import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/modeles/shift_discrepancy_model.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/services/handover_ledger.dart';

/// Raison pour laquelle un service ne peut pas encore être clôturé
/// financièrement. [name] / [amount] alimentent le message traduit.
enum ClosureBlockerKind {
  /// Service encore planifié ou en cours.
  shiftNotClosed,

  /// Un serveur doit encore remettre de l'argent.
  serverRemaining,

  /// Une remise d'un serveur attend la décision du Floor Manager.
  serverHandoverPending,

  /// Le Floor Manager doit encore remettre de l'argent.
  floorManagerRemaining,

  /// Une remise du Floor Manager attend la décision de la gérante.
  floorManagerTransferPending,

  /// Un écart déclaré attend la décision de la gérante.
  discrepancyPending,

  /// Les écarts approuvés ne correspondent plus au reste (une remise a eu
  /// lieu depuis) : l'écart doit être traité à nouveau.
  discrepancyMismatch,
}

class ClosureBlocker {
  final ClosureBlockerKind kind;
  final String name;
  final double amount;

  const ClosureBlocker(this.kind, {this.name = '', this.amount = 0});

  @override
  String toString() => '$kind($name, $amount)';
}

/// Situation d'un encaisseur (serveur ou Floor Manager) pour la clôture.
class ClosureCashierLine {
  final String userId;
  final String name;

  /// Encaissé (serveur) ou détenu (Floor Manager).
  final double collected;

  /// Remis et validé.
  final double handedOver;

  /// Remis, en attente de décision.
  final double pending;

  /// Reste à remettre (hors attente).
  final double remaining;

  /// Manquant documenté par des écarts APPROUVÉS.
  final double documentedShortage;

  const ClosureCashierLine({
    required this.userId,
    required this.name,
    required this.collected,
    required this.handedOver,
    required this.pending,
    required this.remaining,
    required this.documentedShortage,
  });

  /// Reste non expliqué : ni remis, ni documenté par un écart approuvé.
  double get unresolved => remaining - documentedShortage;

  bool get isSettled =>
      pending.abs() < ShiftClosurePolicy.epsilon &&
      unresolved.abs() < ShiftClosurePolicy.epsilon;
}

/// Revue de clôture financière d'un service : résumé, éléments bloquants
/// et statut affiché.
class ShiftClosureReview {
  final ShiftModel shift;
  final List<ClosureCashierLine> servers;
  final ClosureCashierLine floorManager;
  final FloorManagerCash floorManagerCash;
  final ShiftReconciliation reconciliation;
  final List<ShiftDiscrepancyModel> discrepancies;
  final List<ClosureBlocker> blockers;

  const ShiftClosureReview({
    required this.shift,
    required this.servers,
    required this.floorManager,
    required this.floorManagerCash,
    required this.reconciliation,
    required this.discrepancies,
    required this.blockers,
  });

  bool get canClose => blockers.isEmpty && !shift.isFinanciallyReconciled;

  /// Manquants acceptés (écarts approuvés).
  double get documentedShortage => discrepancies
      .where((d) => d.isApproved)
      .fold<double>(0, (sum, d) => sum + d.uncoveredAmount);

  /// Reste non remis de tout le service (serveurs + Floor Manager).
  double get totalRemaining =>
      servers.fold<double>(0, (sum, s) => sum + s.remaining) +
      floorManager.remaining;

  ShiftFinancialStatus get status {
    if (shift.isFinanciallyReconciled) return ShiftFinancialStatus.reconciled;
    if (discrepancies.any((d) => d.isPending)) {
      return ShiftFinancialStatus.disputed;
    }
    if (blockers.isEmpty) return ShiftFinancialStatus.ready;
    return ShiftFinancialStatus.pending;
  }

  /// Montants figés dans le service à la clôture.
  Map<String, double> get frozenSummary => {
    'theoreticalAmount': reconciliation.theoretical,
    'floorManagerDirect': reconciliation.floorManagerDirect,
    'serversCollected': reconciliation.serversCollected,
    'serversHandedOver': reconciliation.serversHandedOver,
    'transfersValidated': reconciliation.transfersValidated,
    'physicalReceived': reconciliation.physicalReceived,
    'countingDifference': reconciliation.countingDifference,
    'documentedShortage': documentedShortage,
    'difference': reconciliation.difference,
  };
}

/// =========================
/// CLÔTURE FINANCIÈRE D'UN SERVICE (13B) : RÈGLES
/// =========================
///
/// Moteur PUR. Un service est clôturable financièrement si :
/// A. il est terminé (`closed`) — jamais la seule preuve ;
/// B. chaque serveur n'a plus rien en attente, et son reste est nul ou
///    exactement documenté par des écarts approuvés ;
/// C. idem pour le Floor Manager, et aucune de ses remises n'attend la
///    gérante ;
/// D. aucun écart n'attend de décision.
class ShiftClosurePolicy {
  const ShiftClosurePolicy._();

  static const double epsilon = 0.005;

  static double _shortageOf(
    String userId,
    Iterable<ShiftDiscrepancyModel> discrepancies,
  ) => discrepancies
      .where((d) => d.isApproved && d.subjectUserId == userId)
      .fold<double>(0, (sum, d) => sum + d.uncoveredAmount);

  static ShiftClosureReview review({
    required ShiftModel shift,
    required List<PaymentModel> payments,
    required List<ServerHandoverModel> transfers,
    required List<ShiftDiscrepancyModel> discrepancies,
    Map<String, String> serverNames = const {},
  }) {
    final shiftDiscrepancies = discrepancies
        .where((d) => d.shiftId == shift.id)
        .toList();
    final fmId = shift.floorManagerId;

    final servers =
        HandoverLedger.balancesForShift(
              shiftId: shift.id,
              payments: payments,
              names: serverNames,
              excludeCashierIds: {fmId},
            )
            .map(
              (b) => ClosureCashierLine(
                userId: b.cashierId,
                name: b.cashierName,
                collected: b.collected,
                handedOver: b.validated,
                pending: b.declared,
                remaining: b.remaining,
                documentedShortage: _shortageOf(
                  b.cashierId,
                  shiftDiscrepancies,
                ),
              ),
            )
            .toList();

    final cash = FloorManagerLedger.cashOf(
      floorManagerId: fmId,
      shiftId: shift.id,
      payments: payments,
      transfers: transfers,
    );
    final floorManager = ClosureCashierLine(
      userId: fmId,
      name: shift.floorManagerName,
      collected: cash.held,
      handedOver: cash.transferValidated,
      pending: cash.transferPending,
      remaining: cash.remaining,
      documentedShortage: _shortageOf(fmId, shiftDiscrepancies),
    );

    final blockers = <ClosureBlocker>[
      if (!shift.isClosed)
        const ClosureBlocker(ClosureBlockerKind.shiftNotClosed),
    ];
    for (final s in servers) {
      if (s.pending > epsilon) {
        blockers.add(
          ClosureBlocker(
            ClosureBlockerKind.serverHandoverPending,
            name: s.name,
            amount: s.pending,
          ),
        );
      }
      _addRemaining(blockers, s, ClosureBlockerKind.serverRemaining);
    }
    if (floorManager.pending > epsilon) {
      blockers.add(
        ClosureBlocker(
          ClosureBlockerKind.floorManagerTransferPending,
          name: floorManager.name,
          amount: floorManager.pending,
        ),
      );
    }
    _addRemaining(
      blockers,
      floorManager,
      ClosureBlockerKind.floorManagerRemaining,
    );
    for (final d in shiftDiscrepancies.where((d) => d.isPending)) {
      blockers.add(
        ClosureBlocker(
          ClosureBlockerKind.discrepancyPending,
          name: d.subjectName,
          amount: d.uncoveredAmount,
        ),
      );
    }

    return ShiftClosureReview(
      shift: shift,
      servers: servers,
      floorManager: floorManager,
      floorManagerCash: cash,
      reconciliation: FloorManagerLedger.reconcile(
        floorManagerId: fmId,
        shiftId: shift.id,
        payments: payments,
        transfers: transfers,
      ),
      discrepancies: shiftDiscrepancies,
      blockers: blockers,
    );
  }

  static void _addRemaining(
    List<ClosureBlocker> blockers,
    ClosureCashierLine line,
    ClosureBlockerKind kind,
  ) {
    if (line.unresolved > epsilon) {
      blockers.add(
        ClosureBlocker(kind, name: line.name, amount: line.unresolved),
      );
    } else if (line.unresolved < -epsilon) {
      // Écart approuvé plus grand que le reste actuel : une remise a eu
      // lieu depuis, l'écart ne décrit plus la réalité.
      blockers.add(
        ClosureBlocker(
          ClosureBlockerKind.discrepancyMismatch,
          name: line.name,
          amount: -line.unresolved,
        ),
      );
    }
  }
}
