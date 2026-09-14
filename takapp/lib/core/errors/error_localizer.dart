import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/l10n/app_localizations.dart';

/// =========================
/// TRADUCTION DES ERREURS
/// =========================
///
/// Point d'entrée unique pour afficher une erreur venant d'un service ou
/// d'un contrôleur.
///
/// Migration progressive : tant qu'un service lève encore un
/// `Exception('texte français')`, le texte brut est affiché tel quel
/// (nettoyé du préfixe `Exception: `). Rien ne casse, et chaque service
/// migré gagne la traduction sans toucher à l'UI.
String localizedError(AppLocalizations l10n, Object? error) {
  if (error == null) {
    return l10n.errUnknown;
  }

  if (error is AppError) {
    return _messageFor(l10n, error);
  }

  return error.toString().replaceFirst('Exception: ', '');
}

/// Le `switch` est exhaustif : ajouter une valeur à [AppErrorCode] sans
/// l'ajouter ici est une erreur de compilation, pas un oubli silencieux.
String _messageFor(AppLocalizations l10n, AppError error) {
  switch (error.code) {
    case AppErrorCode.unknown:
      return l10n.errUnknown;

    case AppErrorCode.establishmentNotFound:
      return l10n.errEstablishmentNotFound;
    case AppErrorCode.establishmentNotFoundReconnect:
      return l10n.errEstablishmentNotFoundReconnect;
    case AppErrorCode.accountWithoutEstablishment:
      return l10n.errAccountWithoutEstablishment;

    case AppErrorCode.invalidCredential:
      return l10n.errInvalidCredential;
    case AppErrorCode.userNotFound:
      return l10n.errUserNotFound;
    case AppErrorCode.wrongPassword:
      return l10n.errWrongPassword;
    case AppErrorCode.networkRequestFailed:
      return l10n.errNetworkRequestFailed;
    case AppErrorCode.permissionDenied:
      return l10n.errPermissionDenied;
    case AppErrorCode.resetEmailFailed:
      return l10n.errResetEmailFailed;

    case AppErrorCode.orderNotFound:
      return l10n.errOrderNotFound;
    case AppErrorCode.invoiceNotFound:
      return l10n.errInvoiceNotFound;
    case AppErrorCode.reservationNotFound:
      return l10n.errReservationNotFound;
    case AppErrorCode.roomNotFound:
      return l10n.errRoomNotFound;
    case AppErrorCode.clientNotFound:
      return l10n.errClientNotFound;
    case AppErrorCode.stockNotFound:
      return l10n.errStockNotFound;
    case AppErrorCode.stockDocumentNotFound:
      return l10n.errStockDocumentNotFound;
    case AppErrorCode.handoverNotFound:
      return l10n.errHandoverNotFound;
    case AppErrorCode.requestNotFound:
      return l10n.errRequestNotFound;

    case AppErrorCode.clientNameRequired:
      return l10n.errClientNameRequired;
    case AppErrorCode.clientTypeInvalid:
      return l10n.errClientTypeInvalid;
    case AppErrorCode.amountMustBePositive:
      return l10n.errAmountMustBePositive;
    case AppErrorCode.quantityMustBePositive:
      return l10n.errQuantityMustBePositive;
    case AppErrorCode.addAtLeastOneItem:
      return l10n.errAddAtLeastOneItem;
    case AppErrorCode.addAtLeastOneUsedItem:
      return l10n.errAddAtLeastOneUsedItem;
    case AppErrorCode.selectAtLeastOneItem:
      return l10n.errSelectAtLeastOneItem;
    case AppErrorCode.selectAtLeastOnePayment:
      return l10n.errSelectAtLeastOnePayment;
    case AppErrorCode.selectAtLeastOneOrderOrPayment:
      return l10n.errSelectAtLeastOneOrderOrPayment;
    case AppErrorCode.selectPaymentMethod:
      return l10n.errSelectPaymentMethod;
    case AppErrorCode.roomNumberRequired:
      return l10n.errRoomNumberRequired;
    case AppErrorCode.tableNumberRequired:
      return l10n.errTableNumberRequired;
    case AppErrorCode.labelRequired:
      return l10n.errLabelRequired;
    case AppErrorCode.storeRequired:
      return l10n.errStoreRequired;
    case AppErrorCode.serverNameRequired:
      return l10n.errServerNameRequired;
    case AppErrorCode.phoneRequired:
      return l10n.errPhoneRequired;
    case AppErrorCode.emailRequired:
      return l10n.errEmailRequired;
    case AppErrorCode.minThresholdNegative:
      return l10n.errMinThresholdNegative;

    case AppErrorCode.certilinkError:
      return l10n.errCertilinkError;
    case AppErrorCode.fiscalizationFailed:
      return l10n.errFiscalizationFailed;
    case AppErrorCode.certificationFailed:
      return l10n.errCertificationFailed;

    case AppErrorCode.stockInsufficient:
      return l10n.errStockInsufficient(error.name ?? '');
    case AppErrorCode.serverRegistrationFailed:
      return l10n.errServerRegistrationFailed(error.name ?? '');

    case AppErrorCode.firebaseUserNotFound:
      return l10n.errFirebaseUserNotFound;
    case AppErrorCode.accountDisabled:
      return l10n.errAccountDisabled;
    case AppErrorCode.userProfileNotFound:
      return l10n.errUserProfileNotFound;

    case AppErrorCode.invalidMenuId:
      return l10n.errInvalidMenuId;
    case AppErrorCode.invalidDishId:
      return l10n.errInvalidDishId;
    case AppErrorCode.dishNameRequired:
      return l10n.errDishNameRequired;
    case AppErrorCode.cocktailNameRequired:
      return l10n.errCocktailNameRequired;
    case AppErrorCode.menuItemNotFound:
      return l10n.errMenuItemNotFound(error.name ?? '');
    case AppErrorCode.noRecipeDefined:
      return l10n.errNoRecipeDefined(error.name ?? '');

    case AppErrorCode.noOrderSelected:
      return l10n.errNoOrderSelected;
    case AppErrorCode.noPaymentSelectedForHandover:
      return l10n.errNoPaymentSelectedForHandover;
    case AppErrorCode.orderAlreadyCancelled:
      return l10n.errOrderAlreadyCancelled;
    case AppErrorCode.stockAlreadyRestored:
      return l10n.errStockAlreadyRestored;
    case AppErrorCode.cannotCancelPaidOrder:
      return l10n.errCannotCancelPaidOrder;
    case AppErrorCode.cannotCancelPaidOrderItems:
      return l10n.errCannotCancelPaidOrderItems;
    case AppErrorCode.cannotCancelKitchenReady:
      return l10n.errCannotCancelKitchenReady;
    case AppErrorCode.cannotCancelBarReady:
      return l10n.errCannotCancelBarReady;
    case AppErrorCode.orderHasNoItems:
      return l10n.errOrderHasNoItems;
    case AppErrorCode.noItemsFoundInOrder:
      return l10n.errNoItemsFoundInOrder;
    case AppErrorCode.noItemSelectedForCancellation:
      return l10n.errNoItemSelectedForCancellation;
    case AppErrorCode.kitchenNotReady:
      return l10n.errKitchenNotReady(error.name ?? '');
    case AppErrorCode.barNotReady:
      return l10n.errBarNotReady(error.name ?? '');
    case AppErrorCode.itemAlreadyCancelled:
      return l10n.errItemAlreadyCancelled(error.name ?? '');
    case AppErrorCode.cannotCancelItemKitchenReady:
      return l10n.errCannotCancelItemKitchenReady(error.name ?? '');
    case AppErrorCode.cannotCancelItemBarReady:
      return l10n.errCannotCancelItemBarReady(error.name ?? '');
    case AppErrorCode.invalidQuantityForItem:
      return l10n.errInvalidQuantityForItem(error.name ?? '');
    case AppErrorCode.invalidQuantityInOrder:
      return l10n.errInvalidQuantityInOrder(error.name ?? '');

    case AppErrorCode.invalidRoomNumber:
      return l10n.errInvalidRoomNumber;
    case AppErrorCode.roomTypeRequired:
      return l10n.errRoomTypeRequired;
    case AppErrorCode.roomNumberAlreadyExists:
      return l10n.errRoomNumberAlreadyExists;
    case AppErrorCode.invalidRoomStatus:
      return l10n.errInvalidRoomStatus;
    case AppErrorCode.invalidRoomTypeName:
      return l10n.errInvalidRoomTypeName;
    case AppErrorCode.pricePerNightMustBePositive:
      return l10n.errPricePerNightMustBePositive;
    case AppErrorCode.roomTypeAlreadyExists:
      return l10n.errRoomTypeAlreadyExists;

    case AppErrorCode.reservationNotAwaitingArrival:
      return l10n.errReservationNotAwaitingArrival;
    case AppErrorCode.reservationNotInStay:
      return l10n.errReservationNotInStay;
    case AppErrorCode.roomNoLongerAvailable:
      return l10n.errRoomNoLongerAvailable;
    case AppErrorCode.roomNotOfReservedType:
      return l10n.errRoomNotOfReservedType;
    case AppErrorCode.checkOutAfterCheckIn:
      return l10n.errCheckOutAfterCheckIn;
    case AppErrorCode.noRoomOfTypeAvailable:
      return l10n.errNoRoomOfTypeAvailable;

    case AppErrorCode.invalidStockItemMissingId:
      return l10n.errInvalidStockItemMissingId;
    case AppErrorCode.itemNotFoundInStock:
      return l10n.errItemNotFoundInStock;
    case AppErrorCode.noItemDelivered:
      return l10n.errNoItemDelivered;
    case AppErrorCode.invalidItemName:
      return l10n.errInvalidItemName;
    case AppErrorCode.invalidStore:
      return l10n.errInvalidStore;
    case AppErrorCode.itemAlreadyExistsInStore:
      return l10n.errItemAlreadyExistsInStore;
    case AppErrorCode.itemNotFoundInStockFor:
      return l10n.errItemNotFoundInStockFor(error.name ?? '');

    case AppErrorCode.invalidServerName:
      return l10n.errInvalidServerName;
    case AppErrorCode.invalidEmail:
      return l10n.errInvalidEmail;
    case AppErrorCode.userEmailAlreadyExists:
      return l10n.errUserEmailAlreadyExists;

    case AppErrorCode.totalAmountInvalid:
      return l10n.errTotalAmountInvalid;
    case AppErrorCode.paymentAmountInvalid:
      return l10n.errPaymentAmountInvalid;
    case AppErrorCode.emptyPdfDocument:
      return l10n.errEmptyPdfDocument;
    case AppErrorCode.firestoreError:
      return l10n.errFirestoreError(error.name ?? '');
    case AppErrorCode.consumptionLoadFailed:
      return l10n.errConsumptionLoadFailed(error.name ?? '');

    case AppErrorCode.invalidIngredientStore:
      return l10n.errInvalidIngredientStore(error.name ?? '');
    case AppErrorCode.invalidIngredientItemId:
      return l10n.errInvalidIngredientItemId(error.name ?? '');
    case AppErrorCode.invalidIngredientUnit:
      return l10n.errInvalidIngredientUnit(error.name ?? '');
    case AppErrorCode.invalidIngredientQuantity:
      return l10n.errInvalidIngredientQuantity(error.name ?? '');

    case AppErrorCode.menuItemIdRequired:
      return l10n.errMenuItemIdRequired;
    case AppErrorCode.menuItemIdMissingForCancel:
      return l10n.errMenuItemIdMissingForCancel;
    case AppErrorCode.itemNotFoundInStockItems:
      return l10n.errItemNotFoundInStockItems;

    case AppErrorCode.certilinkDisabled:
      return l10n.errCertilinkDisabled;
    case AppErrorCode.certilinkConfigIncomplete:
      return l10n.errCertilinkConfigIncomplete;
    case AppErrorCode.certilinkConfigMissingKeys:
      return l10n.errCertilinkConfigMissingKeys;
    case AppErrorCode.invoiceNeedsOneItem:
      return l10n.errInvoiceNeedsOneItem;

    case AppErrorCode.stockNotFoundFor:
      return l10n.errStockNotFoundFor(error.name ?? '');
    case AppErrorCode.inconsistentUnit:
      return l10n.errInconsistentUnit(
        error.name ?? '',
        error.param('stockUnit'),
        error.param('recipeUnit'),
      );
    case AppErrorCode.insufficientStockDetailed:
      return l10n.errInsufficientStockDetailed(
        error.name ?? '',
        error.param('available'),
        error.param('required'),
      );
  }
}
