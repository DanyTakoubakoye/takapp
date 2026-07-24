class AccountTypes {
  static const cash = 'cash';
  static const mobileMoney = 'mobile_money';
  static const bankTransfer = 'bank_transfer';
  static const card = 'card';
  static const credit = 'credit';
  static const beninResto = 'benin_resto';
  static const mixed = 'payement_mixed';

  static const all = [
    cash,
    mobileMoney,
    bankTransfer,
    card,
    credit,
    beninResto,
    mixed
  ];

  static const labels = {
    cash: 'Cash',
    mobileMoney: 'Momo',
    bankTransfer: 'Banque',
    card: 'Carte',
    credit: 'Crédit',
    beninResto: 'Bénin Resto',
    mixed: 'Paiement Mixed'
  };
}
