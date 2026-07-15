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
  /// LABELS UI
  /// =========================

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
  /// LABEL D’UN MODE
  /// =========================

  static String getLabel(String method) {
    return labels[method] ?? method;
  }

  /// =========================
  /// VALIDATION
  /// =========================

  static bool exists(String method) {
    return all.contains(method);
  }
}
