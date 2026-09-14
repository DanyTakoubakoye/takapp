// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonLogout => 'Déconnexion';

  @override
  String commonError(String error) {
    return 'Erreur : $error';
  }

  @override
  String errorPrefixed(String message) {
    return 'Erreur : $message';
  }

  @override
  String get errUnknown => 'Erreur inconnue.';

  @override
  String get errEstablishmentNotFound => 'Établissement introuvable.';

  @override
  String get errEstablishmentNotFoundReconnect =>
      'Établissement introuvable. Reconnectez-vous.';

  @override
  String get errAccountWithoutEstablishment =>
      'Votre compte n’est rattaché à aucun établissement.';

  @override
  String get errInvalidCredential => 'Email ou mot de passe incorrect.';

  @override
  String get errUserNotFound => 'Utilisateur introuvable.';

  @override
  String get errWrongPassword => 'Mot de passe incorrect.';

  @override
  String get errNetworkRequestFailed =>
      'Problème réseau. Vérifiez votre connexion.';

  @override
  String get errPermissionDenied => 'Accès refusé par les règles Firestore.';

  @override
  String get errResetEmailFailed =>
      'Impossible d’envoyer le mail de réinitialisation.';

  @override
  String get errOrderNotFound => 'Commande introuvable.';

  @override
  String get errInvoiceNotFound => 'Facture introuvable.';

  @override
  String get errReservationNotFound => 'Réservation introuvable.';

  @override
  String get errRoomNotFound => 'Chambre introuvable.';

  @override
  String get errClientNotFound => 'Client introuvable.';

  @override
  String get errStockNotFound => 'Stock introuvable.';

  @override
  String get errStockDocumentNotFound => 'Document de stock introuvable.';

  @override
  String get errHandoverNotFound => 'Versement introuvable.';

  @override
  String get errRequestNotFound => 'Demande introuvable.';

  @override
  String get errClientNameRequired => 'Nom du client obligatoire.';

  @override
  String get errClientTypeInvalid => 'Type de client invalide.';

  @override
  String get errAmountMustBePositive => 'Le montant doit être supérieur à 0.';

  @override
  String get errQuantityMustBePositive =>
      'La quantité doit être supérieure à 0.';

  @override
  String get errAddAtLeastOneItem => 'Veuillez ajouter au moins un article.';

  @override
  String get errSelectAtLeastOneItem =>
      'Veuillez sélectionner au moins un article.';

  @override
  String get errSelectPaymentMethod => 'Veuillez choisir un mode de paiement.';

  @override
  String get errRoomNumberRequired => 'Veuillez préciser le numéro de chambre.';

  @override
  String get errTableNumberRequired => 'Veuillez préciser le numéro de table.';

  @override
  String get errAddAtLeastOneUsedItem =>
      'Veuillez ajouter au moins un article utilisé.';

  @override
  String get errSelectAtLeastOnePayment =>
      'Veuillez sélectionner au moins un paiement.';

  @override
  String get errSelectAtLeastOneOrderOrPayment =>
      'Veuillez sélectionner au moins une commande/paiement.';

  @override
  String get errLabelRequired => 'Veuillez saisir un libellé.';

  @override
  String get errStoreRequired => 'Veuillez préciser le magasin.';

  @override
  String get errServerNameRequired => 'Veuillez saisir le nom du serveur.';

  @override
  String get errPhoneRequired => 'Veuillez saisir le numéro de téléphone.';

  @override
  String get errEmailRequired => 'Veuillez saisir une adresse email.';

  @override
  String get errMinThresholdNegative =>
      'Le seuil minimum ne peut pas être négatif.';

  @override
  String get errCertilinkError => 'Erreur CertiLink';

  @override
  String get errFiscalizationFailed => 'Échec de fiscalisation';

  @override
  String get errCertificationFailed => 'Échec de certification';

  @override
  String errStockInsufficient(String name) {
    return 'Stock insuffisant pour $name.';
  }

  @override
  String errServerRegistrationFailed(String name) {
    return 'Erreur lors de l’enregistrement du serveur : $name';
  }

  @override
  String get errFirebaseUserNotFound =>
      'Utilisateur Firebase introuvable après connexion.';

  @override
  String get errAccountDisabled => 'Ce compte est désactivé.';

  @override
  String get errUserProfileNotFound =>
      'Le profil utilisateur est introuvable dans Firestore.';

  @override
  String get errInvalidMenuId => 'Identifiant menu invalide.';

  @override
  String get errInvalidDishId => 'Identifiant du plat invalide.';

  @override
  String get errDishNameRequired => 'Nom du plat obligatoire.';

  @override
  String get errCocktailNameRequired => 'Nom du cocktail obligatoire.';

  @override
  String errMenuItemNotFound(String name) {
    return 'Article menu introuvable : $name';
  }

  @override
  String errNoRecipeDefined(String name) {
    return 'L’article « $name » n’a pas de recette définie.';
  }

  @override
  String get errNoOrderSelected => 'Aucune commande sélectionnée.';

  @override
  String get errNoPaymentSelectedForHandover =>
      'Aucun paiement sélectionné pour le versement.';

  @override
  String get errOrderAlreadyCancelled => 'Cette commande est déjà annulée.';

  @override
  String get errStockAlreadyRestored =>
      'Le stock de cette commande a déjà été restitué.';

  @override
  String get errCannotCancelPaidOrder =>
      'Impossible d’annuler une commande déjà encaissée.';

  @override
  String get errCannotCancelPaidOrderItems =>
      'Impossible d’annuler des articles d’une commande déjà encaissée.';

  @override
  String get errCannotCancelKitchenReady =>
      'Impossible d’annuler : la partie cuisine est déjà prête ou servie.';

  @override
  String get errCannotCancelBarReady =>
      'Impossible d’annuler : la partie bar est déjà prête ou servie.';

  @override
  String get errOrderHasNoItems => 'Cette commande ne contient aucun article.';

  @override
  String get errNoItemsFoundInOrder =>
      'Aucun article trouvé dans cette commande.';

  @override
  String get errNoItemSelectedForCancellation =>
      'Aucun article sélectionné pour annulation.';

  @override
  String errKitchenNotReady(String name) {
    return 'Commande $name : cuisine non prête.';
  }

  @override
  String errBarNotReady(String name) {
    return 'Commande $name : bar non prêt.';
  }

  @override
  String errItemAlreadyCancelled(String name) {
    return 'L’article « $name » est déjà annulé.';
  }

  @override
  String errCannotCancelItemKitchenReady(String name) {
    return 'Impossible d’annuler « $name » : la cuisine est déjà prête ou servie.';
  }

  @override
  String errCannotCancelItemBarReady(String name) {
    return 'Impossible d’annuler « $name » : le bar est déjà prêt ou servi.';
  }

  @override
  String errInvalidQuantityForItem(String name) {
    return 'Quantité invalide pour l’article « $name ».';
  }

  @override
  String errInvalidQuantityInOrder(String name) {
    return 'Quantité invalide dans la commande pour « $name ».';
  }

  @override
  String get errInvalidRoomNumber => 'Numéro de chambre invalide.';

  @override
  String get errRoomTypeRequired => 'Type de chambre requis.';

  @override
  String get errRoomNumberAlreadyExists =>
      'Une chambre avec ce numéro existe déjà.';

  @override
  String get errInvalidRoomStatus => 'Statut de chambre invalide.';

  @override
  String get errInvalidRoomTypeName => 'Nom du type invalide.';

  @override
  String get errPricePerNightMustBePositive =>
      'Le prix par nuit doit être supérieur à 0.';

  @override
  String get errRoomTypeAlreadyExists => 'Ce type de chambre existe déjà.';

  @override
  String get errReservationNotAwaitingArrival =>
      'Cette réservation n’est pas en attente d’arrivée.';

  @override
  String get errReservationNotInStay =>
      'Cette réservation n’est pas en cours de séjour.';

  @override
  String get errRoomNoLongerAvailable => 'Cette chambre n’est plus disponible.';

  @override
  String get errRoomNotOfReservedType =>
      'Cette chambre n’est pas du type réservé.';

  @override
  String get errCheckOutAfterCheckIn =>
      'La date de départ doit être après la date d’arrivée.';

  @override
  String get errNoRoomOfTypeAvailable =>
      'Aucune chambre de ce type disponible sur cette période. Vous pouvez forcer la réservation si nécessaire.';

  @override
  String get errInvalidStockItemMissingId =>
      'Article de stock invalide : itemId manquant.';

  @override
  String get errItemNotFoundInStock => 'Article introuvable dans le stock.';

  @override
  String get errNoItemDelivered => 'Aucun article livré.';

  @override
  String get errInvalidItemName => 'Nom article invalide.';

  @override
  String get errInvalidStore => 'Magasin invalide.';

  @override
  String get errItemAlreadyExistsInStore =>
      'Cet article existe déjà dans ce magasin.';

  @override
  String errItemNotFoundInStockFor(String name) {
    return 'Article introuvable dans le stock : $name';
  }

  @override
  String get errInvalidServerName => 'Nom du serveur invalide.';

  @override
  String get errInvalidEmail => 'Email invalide.';

  @override
  String get errUserEmailAlreadyExists =>
      'Un utilisateur avec cet email existe déjà.';

  @override
  String get errTotalAmountInvalid => 'Montant total invalide.';

  @override
  String get errPaymentAmountInvalid => 'Montant de paiement invalide.';

  @override
  String get errEmptyPdfDocument => 'Document PDF vide.';

  @override
  String errFirestoreError(String name) {
    return 'Erreur Firestore : $name';
  }

  @override
  String errConsumptionLoadFailed(String name) {
    return 'Erreur lors du chargement des consommations : $name';
  }

  @override
  String errStockNotFoundFor(String name) {
    return 'Stock introuvable pour « $name ».';
  }

  @override
  String errInconsistentUnit(String name, String stockUnit, String recipeUnit) {
    return 'Unité incohérente pour « $name » : stock en « $stockUnit » mais recette en « $recipeUnit ».';
  }

  @override
  String errInsufficientStockDetailed(
    String name,
    String available,
    String required,
  ) {
    return 'Stock insuffisant pour « $name » : disponible $available, requis $required.';
  }

  @override
  String get navNotifications => 'Notifications';

  @override
  String get serverNotFound => 'Serveur introuvable.';

  @override
  String get noNotifications => 'Aucune notification.';

  @override
  String get notificationFallbackTitle => 'Notification';

  @override
  String get departmentKitchen => 'Cuisine';

  @override
  String get departmentBar => 'Bar';

  @override
  String labelTable(String number) {
    return 'Table $number';
  }

  @override
  String labelRoom(String number) {
    return 'Chambre $number';
  }

  @override
  String get labelBarClient => 'Client Bar';

  @override
  String clientLine(String client) {
    return 'Client : $client';
  }

  @override
  String cancelPartialTitle(String orderNumber) {
    return 'Annulation partielle $orderNumber';
  }

  @override
  String get cancelItemAlreadyCancelled => 'Déjà annulé';

  @override
  String get cancelItemKitchenDone => 'Cuisine déjà prête/servie';

  @override
  String get cancelItemBarDone => 'Bar déjà prêt/servi';

  @override
  String get cancelItemCancelable => 'Annulable';

  @override
  String get cancelItemsDone => 'Articles annulés et stock restitué.';

  @override
  String cancelLoadOrderError(String error) {
    return 'Erreur chargement commande : $error';
  }

  @override
  String cancelLoadItemsError(String error) {
    return 'Erreur chargement articles : $error';
  }

  @override
  String cancelDepartmentLine(String department) {
    return 'Département : $department';
  }

  @override
  String get cancelReasonLabel => 'Motif d’annulation';

  @override
  String cancelAmountToDeduct(String amount) {
    return 'Montant à retrancher : $amount FCFA';
  }

  @override
  String get cancelInProgress => 'Annulation en cours...';

  @override
  String get cancelValidate => 'Valider l’annulation';

  @override
  String get myInvoicesTitle => 'Mes factures';

  @override
  String get today => 'Aujourd’hui';

  @override
  String todayWithDate(String date) {
    return 'Aujourd’hui ($date)';
  }

  @override
  String get pickDate => 'Choisir une date';

  @override
  String get noInvoiceForDate => 'Aucune facture pour cette date.';

  @override
  String get statusPaid => 'Encaissée';

  @override
  String get statusUnpaid => 'Non encaissée';

  @override
  String get statusFiscalized => 'Fiscalisée';

  @override
  String get statusNotFiscalized => 'Non fiscalisée';

  @override
  String get actionCollectInvoice => 'Encaisser la facture';

  @override
  String get actionPrintInvoice => 'Imprimer facture';

  @override
  String get actionFiscalize => 'Fiscaliser';

  @override
  String get actionPrintFiscalizedInvoice => 'Imprimer facture fiscalisée';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonValidate => 'Valider';

  @override
  String get clientFallback => 'Client';

  @override
  String get noOrders => 'Aucune commande';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusPreparing => 'En préparation';

  @override
  String get statusReady => 'Prête';

  @override
  String get statusServed => 'Servie';

  @override
  String get statusPickedUp => 'Récupérée';

  @override
  String get columnPending => 'En attente';

  @override
  String get columnPreparing => 'En préparation';

  @override
  String get columnReady => 'Prêtes';

  @override
  String get suiviBarTitle => 'Suivi Bar';

  @override
  String get suiviCuisineTitle => 'Suivi Cuisine';

  @override
  String get barItems => 'Articles bar';

  @override
  String get kitchenItems => 'Articles cuisine';

  @override
  String waiterLine(String name) {
    return 'Serveur : $name';
  }

  @override
  String orderTotalLine(String amount) {
    return 'Total commande : $amount FCFA';
  }

  @override
  String totalLine(String amount) {
    return 'Total : $amount FCFA';
  }

  @override
  String noteLine(String note) {
    return 'Note : $note';
  }

  @override
  String barItemsError(String error) {
    return 'Erreur articles bar : $error';
  }

  @override
  String kitchenItemsError(String error) {
    return 'Erreur articles cuisine : $error';
  }

  @override
  String get actionSetPreparing => 'Passer en préparation';

  @override
  String get actionMarkReady => 'Marquer prête';

  @override
  String get actionBackToPreparing => 'Revenir en préparation';

  @override
  String get actionRevert => 'Revenir';

  @override
  String get actionPickedUp => 'Récupéré';

  @override
  String get encaissementTitle => 'Encaissement';

  @override
  String get noUnpaidOrder => 'Aucune commande non encaissée.';

  @override
  String ordersCount(String count) {
    return '$count commandes';
  }

  @override
  String openedAt(String time) {
    return 'Ouverte à $time';
  }

  @override
  String createdByLine(String name) {
    return 'Créée par : $name';
  }

  @override
  String totalToCollect(String amount) {
    return 'Total à encaisser : $amount FCFA';
  }

  @override
  String get actionShowAndPrint => 'Afficher et Imprimer';

  @override
  String get actionCollect => 'Encaisser';

  @override
  String get invalidAmount => 'Montant invalide.';

  @override
  String get paymentRecorded => 'Paiement enregistré avec succès.';

  @override
  String collectForTicket(String label) {
    return 'Encaisser — $label';
  }

  @override
  String groupedOrders(String count, String numbers) {
    return '$count commandes regroupées : $numbers';
  }

  @override
  String get paymentMethodLabel => 'Mode de paiement';

  @override
  String get amountReceived => 'Montant reçu';

  @override
  String get roomConsumptionInvoiceTitle => 'Facture Consommation Chambre';

  @override
  String get noConsumptionForPeriod =>
      'Aucune consommation trouvée pour cette période.';

  @override
  String get roomNumberLabel => 'Numéro chambre';

  @override
  String get startDate => 'Date début';

  @override
  String get endDate => 'Date fin';

  @override
  String get actionShow => 'Afficher';

  @override
  String get pickBothDates => 'Veuillez choisir les dates de début et de fin.';

  @override
  String get startDateBeforeEndDate =>
      'La date de début doit être antérieure ou égale à la date de fin.';

  @override
  String get handoverTitle => 'Versement à la gérante';

  @override
  String get paymentsToHandOver => 'Paiements à verser';

  @override
  String selectionAmount(String amount) {
    return 'Sélection : $amount FCFA';
  }

  @override
  String get noPaymentAvailableForHandover =>
      'Aucun paiement disponible pour versement.';

  @override
  String get handoverDeclared => 'Versement déclaré avec succès.';

  @override
  String get clearSelection => 'Vider la sélection';

  @override
  String get declareHandover => 'Déclarer le versement';

  @override
  String get statusValidated => 'Validé';

  @override
  String get statusRejected => 'Rejeté';

  @override
  String get handoverHistory => 'Historique des versements';

  @override
  String get noHandoverRecorded => 'Aucun versement enregistré.';

  @override
  String includedPayments(String count) {
    return 'Paiements inclus : $count';
  }

  @override
  String get actionPrint => 'Imprimer';

  @override
  String get attachClientOptional => 'Rattacher un client (optionnel)';

  @override
  String get detachClient => 'Détacher le client';

  @override
  String get orderSentSuccess => 'Commande envoyée avec succès.';

  @override
  String get newOrderTitle => 'Nouvelle commande';

  @override
  String get labelRestaurantClient => 'Client Restaurant';

  @override
  String get labelHotelClient => 'Client Hôtel';

  @override
  String get clientTypeLabel => 'Type de client';

  @override
  String get tableNumberLabel => 'Numéro de table';

  @override
  String get roomNumberFieldLabel => 'Numéro de chambre';

  @override
  String get noItemAvailable => 'Aucun article disponible.';

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get cartTitle => 'Panier';

  @override
  String get noItemAdded => 'Aucun article ajouté.';

  @override
  String get actionSendOrder => 'Envoyer la commande';

  @override
  String subtotalLine(String amount) {
    return 'Sous-total : $amount FCFA';
  }

  @override
  String serveurSpaceTitle(String establishment) {
    return 'Espace serveur - $establishment';
  }

  @override
  String welcomeName(String name) {
    return 'Bienvenue $name';
  }

  @override
  String get serveurSpaceSubtitle =>
      'Espace de prise de commande et de suivi serveur';

  @override
  String get moduleOrdersRoomsTitle => 'Commandes & Chambres';

  @override
  String get moduleOrdersRoomsSubtitle =>
      'Prendre les commandes et gérer les consommations chambre';

  @override
  String get actionMenuOrderTitle => 'Menu et Commande';

  @override
  String get actionMenuOrderSubtitle =>
      'Prendre une commande restaurant, bar ou chambre';

  @override
  String get actionRoomConsumptionTitle => 'Consommations Chambre';

  @override
  String get actionRoomConsumptionSubtitle =>
      'Facturer les consommations liées à une chambre';

  @override
  String get modulePaymentsTitle => 'Paiements & Versements';

  @override
  String get modulePaymentsSubtitle =>
      'Encaisser les factures et remettre les fonds';

  @override
  String get actionCollectSubtitle => 'Encaisser les factures non payées';

  @override
  String get actionMyInvoicesSubtitle =>
      'Toutes mes factures : encaisser, fiscaliser, imprimer';

  @override
  String get actionHandoverSubtitle =>
      'Remettre les encaissements à la gérante';

  @override
  String get moduleTrackingTitle => 'Suivi Préparation';

  @override
  String get moduleTrackingSubtitle =>
      'Suivre l’avancement des commandes bar et cuisine';

  @override
  String get actionSuiviBarSubtitle =>
      'Voir l’état des commandes envoyées au bar';

  @override
  String get actionSuiviCuisineSubtitle =>
      'Voir l’état des commandes envoyées en cuisine';

  @override
  String get categoryAll => 'Toutes';

  @override
  String get menuTitle => 'Notre menu';

  @override
  String get searchDishHint => 'Rechercher un plat…';

  @override
  String get noAccompanimentAvailable =>
      'Aucun accompagnement disponible. Plat ajouté sans accompagnement.';

  @override
  String get freeAccompaniment => 'Accompagnement offert';

  @override
  String get chooseOneFreeAccompaniment => 'Choisissez 1 accompagnement offert';

  @override
  String get labelFree => 'Offert';

  @override
  String get paidExtraPortions => 'Portions supplémentaires (payantes)';

  @override
  String get orderRecapTitle => 'Récapitulatif de la commande';

  @override
  String get sendingInProgress => 'Envoi en cours...';

  @override
  String get confirmAndSend => 'Confirmer et envoyer';

  @override
  String recapWithCount(String count) {
    return 'Récapitulatif ($count)';
  }

  @override
  String pricePerPortion(String price) {
    return '$price FCFA / portion';
  }

  @override
  String accompanimentLine(String name) {
    return 'Accompagnement : $name (offert)';
  }

  @override
  String get consumptionDetailsTitle => 'Détails de la Consommation';

  @override
  String get certifiedInvoiceBadge => 'FACTURE CERTIFIEE';

  @override
  String get generalInformation => 'Informations générales';

  @override
  String get labelOrders => 'Commandes';

  @override
  String get labelOrder => 'Commande';

  @override
  String get labelDate => 'Date';

  @override
  String get labelType => 'Type';

  @override
  String get labelAmount => 'Montant';

  @override
  String get clientInfoOptional => 'Informations client (facultatives)';

  @override
  String get clientNameLabel => 'Nom du client';

  @override
  String get clientAddressLabel => 'Adresse du client';

  @override
  String get clientIfuLabel => 'IFU du client';

  @override
  String get consumedItems => 'Articles consommés';

  @override
  String get simpleInvoicePrinted =>
      'Facture simple imprimée et encaissement enregistré.';

  @override
  String get normalizedInvoicePrinted =>
      'Facture normalisée imprimée et encaissement enregistré.';

  @override
  String get invoiceAlreadyCertified => 'Cette facture est déjà certifiée.';

  @override
  String get fiscalizeInvoiceFirst => 'Fiscalisez d’abord la facture.';

  @override
  String get fillEstablishmentIfuFirst =>
      'Renseignez d’abord l’IFU de l’établissement (console admin).';

  @override
  String get actionPrintNormalizedInvoice => 'Imprimer facture normalisée';

  @override
  String get actionPrintSimpleInvoice => 'Imprimer facture simple';

  @override
  String quantityLine(String quantity) {
    return 'Qté : $quantity';
  }

  @override
  String unitPriceLine(String price) {
    return 'P.U : $price FCFA';
  }

  @override
  String invoiceFiscalizedWithCode(String code) {
    return 'Facture fiscalisée avec certilink. Code MECeF : $code';
  }

  @override
  String get paymentCash => 'Espèces';

  @override
  String get paymentMobileMoney => 'Mobile Money';

  @override
  String get paymentCard => 'Carte bancaire';

  @override
  String get paymentBankTransfer => 'Virement bancaire';

  @override
  String get paymentMixed => 'Paiement mixte';

  @override
  String get paymentCredit => 'Vente à crédit';

  @override
  String get paymentBeninResto => 'Bénin Resto';

  @override
  String get accountCash => 'Cash';

  @override
  String get accountMobileMoney => 'Mobile Money';

  @override
  String get accountBankTransfer => 'Banque';

  @override
  String get accountCard => 'Carte Bancaire';

  @override
  String get accountCredit => 'Crédit';

  @override
  String get accountBeninResto => 'Bénin Resto';

  @override
  String get accountMixed => 'Paiement Mixte';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionDisable => 'Désactiver';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get savingInProgress => 'Enregistrement...';

  @override
  String get fieldRequired => 'Obligatoire';

  @override
  String get receptionTitle => 'Réception';

  @override
  String get receptionSubtitle =>
      'Espace réception : chambres, séjours et factures';

  @override
  String get tileRoomsBoardTitle => 'Plan des chambres';

  @override
  String get tileRoomsBoardSubtitle => 'Voir l’état des chambres en temps réel';

  @override
  String get tileReservationsTitle => 'Réservations';

  @override
  String get tileReservationsSubtitle => 'Créer et gérer les réservations';

  @override
  String get tileRoomInvoicingTitle => 'Facturation chambre';

  @override
  String get tileRoomInvoicingSubtitle => 'Facturer et certifier un séjour';

  @override
  String get tileInvoicesListTitle => 'Liste des factures';

  @override
  String get tileInvoicesListSubtitle => 'Consulter les factures chambres';

  @override
  String get tileClientsTitle => 'Clients';

  @override
  String get tileClientsSubtitle => 'Fiches clients et historique';

  @override
  String get roomsTitle => 'Chambres';

  @override
  String get tileRoomsSubtitle => 'Gérer les chambres';

  @override
  String get roomTypesTitle => 'Types de chambres';

  @override
  String get tileRoomTypesSubtitle => 'Configurer les catégories';

  @override
  String get disableTypeConfirmTitle => 'Désactiver ce type ?';

  @override
  String disableTypeConfirmBody(String name) {
    return 'Le type « $name » ne sera plus proposé, mais les chambres existantes ne sont pas supprimées.';
  }

  @override
  String get typeDisabled => 'Type désactivé.';

  @override
  String get typeUpdated => 'Type modifié.';

  @override
  String get typeAdded => 'Type ajouté.';

  @override
  String get addRoomType => 'Ajouter un type';

  @override
  String get noRoomType =>
      'Aucun type de chambre.\nAjoutez vos catégories (Simple, Suite, Bungalow...).';

  @override
  String roomTypeSubtitle(String price, String capacity) {
    return '$price FCFA / nuit · $capacity pers.';
  }

  @override
  String get editTypeTitle => 'Modifier le type';

  @override
  String get newTypeTitle => 'Nouveau type de chambre';

  @override
  String get typeNameLabel => 'Nom du type';

  @override
  String get typeNameHint => 'Ex. Suite Présidentielle, Bungalow...';

  @override
  String get pricePerNightLabel => 'Prix par nuit (FCFA)';

  @override
  String get pricePerNightHint => 'Ex. 25000';

  @override
  String get invalidPrice => 'Prix invalide';

  @override
  String get capacityLabel => 'Capacité (personnes)';

  @override
  String get capacityHint => 'Ex. 2';

  @override
  String get invalidCapacity => 'Capacité invalide';

  @override
  String get descriptionOptionalLabel => 'Description (optionnel)';

  @override
  String get amenitiesLabel => 'Équipements (séparés par des virgules)';

  @override
  String get amenitiesHint => 'Ex. Clim, Wifi, TV, Minibar';

  @override
  String get roomStatusAvailable => 'Libre';

  @override
  String get roomStatusOccupied => 'Occupée';

  @override
  String get roomStatusCleaning => 'À nettoyer';

  @override
  String get roomStatusMaintenance => 'Maintenance';

  @override
  String changeRoomStateTitle(String number) {
    return 'Chambre $number — changer l’état';
  }

  @override
  String roomOccupiedTitle(String number) {
    return 'Chambre $number (occupée)';
  }

  @override
  String get actionCheckOut => 'Check-out (départ du client)';

  @override
  String get actionChangeStateManually => 'Changer l’état manuellement';

  @override
  String roomStatusChanged(String number, String status) {
    return 'Chambre $number : $status';
  }

  @override
  String get noActiveReservationForRoom =>
      'Aucune réservation active trouvée pour cette chambre. Vous pouvez changer son état manuellement.';

  @override
  String get checkOutTitle => 'Check-out';

  @override
  String checkOutConfirmBody(String client, String number) {
    return 'Confirmer le départ de $client (chambre $number) ?\n\nLa chambre passera « à nettoyer ».';
  }

  @override
  String get actionConfirmDeparture => 'Confirmer le départ';

  @override
  String get checkOutDone => 'Check-out effectué.';

  @override
  String get billStayTitle => 'Facturer le séjour ?';

  @override
  String billStayBody(String client) {
    return 'Voulez-vous établir la facture de $client maintenant ?';
  }

  @override
  String get actionLater => 'Plus tard';

  @override
  String get actionBill => 'Facturer';

  @override
  String get noRoomBoard =>
      'Aucune chambre.\nAjoutez vos chambres pour voir le plan.';

  @override
  String roomsCountSummary(
    String total,
    String free,
    String occupied,
    String toClean,
  ) {
    return '$total chambres · $free libres · $occupied occupées · $toClean à nettoyer';
  }

  @override
  String get createRoomTypeFirst =>
      'Créez d’abord au moins un type de chambre.';

  @override
  String get deleteRoomConfirmTitle => 'Supprimer cette chambre ?';

  @override
  String deleteRoomConfirmBody(String number) {
    return 'La chambre « $number » sera retirée de la liste.';
  }

  @override
  String get roomDeleted => 'Chambre supprimée.';

  @override
  String get addRoom => 'Ajouter une chambre';

  @override
  String get noRoomTypeThenRooms =>
      'Créez d’abord un type de chambre,\npuis ajoutez vos chambres.';

  @override
  String get noRoomYet =>
      'Aucune chambre.\nAjoutez vos chambres avec le bouton +.';

  @override
  String floorSuffix(String floor) {
    return ' · Étage $floor';
  }

  @override
  String get pickRoomType => 'Veuillez choisir un type de chambre.';

  @override
  String get chooseRoomType => 'Choisissez un type';

  @override
  String get roomUpdated => 'Chambre modifiée.';

  @override
  String get roomAdded => 'Chambre ajoutée.';

  @override
  String get editRoomTitle => 'Modifier la chambre';

  @override
  String get newRoomTitle => 'Nouvelle chambre';

  @override
  String get roomNumberOrNameLabel => 'Numéro / nom de la chambre';

  @override
  String get roomNumberOrNameHint => 'Ex. 101, Jasmin, A2';

  @override
  String get roomTypeLabel => 'Type de chambre';

  @override
  String roomTypeOption(String name, String price) {
    return '$name ($price FCFA)';
  }

  @override
  String get floorOptionalLabel => 'Étage (optionnel)';

  @override
  String get floorHint => 'Ex. 1, RDC';

  @override
  String get specificPriceLabel => 'Prix spécifique (optionnel)';

  @override
  String get specificPriceHint => 'Laisser vide = prix du type';

  @override
  String get reservationStatusConfirmed => 'Confirmée';

  @override
  String get reservationStatusCheckedIn => 'Arrivée';

  @override
  String get reservationStatusCheckedOut => 'Partie';

  @override
  String get reservationStatusCancelled => 'Annulée';

  @override
  String get cancelReservationConfirmTitle => 'Annuler cette réservation ?';

  @override
  String cancelReservationConfirmBody(String client) {
    return 'La réservation de $client sera marquée annulée.';
  }

  @override
  String get actionBack => 'Retour';

  @override
  String get actionCancelReservation => 'Annuler la réservation';

  @override
  String get reservationCancelled => 'Réservation annulée.';

  @override
  String noFreeRoomOfType(String type) {
    return 'Aucune chambre libre pour le type « $type ». Libérez ou préparez une chambre d’abord.';
  }

  @override
  String assignRoomTo(String client) {
    return 'Attribuer une chambre à $client';
  }

  @override
  String floorLabel(String floor) {
    return 'Étage $floor';
  }

  @override
  String checkInDone(String number) {
    return 'Check-in effectué : chambre $number.';
  }

  @override
  String get actionCheckIn => 'Check-in';

  @override
  String get newReservation => 'Nouvelle réservation';

  @override
  String get noReservation =>
      'Aucune réservation.\nCréez-en une avec le bouton +.';

  @override
  String roomShortSuffix(String number) {
    return ' · Ch. $number';
  }

  @override
  String nightsCount(String nights) {
    return '$nights nuit(s)';
  }

  @override
  String get editReservationTitle => 'Modifier la réservation';

  @override
  String get dateHintDdMmYyyy => 'jj/mm/aaaa';

  @override
  String get invalidDate => 'Date invalide';

  @override
  String get pickStayDates => 'Choisissez les dates du séjour.';

  @override
  String get phoneOptionalLabel => 'Téléphone (optionnel)';

  @override
  String get ifuOptionalLabel => 'IFU (optionnel, pour la facture)';

  @override
  String get labelArrival => 'Arrivée';

  @override
  String get labelDeparture => 'Départ';

  @override
  String get pickFromCalendar => 'Choisir au calendrier';

  @override
  String get pricePerNightShortLabel => 'Prix / nuit';

  @override
  String get noteOptionalLabel => 'Note (optionnel)';

  @override
  String get reservationUpdated => 'Réservation modifiée.';

  @override
  String totalWithNights(String amount, String nights) {
    return 'Total : $amount FCFA ($nights nuit(s))';
  }

  @override
  String get chooseExistingClient => 'Choisir un client existant';

  @override
  String attachedClient(String name) {
    return 'Client rattaché : $name';
  }

  @override
  String get detachRecord => 'Détacher la fiche';

  @override
  String get checkingAvailability => 'Vérification de la disponibilité...';

  @override
  String get typeFullOnPeriod =>
      'Type complet sur cette période (vous pourrez forcer).';

  @override
  String roomsAvailableCount(String count) {
    return '$count chambre(s) disponible(s).';
  }

  @override
  String get typeFullTitle => 'Type complet';

  @override
  String get typeFullBody =>
      'Aucune chambre de ce type n’est disponible sur cette période. Voulez-vous forcer la réservation malgré tout ?';

  @override
  String get actionNo => 'Non';

  @override
  String get actionForce => 'Forcer';

  @override
  String get guestsLabel => 'Personnes';

  @override
  String get reservationCreated => 'Réservation créée.';

  @override
  String get creatingInProgress => 'Création...';

  @override
  String get actionCreate => 'Créer';

  @override
  String get chooseClient => 'Choisir un client';

  @override
  String get searchLabel => 'Rechercher';

  @override
  String get searchNameOrPhoneHint => 'Nom ou téléphone';

  @override
  String get noClientRecord =>
      'Aucune fiche client.\nVous pouvez saisir le client à la main.';

  @override
  String get noClientMatches => 'Aucun client ne correspond à cette recherche.';

  @override
  String ifuPrefix(String ifu) {
    return 'IFU $ifu';
  }

  @override
  String get serverPaymentsNotHandedTitle =>
      'Encaissements serveurs non versés';

  @override
  String get noPendingPayment => 'Aucun encaissement en attente';

  @override
  String methodLine(String method) {
    return 'Mode : $method';
  }

  @override
  String get stockManagementTitle => 'Gestion des stocks';

  @override
  String get supplyRequests => 'Demandes d’approvisionnement';

  @override
  String get storesOverview => 'Pilotage des magasins';

  @override
  String get storesOverviewSubtitle =>
      'Consulte les stocks, traite les demandes et valide les approvisionnements.';

  @override
  String get storeHotelTitle => 'Magasin Hôtel';

  @override
  String get storeHotelSubtitle =>
      'Produits d’hygiène, entretien, consommables chambre';

  @override
  String get storeRestaurantTitle => 'Magasin Restaurant';

  @override
  String get storeRestaurantSubtitle => 'Denrées, cuisine, matières premières';

  @override
  String get storeBarTitle => 'Magasin Bar';

  @override
  String get storeBarSubtitle => 'Boissons, snacks, accessoires bar';

  @override
  String get actionViewStock => 'Voir stock';

  @override
  String get actionRequests => 'Demandes';

  @override
  String get clientDisabled => 'Client désactivé.';

  @override
  String get clientAdded => 'Client ajouté.';

  @override
  String get loginSubtitle => 'Connectez-vous à votre espace de travail';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailHint => 'exemple@domaine.com';

  @override
  String get loginEmailRequired => 'Veuillez saisir votre email';

  @override
  String get loginEmailInvalid => 'Email invalide';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginPasswordEmailFirst =>
      'Veuillez saisir un email complet d’abord';

  @override
  String get loginPasswordRequired => 'Veuillez saisir votre mot de passe';

  @override
  String get loginPasswordTooShort => 'Minimum 6 caractères';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get loginResetNeedsEmail =>
      'Veuillez d’abord saisir votre adresse email pour recevoir le lien de réinitialisation.';

  @override
  String get loginResetInvalidEmail => 'Veuillez saisir un email valide.';

  @override
  String loginResetSent(String email) {
    return 'Un lien de réinitialisation a été envoyé à $email. Vérifiez aussi vos spams/indésirables.';
  }

  @override
  String get loginResetFailed =>
      'Impossible d’envoyer le mail de réinitialisation.';

  @override
  String loginResetError(String error) {
    return 'Erreur lors de l’envoi du mail : $error';
  }

  @override
  String get roleGlobalAdmin => 'Administrateur global';

  @override
  String get roleSuperAdmin => 'Super Administrateur';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleManager => 'Gérante';

  @override
  String get roleAccountant => 'Comptable';

  @override
  String get roleHeadChef => 'Chef Cuisine';

  @override
  String get roleWaiter => 'Serveur';

  @override
  String get roleHousekeeping => 'Service Hygiène';

  @override
  String get roleBartender => 'Barman';

  @override
  String get roleButler => 'Majordhomme';

  @override
  String get roleReceptionist => 'Réceptionniste';

  @override
  String get labelReason => 'Motif';

  @override
  String get labelItem => 'Article';

  @override
  String labelItemIndex(int index) {
    return 'Article $index';
  }

  @override
  String get labelQuantitySupplied => 'Quantité approvisionnée';

  @override
  String get actionAddItem => 'Ajouter un article';

  @override
  String get actionValidateSupply => 'Valider l’approvisionnement';

  @override
  String get reasonDirectSupplyDefault => 'Approvisionnement direct gérante';

  @override
  String selectItemAtLine(int line) {
    return 'Sélectionne l’article à la ligne $line.';
  }

  @override
  String invalidQuantityAtLine(int line) {
    return 'Quantité invalide à la ligne $line.';
  }

  @override
  String get directSupplyRecorded =>
      'Approvisionnement direct enregistré avec succès.';

  @override
  String get registerServerTitle => 'Enregistrer un serveur';

  @override
  String get newServerTitle => 'Nouveau serveur';

  @override
  String get labelFullName => 'Nom complet';

  @override
  String get labelPhone => 'Téléphone';

  @override
  String get labelEmail => 'Email';

  @override
  String get errFullNameRequired => 'Veuillez renseigner le nom complet';

  @override
  String get errPhoneTooShort => 'Numéro trop court';

  @override
  String get serverRegisteredSuccess => 'Serveur enregistré avec succès.';

  @override
  String get storeNameHotel => 'Hôtel';

  @override
  String get storeNameRestaurant => 'Restaurant';

  @override
  String get storeNameBar => 'Bar';

  @override
  String get statusDelivered => 'Livrée';

  @override
  String get statusReceived => 'Réceptionnée';

  @override
  String get deliveryTitle => 'Livraison / Approvisionnement';

  @override
  String get requestAlreadyProcessed => 'Cette demande a déjà été traitée.';

  @override
  String get requestAlreadyProcessedShort => 'Demande déjà traitée';

  @override
  String invalidDeliveredQuantityAtLine(int line) {
    return 'Quantité livrée invalide à la ligne $line.';
  }

  @override
  String get supplyValidatedSuccess => 'Approvisionnement validé avec succès.';

  @override
  String requestedByLine(String name) {
    return 'Demandé par : $name';
  }

  @override
  String roleLine(String role) {
    return 'Rôle : $role';
  }

  @override
  String statusLine(String status) {
    return 'Statut : $status';
  }

  @override
  String get quantitiesToDeliver => 'Quantités à livrer';

  @override
  String requestedQuantityLine(String quantity, String unit) {
    return 'Demandé : $quantity $unit';
  }

  @override
  String get labelQuantityDelivered => 'Quantité livrée';

  @override
  String get actionValidateDelivery => 'Valider la livraison';
}
