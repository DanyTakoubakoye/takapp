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
