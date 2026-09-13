import 'package:takapp/l10n/app_localizations.dart';

class AppPaymentMethods {
  /// =========================
  /// MODES DE PAIEMENT
  /// =========================

  static const cash = 'cash';

  static const mobileMoney = 'mobile_money';

  static const card = 'card';

  static const credit = 'credit';

  static const bankTransfer = 'bank_transfer';

  static const mixed = 'mixed';

  static const beninResto = 'benin_resto';

  /// =========================
  /// TOUS LES MODES
  /// =========================

  static const all = [
    cash,
    mobileMoney,
    card,
    credit,
    bankTransfer,
    mixed,
    beninResto,
  ];

  /// =========================
  /// LABELS POUR LES DOCUMENTS
  /// =========================
  ///
  /// Volontairement en français et indépendants de la langue de
  /// l'utilisateur : ces libellés partent dans les factures imprimées, dont
  /// le contenu ne doit pas changer selon qui clique sur « imprimer ».
  ///
  /// Pour l'AFFICHAGE, utiliser [label]. L'ordre de cette map définit aussi
  /// l'ordre des menus déroulants : ne pas le modifier sans raison.
  static const labels = {
    cash: 'Espèces',

    mobileMoney: 'Mobile Money',

    card: 'Carte bancaire',

    bankTransfer: 'Virement bancaire',

    mixed: 'Paiement mixte',

    credit: 'Vente à crédit',

    beninResto: 'Bénin Resto',
  };

  /// =========================
  /// MODULES AUTORISÉS
  /// =========================
  ///
  /// SaaS :
  /// certains établissements
  /// peuvent activer/désactiver
  /// certains modes.

  static const modules = {
    cash: ['restaurant', 'bar', 'hotel'],

    mobileMoney: ['restaurant', 'bar', 'hotel'],

    card: ['restaurant', 'bar', 'hotel'],

    bankTransfer: ['restaurant', 'hotel'],

    mixed: ['restaurant', 'bar', 'hotel'],

    credit: ['restaurant', 'hotel'],

    beninResto: ['restaurant'],
  };

  /// =========================
  /// RECUPERER LES MODES
  /// D'UN MODULE
  /// =========================

  static List<String> getByModule(String module) {
    return all.where((method) {
      final allowedModules = modules[method] ?? [];

      return allowedModules.contains(module);
    }).toList();
  }

  /// =========================
  /// LABEL D’UN MODE (DOCUMENTS)
  /// =========================

  static String getLabel(String method) {
    return labels[method] ?? method;
  }

  /// =========================
  /// LABEL D’UN MODE (AFFICHAGE)
  /// =========================
  ///
  /// La clé reste technique ('cash', 'mobile_money'…) : c'est elle qui est
  /// stockée en base. Seul son rendu est localisé. Un mode inconnu est
  /// renvoyé tel quel plutôt que masqué.
  static String label(AppLocalizations l10n, String method) {
    switch (method) {
      case cash:
        return l10n.paymentCash;
      case mobileMoney:
        return l10n.paymentMobileMoney;
      case card:
        return l10n.paymentCard;
      case bankTransfer:
        return l10n.paymentBankTransfer;
      case mixed:
        return l10n.paymentMixed;
      case credit:
        return l10n.paymentCredit;
      case beninResto:
        return l10n.paymentBeninResto;
      default:
        return method;
    }
  }

  /// =========================
  /// VALIDATION
  /// =========================

  static bool exists(String method) {
    return all.contains(method);
  }
}
