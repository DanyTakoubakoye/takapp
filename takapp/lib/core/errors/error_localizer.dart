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
    case AppErrorCode.selectAtLeastOneItem:
      return l10n.errSelectAtLeastOneItem;
    case AppErrorCode.selectPaymentMethod:
      return l10n.errSelectPaymentMethod;
    case AppErrorCode.roomNumberRequired:
      return l10n.errRoomNumberRequired;
    case AppErrorCode.tableNumberRequired:
      return l10n.errTableNumberRequired;

    case AppErrorCode.stockInsufficient:
      return l10n.errStockInsufficient(error.name ?? '');
  }
}
