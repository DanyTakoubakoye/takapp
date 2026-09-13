/// =========================
/// ERREURS APPLICATIVES
/// =========================
///
/// Les services et les contrôleurs n'ont pas de `BuildContext` : ils ne
/// peuvent donc pas traduire un message. Ils lèvent (ou stockent) un
/// [AppError] porteur d'un **code stable**, et c'est l'UI qui traduit au
/// moment de l'affichage via `localizedError()`.
///
/// Avantages :
/// - un même code = un seul texte à traduire, réutilisé partout ;
/// - aucune logique métier ne dépend plus d'un texte français ;
/// - le `switch` du traducteur est exhaustif : ajouter un code ici
///   provoque une **erreur de compilation** tant qu'il n'est pas traduit.
enum AppErrorCode {
  /// =========================
  /// GENERIQUE
  /// =========================
  unknown,

  /// =========================
  /// SAAS / ETABLISSEMENT
  /// =========================
  establishmentNotFound,
  establishmentNotFoundReconnect,
  accountWithoutEstablishment,

  /// =========================
  /// AUTHENTIFICATION
  /// =========================
  invalidCredential,
  userNotFound,
  wrongPassword,
  networkRequestFailed,
  permissionDenied,
  resetEmailFailed,

  /// =========================
  /// INTROUVABLE
  /// =========================
  orderNotFound,
  invoiceNotFound,
  reservationNotFound,
  roomNotFound,
  clientNotFound,
  stockNotFound,
  stockDocumentNotFound,
  handoverNotFound,
  requestNotFound,

  /// =========================
  /// VALIDATION
  /// =========================
  clientNameRequired,
  clientTypeInvalid,
  amountMustBePositive,
  quantityMustBePositive,
  addAtLeastOneItem,
  addAtLeastOneUsedItem,
  selectAtLeastOneItem,
  selectAtLeastOnePayment,
  selectAtLeastOneOrderOrPayment,
  selectPaymentMethod,
  roomNumberRequired,
  tableNumberRequired,
  labelRequired,
  storeRequired,
  serverNameRequired,
  phoneRequired,
  emailRequired,
  minThresholdNegative,

  /// =========================
  /// FISCALISATION
  /// =========================
  certilinkError,
  fiscalizationFailed,
  certificationFailed,

  /// =========================
  /// STOCK
  /// =========================
  /// Utilise le paramètre [AppError.name].
  stockInsufficient,

  /// Utilise [AppError.name] pour transporter le détail de l'échec.
  serverRegistrationFailed,
}

/// Exception traduisible à l'affichage.
///
/// [name] porte le seul paramètre variable de l'application (un nom
/// d'article, ou le détail technique d'un échec), interpolé par les
/// quelques messages qui en ont besoin.
class AppError implements Exception {
  final AppErrorCode code;
  final String? name;

  const AppError(this.code, {this.name});

  /// Volontairement technique : ce texte ne doit jamais être montré à
  /// l'utilisateur. Il n'apparaît que dans les logs.
  @override
  String toString() {
    return name == null ? 'AppError(${code.name})' : 'AppError(${code.name}: $name)';
  }
}
