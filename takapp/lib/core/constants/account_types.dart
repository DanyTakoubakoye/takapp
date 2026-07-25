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
  /// LABELS UI
  /// =========================

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
  /// LABEL D’UN TYPE
  /// =========================

  static String getLabel(String type) {
    return labels[type] ?? type;
  }

  /// =========================
  /// VALIDATION
  /// =========================

  static bool exists(String type) {
    return all.contains(type);
  }
}
