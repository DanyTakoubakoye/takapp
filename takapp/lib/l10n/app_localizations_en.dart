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
  String get actionBack => 'Back';

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
