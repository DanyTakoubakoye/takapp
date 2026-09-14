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
  String errStockNotFoundFor(String name) {
    return 'Stock not found for \"$name\".';
  }

  @override
  String errInconsistentUnit(String name, String stockUnit, String recipeUnit) {
    return 'Inconsistent unit for \"$name\": stock in \"$stockUnit\" but recipe in \"$recipeUnit\".';
  }

  @override
  String errInsufficientStockDetailed(
    String name,
    String available,
    String required,
  ) {
    return 'Insufficient stock for \"$name\": $available available, $required required.';
  }

  @override
  String get navNotifications => 'Notifications';

  @override
  String get serverNotFound => 'Waiter not found.';

  @override
  String get noNotifications => 'No notifications.';

  @override
  String get notificationFallbackTitle => 'Notification';

  @override
  String get departmentKitchen => 'Kitchen';

  @override
  String get departmentBar => 'Bar';

  @override
  String labelTable(String number) {
    return 'Table $number';
  }

  @override
  String labelRoom(String number) {
    return 'Room $number';
  }

  @override
  String get labelBarClient => 'Bar client';

  @override
  String clientLine(String client) {
    return 'Client: $client';
  }

  @override
  String cancelPartialTitle(String orderNumber) {
    return 'Partial cancellation $orderNumber';
  }

  @override
  String get cancelItemAlreadyCancelled => 'Already cancelled';

  @override
  String get cancelItemKitchenDone => 'Kitchen already ready/served';

  @override
  String get cancelItemBarDone => 'Bar already ready/served';

  @override
  String get cancelItemCancelable => 'Can be cancelled';

  @override
  String get cancelItemsDone => 'Items cancelled and stock restored.';

  @override
  String cancelLoadOrderError(String error) {
    return 'Error loading the order: $error';
  }

  @override
  String cancelLoadItemsError(String error) {
    return 'Error loading the items: $error';
  }

  @override
  String cancelDepartmentLine(String department) {
    return 'Department: $department';
  }

  @override
  String get cancelReasonLabel => 'Cancellation reason';

  @override
  String cancelAmountToDeduct(String amount) {
    return 'Amount to deduct: $amount FCFA';
  }

  @override
  String get cancelInProgress => 'Cancelling...';

  @override
  String get cancelValidate => 'Confirm cancellation';

  @override
  String get myInvoicesTitle => 'My invoices';

  @override
  String get today => 'Today';

  @override
  String todayWithDate(String date) {
    return 'Today ($date)';
  }

  @override
  String get pickDate => 'Pick a date';

  @override
  String get noInvoiceForDate => 'No invoice for this date.';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get statusFiscalized => 'Fiscalized';

  @override
  String get statusNotFiscalized => 'Not fiscalized';

  @override
  String get actionCollectInvoice => 'Collect payment';

  @override
  String get actionPrintInvoice => 'Print invoice';

  @override
  String get actionFiscalize => 'Fiscalize';

  @override
  String get actionPrintFiscalizedInvoice => 'Print fiscalized invoice';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonValidate => 'Confirm';

  @override
  String get clientFallback => 'Client';

  @override
  String get noOrders => 'No orders';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusServed => 'Served';

  @override
  String get statusPickedUp => 'Picked up';

  @override
  String get columnPending => 'Pending';

  @override
  String get columnPreparing => 'Preparing';

  @override
  String get columnReady => 'Ready';

  @override
  String get suiviBarTitle => 'Bar tracking';

  @override
  String get suiviCuisineTitle => 'Kitchen tracking';

  @override
  String get barItems => 'Bar items';

  @override
  String get kitchenItems => 'Kitchen items';

  @override
  String waiterLine(String name) {
    return 'Waiter: $name';
  }

  @override
  String orderTotalLine(String amount) {
    return 'Order total: $amount FCFA';
  }

  @override
  String totalLine(String amount) {
    return 'Total: $amount FCFA';
  }

  @override
  String noteLine(String note) {
    return 'Note: $note';
  }

  @override
  String barItemsError(String error) {
    return 'Error loading bar items: $error';
  }

  @override
  String kitchenItemsError(String error) {
    return 'Error loading kitchen items: $error';
  }

  @override
  String get actionSetPreparing => 'Start preparing';

  @override
  String get actionMarkReady => 'Mark as ready';

  @override
  String get actionBackToPreparing => 'Back to preparing';

  @override
  String get actionRevert => 'Revert';

  @override
  String get actionPickedUp => 'Picked up';

  @override
  String get encaissementTitle => 'Payment collection';

  @override
  String get noUnpaidOrder => 'No unpaid order.';

  @override
  String ordersCount(String count) {
    return '$count orders';
  }

  @override
  String openedAt(String time) {
    return 'Opened at $time';
  }

  @override
  String createdByLine(String name) {
    return 'Created by: $name';
  }

  @override
  String totalToCollect(String amount) {
    return 'Total to collect: $amount FCFA';
  }

  @override
  String get actionShowAndPrint => 'View and print';

  @override
  String get actionCollect => 'Collect';

  @override
  String get invalidAmount => 'Invalid amount.';

  @override
  String get paymentRecorded => 'Payment recorded successfully.';

  @override
  String collectForTicket(String label) {
    return 'Collect — $label';
  }

  @override
  String groupedOrders(String count, String numbers) {
    return '$count grouped orders: $numbers';
  }

  @override
  String get paymentMethodLabel => 'Payment method';

  @override
  String get amountReceived => 'Amount received';

  @override
  String get roomConsumptionInvoiceTitle => 'Room consumption invoice';

  @override
  String get noConsumptionForPeriod => 'No consumption found for this period.';

  @override
  String get roomNumberLabel => 'Room number';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get actionShow => 'Show';

  @override
  String get pickBothDates => 'Please choose both the start and end dates.';

  @override
  String get startDateBeforeEndDate =>
      'The start date must be on or before the end date.';

  @override
  String get handoverTitle => 'Handover to the manager';

  @override
  String get paymentsToHandOver => 'Payments to hand over';

  @override
  String selectionAmount(String amount) {
    return 'Selection: $amount FCFA';
  }

  @override
  String get noPaymentAvailableForHandover =>
      'No payment available for handover.';

  @override
  String get handoverDeclared => 'Handover declared successfully.';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get declareHandover => 'Declare handover';

  @override
  String get statusValidated => 'Validated';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get handoverHistory => 'Handover history';

  @override
  String get noHandoverRecorded => 'No handover recorded.';

  @override
  String includedPayments(String count) {
    return 'Included payments: $count';
  }

  @override
  String get actionPrint => 'Print';

  @override
  String get attachClientOptional => 'Attach a client (optional)';

  @override
  String get detachClient => 'Detach client';

  @override
  String get orderSentSuccess => 'Order sent successfully.';

  @override
  String get newOrderTitle => 'New order';

  @override
  String get labelRestaurantClient => 'Restaurant client';

  @override
  String get labelHotelClient => 'Hotel client';

  @override
  String get clientTypeLabel => 'Client type';

  @override
  String get tableNumberLabel => 'Table number';

  @override
  String get roomNumberFieldLabel => 'Room number';

  @override
  String get noItemAvailable => 'No item available.';

  @override
  String get actionAdd => 'Add';

  @override
  String get cartTitle => 'Cart';

  @override
  String get noItemAdded => 'No item added.';

  @override
  String get actionSendOrder => 'Send order';

  @override
  String subtotalLine(String amount) {
    return 'Subtotal: $amount FCFA';
  }

  @override
  String serveurSpaceTitle(String establishment) {
    return 'Waiter area - $establishment';
  }

  @override
  String welcomeName(String name) {
    return 'Welcome $name';
  }

  @override
  String get serveurSpaceSubtitle => 'Order taking and waiter tracking area';

  @override
  String get moduleOrdersRoomsTitle => 'Orders & Rooms';

  @override
  String get moduleOrdersRoomsSubtitle =>
      'Take orders and manage room consumption';

  @override
  String get actionMenuOrderTitle => 'Menu and order';

  @override
  String get actionMenuOrderSubtitle => 'Take a restaurant, bar or room order';

  @override
  String get actionRoomConsumptionTitle => 'Room consumption';

  @override
  String get actionRoomConsumptionSubtitle =>
      'Invoice consumption linked to a room';

  @override
  String get modulePaymentsTitle => 'Payments & Handovers';

  @override
  String get modulePaymentsSubtitle => 'Collect invoices and hand over funds';

  @override
  String get actionCollectSubtitle => 'Collect unpaid invoices';

  @override
  String get actionMyInvoicesSubtitle =>
      'All my invoices: collect, fiscalize, print';

  @override
  String get actionHandoverSubtitle => 'Hand the collected cash to the manager';

  @override
  String get moduleTrackingTitle => 'Preparation tracking';

  @override
  String get moduleTrackingSubtitle =>
      'Track the progress of bar and kitchen orders';

  @override
  String get actionSuiviBarSubtitle =>
      'See the status of orders sent to the bar';

  @override
  String get actionSuiviCuisineSubtitle =>
      'See the status of orders sent to the kitchen';

  @override
  String get categoryAll => 'All';

  @override
  String get menuTitle => 'Our menu';

  @override
  String get searchDishHint => 'Search for a dish…';

  @override
  String get noAccompanimentAvailable =>
      'No side dish available. Dish added without a side.';

  @override
  String get freeAccompaniment => 'Free side dish';

  @override
  String get chooseOneFreeAccompaniment => 'Choose 1 free side dish';

  @override
  String get labelFree => 'Free';

  @override
  String get paidExtraPortions => 'Extra portions (paid)';

  @override
  String get orderRecapTitle => 'Order summary';

  @override
  String get sendingInProgress => 'Sending...';

  @override
  String get confirmAndSend => 'Confirm and send';

  @override
  String recapWithCount(String count) {
    return 'Summary ($count)';
  }

  @override
  String pricePerPortion(String price) {
    return '$price FCFA / portion';
  }

  @override
  String accompanimentLine(String name) {
    return 'Side dish: $name (free)';
  }

  @override
  String get consumptionDetailsTitle => 'Consumption details';

  @override
  String get certifiedInvoiceBadge => 'CERTIFIED INVOICE';

  @override
  String get generalInformation => 'General information';

  @override
  String get labelOrders => 'Orders';

  @override
  String get labelOrder => 'Order';

  @override
  String get labelDate => 'Date';

  @override
  String get labelType => 'Type';

  @override
  String get labelAmount => 'Amount';

  @override
  String get clientInfoOptional => 'Client information (optional)';

  @override
  String get clientNameLabel => 'Client name';

  @override
  String get clientAddressLabel => 'Client address';

  @override
  String get clientIfuLabel => 'Client IFU';

  @override
  String get consumedItems => 'Items consumed';

  @override
  String get simpleInvoicePrinted =>
      'Simple invoice printed and payment recorded.';

  @override
  String get normalizedInvoicePrinted =>
      'Normalized invoice printed and payment recorded.';

  @override
  String get invoiceAlreadyCertified => 'This invoice is already certified.';

  @override
  String get fiscalizeInvoiceFirst => 'Fiscalize the invoice first.';

  @override
  String get fillEstablishmentIfuFirst =>
      'Enter the establishment\'s IFU first (admin console).';

  @override
  String get actionPrintNormalizedInvoice => 'Print normalized invoice';

  @override
  String get actionPrintSimpleInvoice => 'Print simple invoice';

  @override
  String quantityLine(String quantity) {
    return 'Qty: $quantity';
  }

  @override
  String unitPriceLine(String price) {
    return 'Unit price: $price FCFA';
  }

  @override
  String invoiceFiscalizedWithCode(String code) {
    return 'Invoice fiscalized with certilink. MECeF code: $code';
  }

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentMobileMoney => 'Mobile Money';

  @override
  String get paymentCard => 'Bank card';

  @override
  String get paymentBankTransfer => 'Bank transfer';

  @override
  String get paymentMixed => 'Mixed payment';

  @override
  String get paymentCredit => 'Credit sale';

  @override
  String get paymentBeninResto => 'Bénin Resto';

  @override
  String get accountCash => 'Cash';

  @override
  String get accountMobileMoney => 'Mobile Money';

  @override
  String get accountBankTransfer => 'Bank';

  @override
  String get accountCard => 'Bank card';

  @override
  String get accountCredit => 'Credit';

  @override
  String get accountBeninResto => 'Bénin Resto';

  @override
  String get accountMixed => 'Mixed payment';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDisable => 'Disable';

  @override
  String get actionSave => 'Save';

  @override
  String get savingInProgress => 'Saving...';

  @override
  String get fieldRequired => 'Required';

  @override
  String get receptionTitle => 'Reception';

  @override
  String get receptionSubtitle => 'Reception area: rooms, stays and invoices';

  @override
  String get tileRoomsBoardTitle => 'Rooms board';

  @override
  String get tileRoomsBoardSubtitle => 'See room status in real time';

  @override
  String get tileReservationsTitle => 'Reservations';

  @override
  String get tileReservationsSubtitle => 'Create and manage reservations';

  @override
  String get tileRoomInvoicingTitle => 'Room invoicing';

  @override
  String get tileRoomInvoicingSubtitle => 'Invoice and certify a stay';

  @override
  String get tileInvoicesListTitle => 'Invoice list';

  @override
  String get tileInvoicesListSubtitle => 'Browse room invoices';

  @override
  String get tileClientsTitle => 'Clients';

  @override
  String get tileClientsSubtitle => 'Client records and history';

  @override
  String get roomsTitle => 'Rooms';

  @override
  String get tileRoomsSubtitle => 'Manage rooms';

  @override
  String get roomTypesTitle => 'Room types';

  @override
  String get tileRoomTypesSubtitle => 'Configure categories';

  @override
  String get disableTypeConfirmTitle => 'Disable this type?';

  @override
  String disableTypeConfirmBody(String name) {
    return 'The type \"$name\" will no longer be offered, but existing rooms are not deleted.';
  }

  @override
  String get typeDisabled => 'Type disabled.';

  @override
  String get typeUpdated => 'Type updated.';

  @override
  String get typeAdded => 'Type added.';

  @override
  String get addRoomType => 'Add a type';

  @override
  String get noRoomType =>
      'No room type yet.\nAdd your categories (Single, Suite, Bungalow...).';

  @override
  String roomTypeSubtitle(String price, String capacity) {
    return '$price FCFA / night · $capacity people';
  }

  @override
  String get editTypeTitle => 'Edit type';

  @override
  String get newTypeTitle => 'New room type';

  @override
  String get typeNameLabel => 'Type name';

  @override
  String get typeNameHint => 'E.g. Presidential Suite, Bungalow...';

  @override
  String get pricePerNightLabel => 'Price per night (FCFA)';

  @override
  String get pricePerNightHint => 'E.g. 25000';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get capacityLabel => 'Capacity (people)';

  @override
  String get capacityHint => 'E.g. 2';

  @override
  String get invalidCapacity => 'Invalid capacity';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get amenitiesLabel => 'Amenities (comma separated)';

  @override
  String get amenitiesHint => 'E.g. AC, Wifi, TV, Minibar';

  @override
  String get roomStatusAvailable => 'Free';

  @override
  String get roomStatusOccupied => 'Occupied';

  @override
  String get roomStatusCleaning => 'To clean';

  @override
  String get roomStatusMaintenance => 'Maintenance';

  @override
  String changeRoomStateTitle(String number) {
    return 'Room $number — change status';
  }

  @override
  String roomOccupiedTitle(String number) {
    return 'Room $number (occupied)';
  }

  @override
  String get actionCheckOut => 'Check-out (client departure)';

  @override
  String get actionChangeStateManually => 'Change status manually';

  @override
  String roomStatusChanged(String number, String status) {
    return 'Room $number: $status';
  }

  @override
  String get noActiveReservationForRoom =>
      'No active reservation found for this room. You can change its status manually.';

  @override
  String get checkOutTitle => 'Check-out';

  @override
  String checkOutConfirmBody(String client, String number) {
    return 'Confirm the departure of $client (room $number)?\n\nThe room will be set to \"to clean\".';
  }

  @override
  String get actionConfirmDeparture => 'Confirm departure';

  @override
  String get checkOutDone => 'Check-out completed.';

  @override
  String get billStayTitle => 'Invoice the stay?';

  @override
  String billStayBody(String client) {
    return 'Do you want to issue $client\'s invoice now?';
  }

  @override
  String get actionLater => 'Later';

  @override
  String get actionBill => 'Invoice';

  @override
  String get noRoomBoard => 'No room yet.\nAdd your rooms to see the board.';

  @override
  String roomsCountSummary(
    String total,
    String free,
    String occupied,
    String toClean,
  ) {
    return '$total rooms · $free free · $occupied occupied · $toClean to clean';
  }

  @override
  String get createRoomTypeFirst => 'Create at least one room type first.';

  @override
  String get deleteRoomConfirmTitle => 'Delete this room?';

  @override
  String deleteRoomConfirmBody(String number) {
    return 'The room \"$number\" will be removed from the list.';
  }

  @override
  String get roomDeleted => 'Room deleted.';

  @override
  String get addRoom => 'Add a room';

  @override
  String get noRoomTypeThenRooms =>
      'Create a room type first,\nthen add your rooms.';

  @override
  String get noRoomYet => 'No room yet.\nAdd your rooms with the + button.';

  @override
  String floorSuffix(String floor) {
    return ' · Floor $floor';
  }

  @override
  String get pickRoomType => 'Please choose a room type.';

  @override
  String get chooseRoomType => 'Choose a type';

  @override
  String get roomUpdated => 'Room updated.';

  @override
  String get roomAdded => 'Room added.';

  @override
  String get editRoomTitle => 'Edit room';

  @override
  String get newRoomTitle => 'New room';

  @override
  String get roomNumberOrNameLabel => 'Room number / name';

  @override
  String get roomNumberOrNameHint => 'E.g. 101, Jasmine, A2';

  @override
  String get roomTypeLabel => 'Room type';

  @override
  String roomTypeOption(String name, String price) {
    return '$name ($price FCFA)';
  }

  @override
  String get floorOptionalLabel => 'Floor (optional)';

  @override
  String get floorHint => 'E.g. 1, Ground';

  @override
  String get specificPriceLabel => 'Specific price (optional)';

  @override
  String get specificPriceHint => 'Leave empty = type price';

  @override
  String get reservationStatusConfirmed => 'Confirmed';

  @override
  String get reservationStatusCheckedIn => 'Checked in';

  @override
  String get reservationStatusCheckedOut => 'Checked out';

  @override
  String get reservationStatusCancelled => 'Cancelled';

  @override
  String get cancelReservationConfirmTitle => 'Cancel this reservation?';

  @override
  String cancelReservationConfirmBody(String client) {
    return '$client\'s reservation will be marked as cancelled.';
  }

  @override
  String get actionBack => 'Back';

  @override
  String get actionCancelReservation => 'Cancel the reservation';

  @override
  String get reservationCancelled => 'Reservation cancelled.';

  @override
  String noFreeRoomOfType(String type) {
    return 'No free room for the type \"$type\". Free up or prepare a room first.';
  }

  @override
  String assignRoomTo(String client) {
    return 'Assign a room to $client';
  }

  @override
  String floorLabel(String floor) {
    return 'Floor $floor';
  }

  @override
  String checkInDone(String number) {
    return 'Check-in completed: room $number.';
  }

  @override
  String get actionCheckIn => 'Check-in';

  @override
  String get newReservation => 'New reservation';

  @override
  String get noReservation =>
      'No reservation yet.\nCreate one with the + button.';

  @override
  String roomShortSuffix(String number) {
    return ' · Rm. $number';
  }

  @override
  String nightsCount(String nights) {
    return '$nights night(s)';
  }

  @override
  String get editReservationTitle => 'Edit reservation';

  @override
  String get dateHintDdMmYyyy => 'dd/mm/yyyy';

  @override
  String get invalidDate => 'Invalid date';

  @override
  String get pickStayDates => 'Choose the stay dates.';

  @override
  String get phoneOptionalLabel => 'Phone (optional)';

  @override
  String get ifuOptionalLabel => 'IFU (optional, for the invoice)';

  @override
  String get labelArrival => 'Arrival';

  @override
  String get labelDeparture => 'Departure';

  @override
  String get pickFromCalendar => 'Pick from calendar';

  @override
  String get pricePerNightShortLabel => 'Price / night';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get reservationUpdated => 'Reservation updated.';

  @override
  String totalWithNights(String amount, String nights) {
    return 'Total: $amount FCFA ($nights night(s))';
  }

  @override
  String get chooseExistingClient => 'Choose an existing client';

  @override
  String attachedClient(String name) {
    return 'Attached client: $name';
  }

  @override
  String get detachRecord => 'Detach record';

  @override
  String get checkingAvailability => 'Checking availability...';

  @override
  String get typeFullOnPeriod =>
      'Type fully booked for this period (you can force).';

  @override
  String roomsAvailableCount(String count) {
    return '$count room(s) available.';
  }

  @override
  String get typeFullTitle => 'Type fully booked';

  @override
  String get typeFullBody =>
      'No room of this type is available for this period. Do you want to force the reservation anyway?';

  @override
  String get actionNo => 'No';

  @override
  String get actionForce => 'Force';

  @override
  String get guestsLabel => 'Guests';

  @override
  String get reservationCreated => 'Reservation created.';

  @override
  String get creatingInProgress => 'Creating...';

  @override
  String get actionCreate => 'Create';

  @override
  String get chooseClient => 'Choose a client';

  @override
  String get searchLabel => 'Search';

  @override
  String get searchNameOrPhoneHint => 'Name or phone';

  @override
  String get noClientRecord =>
      'No client record.\nYou can enter the client manually.';

  @override
  String get noClientMatches => 'No client matches this search.';

  @override
  String ifuPrefix(String ifu) {
    return 'IFU $ifu';
  }

  @override
  String get serverPaymentsNotHandedTitle => 'Waiter payments not handed over';

  @override
  String get noPendingPayment => 'No pending payment';

  @override
  String methodLine(String method) {
    return 'Method: $method';
  }

  @override
  String get stockManagementTitle => 'Stock management';

  @override
  String get supplyRequests => 'Supply requests';

  @override
  String get storesOverview => 'Stores overview';

  @override
  String get storesOverviewSubtitle =>
      'Check stock, process requests and approve supplies.';

  @override
  String get storeHotelTitle => 'Hotel store';

  @override
  String get storeHotelSubtitle =>
      'Hygiene products, maintenance, room consumables';

  @override
  String get storeRestaurantTitle => 'Restaurant store';

  @override
  String get storeRestaurantSubtitle => 'Food, kitchen, raw materials';

  @override
  String get storeBarTitle => 'Bar store';

  @override
  String get storeBarSubtitle => 'Drinks, snacks, bar accessories';

  @override
  String get actionViewStock => 'View stock';

  @override
  String get actionRequests => 'Requests';

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

  @override
  String get labelReason => 'Reason';

  @override
  String get labelItem => 'Item';

  @override
  String labelItemIndex(int index) {
    return 'Item $index';
  }

  @override
  String get labelQuantitySupplied => 'Quantity supplied';

  @override
  String get actionAddItem => 'Add an item';

  @override
  String get actionValidateSupply => 'Confirm the supply';

  @override
  String get reasonDirectSupplyDefault => 'Direct supply by the manager';

  @override
  String selectItemAtLine(int line) {
    return 'Select the item on line $line.';
  }

  @override
  String invalidQuantityAtLine(int line) {
    return 'Invalid quantity on line $line.';
  }

  @override
  String get directSupplyRecorded => 'Direct supply recorded successfully.';

  @override
  String get registerServerTitle => 'Register a waiter';

  @override
  String get newServerTitle => 'New waiter';

  @override
  String get labelFullName => 'Full name';

  @override
  String get labelPhone => 'Phone';

  @override
  String get labelEmail => 'Email';

  @override
  String get errFullNameRequired => 'Please enter the full name';

  @override
  String get errPhoneTooShort => 'Number too short';

  @override
  String get serverRegisteredSuccess => 'Waiter registered successfully.';

  @override
  String get storeNameHotel => 'Hotel';

  @override
  String get storeNameRestaurant => 'Restaurant';

  @override
  String get storeNameBar => 'Bar';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusReceived => 'Received';

  @override
  String get deliveryTitle => 'Delivery / Supply';

  @override
  String get requestAlreadyProcessed =>
      'This request has already been processed.';

  @override
  String get requestAlreadyProcessedShort => 'Request already processed';

  @override
  String invalidDeliveredQuantityAtLine(int line) {
    return 'Invalid delivered quantity on line $line.';
  }

  @override
  String get supplyValidatedSuccess => 'Supply confirmed successfully.';

  @override
  String requestedByLine(String name) {
    return 'Requested by: $name';
  }

  @override
  String roleLine(String role) {
    return 'Role: $role';
  }

  @override
  String statusLine(String status) {
    return 'Status: $status';
  }

  @override
  String get quantitiesToDeliver => 'Quantities to deliver';

  @override
  String requestedQuantityLine(String quantity, String unit) {
    return 'Requested: $quantity $unit';
  }

  @override
  String get labelQuantityDelivered => 'Quantity delivered';

  @override
  String get actionValidateDelivery => 'Confirm the delivery';

  @override
  String amountLine(String amount) {
    return 'Amount: $amount FCFA';
  }

  @override
  String get labelTotalCaps => 'TOTAL';

  @override
  String get labelStatus => 'Status';

  @override
  String get actionOpen => 'Open';

  @override
  String get noResult => 'No result';

  @override
  String dateLine(String date) {
    return 'Date: $date';
  }

  @override
  String roomLine(String number) {
    return 'Room: $number';
  }

  @override
  String get labelClientName => 'Client name';

  @override
  String get labelRoomNumber => 'Room number';

  @override
  String get actionViewDetails => 'View details';

  @override
  String get statusDeclared => 'Declared';

  @override
  String get noElementSelected => 'No item selected.';

  @override
  String get transferDeclaredToAccounting => 'Transfer declared to accounting.';

  @override
  String get managerToAccountingTitle => 'Manager → accounting transfer';

  @override
  String get validatedServerHandovers => 'Validated waiter handovers';

  @override
  String get noServerHandoverAvailable => 'No waiter handover available.';

  @override
  String get paidRoomInvoicesNotTransferred =>
      'Paid room invoices not yet transferred';

  @override
  String get noRoomInvoiceAvailable => 'No room invoice available.';

  @override
  String get transferSummary => 'Transfer summary';

  @override
  String get serverHandoversLabel => 'Waiter handovers';

  @override
  String get roomInvoicesLabel => 'Room invoices';

  @override
  String get actionDeclareToAccounting => 'Declare to accounting';

  @override
  String get managerTransferHistory => 'Manager transfer history';

  @override
  String get noTransferRecorded => 'No transfer recorded.';

  @override
  String get statusPaidShort => 'Paid';

  @override
  String get statusUnpaidShort => 'Unpaid';

  @override
  String errSearchFailed(String error) {
    return 'Search error: $error';
  }

  @override
  String get searchByClientOption => 'Search by client';

  @override
  String get searchByRoomOption => 'Search by room';

  @override
  String get searchByClientShort => 'By client';

  @override
  String get searchByRoomShort => 'By room';

  @override
  String arrivalLine(String date) {
    return 'Check-in: $date';
  }

  @override
  String departureLine(String date) {
    return 'Check-out: $date';
  }

  @override
  String mecefCodeLine(String code) {
    return 'MECeF code: $code';
  }

  @override
  String get searchRoomInvoicesTitle => 'Search room invoices';

  @override
  String get serverHandoversTitle => 'Waiter handovers';

  @override
  String get noPendingHandover => 'No pending handover.';

  @override
  String declaredAmountLine(String amount) {
    return 'Declared amount: $amount FCFA';
  }

  @override
  String includedPaymentsLine(int count) {
    return 'Payments included: $count';
  }

  @override
  String get errObservedAmountInvalid => 'Invalid observed amount.';

  @override
  String get ordersValidated => 'Orders validated.';

  @override
  String get ordersRejected => 'Orders rejected.';

  @override
  String handoverTitleFor(String name) {
    return 'Handover - $name';
  }

  @override
  String get labelObservedAmount => 'Observed amount';

  @override
  String get noPaymentFound => 'No payment found.';

  @override
  String methodAmountLine(String method, String amount) {
    return '$method • $amount FCFA';
  }

  @override
  String get suffixAlreadyValidated => ' • already validated';

  @override
  String get suffixRejected => ' • rejected';

  @override
  String get actionRejectSelection => 'Reject selection';

  @override
  String get actionValidateSelection => 'Validate selection';

  @override
  String supplyRequestsForStore(String store) {
    return 'Requests - $store';
  }

  @override
  String get filterRequests => 'Filter requests';

  @override
  String get filterDelivered => 'Delivered';

  @override
  String get filterReceived => 'Received';

  @override
  String get noRequestFound => 'No request found.';

  @override
  String get labelQuantity => 'Quantity';

  @override
  String periodLine(String start, String end) {
    return 'Period: $start → $end';
  }

  @override
  String get actionMarkPaid => 'Mark as paid';

  @override
  String get actionPrintNormalized => 'Print normalized';

  @override
  String get filterAllInvoices => 'All';

  @override
  String get filterPaid => 'Paid';

  @override
  String get filterUnpaid => 'Unpaid';

  @override
  String get noInvoiceFound => 'No invoice found.';

  @override
  String get searchClientOrRoom => 'Search client / room';

  @override
  String get roomInvoicesListTitle => 'Room invoices list';

  @override
  String get errInvoiceDatesInvalid => 'The invoice dates are invalid.';

  @override
  String get errInvoiceNotFiscalizedYet =>
      'This invoice is not fiscalized yet.';

  @override
  String get errSetIfuFirst =>
      'Set the establishment\'s IFU first (admin console).';

  @override
  String get errInvoiceAlreadyFiscalized =>
      'This invoice is already fiscalized.';

  @override
  String get managerWorkspaceSubtitle => 'Supervision and validation workspace';

  @override
  String get moduleStocksTitle => 'Stock & Supply';

  @override
  String get moduleStocksSubtitle =>
      'Stock, requests, thresholds, items and supplies';

  @override
  String get actionStockRequests => 'Stock requests';

  @override
  String get lowStockTitle => 'Low stock';

  @override
  String get actionSupplyRestaurant => 'Supply Restaurant';

  @override
  String get actionSupplyBar => 'Supply Bar';

  @override
  String get actionSupplyHotel => 'Supply Hotel';

  @override
  String get directSupplyRestaurantTitle => 'Direct supply - Restaurant';

  @override
  String get directSupplyBarTitle => 'Direct supply - Bar';

  @override
  String get directSupplyHotelTitle => 'Direct supply - Hotel';

  @override
  String get actionItemRegistry => 'Item registry';

  @override
  String get actionCreateStock => 'Create a stock';

  @override
  String get moduleServersTitle => 'Waiters & Collections';

  @override
  String get moduleServersSubtitle => 'Waiters, handovers and collections';

  @override
  String get actionValidateHandovers => 'Validate handovers';

  @override
  String get actionServerCollections => 'Waiter collections';

  @override
  String get moduleBillingRoomsTitle => 'Billing & Rooms';

  @override
  String get moduleBillingRoomsSubtitle =>
      'Invoices, rooms and accounting transfer';

  @override
  String get actionRoomBilling => 'Room billing';

  @override
  String get actionInvoicesList => 'Invoice list';

  @override
  String get actionAccountingTransfer => 'Accounting transfer';

  @override
  String get moduleMenuTitle => 'Menu & Operations';

  @override
  String get moduleMenuSubtitle => 'Restaurant and bar menu management';

  @override
  String get actionManageMenu => 'Manage the menu';

  @override
  String get createStockPageTitle => 'Manager stock creation';

  @override
  String get createStockTitle => 'Stock creation / import';

  @override
  String get createStockSubtitle =>
      'Pick an active item and enter the quantity, or import several rows from a file.';

  @override
  String get manualEntry => 'Manual entry';

  @override
  String get noActiveItemFound => 'No active item found in stock_items.';

  @override
  String get labelStockItem => 'Stock item';

  @override
  String get hintQuantityExample => 'E.g. 25';

  @override
  String get errQuantityRequired => 'Please enter a quantity';

  @override
  String get errQuantityMustBeInteger => 'The quantity must be a whole number.';

  @override
  String get errQuantityNegative => 'The quantity cannot be negative';

  @override
  String get errChooseAnItem => 'Please choose an item';

  @override
  String get errSelectAnItem => 'Please select an item.';

  @override
  String get stockSavedSuccess => 'Stock saved successfully.';

  @override
  String errLoadItemsFailed(String error) {
    return 'Error loading items: $error';
  }

  @override
  String errSaveFailed(String error) {
    return 'Error while saving: $error';
  }

  @override
  String errImportFailed(String error) {
    return 'Import error: $error';
  }

  @override
  String get importCancelled => 'Import cancelled.';

  @override
  String get errFileUnreadable => 'Unable to read the selected file.';

  @override
  String get errUnsupportedFormat => 'Unsupported format. Use CSV or XLSX.';

  @override
  String get errNoUsableRow => 'No usable row found.';

  @override
  String get errItemNameMissing => 'missing item name';

  @override
  String get errQuantityInvalidShort => 'invalid quantity';

  @override
  String errItemNotInStockItems(String name) {
    return 'item “$name” not found in stock_items';
  }

  @override
  String lineErrorLine(int line, String message) {
    return 'Row $line: $message';
  }

  @override
  String importSuccessCount(int count) {
    return '$count stock(s) imported successfully.';
  }

  @override
  String importPartialResult(int success, int errors) {
    return '$success successful import(s), $errors error(s).';
  }

  @override
  String importedCountShort(int count) {
    return '$count stock(s) imported.';
  }

  @override
  String get importingInProgress => 'Importing...';

  @override
  String get actionImportCsvExcel => 'Import CSV / Excel';

  @override
  String get importRecommendedFormat => 'Recommended import format';

  @override
  String get expectedColumns => 'Expected columns:';

  @override
  String get exampleLabel => 'Example:';

  @override
  String get importExampleRow1 => 'Mineral water | 48';

  @override
  String get importExampleRow2 => 'Local rice | 120';

  @override
  String get fieldsSavedInStoreStocks => 'Fields saved in store_stocks';

  @override
  String storeLine(String store) {
    return 'Store: $store';
  }

  @override
  String unitLine(String unit) {
    return 'Unit: $unit';
  }

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get confirmationTitle => 'Confirmation';

  @override
  String get labelClient => 'Client';

  @override
  String get labelClientIfu => 'Client IFU';

  @override
  String get labelAddress => 'Address';

  @override
  String get labelRoomWord => 'Room';

  @override
  String get labelEntry => 'Check-in';

  @override
  String get labelExit => 'Check-out';

  @override
  String get labelNights => 'Nights';

  @override
  String get labelPricePerNightShort => 'Price / night';

  @override
  String get labelExtras => 'Extras';

  @override
  String get labelServices => 'Services';

  @override
  String get labelPaymentStatus => 'Payment status';

  @override
  String get labelFiscalStatus => 'Fiscal status';

  @override
  String get statusCertified => 'Certified';

  @override
  String get statusNotCertified => 'Not certified';

  @override
  String get labelMecefCode => 'MECeF code';

  @override
  String get labelCounters => 'Counters';

  @override
  String get labelFiscalDate => 'Fiscal date';

  @override
  String get paymentBank => 'Bank';

  @override
  String get paymentCheque => 'Cheque';

  @override
  String get aibNone => 'No AIB';

  @override
  String get errInvoiceDatesInvalidShort => 'Invalid invoice dates.';

  @override
  String get actionFiscalizeWithCertilink => 'Fiscalize with Certilink';

  @override
  String get roomInvoiceDetailTitle => 'Room invoice details';

  @override
  String get errInvoiceNotCertifiedYet => 'This invoice is not certified yet.';

  @override
  String get errInvoiceAlreadyCertified => 'This invoice is already certified.';

  @override
  String invoiceCertifiedWithCode(String code) {
    return 'Invoice certified with Certilink. MECeF code: $code';
  }

  @override
  String get tooltipPrintClassic => 'Classic printing';

  @override
  String get tooltipPrintNormalized => 'Normalized printing';

  @override
  String get actionPrintClassicMode => 'Print in classic mode';

  @override
  String get actionPrintNormalizedMode => 'Print in normalized mode';

  @override
  String get roomBillingTitle => 'Room billing';

  @override
  String get errSaveInvoiceFirst => 'Please save the invoice first.';

  @override
  String get errFiscalizeFirst =>
      'This invoice is not fiscalized yet. Fiscalize it first.';

  @override
  String get errFillRoomAndPeriodFirst =>
      'Please fill in the room and the period first.';

  @override
  String get extrasDetailsTitle => 'Extras details';

  @override
  String get noConsumptionFound => 'No consumption found.';

  @override
  String extrasTotalLine(String amount) {
    return 'Extras total: $amount FCFA';
  }

  @override
  String get errRequiredFieldsMissing => 'Required fields are missing';

  @override
  String get errStartBeforeEnd =>
      'The check-in date must be before or equal to the check-out date.';

  @override
  String get errInvalidNightPrice => 'Invalid night price';

  @override
  String get errInvoiceAlreadyExistsForPeriod =>
      'An invoice already exists for this room and this period.';

  @override
  String get invoiceCreatedSuccess =>
      'Invoice created successfully. You can now collect or fiscalize it.';

  @override
  String errSaveInvoiceFailed(String error) {
    return 'Error while saving the invoice: $error';
  }

  @override
  String get actionChoose => 'Choose';

  @override
  String get paymentDialogTitle => 'Payment';

  @override
  String get clientInfoTitle => 'Client information';

  @override
  String get labelClientAddress => 'Client address';

  @override
  String get labelClientPhone => 'Client phone';

  @override
  String startLine(String date) {
    return 'Start: $date';
  }

  @override
  String endLine(String date) {
    return 'End: $date';
  }

  @override
  String get labelOtherServices => 'Other services';

  @override
  String get actionSaveInvoice => 'Save invoice';

  @override
  String get actionSearchInvoice => 'Search for an invoice';

  @override
  String get actionNewInvoice => 'New invoice';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get labelBarRestoConsumptions => 'Bar/restaurant consumptions';

  @override
  String get invoiceAlreadyFiscalizedLabel => 'Invoice already fiscalized';

  @override
  String get invoiceSavedAndFiscalized => 'Invoice saved and fiscalized.';

  @override
  String get invoiceSavedReady =>
      'Invoice saved. Ready to be collected or fiscalized.';

  @override
  String get menuManagementTitle => 'Menu management';

  @override
  String get errItemNameRequired => 'Please enter the item name.';

  @override
  String get errCategoryRequired => 'Please enter the category.';

  @override
  String get errValidPriceRequired => 'Please enter a valid price.';

  @override
  String get errItemMustBelongToBarOrKitchen =>
      'The item must belong to the bar, the kitchen, or both.';

  @override
  String get errAtLeastOneIngredient =>
      'Please define at least one ingredient for this item.';

  @override
  String get menuItemSavedSuccess => 'Item saved successfully.';

  @override
  String get photoSaved => 'Photo saved.';

  @override
  String errPhotoSaveFailed(String error) {
    return 'Error saving the photo: $error';
  }

  @override
  String get addIngredientTitle => 'Add an ingredient';

  @override
  String get labelQuantityPerUnitSold => 'Quantity used per unit sold';

  @override
  String get errFileEmptyOrUnreadable => 'Empty or unreadable file.';

  @override
  String get errUnsupportedFormatExcel =>
      'Unsupported format. Use CSV or Excel.';

  @override
  String get errNoUsableRowInFile => 'No usable row found in the file.';

  @override
  String get rowSkippedInvalidFields =>
      'Row skipped: invalid name/category/price.';

  @override
  String rowSkippedNoDepartment(String name) {
    return 'Item “$name” skipped: neither bar nor kitchen.';
  }

  @override
  String rowSkippedWithReason(String reason) {
    return 'Row skipped: $reason';
  }

  @override
  String importedItemsCount(int count) {
    return '$count item(s) imported';
  }

  @override
  String skippedSuffix(int count) {
    return ' • $count skipped';
  }

  @override
  String get importResultTitle => 'Import result';

  @override
  String get departmentKitchenAndBar => 'Kitchen + Bar';

  @override
  String get newItemTitle => 'New item';

  @override
  String get labelItemName => 'Item name';

  @override
  String get helperNewOrExistingDish =>
      'Type a new name, or choose an existing dish';

  @override
  String get helperExistingDishPriceOnly =>
      'Existing dish: only the price can be changed';

  @override
  String get tooltipNewDish => 'New dish';

  @override
  String get labelCompositionFree => 'Composition (free text)';

  @override
  String get labelCategory => 'Category';

  @override
  String get hintCategoryExample => 'E.g. drink, dish, dessert, snack...';

  @override
  String get labelPrice => 'Price';

  @override
  String get dishPhotoTitle => 'Dish photo';

  @override
  String get labelAvailable => 'Available';

  @override
  String get labelForKitchen => 'For the kitchen';

  @override
  String get labelForBar => 'For the bar';

  @override
  String get labelFreeAccompaniment => 'Includes one free side';

  @override
  String get labelFreeAccompanimentHint => 'The client may choose 1 free side.';

  @override
  String get recipeIngredientsTitle => 'Recipe / ingredients';

  @override
  String get noIngredientAdded => 'No ingredient added.';

  @override
  String get actionImportExcelCsv => 'Import Excel / CSV';

  @override
  String get acceptedColumnsHint =>
      'Accepted columns: name, composition, category, price, available, kitchen, bar.';

  @override
  String get noItemRecorded => 'No item recorded.';

  @override
  String get menuItemsTitle => 'Menu items';

  @override
  String confirmDeleteItem(String name) {
    return 'Delete the item “$name”?';
  }

  @override
  String ingredientsCount(int count) {
    return '$count ingredient(s)';
  }

  @override
  String get errAccessDenied => 'Access denied.';

  @override
  String get accountingTitle => 'Accounting';

  @override
  String get accountantWorkspaceSubtitle =>
      'Reception, control, expenses, balances and reports';

  @override
  String get moduleReceptionsTitle => 'Receptions & Controls';

  @override
  String get moduleReceptionsSubtitle =>
      'Waiter and manager handovers, and untransferred invoices';

  @override
  String get actionReceiveHandovers => 'Handover reception';

  @override
  String get actionReceiveHandoversSubtitle => 'Check the waiters\' handovers';

  @override
  String get actionManagerReception => 'Manager reception';

  @override
  String get actionManagerReceptionSubtitle =>
      'Receive the handovers sent by the manager';

  @override
  String get actionTrackUntransferred => 'Untransferred tracking';

  @override
  String get actionTrackUntransferredSubtitle =>
      'Track invoices not yet transferred';

  @override
  String get moduleExpensesBalancesTitle => 'Expenses & Balances';

  @override
  String get moduleExpensesBalancesSubtitle =>
      'Current expenses and previous balances';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get actionExpensesSubtitle => 'Record and review expenses';

  @override
  String get previousBalancesTitle => 'Previous balances';

  @override
  String get actionPreviousBalancesSubtitle =>
      'Manage opening or earlier balances';

  @override
  String get moduleReportsTitle => 'Reports & Summaries';

  @override
  String get moduleReportsSubtitle => 'Weekly summary and accounting tracking';

  @override
  String get weeklyReportTitle => 'Weekly summary';

  @override
  String get actionWeeklyReportSubtitle =>
      'Produce the weekly accounting summary';

  @override
  String get expenseSaved => 'Expense recorded.';

  @override
  String get newExpenseTitle => 'New expense';

  @override
  String get labelDesignation => 'Label';

  @override
  String get labelAccountType => 'Account type';

  @override
  String get expenseHistoryTitle => 'Expense history';

  @override
  String get noExpenseRecorded => 'No expense recorded.';

  @override
  String enteredByLine(String name) {
    return 'Entered by: $name';
  }

  @override
  String get previousBalanceSaved => 'Previous balance recorded.';

  @override
  String get newPreviousBalanceTitle => 'New previous balance';

  @override
  String get balanceHistoryTitle => 'Balance history';

  @override
  String get noPreviousBalance => 'No previous balance.';

  @override
  String get untransferredFullTitle =>
      'Untransferred invoices / collections tracking';

  @override
  String get noUntransferredInvoice => 'No untransferred invoice.';

  @override
  String transferStatusLine(String status) {
    return 'Transfer status: $status';
  }

  @override
  String get statusNotDeclared => 'not declared';

  @override
  String get untransferredServerCollections =>
      'Untransferred waiter collections';

  @override
  String get noUntransferredServerCollection =>
      'No untransferred waiter collection.';

  @override
  String errWeeklySummaryLoadFailed(String error) {
    return 'Error loading the weekly summary: $error';
  }

  @override
  String errPrintFailed(String error) {
    return 'Printing error: $error';
  }

  @override
  String get handoversReceived => 'Handovers received';

  @override
  String get labelOutflows => 'Outflows';

  @override
  String get theoreticalBalance => 'Theoretical balance';

  @override
  String get noHandoverAwaitingReception => 'No handover awaiting reception.';

  @override
  String get receptionConfirmed => 'Reception confirmed.';

  @override
  String get actionConfirmReception => 'Confirm reception';

  @override
  String get receptionValidatedQuitusPrinted =>
      'Reception validated and receipt printed.';

  @override
  String get managerHandoverReceptionTitle => 'Manager handover reception';

  @override
  String get pendingHandoversTitle => 'Pending handovers';

  @override
  String serversRoomsCounts(int servers, int rooms) {
    return 'Waiters: $servers • Rooms: $rooms';
  }

  @override
  String get noHandoverReceived => 'No handover received.';

  @override
  String receivedByLine(String name) {
    return 'Received by: $name';
  }

  @override
  String get stockItemsManagementTitle => 'Stock item management';

  @override
  String get labelName => 'Name';

  @override
  String get labelUnit => 'Unit';

  @override
  String get labelStore => 'Store';

  @override
  String get labelActiveItem => 'Active item';

  @override
  String get errRequiredField => 'Required field';

  @override
  String get hintItemNameExample => 'E.g. Mineral water 50cl';

  @override
  String get hintCategoryDrink => 'E.g. Drink';

  @override
  String get hintUnitExamples => 'E.g. bottle, kg, box';

  @override
  String get excelExpectedFormat => 'Expected Excel format';

  @override
  String get recommendedColumns => 'Recommended columns:';

  @override
  String get exampleRowLabel => 'Sample row:';

  @override
  String get stockImportExampleRow =>
      'Mineral water | Drink | bottle | bar | true';

  @override
  String get errCannotReadFile =>
      'Unable to read the file. Select a valid file.';

  @override
  String get errUnsupportedFormatXlsx =>
      'Unsupported format. Use .xlsx or .xls';

  @override
  String get errNoValidRowAfterNormalization =>
      'No valid row after normalization. Check the columns.';

  @override
  String get errXlsNotSupportedWeb =>
      'Legacy .xls support is not available here for Flutter Web. Use an .xlsx file on the web instead.';

  @override
  String importedItemsSuccessCount(int count) {
    return '$count item(s) imported successfully.';
  }

  @override
  String get excelImportTitle => 'Excel import';

  @override
  String get excelImportStockDescription =>
      'The file can be .xlsx or .xls. Each valid row will be added to stock_items for this establishment with an automatic Firestore id.';

  @override
  String get actionImportFromExcel => 'Import from Excel';

  @override
  String get kitchenTitle => 'Kitchen';

  @override
  String establishmentKitchenTitle(String name) {
    return '$name - Kitchen';
  }

  @override
  String get newKitchenOrderTitle => 'New kitchen order';

  @override
  String orderNumberLine(String number) {
    return 'Order $number';
  }

  @override
  String orderNumberWithClient(String number, String client) {
    return 'Order $number - $client';
  }

  @override
  String get kitchenOrdersFollowUp => 'Kitchen order tracking for all waiters';

  @override
  String get kitchenStockManagementTitle => 'Kitchen stock management';

  @override
  String get stockManagementCardTitle => 'Stock management';

  @override
  String get stockManagementCardSubtitleMobile =>
      'Compose menu • Add item\nDeclare consumption • Request supply';

  @override
  String get stockManagementCardSubtitle =>
      'Compose menu • Add item • Declare consumption • Request supply';

  @override
  String get stockConsultationCardTitle => 'View stocks';

  @override
  String get stockConsultationCardSubtitle =>
      'View stocks • Confirm reception • Stock history';

  @override
  String get actionComposeMenu => 'Compose menu';

  @override
  String get actionAddArticle => 'Add item';

  @override
  String get actionDeclareConsumption => 'Declare a consumption';

  @override
  String get actionRequestSupply => 'Request a supply';

  @override
  String get actionViewStocks => 'View stocks';

  @override
  String get actionConfirmAReception => 'Confirm a reception';

  @override
  String get actionStockHistory => 'Stock history';

  @override
  String get stockOutRestaurantTitle => 'Stock out - Restaurant';

  @override
  String get reasonKitchenPreparation => 'Kitchen preparation';

  @override
  String get supplyRequestRestaurantTitle => 'Supply request - Restaurant';

  @override
  String get stockRestaurantTitle => 'Restaurant stock';

  @override
  String get receptionsToConfirmRestaurantTitle =>
      'Receptions to confirm - Restaurant';

  @override
  String get movementHistoryRestaurantTitle => 'Movement history - Restaurant';

  @override
  String get kitchenOrderReadyTitle => 'Kitchen order ready';

  @override
  String kitchenOrderReadyBody(String client) {
    return 'The order for $client is ready in the kitchen.';
  }

  @override
  String get clientGeneric => 'the client';

  @override
  String roomLowercaseLine(String number) {
    return 'room $number';
  }

  @override
  String tableLowercaseLine(String number) {
    return 'table $number';
  }

  @override
  String get noKitchenItems => 'No kitchen item.';

  @override
  String accompanimentPlainLine(String name) {
    return 'Side dish: $name';
  }

  @override
  String get actionServed => 'Served';

  @override
  String get statusReadyPlural => 'Ready';

  @override
  String get errPickKitchenItem => 'Please choose a kitchen item.';

  @override
  String get errPickAllIngredients => 'Please choose every ingredient.';

  @override
  String get errQuantityMustBePositiveInteger =>
      'Each quantity must be a positive whole number.';

  @override
  String get kitchenIngredientsSaved =>
      'Kitchen ingredients saved successfully.';

  @override
  String dishCreatedCompose(String name) {
    return 'Dish « $name » created. You can now compose it.';
  }

  @override
  String get errEmptyExcelFile => 'Empty Excel file.';

  @override
  String get errNoDataRow => 'The file contains no data row.';

  @override
  String get importReportTitle => 'Import report';

  @override
  String importedRecipesCount(int count) {
    return '$count recipe(s) imported';
  }

  @override
  String ignoredRowsCount(int count) {
    return '$count row(s) skipped (incomplete).';
  }

  @override
  String get dishesNotFound => 'Dishes not found:';

  @override
  String get ingredientsNotFound => 'Ingredients not found:';

  @override
  String get checkNamesMatchApp =>
      'Check that these names match exactly the ones entered in the app.';

  @override
  String get kitchenItemsCompositionTitle => 'Kitchen item composition';

  @override
  String errMenuItemsStream(String error) {
    return 'menuItems error: $error';
  }

  @override
  String errStockItemsStream(String error) {
    return 'stock_items error: $error';
  }

  @override
  String get createNewDishTitle => 'Create a new dish';

  @override
  String get priceSetByManager => 'The price will be set by the manager.';

  @override
  String get labelDishName => 'Dish name';

  @override
  String get hintDishExample => 'E.g. Grilled chicken';

  @override
  String get labelKitchenItem => 'Kitchen item';

  @override
  String get labelCompositionOptional => 'Composition (optional)';

  @override
  String get hintCompositionEmpty =>
      'Leave empty to display the ingredient list';

  @override
  String get kitchenIngredientsTitle => 'Kitchen ingredients';

  @override
  String get actionValidateKitchenComposition => 'Validate kitchen composition';

  @override
  String get defineKitchenIngredientsTitle => 'Define kitchen ingredients';

  @override
  String get actionImportExcel => 'Import Excel';

  @override
  String get oneRowPerIngredient =>
      'One row per ingredient (the dish name is repeated).';

  @override
  String get columnsLabel => 'Columns:';

  @override
  String get recipeImportExampleRows =>
      'Grilled chicken | Chicken | 1\nGrilled chicken | Onion | 2';

  @override
  String get namesMustExistInApp =>
      'Dish and ingredient names must already exist in the app.';

  @override
  String labelIngredientIndex(int index) {
    return 'Ingredient $index';
  }

  @override
  String get errChooseIngredient => 'Choose an ingredient';

  @override
  String get errInvalidQuantity => 'Invalid quantity';

  @override
  String get tooltipRemoveLine => 'Remove this row';

  @override
  String get barTitle => 'Bar';

  @override
  String establishmentBarTitle(String name) {
    return '$name - Bar';
  }

  @override
  String get newBarOrderTitle => 'New bar order';

  @override
  String get barOrdersFollowUp => 'Bar order tracking for all waiters';

  @override
  String get barStockTitle => 'Bar stock';

  @override
  String get actionSupply => 'Supply';

  @override
  String get supplyRequestBarTitle => 'Bar supply request';

  @override
  String get actionStockOut => 'Stock out';

  @override
  String get stockOutBarTitle => 'Bar stock out';

  @override
  String get reasonBarConsumption => 'Bar consumption';

  @override
  String get actionMovements => 'Movements';

  @override
  String get movementHistoryBarTitle => 'Bar movement history';

  @override
  String get actionReceptions => 'Receptions';

  @override
  String get receptionsBarTitle => 'Bar receptions';

  @override
  String get actionBarItems => 'Bar items';

  @override
  String get actionIngredients => 'Ingredients';

  @override
  String errBarItemsLoad(String error) {
    return 'Bar items error: $error';
  }

  @override
  String get barStockItemsTitle => 'Stock items - Bar';

  @override
  String get newBarItemTitle => 'New bar item';

  @override
  String get storeAutoSetToBar => 'The store is automatically set to: bar';

  @override
  String get errItemAlreadyExists => 'This item already exists.';

  @override
  String get barItemSavedSuccess => 'Bar item saved successfully.';

  @override
  String get actionSaveItem => 'Save item';

  @override
  String get hintBarItemNameExample => 'E.g. Coca-Cola 33cl';

  @override
  String get hintBarCategoryExample => 'E.g. Soft drink';

  @override
  String get hintBarUnitExamples => 'E.g. bottle, can, box';

  @override
  String cocktailCreatedCompose(String name) {
    return 'Cocktail « $name » created. You can now compose it.';
  }

  @override
  String get barIngredientsSaved => 'Cocktail ingredients saved successfully.';

  @override
  String importedCompositionsCount(int count) {
    return '$count composition(s) imported';
  }

  @override
  String get cocktailsNotFound => 'Cocktails / items not found:';

  @override
  String get oneRowPerBarIngredient =>
      'One row per ingredient (the cocktail name is repeated).';

  @override
  String get cocktailImportExampleRows => 'Mojito | Rum | 1\nMojito | Mint | 1';

  @override
  String get barNamesMustExistInApp =>
      'Cocktail and ingredient names must already exist in the app.';

  @override
  String get barCocktailsCompositionTitle => 'Bar cocktail composition';

  @override
  String get createNewCocktailTitle => 'Create a new cocktail';

  @override
  String get labelCocktailName => 'Cocktail name';

  @override
  String get hintCocktailExample => 'E.g. Mojito';

  @override
  String get labelBarItemOrCocktail => 'Cocktail / bar item';

  @override
  String get errPickBarItem => 'Please choose a bar item.';

  @override
  String get barIngredientsTitle => 'Bar ingredients';

  @override
  String get actionValidateCocktailComposition =>
      'Validate cocktail composition';

  @override
  String get defineCocktailIngredientsTitle => 'Define cocktail ingredients';

  @override
  String get cocktailPhotoTitle => 'Cocktail photo';

  @override
  String get errPickCocktailOrBarItem =>
      'Please choose a cocktail or bar item.';

  @override
  String get hygieneServiceTitle => 'Housekeeping service';

  @override
  String get butlerHygieneLeadTitle => 'Butler / Head of housekeeping';

  @override
  String get butlerHygieneLeadSubtitle =>
      'Oversees room preparation, product usage and restocking requests.';

  @override
  String get actionDailyHygiene => 'Daily housekeeping';

  @override
  String get actionAddHotelItem => 'Add hotel item';

  @override
  String get supplyRequestHotelTitle => 'Supply request - Hotel';

  @override
  String get actionRequestSupplyShort => 'Request supply';

  @override
  String get receptionsToConfirmHotelTitle => 'Receptions to confirm - Hotel';

  @override
  String get actionValidateReception => 'Validate reception';

  @override
  String get hotelStockItemsTitle => 'Stock items - Hotel';

  @override
  String get newHotelItemTitle => 'New hotel item';

  @override
  String get storeAutoSetToHotel => 'The store is automatically set to: hotel';

  @override
  String get hotelItemSavedSuccess => 'Hotel item saved successfully.';

  @override
  String get hintHotelItemNameExample => 'E.g. White towel';

  @override
  String get hintHotelCategoryExample => 'E.g. Linen, Housekeeping, Room';

  @override
  String get hintHotelUnitExamples => 'E.g. piece, box, litre';

  @override
  String storeNameLine(String store) {
    return 'Store: $store';
  }

  @override
  String typeLine(String type) {
    return 'Type: $type';
  }

  @override
  String quantityUnitLine(String quantity, String unit) {
    return 'Quantity: $quantity $unit';
  }

  @override
  String reasonLine(String reason) {
    return 'Reason: $reason';
  }

  @override
  String byLine(String name) {
    return 'By: $name';
  }

  @override
  String updatedAtLine(String date) {
    return 'Updated: $date';
  }

  @override
  String get noMovementRecorded => 'No movement recorded.';

  @override
  String get noStockForStore => 'No stock recorded for this store.';

  @override
  String get labelStoreWord => 'Store';

  @override
  String get labelLastUpdate => 'Last update';

  @override
  String get actionTakePhoto => 'Take a photo';

  @override
  String get actionChooseFromGallery => 'Choose from gallery';

  @override
  String errPhotoFailed(String error) {
    return 'Photo error: $error';
  }

  @override
  String get errSaveDishFirst => 'Save the dish first, then add its photo.';

  @override
  String get errNoDataRowShort => 'No data row.';

  @override
  String rejectedRowMissingNameUnit(int line) {
    return 'Row $line: missing name or unit.';
  }

  @override
  String rejectedRowUnknownCategory(int line, String name, String category) {
    return 'Row $line ($name): unknown category « $category ».';
  }

  @override
  String rejectedRowUnknownStore(int line, String name, String store) {
    return 'Row $line ($name): unknown store « $store ».';
  }

  @override
  String createdItemsCount(int count) {
    return '$count item(s) created';
  }

  @override
  String ignoredEmptyRowsCount(int count) {
    return '$count empty row(s) skipped.';
  }

  @override
  String get existingItemsIgnored => 'Items already existing (skipped):';

  @override
  String get rejectedRowsTitle => 'Rejected rows:';

  @override
  String get validCategoriesAndStoresHint =>
      'Valid categories: see the list in the form. Valid stores: Hotel, Restaurant, Bar.';

  @override
  String get itemRegistryTitle => 'Item registry';

  @override
  String get itemRegistrySubtitle =>
      'Create and organize stock items before supplying.';

  @override
  String get registryImportExampleRows =>
      'Rice | Cereals | bag | restaurant\nCoke | Drinks | bottle | Bar';

  @override
  String get registryImportHint =>
      'The category must exist in the list. The store: Hotel, Restaurant or Bar.';

  @override
  String get hintItemNameExamples => 'E.g. Rice, Oil, Sugar';

  @override
  String get labelStoreField => 'Store';

  @override
  String get hintUnitExamplesLong => 'E.g. g, cl, bottle, sachet, piece';

  @override
  String get errUnitRequired => 'Please enter the unit.';

  @override
  String get savedItemsTitle => 'Saved items';

  @override
  String get noItemRecordedYet => 'No item recorded yet.';

  @override
  String get startCreatingItemsHint =>
      'Start by creating items such as rice, oil, sugar, mineral water, detergent, etc.';

  @override
  String get noClientRecordOrderless =>
      'No client record.\nThe order can be sent without a client.';

  @override
  String get noClientMatchesSearch => 'No client matches this search.';

  @override
  String get accessDeniedTitle => 'Access denied';

  @override
  String get unauthorizedMessage =>
      'Your role is not recognized, your account is not linked to an establishment, or you do not have access to this module.';

  @override
  String get orderStatusSent => 'Sent';

  @override
  String get orderStatusPartiallyCancelled => 'Partially cancelled';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusStockError => 'Stock error';

  @override
  String get datesNotProvided => 'Dates not provided';

  @override
  String departureOnDate(String date) {
    return 'Departure on $date';
  }

  @override
  String arrivalOnDate(String date) {
    return 'Arrival on $date';
  }

  @override
  String clientHistoryTitle(String name) {
    return 'History · $name';
  }

  @override
  String get staysSectionTitle => 'Stays';

  @override
  String get noStayForClient => 'No stay recorded for this client.';

  @override
  String get noOrderForClient => 'No order linked to this client.';

  @override
  String get stayWordSingular => 'stay';

  @override
  String get stayWordPlural => 'stays';

  @override
  String get totalSpentExcludingCancellations =>
      'Total spent (excluding cancellations)';

  @override
  String get barRestaurantConsumptionsTitle => 'Bar/restaurant consumptions';

  @override
  String get noEstablishmentAvailable => 'No establishment available.';

  @override
  String get adminCreatedSuccess => 'Administrator created successfully.';

  @override
  String errAdminCreationFailed(String error) {
    return 'Administrator creation error: $error';
  }

  @override
  String get createEstablishmentTitle => 'Create an establishment';

  @override
  String get editEstablishmentTitle => 'Edit establishment';

  @override
  String get establishmentCreatedSuccess =>
      'Establishment created successfully.';

  @override
  String errEstablishmentCreationFailed(String error) {
    return 'Establishment creation error: $error';
  }

  @override
  String get establishmentUpdatedSuccess =>
      'Establishment updated successfully.';

  @override
  String errEstablishmentUpdateFailed(String error) {
    return 'Establishment update error: $error';
  }

  @override
  String get saasAdministrationTitle => 'SaaS administration';

  @override
  String get actionCreateAdmin => 'Create administrator';

  @override
  String get actionCreateEstablishment => 'Create establishment';

  @override
  String get noEstablishmentRecorded => 'No establishment recorded.';

  @override
  String get establishmentInformation => 'Establishment information';

  @override
  String get labelEstablishmentName => 'Establishment name';

  @override
  String get labelIfu => 'IFU';

  @override
  String get labelCity => 'City';

  @override
  String get labelCountry => 'Country';

  @override
  String get labelEstablishmentType => 'Establishment type';

  @override
  String get typeHotelBarRestaurant => 'Hotel + Bar + Restaurant';

  @override
  String get labelPlan => 'Plan';

  @override
  String get establishmentStatusActive => 'Active';

  @override
  String get establishmentStatusSuspended => 'Suspended';

  @override
  String get establishmentStatusTrial => 'Trial';

  @override
  String get enabledModules => 'Enabled modules';

  @override
  String get firstEstablishmentAdmin => 'First establishment administrator';

  @override
  String get labelAdminName => 'Administrator name';

  @override
  String get labelAdminEmail => 'Administrator email';

  @override
  String get labelTemporaryPassword => 'Temporary password';

  @override
  String get hintDefaultTemporaryPassword => 'Temp@123456 by default';

  @override
  String get globalConsoleTitle => 'Takapp SaaS global console';

  @override
  String get globalConsoleSubtitle =>
      'Create establishments, enable modules, manage plans and initialize administrators.';

  @override
  String get unnamedEstablishment => 'Unnamed establishment';

  @override
  String idLine(String id) {
    return 'ID: $id';
  }

  @override
  String ifuLine(String ifu) {
    return 'IFU: $ifu';
  }

  @override
  String planChipLabel(String plan) {
    return 'Plan $plan';
  }

  @override
  String get createEstablishmentAdminTitle =>
      'Create an establishment administrator';

  @override
  String get labelEstablishment => 'Establishment';

  @override
  String get noStatus => 'No status';
}
