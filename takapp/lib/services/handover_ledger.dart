import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';

/// Situation d'une personne (celle qui a ENCAISSÉ) pour un service.
class ShiftCashBalance {
  final String cashierId;
  final String cashierName;

  /// Tout ce qu'elle a encaissé pendant le service.
  final double collected;

  /// Déclaré dans une remise, en attente de validation.
  final double declared;

  /// Remis et validé par le destinataire.
  final double validated;

  /// Encore détenu : encaissé − déclaré − validé. Un rejet remet les
  /// paiements « à remettre » : le reste remonte.
  final double remaining;

  /// Reste à remettre par moyen de paiement (espèces, mobile money…).
  final Map<String, double> remainingByMethod;

  /// Paiements encore à remettre (base d'une nouvelle remise).
  final List<PaymentModel> remainingPayments;

  const ShiftCashBalance({
    required this.cashierId,
    required this.cashierName,
    required this.collected,
    required this.declared,
    required this.validated,
    required this.remaining,
    required this.remainingByMethod,
    required this.remainingPayments,
  });
}

/// =========================
/// REMISES D'UN SERVICE : RÈGLES DE CALCUL
/// =========================
///
/// Moteur PUR. L'argent appartient à celui qui l'a RÉELLEMENT encaissé
/// (`receivedBy`), jamais au serveur responsable de la vente : si Paul
/// (Floor Manager) encaisse la vente de Jean, c'est Paul qui détient
/// l'argent, Jean n'a rien à lui remettre.
///
/// Un paiement compte pour un service seulement s'il porte ce `shiftId`
/// (posé au moment de l'encaissement). Les paiements historiques sans
/// `shiftId` ne sont jamais rattachés après coup : ils restent dans le
/// circuit serveur -> gérante.
///
/// Moyens de paiement : TAKAPP ne distingue pas l'argent physiquement
/// détenu ; tous les paiements confirmés (hors note de chambre) sont remis,
/// avec leur détail par moyen pour que le destinataire sache quoi compter.
class HandoverLedger {
  const HandoverLedger._();

  static bool isShiftCash(PaymentModel payment, String shiftId) {
    return payment.shiftId == shiftId &&
        payment.status == 'confirmed' &&
        payment.type != 'room' &&
        payment.method != 'room';
  }

  static Map<String, double> byMethod(Iterable<PaymentModel> payments) {
    final result = <String, double>{};
    for (final payment in payments) {
      result[payment.method] = (result[payment.method] ?? 0) + payment.amount;
    }
    return result;
  }

  static double _sum(Iterable<PaymentModel> payments) =>
      payments.fold<double>(0, (running, p) => running + p.amount);

  /// Situation de [cashierId] pour le service [shiftId].
  static ShiftCashBalance balanceFor({
    required String cashierId,
    required String cashierName,
    required String shiftId,
    required List<PaymentModel> payments,
  }) {
    final mine = payments
        .where((p) => p.receivedBy == cashierId && isShiftCash(p, shiftId))
        .toList();

    final pending = mine.where((p) => p.handoverStatus == 'pending').toList();
    final declared = mine.where((p) => p.handoverStatus == 'declared');
    final validated = mine.where((p) => p.handoverStatus == 'validated');

    return ShiftCashBalance(
      cashierId: cashierId,
      cashierName: cashierName,
      collected: _sum(mine),
      declared: _sum(declared),
      validated: _sum(validated),
      remaining: _sum(pending),
      remainingByMethod: byMethod(pending),
      remainingPayments: pending,
    );
  }

  /// Situation de chaque encaisseur du service (rapport du Floor Manager).
  /// [names] complète les noms des serveurs sans encaissement.
  static List<ShiftCashBalance> balancesForShift({
    required String shiftId,
    required List<PaymentModel> payments,
    Map<String, String> names = const {},
    Set<String> excludeCashierIds = const {},
  }) {
    final ids = <String>{
      ...names.keys,
      ...payments
          .where((p) => isShiftCash(p, shiftId))
          .map((p) => p.receivedBy),
    }..removeAll(excludeCashierIds);

    final balances = ids.map((id) {
      final paymentName = payments
          .where((p) => p.receivedBy == id)
          .map((p) => p.receivedByName)
          .firstWhere((n) => n.isNotEmpty, orElse: () => '');
      return balanceFor(
        cashierId: id,
        cashierName: names[id] ?? (paymentName.isEmpty ? id : paymentName),
        shiftId: shiftId,
        payments: payments,
      );
    }).toList()..sort((a, b) => a.cashierName.compareTo(b.cashierName));

    return balances;
  }

  /// Contrôle d'une nouvelle remise : uniquement des paiements de CE
  /// service, encaissés par l'émetteur, encore à remettre.
  static AppError? validateHandover({
    required String senderId,
    required String shiftId,
    required List<PaymentModel> payments,
  }) {
    if (payments.isEmpty) {
      return const AppError(AppErrorCode.handoverNothingToHand);
    }
    for (final payment in payments) {
      if (payment.receivedBy != senderId ||
          !isShiftCash(payment, shiftId) ||
          payment.handoverStatus != 'pending') {
        return const AppError(AppErrorCode.handoverNothingToHand);
      }
    }
    return null;
  }
}

/// =========================
/// CAISSE DU FLOOR MANAGER (12B)
/// =========================

/// Ce que le Floor Manager détient pour un service, et ce qu'il doit
/// encore remettre à la gérante.
class FloorManagerCash {
  /// A. Encaissé directement par lui (`receivedBy == Floor Manager`).
  final double direct;

  /// B. Remises de ses serveurs VALIDÉES par lui (rejetées exclues).
  final double fromServers;

  /// Remises à la gérante en attente de sa validation.
  final double transferPending;

  /// Remises à la gérante validées par elle.
  final double transferValidated;

  /// Détenu − remis (en attente + validé). Un rejet ne réduit rien.
  final double remaining;

  final Map<String, double> heldByMethod;
  final Map<String, double> remainingByMethod;

  /// Rang de la prochaine remise (identifiant idempotent).
  final int nextSequence;

  const FloorManagerCash({
    required this.direct,
    required this.fromServers,
    required this.transferPending,
    required this.transferValidated,
    required this.remaining,
    required this.heldByMethod,
    required this.remainingByMethod,
    required this.nextSequence,
  });

  double get held => direct + fromServers;
  double get transferred => transferPending + transferValidated;
}

/// Rapprochement financier d'un service (vue gérante / Floor Manager).
class ShiftReconciliation {
  /// Encaissé directement par le Floor Manager.
  final double floorManagerDirect;

  /// Encaissé par les serveurs du service.
  final double serversCollected;

  /// Remises serveurs validées par le Floor Manager.
  final double serversHandedOver;

  /// Encore chez les serveurs (non remis ou remise en attente).
  final double serversStillHeld;

  final double transfersValidated;
  final double transfersPending;

  /// Encore chez le Floor Manager (hors remises en attente).
  final double floorManagerStillHeld;

  /// Montant physiquement compté par la gérante sur les remises validées.
  final double physicalReceived;

  /// Somme des écarts constatés à la validation des remises.
  final double countingDifference;

  const ShiftReconciliation({
    required this.floorManagerDirect,
    required this.serversCollected,
    required this.serversHandedOver,
    required this.serversStillHeld,
    required this.transfersValidated,
    required this.transfersPending,
    required this.floorManagerStillHeld,
    required this.physicalReceived,
    required this.countingDifference,
  });

  /// Tout ce que le service aurait dû faire arriver à la gérante.
  double get theoretical => floorManagerDirect + serversCollected;

  /// Pas encore arrivé chez la gérante (détenu ou en attente).
  double get stillHeld =>
      serversStillHeld + floorManagerStillHeld + transfersPending;

  /// Physique − théorique : négatif tant que de l'argent est encore détenu
  /// ou s'il manque de l'argent au comptage.
  double get difference => physicalReceived - theoretical;
}

/// Règles de calcul de la caisse du Floor Manager. Même logique de moyens
/// de paiement que les remises serveur -> Floor Manager : tout paiement
/// confirmé hors note de chambre, détaillé par moyen.
class FloorManagerLedger {
  const FloorManagerLedger._();

  static const double _epsilon = 0.005;

  static Iterable<ServerHandoverModel> _transfersOf(
    String floorManagerId,
    String shiftId,
    Iterable<ServerHandoverModel> transfers,
  ) => transfers.where(
    (t) =>
        t.isFromFloorManager &&
        t.senderUserId == floorManagerId &&
        t.shiftId == shiftId,
  );

  static void _add(
    Map<String, double> target,
    Map<String, double> source, [
    double sign = 1,
  ]) {
    source.forEach((method, amount) {
      target[method] = (target[method] ?? 0) + sign * amount;
    });
  }

  static FloorManagerCash cashOf({
    required String floorManagerId,
    required String shiftId,
    required List<PaymentModel> payments,
    required List<ServerHandoverModel> transfers,
  }) {
    final shiftCash = payments.where(
      (p) => HandoverLedger.isShiftCash(p, shiftId),
    );
    final direct = shiftCash.where((p) => p.receivedBy == floorManagerId);
    // Seuls les paiements d'un service peuvent être remis au Floor Manager
    // de ce service (règle 11B) : validé = reçu par lui.
    final fromServers = shiftCash.where(
      (p) => p.receivedBy != floorManagerId && p.handoverStatus == 'validated',
    );

    final mine = _transfersOf(floorManagerId, shiftId, transfers).toList();
    final pending = mine.where((t) => t.status == 'pending');
    final validated = mine.where((t) => t.status == 'validated');

    final held = <String, double>{};
    _add(held, HandoverLedger.byMethod(direct));
    _add(held, HandoverLedger.byMethod(fromServers));

    final remainingByMethod = Map<String, double>.from(held);
    for (final t in [...pending, ...validated]) {
      _add(remainingByMethod, _breakdownOf(t), -1);
    }
    remainingByMethod.removeWhere((_, v) => v.abs() < _epsilon);

    double sumTransfers(Iterable<ServerHandoverModel> list) =>
        list.fold<double>(0, (running, t) => running + t.declaredAmount);

    final directTotal = HandoverLedger._sum(direct);
    final fromServersTotal = HandoverLedger._sum(fromServers);
    final pendingTotal = sumTransfers(pending);
    final validatedTotal = sumTransfers(validated);

    final nextSequence = mine.fold<int>(
      0,
      (next, t) => (t.transferSequence ?? -1) + 1 > next
          ? (t.transferSequence ?? -1) + 1
          : next,
    );

    return FloorManagerCash(
      direct: directTotal,
      fromServers: fromServersTotal,
      transferPending: pendingTotal,
      transferValidated: validatedTotal,
      remaining: directTotal + fromServersTotal - pendingTotal - validatedTotal,
      heldByMethod: held,
      remainingByMethod: remainingByMethod,
      nextSequence: nextSequence,
    );
  }

  /// Détail d'une remise ; une remise sans détail compte en espèces.
  static Map<String, double> _breakdownOf(ServerHandoverModel t) =>
      t.paymentBreakdown.isEmpty
      ? {AppPaymentMethods.cash: t.declaredAmount}
      : t.paymentBreakdown;

  /// Contrôle d'une nouvelle remise : montant positif, et jamais plus que
  /// ce qui reste, moyen par moyen.
  static AppError? validateTransfer({
    required FloorManagerCash cash,
    required Map<String, double> breakdown,
  }) {
    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0 || breakdown.values.any((v) => v < 0)) {
      return const AppError(AppErrorCode.amountMustBePositive);
    }
    for (final entry in breakdown.entries) {
      if (!AppPaymentMethods.all.contains(entry.key)) {
        return const AppError(AppErrorCode.transferExceedsAvailable);
      }
      final available = cash.remainingByMethod[entry.key] ?? 0;
      if (entry.value > available + _epsilon) {
        return const AppError(AppErrorCode.transferExceedsAvailable);
      }
    }
    return null;
  }

  static ShiftReconciliation reconcile({
    required String floorManagerId,
    required String shiftId,
    required List<PaymentModel> payments,
    required List<ServerHandoverModel> transfers,
  }) {
    final cash = cashOf(
      floorManagerId: floorManagerId,
      shiftId: shiftId,
      payments: payments,
      transfers: transfers,
    );
    final servers = payments.where(
      (p) =>
          HandoverLedger.isShiftCash(p, shiftId) &&
          p.receivedBy != floorManagerId,
    );
    final serversCollected = HandoverLedger._sum(servers);
    final validated = _transfersOf(
      floorManagerId,
      shiftId,
      transfers,
    ).where((t) => t.status == 'validated');

    return ShiftReconciliation(
      floorManagerDirect: cash.direct,
      serversCollected: serversCollected,
      serversHandedOver: cash.fromServers,
      serversStillHeld: serversCollected - cash.fromServers,
      transfersValidated: cash.transferValidated,
      transfersPending: cash.transferPending,
      floorManagerStillHeld: cash.remaining,
      physicalReceived: validated.fold<double>(
        0,
        (running, t) => running + (t.physicalAmount ?? t.declaredAmount),
      ),
      countingDifference: validated.fold<double>(
        0,
        (running, t) => running + (t.difference ?? 0),
      ),
    );
  }
}
