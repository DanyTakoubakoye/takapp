import 'package:takapp/l10n/app_localizations.dart';

class AccountTypes {
  /// =========================
  /// TYPES DE COMPTES
  /// =========================

  static const cash = 'cash';

  static const mobileMoney = 'mobile_money';

  static const bankTransfer = 'bank_transfer';

  static const card = 'card';

  static const credit = 'credit';

  static const beninResto = 'benin_resto';

  static const mixed = 'payment_mixed';

  /// =========================
  /// LISTE COMPLETE
  /// =========================

  static const all = [
    cash,
    mobileMoney,
    bankTransfer,
    card,
    credit,
    beninResto,
    mixed,
  ];

  /// =========================
  /// LABELS DE REPLI
  /// =========================
  ///
  /// Conservés en français pour les usages hors interface (documents,
  /// exports). Pour l'AFFICHAGE, utiliser [label].
  ///
  /// Le vocabulaire comptable diffère volontairement de celui de la caisse :
  /// ici « Banque » là où AppPaymentMethods dit « Virement bancaire ».
  static const labels = {
    cash: 'Cash',

    mobileMoney: 'Mobile Money',

    bankTransfer: 'Banque',

    card: 'Carte Bancaire',

    credit: 'Crédit',

    beninResto: 'Bénin Resto',

    mixed: 'Paiement Mixte',
  };

  /// =========================
  /// MODULES AUTORISÉS
  /// =========================
  ///
  /// SaaS :
  /// certains types peuvent être activés
  /// ou désactivés selon l’établissement.

  static const modules = {
    cash: ['restaurant', 'bar', 'hotel'],

    mobileMoney: ['restaurant', 'bar', 'hotel'],

    bankTransfer: ['restaurant', 'hotel'],

    card: ['restaurant', 'bar', 'hotel'],

    credit: ['restaurant', 'hotel'],

    beninResto: ['restaurant'],

    mixed: ['restaurant', 'bar', 'hotel'],
  };

  /// =========================
  /// TYPES PAR MODULE
  /// =========================

  static List<String> getByModule(String module) {
    return all.where((type) {
      final allowedModules = modules[type] ?? [];

      return allowedModules.contains(module);
    }).toList();
  }

  /// =========================
  /// LABEL D’UN TYPE (REPLI)
  /// =========================

  static String getLabel(String type) {
    return labels[type] ?? type;
  }

  /// =========================
  /// LABEL D’UN TYPE (AFFICHAGE)
  /// =========================
  ///
  /// La clé reste technique : seul son rendu est localisé.
  static String label(AppLocalizations l10n, String type) {
    switch (type) {
      case cash:
        return l10n.accountCash;
      case mobileMoney:
        return l10n.accountMobileMoney;
      case bankTransfer:
        return l10n.accountBankTransfer;
      case card:
        return l10n.accountCard;
      case credit:
        return l10n.accountCredit;
      case beninResto:
        return l10n.accountBeninResto;
      case mixed:
        return l10n.accountMixed;
      default:
        return type;
    }
  }

  /// =========================
  /// VALIDATION
  /// =========================

  static bool exists(String type) {
    return all.contains(type);
  }
}
