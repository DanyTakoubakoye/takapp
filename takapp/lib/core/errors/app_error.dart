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

  /// =========================
  /// COMPTE / PROFIL
  /// =========================
  firebaseUserNotFound,
  accountDisabled,
  userProfileNotFound,

  /// =========================
  /// MENU
  /// =========================
  invalidMenuId,
  invalidDishId,
  dishNameRequired,
  cocktailNameRequired,

  /// Utilisent [AppError.name] (nom ou identifiant de l'article).
  menuItemNotFound,
  noRecipeDefined,

  /// =========================
  /// COMMANDE / ANNULATION
  /// =========================
  noOrderSelected,
  noPaymentSelectedForHandover,
  orderAlreadyCancelled,
  stockAlreadyRestored,
  cannotCancelPaidOrder,
  cannotCancelPaidOrderItems,
  cannotCancelKitchenReady,
  cannotCancelBarReady,
  orderHasNoItems,
  noItemsFoundInOrder,
  noItemSelectedForCancellation,

  /// Utilisent [AppError.name].
  kitchenNotReady,
  barNotReady,
  itemAlreadyCancelled,
  cannotCancelItemKitchenReady,
  cannotCancelItemBarReady,
  invalidQuantityForItem,
  invalidQuantityInOrder,

  /// =========================
  /// CHAMBRES ET TYPES
  /// =========================
  invalidRoomNumber,
  roomTypeRequired,
  roomNumberAlreadyExists,
  invalidRoomStatus,
  invalidRoomTypeName,
  pricePerNightMustBePositive,
  roomTypeAlreadyExists,

  /// =========================
  /// RESERVATION
  /// =========================
  reservationNotAwaitingArrival,
  reservationNotInStay,
  roomNoLongerAvailable,
  roomNotOfReservedType,
  checkOutAfterCheckIn,

  /// Type complet sur la période : l'UI propose de forcer la réservation.
  /// Ce code remplace la détection par texte qui existait auparavant.
  noRoomOfTypeAvailable,

  /// =========================
  /// STOCK ET ARTICLES
  /// =========================
  invalidStockItemMissingId,
  itemNotFoundInStock,
  noItemDelivered,
  invalidItemName,
  invalidStore,
  itemAlreadyExistsInStore,

  /// Utilise [AppError.name].
  itemNotFoundInStockFor,

  /// =========================
  /// SERVEUR
  /// =========================
  invalidServerName,
  invalidEmail,
  userEmailAlreadyExists,

  /// =========================
  /// MONTANTS ET DOCUMENTS
  /// =========================
  totalAmountInvalid,
  paymentAmountInvalid,
  emptyPdfDocument,

  /// Utilisent [AppError.name] (détail technique de l'échec).
  firestoreError,
  consumptionLoadFailed,

  /// =========================
  /// STOCK DETAILLE
  /// =========================
  ///
  /// Ces trois messages portent plusieurs variables : ils utilisent
  /// [AppError.params] en plus de [AppError.name].
  stockNotFoundFor,
  inconsistentUnit,
  insufficientStockDetailed,

  /// =========================
  /// INGREDIENTS (RECETTES)
  /// =========================
  ///
  /// Utilisent [AppError.name] (nom de l'ingredient concerne).
  invalidIngredientStore,
  invalidIngredientItemId,
  invalidIngredientUnit,
  invalidIngredientQuantity,

  /// =========================
  /// ARTICLES DE COMMANDE
  /// =========================
  menuItemIdRequired,
  menuItemIdMissingForCancel,
  itemNotFoundInStockItems,

  /// =========================
  /// CERTILINK
  /// =========================
  certilinkDisabled,
  certilinkConfigIncomplete,
  certilinkConfigMissingKeys,
  invoiceNeedsOneItem,
}

/// Exception traduisible à l'affichage.
///
/// [name] porte le seul paramètre variable de l'application (un nom
/// d'article, ou le détail technique d'un échec), interpolé par les
/// quelques messages qui en ont besoin.
class AppError implements Exception {
  final AppErrorCode code;
  final String? name;

  /// Variables supplémentaires, pour les rares messages qui en portent
  /// plus d'une (unités, quantités disponibles et requises…).
  ///
  /// [name] reste le paramètre principal et couvre la grande majorité des
  /// cas ; `params` ne sert qu'aux messages composés.
  final Map<String, String> params;

  const AppError(this.code, {this.name, this.params = const {}});

  /// Valeur d'un paramètre supplémentaire, ou chaîne vide s'il est absent :
  /// un message incomplet vaut mieux qu'un plantage à l'affichage.
  String param(String key) => params[key] ?? '';

  /// Volontairement technique : ce texte ne doit jamais être montré à
  /// l'utilisateur. Il n'apparaît que dans les logs.
  @override
  String toString() {
    return name == null ? 'AppError(${code.name})' : 'AppError(${code.name}: $name)';
  }
}
