// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageLabel => 'Language';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonLogout => 'Sign out';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String errorPrefixed(String message) {
    return 'Error: $message';
  }

  @override
  String get errUnknown => 'An unknown error occurred.';

  @override
  String get errEstablishmentNotFound => 'Establishment not found.';

  @override
  String get errEstablishmentNotFoundReconnect =>
      'Establishment not found. Please sign in again.';

  @override
  String get errAccountWithoutEstablishment =>
      'Your account is not linked to any establishment.';

  @override
  String get errInvalidCredential => 'Incorrect email or password.';

  @override
  String get errUserNotFound => 'User not found.';

  @override
  String get errWrongPassword => 'Incorrect password.';

  @override
  String get errNetworkRequestFailed =>
      'Network problem. Please check your connection.';

  @override
  String get errPermissionDenied => 'Access denied by Firestore rules.';

  @override
  String get errResetEmailFailed => 'Could not send the reset email.';

  @override
  String get errOrderNotFound => 'Order not found.';

  @override
  String get errInvoiceNotFound => 'Invoice not found.';

  @override
  String get errReservationNotFound => 'Reservation not found.';

  @override
  String get errRoomNotFound => 'Room not found.';

  @override
  String get errClientNotFound => 'Client not found.';

  @override
  String get errStockNotFound => 'Stock not found.';

  @override
  String get errStockDocumentNotFound => 'Stock document not found.';

  @override
  String get errHandoverNotFound => 'Handover not found.';

  @override
  String get errRequestNotFound => 'Request not found.';

  @override
  String get errClientNameRequired => 'Client name is required.';

  @override
  String get errClientTypeInvalid => 'Invalid client type.';

  @override
  String get errAmountMustBePositive => 'The amount must be greater than 0.';

  @override
  String get errQuantityMustBePositive =>
      'The quantity must be greater than 0.';

  @override
  String get errAddAtLeastOneItem => 'Please add at least one item.';

  @override
  String get errSelectAtLeastOneItem => 'Please select at least one item.';

  @override
  String get errSelectPaymentMethod => 'Please choose a payment method.';

  @override
  String get errRoomNumberRequired => 'Please specify the room number.';

  @override
  String get errTableNumberRequired => 'Please specify the table number.';

  @override
  String get errAddAtLeastOneUsedItem => 'Please add at least one item used.';

  @override
  String get errSelectAtLeastOnePayment =>
      'Please select at least one payment.';

  @override
  String get errSelectAtLeastOneOrderOrPayment =>
      'Please select at least one order or payment.';

  @override
  String get errLabelRequired => 'Please enter a label.';

  @override
  String get errStoreRequired => 'Please specify the store.';

  @override
  String get errServerNameRequired => 'Please enter the waiter\'s name.';

  @override
  String get errPhoneRequired => 'Please enter the phone number.';

  @override
  String get errEmailRequired => 'Please enter an email address.';

  @override
  String get errMinThresholdNegative =>
      'The minimum threshold cannot be negative.';

  @override
  String get errCertilinkError => 'CertiLink error';

  @override
  String get errFiscalizationFailed => 'Fiscalization failed';

  @override
  String get errCertificationFailed => 'Certification failed';

  @override
  String errStockInsufficient(String name) {
    return 'Insufficient stock for $name.';
  }

  @override
  String errServerRegistrationFailed(String name) {
    return 'Error while registering the waiter: $name';
  }

  @override
  String get errFirebaseUserNotFound =>
      'Firebase user not found after sign-in.';

  @override
  String get errAccountDisabled => 'This account is disabled.';

  @override
  String get errUserProfileNotFound =>
      'The user profile could not be found in Firestore.';

  @override
  String get errInvalidMenuId => 'Invalid menu identifier.';

  @override
  String get errInvalidDishId => 'Invalid dish identifier.';

  @override
  String get errDishNameRequired => 'Dish name is required.';

  @override
  String get errCocktailNameRequired => 'Cocktail name is required.';

  @override
  String errMenuItemNotFound(String name) {
    return 'Menu item not found: $name';
  }

  @override
  String errNoRecipeDefined(String name) {
    return 'The item \"$name\" has no recipe defined.';
  }

  @override
  String get errNoOrderSelected => 'No order selected.';

  @override
  String get errNoPaymentSelectedForHandover =>
      'No payment selected for the handover.';

  @override
  String get errOrderAlreadyCancelled => 'This order is already cancelled.';

  @override
  String get errStockAlreadyRestored =>
      'The stock for this order has already been restored.';

  @override
  String get errCannotCancelPaidOrder =>
      'Cannot cancel an order that has already been paid.';

  @override
  String get errCannotCancelPaidOrderItems =>
      'Cannot cancel items from an order that has already been paid.';

  @override
  String get errCannotCancelKitchenReady =>
      'Cannot cancel: the kitchen part is already ready or served.';

  @override
  String get errCannotCancelBarReady =>
      'Cannot cancel: the bar part is already ready or served.';

  @override
  String get errOrderHasNoItems => 'This order contains no items.';

  @override
  String get errNoItemsFoundInOrder => 'No item found in this order.';

  @override
  String get errNoItemSelectedForCancellation =>
      'No item selected for cancellation.';

  @override
  String errKitchenNotReady(String name) {
    return 'Order $name: kitchen not ready.';
  }

  @override
  String errBarNotReady(String name) {
    return 'Order $name: bar not ready.';
  }

  @override
  String errItemAlreadyCancelled(String name) {
    return 'The item \"$name\" is already cancelled.';
  }

  @override
  String errCannotCancelItemKitchenReady(String name) {
    return 'Cannot cancel \"$name\": the kitchen is already ready or served.';
  }

  @override
  String errCannotCancelItemBarReady(String name) {
    return 'Cannot cancel \"$name\": the bar is already ready or served.';
  }

  @override
  String errInvalidQuantityForItem(String name) {
    return 'Invalid quantity for the item \"$name\".';
  }

  @override
  String errInvalidQuantityInOrder(String name) {
    return 'Invalid quantity in the order for \"$name\".';
  }

  @override
  String get errInvalidRoomNumber => 'Invalid room number.';

  @override
  String get errRoomTypeRequired => 'Room type is required.';

  @override
  String get errRoomNumberAlreadyExists =>
      'A room with this number already exists.';

  @override
  String get errInvalidRoomStatus => 'Invalid room status.';

  @override
  String get errInvalidRoomTypeName => 'Invalid type name.';

  @override
  String get errPricePerNightMustBePositive =>
      'The price per night must be greater than 0.';

  @override
  String get errRoomTypeAlreadyExists => 'This room type already exists.';

  @override
  String get errReservationNotAwaitingArrival =>
      'This reservation is not awaiting arrival.';

  @override
  String get errReservationNotInStay =>
      'This reservation is not currently in stay.';

  @override
  String get errRoomNoLongerAvailable => 'This room is no longer available.';

  @override
  String get errRoomNotOfReservedType =>
      'This room is not of the reserved type.';

  @override
  String get errCheckOutAfterCheckIn =>
      'The departure date must be after the arrival date.';

  @override
  String get errNoRoomOfTypeAvailable =>
      'No room of this type is available for this period. You can force the reservation if necessary.';

  @override
  String get errInvalidStockItemMissingId =>
      'Invalid stock item: missing itemId.';

  @override
  String get errItemNotFoundInStock => 'Item not found in stock.';

  @override
  String get errNoItemDelivered => 'No item delivered.';

  @override
  String get errInvalidItemName => 'Invalid item name.';

  @override
  String get errInvalidStore => 'Invalid store.';

  @override
  String get errItemAlreadyExistsInStore =>
      'This item already exists in this store.';

  @override
  String errItemNotFoundInStockFor(String name) {
    return 'Item not found in stock: $name';
  }

  @override
  String get errInvalidServerName => 'Invalid waiter name.';

  @override
  String get errInvalidEmail => 'Invalid email.';

  @override
  String get errUserEmailAlreadyExists =>
      'A user with this email already exists.';

  @override
  String get errTotalAmountInvalid => 'Invalid total amount.';

  @override
  String get errPaymentAmountInvalid => 'Invalid payment amount.';

  @override
  String get errEmptyPdfDocument => 'Empty PDF document.';

  @override
  String errFirestoreError(String name) {
    return 'Firestore error: $name';
  }

  @override
  String errConsumptionLoadFailed(String name) {
    return 'Error while loading consumption: $name';
  }

  @override
  String get clientDisabled => 'Client disabled.';

  @override
  String get clientAdded => 'Client added.';

  @override
  String get loginSubtitle => 'Sign in to your workspace';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailHint => 'example@domain.com';

  @override
  String get loginEmailRequired => 'Please enter your email';

  @override
  String get loginEmailInvalid => 'Invalid email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordEmailFirst => 'Please enter a complete email first';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get loginPasswordTooShort => 'Minimum 6 characters';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginResetNeedsEmail =>
      'Please enter your email address first to receive the reset link.';

  @override
  String get loginResetInvalidEmail => 'Please enter a valid email address.';

  @override
  String loginResetSent(String email) {
    return 'A reset link has been sent to $email. Remember to check your spam folder.';
  }

  @override
  String get loginResetFailed => 'Could not send the reset email.';

  @override
  String loginResetError(String error) {
    return 'Error while sending the email: $error';
  }

  @override
  String get roleGlobalAdmin => 'Global Administrator';

  @override
  String get roleSuperAdmin => 'Super Administrator';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleAccountant => 'Accountant';

  @override
  String get roleHeadChef => 'Head Chef';

  @override
  String get roleWaiter => 'Waiter';

  @override
  String get roleHousekeeping => 'Housekeeping';

  @override
  String get roleBartender => 'Bartender';

  @override
  String get roleButler => 'Butler';

  @override
  String get roleReceptionist => 'Receptionist';
}
