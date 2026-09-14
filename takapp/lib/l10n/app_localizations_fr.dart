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

  @override
  String amountLine(String amount) {
    return 'Montant : $amount FCFA';
  }

  @override
  String get labelTotalCaps => 'TOTAL';

  @override
  String get labelStatus => 'Statut';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get noResult => 'Aucun résultat';

  @override
  String dateLine(String date) {
    return 'Date : $date';
  }

  @override
  String roomLine(String number) {
    return 'Chambre : $number';
  }

  @override
  String get labelClientName => 'Nom du client';

  @override
  String get labelRoomNumber => 'Numéro de chambre';

  @override
  String get actionViewDetails => 'Voir détails';

  @override
  String get statusDeclared => 'Déclaré';

  @override
  String get noElementSelected => 'Aucun élément sélectionné.';

  @override
  String get transferDeclaredToAccounting =>
      'Versement déclaré à la comptabilité.';

  @override
  String get managerToAccountingTitle => 'Versement gérante → comptabilité';

  @override
  String get validatedServerHandovers => 'Versements serveurs validés';

  @override
  String get noServerHandoverAvailable => 'Aucun versement serveur disponible.';

  @override
  String get paidRoomInvoicesNotTransferred =>
      'Factures chambres encaissées non versées';

  @override
  String get noRoomInvoiceAvailable => 'Aucune facture chambre disponible.';

  @override
  String get transferSummary => 'Résumé du versement';

  @override
  String get serverHandoversLabel => 'Versements serveurs';

  @override
  String get roomInvoicesLabel => 'Factures chambres';

  @override
  String get actionDeclareToAccounting => 'Déclarer à la comptabilité';

  @override
  String get managerTransferHistory => 'Historique versements gérante';

  @override
  String get noTransferRecorded => 'Aucun versement enregistré.';

  @override
  String get statusPaidShort => 'Payée';

  @override
  String get statusUnpaidShort => 'Non payée';

  @override
  String errSearchFailed(String error) {
    return 'Erreur lors de la recherche : $error';
  }

  @override
  String get searchByClientOption => 'Recherche par client';

  @override
  String get searchByRoomOption => 'Recherche par chambre';

  @override
  String get searchByClientShort => 'Par client';

  @override
  String get searchByRoomShort => 'Par chambre';

  @override
  String arrivalLine(String date) {
    return 'Entrée : $date';
  }

  @override
  String departureLine(String date) {
    return 'Sortie : $date';
  }

  @override
  String mecefCodeLine(String code) {
    return 'Code MECeF : $code';
  }

  @override
  String get searchRoomInvoicesTitle => 'Recherche factures chambre';

  @override
  String get serverHandoversTitle => 'Versements des serveurs';

  @override
  String get noPendingHandover => 'Aucun versement en attente.';

  @override
  String declaredAmountLine(String amount) {
    return 'Montant déclaré : $amount FCFA';
  }

  @override
  String includedPaymentsLine(int count) {
    return 'Paiements inclus : $count';
  }

  @override
  String get errObservedAmountInvalid => 'Montant constaté invalide.';

  @override
  String get ordersValidated => 'Commandes validées.';

  @override
  String get ordersRejected => 'Commandes rejetées.';

  @override
  String handoverTitleFor(String name) {
    return 'Versement - $name';
  }

  @override
  String get labelObservedAmount => 'Montant constaté';

  @override
  String get noPaymentFound => 'Aucun paiement trouvé.';

  @override
  String methodAmountLine(String method, String amount) {
    return '$method • $amount FCFA';
  }

  @override
  String get suffixAlreadyValidated => ' • déjà validée';

  @override
  String get suffixRejected => ' • rejetée';

  @override
  String get actionRejectSelection => 'Rejeter sélection';

  @override
  String get actionValidateSelection => 'Valider sélection';

  @override
  String supplyRequestsForStore(String store) {
    return 'Demandes - $store';
  }

  @override
  String get filterRequests => 'Filtrer les demandes';

  @override
  String get filterDelivered => 'Livrées';

  @override
  String get filterReceived => 'Réceptionnées';

  @override
  String get noRequestFound => 'Aucune demande trouvée.';

  @override
  String get labelQuantity => 'Quantité';

  @override
  String periodLine(String start, String end) {
    return 'Période : $start → $end';
  }

  @override
  String get actionMarkPaid => 'Marquer payée';

  @override
  String get actionPrintNormalized => 'Imprimer normalisée';

  @override
  String get filterAllInvoices => 'Tous';

  @override
  String get filterPaid => 'Payées';

  @override
  String get filterUnpaid => 'Non payées';

  @override
  String get noInvoiceFound => 'Aucune facture trouvée.';

  @override
  String get searchClientOrRoom => 'Recherche client / chambre';

  @override
  String get roomInvoicesListTitle => 'Liste des factures chambres';

  @override
  String get errInvoiceDatesInvalid =>
      'Les dates de la facture sont invalides.';

  @override
  String get errInvoiceNotFiscalizedYet =>
      'Cette facture n’est pas encore fiscalisée.';

  @override
  String get errSetIfuFirst =>
      'Renseignez d’abord l’IFU de l’établissement (console admin).';

  @override
  String get errInvoiceAlreadyFiscalized =>
      'Cette facture est déjà fiscalisée.';

  @override
  String get managerWorkspaceSubtitle => 'Espace de supervision et validation';

  @override
  String get moduleStocksTitle => 'Stocks & Approvisionnements';

  @override
  String get moduleStocksSubtitle =>
      'Stocks, demandes, seuils, articles et approvisionnements';

  @override
  String get actionStockRequests => 'Demandes stock';

  @override
  String get lowStockTitle => 'Stocks faibles';

  @override
  String get actionSupplyRestaurant => 'Approvisionner Restaurant';

  @override
  String get actionSupplyBar => 'Approvisionner Bar';

  @override
  String get actionSupplyHotel => 'Approvisionner Hôtel';

  @override
  String get directSupplyRestaurantTitle =>
      'Approvisionnement direct - Restaurant';

  @override
  String get directSupplyBarTitle => 'Approvisionnement direct - Bar';

  @override
  String get directSupplyHotelTitle => 'Approvisionnement direct - Hôtel';

  @override
  String get actionItemRegistry => 'Registre des articles';

  @override
  String get actionCreateStock => 'Créer un stock';

  @override
  String get moduleServersTitle => 'Serveurs & Encaissements';

  @override
  String get moduleServersSubtitle => 'Serveurs, versements et encaissements';

  @override
  String get actionValidateHandovers => 'Valider les versements';

  @override
  String get actionServerCollections => 'Encaissements serveurs';

  @override
  String get moduleBillingRoomsTitle => 'Facturation & Chambres';

  @override
  String get moduleBillingRoomsSubtitle =>
      'Factures, chambres et versement comptable';

  @override
  String get actionRoomBilling => 'Facturation chambres';

  @override
  String get actionInvoicesList => 'Liste des factures';

  @override
  String get actionAccountingTransfer => 'Versement compta';

  @override
  String get moduleMenuTitle => 'Menu & Exploitation';

  @override
  String get moduleMenuSubtitle => 'Gestion du menu restaurant et bar';

  @override
  String get actionManageMenu => 'Gérer le menu';

  @override
  String get createStockPageTitle => 'Création stock gérante';

  @override
  String get createStockTitle => 'Création / import de stock';

  @override
  String get createStockSubtitle =>
      'Choisissez un article actif, saisissez la quantité, ou importez plusieurs lignes depuis un fichier.';

  @override
  String get manualEntry => 'Saisie manuelle';

  @override
  String get noActiveItemFound =>
      'Aucun article actif trouvé dans stock_items.';

  @override
  String get labelStockItem => 'Article de stock';

  @override
  String get hintQuantityExample => 'Ex. 25';

  @override
  String get errQuantityRequired => 'Veuillez saisir une quantité';

  @override
  String get errQuantityMustBeInteger => 'La quantité doit être un entier.';

  @override
  String get errQuantityNegative => 'La quantité ne peut pas être négative';

  @override
  String get errChooseAnItem => 'Veuillez choisir un article';

  @override
  String get errSelectAnItem => 'Veuillez sélectionner un article.';

  @override
  String get stockSavedSuccess => 'Stock enregistré avec succès.';

  @override
  String errLoadItemsFailed(String error) {
    return 'Erreur chargement articles : $error';
  }

  @override
  String errSaveFailed(String error) {
    return 'Erreur lors de l’enregistrement : $error';
  }

  @override
  String errImportFailed(String error) {
    return 'Erreur import : $error';
  }

  @override
  String get importCancelled => 'Import annulé.';

  @override
  String get errFileUnreadable => 'Impossible de lire le fichier sélectionné.';

  @override
  String get errUnsupportedFormat =>
      'Format non supporté. Utilise CSV ou XLSX.';

  @override
  String get errNoUsableRow => 'Aucune ligne exploitable trouvée.';

  @override
  String get errItemNameMissing => 'nom d’article manquant';

  @override
  String get errQuantityInvalidShort => 'quantité invalide';

  @override
  String errItemNotInStockItems(String name) {
    return 'article « $name » introuvable dans stock_items';
  }

  @override
  String lineErrorLine(int line, String message) {
    return 'Ligne $line: $message';
  }

  @override
  String importSuccessCount(int count) {
    return '$count stock(s) importé(s) avec succès.';
  }

  @override
  String importPartialResult(int success, int errors) {
    return '$success import(s) réussi(s), $errors erreur(s).';
  }

  @override
  String importedCountShort(int count) {
    return '$count stock(s) importé(s).';
  }

  @override
  String get importingInProgress => 'Import en cours...';

  @override
  String get actionImportCsvExcel => 'Importer CSV / Excel';

  @override
  String get importRecommendedFormat => 'Format d’import recommandé';

  @override
  String get expectedColumns => 'Colonnes attendues :';

  @override
  String get exampleLabel => 'Exemple :';

  @override
  String get importExampleRow1 => 'Eau minérale | 48';

  @override
  String get importExampleRow2 => 'Riz local | 120';

  @override
  String get fieldsSavedInStoreStocks => 'Champs enregistrés dans store_stocks';

  @override
  String storeLine(String store) {
    return 'Store : $store';
  }

  @override
  String unitLine(String unit) {
    return 'Unité : $unit';
  }

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionClose => 'Fermer';

  @override
  String get confirmationTitle => 'Confirmation';

  @override
  String get labelClient => 'Client';

  @override
  String get labelClientIfu => 'IFU client';

  @override
  String get labelAddress => 'Adresse';

  @override
  String get labelRoomWord => 'Chambre';

  @override
  String get labelEntry => 'Entrée';

  @override
  String get labelExit => 'Sortie';

  @override
  String get labelNights => 'Nuitées';

  @override
  String get labelPricePerNightShort => 'Prix / nuit';

  @override
  String get labelExtras => 'Extras';

  @override
  String get labelServices => 'Services';

  @override
  String get labelPaymentStatus => 'Statut paiement';

  @override
  String get labelFiscalStatus => 'Statut fiscal';

  @override
  String get statusCertified => 'Certifiée';

  @override
  String get statusNotCertified => 'Non certifiée';

  @override
  String get labelMecefCode => 'Code MECeF';

  @override
  String get labelCounters => 'Compteurs';

  @override
  String get labelFiscalDate => 'Date fiscale';

  @override
  String get paymentBank => 'Banque';

  @override
  String get paymentCheque => 'Chèque';

  @override
  String get aibNone => 'Aucun AIB';

  @override
  String get errInvoiceDatesInvalidShort => 'Dates de facture invalides.';

  @override
  String get actionFiscalizeWithCertilink => 'Fiscaliser avec Certilink';

  @override
  String get roomInvoiceDetailTitle => 'Détail facture chambre';

  @override
  String get errInvoiceNotCertifiedYet =>
      'Cette facture n’est pas encore certifiée.';

  @override
  String get errInvoiceAlreadyCertified => 'Cette facture est déjà certifiée.';

  @override
  String invoiceCertifiedWithCode(String code) {
    return 'Facture certifiée avec Certilink Code MECeF : $code';
  }

  @override
  String get tooltipPrintClassic => 'Impression classique';

  @override
  String get tooltipPrintNormalized => 'Impression normalisée';

  @override
  String get actionPrintClassicMode => 'Imprimer en mode classique';

  @override
  String get actionPrintNormalizedMode => 'Imprimer en mode normalisé';

  @override
  String get roomBillingTitle => 'Facturation Chambre';

  @override
  String get errSaveInvoiceFirst => 'Veuillez d’abord enregistrer la facture.';

  @override
  String get errFiscalizeFirst =>
      'Cette facture n’est pas encore fiscalisée. Fiscalisez-la d’abord.';

  @override
  String get errFillRoomAndPeriodFirst =>
      'Veuillez d’abord renseigner la chambre et la période.';

  @override
  String get extrasDetailsTitle => 'Détails Extras';

  @override
  String get noConsumptionFound => 'Aucune consommation trouvée.';

  @override
  String extrasTotalLine(String amount) {
    return 'Total extras : $amount FCFA';
  }

  @override
  String get errRequiredFieldsMissing => 'Champs obligatoires manquants';

  @override
  String get errStartBeforeEnd =>
      'La date d’entrée doit être antérieure ou égale à la date de sortie.';

  @override
  String get errInvalidNightPrice => 'Prix de nuitée invalide';

  @override
  String get errInvoiceAlreadyExistsForPeriod =>
      'Une facture existe déjà pour cette chambre et cette période.';

  @override
  String get invoiceCreatedSuccess =>
      'Facture créée avec succès. Vous pouvez maintenant l’encaisser ou la fiscaliser.';

  @override
  String errSaveInvoiceFailed(String error) {
    return 'Erreur lors de l’enregistrement de la facture : $error';
  }

  @override
  String get actionChoose => 'Choisir';

  @override
  String get paymentDialogTitle => 'Encaissement';

  @override
  String get clientInfoTitle => 'Informations client';

  @override
  String get labelClientAddress => 'Adresse client';

  @override
  String get labelClientPhone => 'Téléphone client';

  @override
  String startLine(String date) {
    return 'Début : $date';
  }

  @override
  String endLine(String date) {
    return 'Fin : $date';
  }

  @override
  String get labelOtherServices => 'Autres services';

  @override
  String get actionSaveInvoice => 'Enregistrer facture';

  @override
  String get actionSearchInvoice => 'Rechercher une facture';

  @override
  String get actionNewInvoice => 'Nouvelle facture';

  @override
  String get summaryTitle => 'Résumé';

  @override
  String get labelBarRestoConsumptions => 'Consommations bar/resto';

  @override
  String get invoiceAlreadyFiscalizedLabel => 'Facture déjà fiscalisée';

  @override
  String get invoiceSavedAndFiscalized => 'Facture enregistrée et fiscalisée.';

  @override
  String get invoiceSavedReady =>
      'Facture enregistrée. Prête à être encaissée ou fiscalisée.';

  @override
  String get menuManagementTitle => 'Gestion du menu';

  @override
  String get errItemNameRequired => 'Veuillez renseigner le nom de l’article.';

  @override
  String get errCategoryRequired => 'Veuillez renseigner la catégorie.';

  @override
  String get errValidPriceRequired => 'Veuillez renseigner un prix valide.';

  @override
  String get errItemMustBelongToBarOrKitchen =>
      'L’article doit appartenir au bar, à la cuisine, ou aux deux.';

  @override
  String get errAtLeastOneIngredient =>
      'Veuillez définir au moins un ingrédient pour cet article.';

  @override
  String get menuItemSavedSuccess => 'Article enregistré avec succès.';

  @override
  String get photoSaved => 'Photo enregistrée.';

  @override
  String errPhotoSaveFailed(String error) {
    return 'Erreur enregistrement photo : $error';
  }

  @override
  String get addIngredientTitle => 'Ajouter un ingrédient';

  @override
  String get labelQuantityPerUnitSold => 'Quantité consommée par unité vendue';

  @override
  String get errFileEmptyOrUnreadable => 'Fichier vide ou illisible.';

  @override
  String get errUnsupportedFormatExcel =>
      'Format non supporté. Utilisez CSV ou Excel.';

  @override
  String get errNoUsableRowInFile =>
      'Aucune ligne exploitable trouvée dans le fichier.';

  @override
  String get rowSkippedInvalidFields =>
      'Ligne ignorée : nom/catégorie/prix invalide(s).';

  @override
  String rowSkippedNoDepartment(String name) {
    return 'Article « $name » ignoré : ni bar ni cuisine.';
  }

  @override
  String rowSkippedWithReason(String reason) {
    return 'Ligne ignorée : $reason';
  }

  @override
  String importedItemsCount(int count) {
    return '$count article(s) importé(s)';
  }

  @override
  String skippedSuffix(int count) {
    return ' • $count ignoré(s)';
  }

  @override
  String get importResultTitle => 'Résultat de l’import';

  @override
  String get departmentKitchenAndBar => 'Cuisine + Bar';

  @override
  String get newItemTitle => 'Nouvel article';

  @override
  String get labelItemName => 'Nom de l’article';

  @override
  String get helperNewOrExistingDish =>
      'Tapez un nouveau nom, ou choisissez un plat existant';

  @override
  String get helperExistingDishPriceOnly =>
      'Plat existant : seul le prix est modifiable';

  @override
  String get tooltipNewDish => 'Nouveau plat';

  @override
  String get labelCompositionFree => 'Composition (texte libre)';

  @override
  String get labelCategory => 'Catégorie';

  @override
  String get hintCategoryExample => 'Ex: boisson, plat, dessert, snack...';

  @override
  String get labelPrice => 'Prix';

  @override
  String get dishPhotoTitle => 'Photo du plat';

  @override
  String get labelAvailable => 'Disponible';

  @override
  String get labelForKitchen => 'Destiné à la cuisine';

  @override
  String get labelForBar => 'Destiné au bar';

  @override
  String get labelFreeAccompaniment =>
      'Donne droit à un accompagnement gratuit';

  @override
  String get labelFreeAccompanimentHint =>
      'Le client pourra choisir 1 accompagnement offert.';

  @override
  String get recipeIngredientsTitle => 'Recette / ingrédients';

  @override
  String get noIngredientAdded => 'Aucun ingrédient ajouté.';

  @override
  String get actionImportExcelCsv => 'Importer Excel / CSV';

  @override
  String get acceptedColumnsHint =>
      'Colonnes acceptées : nom, composition, catégorie, prix, disponible, cuisine, bar.';

  @override
  String get noItemRecorded => 'Aucun article enregistré.';

  @override
  String get menuItemsTitle => 'Articles du menu';

  @override
  String confirmDeleteItem(String name) {
    return 'Supprimer l’article « $name » ?';
  }

  @override
  String ingredientsCount(int count) {
    return '$count ingrédient(s)';
  }

  @override
  String get errAccessDenied => 'Accès refusé.';

  @override
  String get accountingTitle => 'Comptabilité';

  @override
  String get accountantWorkspaceSubtitle =>
      'Réception, contrôle, dépenses, soldes et rapports';

  @override
  String get moduleReceptionsTitle => 'Réceptions & Contrôles';

  @override
  String get moduleReceptionsSubtitle =>
      'Versements serveurs, gérante et factures non versées';

  @override
  String get actionReceiveHandovers => 'Réception des versements';

  @override
  String get actionReceiveHandoversSubtitle =>
      'Contrôler les versements des serveurs';

  @override
  String get actionManagerReception => 'Réception gérante';

  @override
  String get actionManagerReceptionSubtitle =>
      'Recevoir les versements transmis par la gérante';

  @override
  String get actionTrackUntransferred => 'Suivi non versés';

  @override
  String get actionTrackUntransferredSubtitle =>
      'Suivre les factures non encore versées';

  @override
  String get moduleExpensesBalancesTitle => 'Dépenses & Soldes';

  @override
  String get moduleExpensesBalancesSubtitle =>
      'Dépenses courantes et soldes précédents';

  @override
  String get expensesTitle => 'Dépenses';

  @override
  String get actionExpensesSubtitle => 'Enregistrer et consulter les dépenses';

  @override
  String get previousBalancesTitle => 'Soldes précédents';

  @override
  String get actionPreviousBalancesSubtitle =>
      'Gérer les soldes d’ouverture ou antérieurs';

  @override
  String get moduleReportsTitle => 'Rapports & Points';

  @override
  String get moduleReportsSubtitle =>
      'Synthèse hebdomadaire et suivi comptable';

  @override
  String get weeklyReportTitle => 'Point hebdomadaire';

  @override
  String get actionWeeklyReportSubtitle =>
      'Produire le point hebdomadaire de comptabilité';

  @override
  String get expenseSaved => 'Dépense enregistrée.';

  @override
  String get newExpenseTitle => 'Nouvelle dépense';

  @override
  String get labelDesignation => 'Libellé';

  @override
  String get labelAccountType => 'Type de compte';

  @override
  String get expenseHistoryTitle => 'Historique des dépenses';

  @override
  String get noExpenseRecorded => 'Aucune dépense enregistrée.';

  @override
  String enteredByLine(String name) {
    return 'Saisi par : $name';
  }

  @override
  String get previousBalanceSaved => 'Solde précédent enregistré.';

  @override
  String get newPreviousBalanceTitle => 'Nouveau solde précédent';

  @override
  String get balanceHistoryTitle => 'Historique des soldes';

  @override
  String get noPreviousBalance => 'Aucun solde précédent.';

  @override
  String get untransferredFullTitle =>
      'Suivi factures / encaissements non versés';

  @override
  String get noUntransferredInvoice => 'Aucune facture non versée.';

  @override
  String transferStatusLine(String status) {
    return 'Statut transfert : $status';
  }

  @override
  String get statusNotDeclared => 'non déclaré';

  @override
  String get untransferredServerCollections =>
      'Encaissements serveurs non versés';

  @override
  String get noUntransferredServerCollection =>
      'Aucun encaissement serveur non versé.';

  @override
  String errWeeklySummaryLoadFailed(String error) {
    return 'Erreur chargement point hebdo : $error';
  }

  @override
  String errPrintFailed(String error) {
    return 'Erreur impression : $error';
  }

  @override
  String get handoversReceived => 'Versements reçus';

  @override
  String get labelOutflows => 'Sorties';

  @override
  String get theoreticalBalance => 'Solde théorique';

  @override
  String get noHandoverAwaitingReception =>
      'Aucun versement en attente de réception.';

  @override
  String get receptionConfirmed => 'Réception confirmée.';

  @override
  String get actionConfirmReception => 'Confirmer réception';

  @override
  String get receptionValidatedQuitusPrinted =>
      'Réception validée et quitus imprimé.';

  @override
  String get managerHandoverReceptionTitle => 'Réception versements gérante';

  @override
  String get pendingHandoversTitle => 'Versements en attente';

  @override
  String serversRoomsCounts(int servers, int rooms) {
    return 'Serveurs: $servers • Chambres: $rooms';
  }

  @override
  String get noHandoverReceived => 'Aucun versement reçu.';

  @override
  String receivedByLine(String name) {
    return 'Reçu par : $name';
  }

  @override
  String get stockItemsManagementTitle => 'Gestion des articles de stock';

  @override
  String get labelName => 'Nom';

  @override
  String get labelUnit => 'Unité';

  @override
  String get labelStore => 'Store';

  @override
  String get labelActiveItem => 'Article actif';

  @override
  String get errRequiredField => 'Champ obligatoire';

  @override
  String get hintItemNameExample => 'Ex. Eau minérale 50cl';

  @override
  String get hintCategoryDrink => 'Ex. Boisson';

  @override
  String get hintUnitExamples => 'Ex. bouteille, kg, carton';

  @override
  String get excelExpectedFormat => 'Format Excel attendu';

  @override
  String get recommendedColumns => 'Colonnes recommandées :';

  @override
  String get exampleRowLabel => 'Exemple de ligne :';

  @override
  String get stockImportExampleRow =>
      'Eau minérale | Boisson | bouteille | bar | true';

  @override
  String get errCannotReadFile =>
      'Impossible de lire le fichier. Sélectionne un fichier valide.';

  @override
  String get errUnsupportedFormatXlsx =>
      'Format non supporté. Utilise .xlsx ou .xls';

  @override
  String get errNoValidRowAfterNormalization =>
      'Aucune ligne valide après normalisation. Vérifie les colonnes.';

  @override
  String get errXlsNotSupportedWeb =>
      'Le support .xls hérité n’est pas prévu ici pour Flutter Web. Utilise plutôt un fichier .xlsx sur le web.';

  @override
  String importedItemsSuccessCount(int count) {
    return '$count article(s) importé(s) avec succès.';
  }

  @override
  String get excelImportTitle => 'Import Excel';

  @override
  String get excelImportStockDescription =>
      'Le fichier peut être en .xlsx ou .xls. Chaque ligne valide sera ajoutée dans stock_items de cet établissement avec un id Firestore automatique.';

  @override
  String get actionImportFromExcel => 'Importer depuis Excel';

  @override
  String get kitchenTitle => 'Cuisine';

  @override
  String establishmentKitchenTitle(String name) {
    return '$name - Cuisine';
  }

  @override
  String get newKitchenOrderTitle => 'Nouvelle commande cuisine';

  @override
  String orderNumberLine(String number) {
    return 'Commande $number';
  }

  @override
  String orderNumberWithClient(String number, String client) {
    return 'Commande $number - $client';
  }

  @override
  String get kitchenOrdersFollowUp =>
      'Suivi des commandes cuisine de tous les serveurs';

  @override
  String get kitchenStockManagementTitle => 'Gestion stock cuisine';

  @override
  String get stockManagementCardTitle => 'Gestion de Stocks';

  @override
  String get stockManagementCardSubtitleMobile =>
      'Composer menu • Ajouter article\nDéclarer consommation • Demander approvisionnement';

  @override
  String get stockManagementCardSubtitle =>
      'Composer menu • Ajouter article • Déclarer consommation • Demander approvisionnement';

  @override
  String get stockConsultationCardTitle => 'Consulter Stocks';

  @override
  String get stockConsultationCardSubtitle =>
      'Voir les stocks • Confirmer réception • Historique stocks';

  @override
  String get actionComposeMenu => 'Composer menu';

  @override
  String get actionAddArticle => 'Ajouter article';

  @override
  String get actionDeclareConsumption => 'Déclarer une consommation';

  @override
  String get actionRequestSupply => 'Demander un approvisionnement';

  @override
  String get actionViewStocks => 'Voir les stocks';

  @override
  String get actionConfirmAReception => 'Confirmer une réception';

  @override
  String get actionStockHistory => 'Historique stocks';

  @override
  String get stockOutRestaurantTitle => 'Sortie de stock - Restaurant';

  @override
  String get reasonKitchenPreparation => 'Préparation cuisine';

  @override
  String get supplyRequestRestaurantTitle =>
      'Demande approvisionnement - Restaurant';

  @override
  String get stockRestaurantTitle => 'Stock Restaurant';

  @override
  String get receptionsToConfirmRestaurantTitle =>
      'Réceptions à confirmer - Restaurant';

  @override
  String get movementHistoryRestaurantTitle =>
      'Historique mouvements - Restaurant';

  @override
  String get kitchenOrderReadyTitle => 'Commande cuisine prête';

  @override
  String kitchenOrderReadyBody(String client) {
    return 'La commande de $client est prête en cuisine.';
  }

  @override
  String get clientGeneric => 'client';

  @override
  String roomLowercaseLine(String number) {
    return 'la chambre $number';
  }

  @override
  String tableLowercaseLine(String number) {
    return 'la table $number';
  }

  @override
  String get noKitchenItems => 'Aucun article cuisine.';

  @override
  String accompanimentPlainLine(String name) {
    return 'Accompagnement : $name';
  }

  @override
  String get actionServed => 'Servi';

  @override
  String get statusReadyPlural => 'Prêtes';

  @override
  String get errPickKitchenItem => 'Veuillez choisir un article cuisine.';

  @override
  String get errPickAllIngredients => 'Veuillez choisir tous les ingrédients.';

  @override
  String get errQuantityMustBePositiveInteger =>
      'Chaque quantité doit être un nombre entier positif.';

  @override
  String get kitchenIngredientsSaved =>
      'Ingrédients cuisine enregistrés avec succès.';

  @override
  String dishCreatedCompose(String name) {
    return 'Plat « $name » créé. Vous pouvez maintenant le composer.';
  }

  @override
  String get errEmptyExcelFile => 'Fichier Excel vide.';

  @override
  String get errNoDataRow => 'Le fichier ne contient aucune ligne de données.';

  @override
  String get importReportTitle => 'Rapport d’import';

  @override
  String importedRecipesCount(int count) {
    return '$count recette(s) importée(s)';
  }

  @override
  String ignoredRowsCount(int count) {
    return '$count ligne(s) ignorée(s) (incomplètes).';
  }

  @override
  String get dishesNotFound => 'Plats non trouvés :';

  @override
  String get ingredientsNotFound => 'Ingrédients non trouvés :';

  @override
  String get checkNamesMatchApp =>
      'Vérifiez que ces noms correspondent exactement à ceux saisis dans l’application.';

  @override
  String get kitchenItemsCompositionTitle => 'Composition articles cuisine';

  @override
  String errMenuItemsStream(String error) {
    return 'Erreur menuItems : $error';
  }

  @override
  String errStockItemsStream(String error) {
    return 'Erreur stock_items : $error';
  }

  @override
  String get createNewDishTitle => 'Créer un nouveau plat';

  @override
  String get priceSetByManager => 'Le prix sera fixé par la gérante.';

  @override
  String get labelDishName => 'Nom du plat';

  @override
  String get hintDishExample => 'Ex : Poulet braisé';

  @override
  String get labelKitchenItem => 'Article cuisine';

  @override
  String get labelCompositionOptional => 'Composition (optionnel)';

  @override
  String get hintCompositionEmpty =>
      'Laissez vide pour afficher la liste des ingrédients';

  @override
  String get kitchenIngredientsTitle => 'Ingrédients cuisine';

  @override
  String get actionValidateKitchenComposition =>
      'Valider la composition cuisine';

  @override
  String get defineKitchenIngredientsTitle => 'Définir les ingrédients cuisine';

  @override
  String get actionImportExcel => 'Importer Excel';

  @override
  String get oneRowPerIngredient =>
      'Une ligne par ingrédient (le nom du plat est répété).';

  @override
  String get columnsLabel => 'Colonnes :';

  @override
  String get recipeImportExampleRows =>
      'Poulet braisé | Poulet | 1\nPoulet braisé | Oignon | 2';

  @override
  String get namesMustExistInApp =>
      'Les noms des plats et ingrédients doivent déjà exister dans l’application.';

  @override
  String labelIngredientIndex(int index) {
    return 'Ingrédient $index';
  }

  @override
  String get errChooseIngredient => 'Choisissez un ingrédient';

  @override
  String get errInvalidQuantity => 'Quantité invalide';

  @override
  String get tooltipRemoveLine => 'Retirer cette ligne';

  @override
  String get barTitle => 'Bar';

  @override
  String establishmentBarTitle(String name) {
    return '$name - Bar';
  }

  @override
  String get newBarOrderTitle => 'Nouvelle commande bar';

  @override
  String get barOrdersFollowUp =>
      'Suivi des commandes bar de tous les serveurs';

  @override
  String get barStockTitle => 'Stock Bar';

  @override
  String get actionSupply => 'Approvisionnement';

  @override
  String get supplyRequestBarTitle => 'Demande approvisionnement Bar';

  @override
  String get actionStockOut => 'Sortie Stock';

  @override
  String get stockOutBarTitle => 'Sortie Stock Bar';

  @override
  String get reasonBarConsumption => 'Consommation Bar';

  @override
  String get actionMovements => 'Mouvements';

  @override
  String get movementHistoryBarTitle => 'Historique mouvements Bar';

  @override
  String get actionReceptions => 'Réceptions';

  @override
  String get receptionsBarTitle => 'Réceptions Bar';

  @override
  String get actionBarItems => 'Articles Bar';

  @override
  String get actionIngredients => 'Ingrédients';

  @override
  String errBarItemsLoad(String error) {
    return 'Erreur articles bar : $error';
  }

  @override
  String get barStockItemsTitle => 'Articles de stock - Bar';

  @override
  String get newBarItemTitle => 'Nouvel article du bar';

  @override
  String get storeAutoSetToBar =>
      'Le store est automatiquement défini sur : bar';

  @override
  String get errItemAlreadyExists => 'Cet article existe déjà.';

  @override
  String get barItemSavedSuccess => 'Article du bar enregistré avec succès.';

  @override
  String get actionSaveItem => 'Enregistrer l’article';

  @override
  String get hintBarItemNameExample => 'Ex. Coca-Cola 33cl';

  @override
  String get hintBarCategoryExample => 'Ex. Boisson gazeuse';

  @override
  String get hintBarUnitExamples => 'Ex. bouteille, canette, carton';

  @override
  String cocktailCreatedCompose(String name) {
    return 'Cocktail « $name » créé. Vous pouvez maintenant le composer.';
  }

  @override
  String get barIngredientsSaved =>
      'Ingrédients du cocktail enregistrés avec succès.';

  @override
  String importedCompositionsCount(int count) {
    return '$count composition(s) importée(s)';
  }

  @override
  String get cocktailsNotFound => 'Cocktails / articles non trouvés :';

  @override
  String get oneRowPerBarIngredient =>
      'Une ligne par ingrédient (le nom du cocktail est répété).';

  @override
  String get cocktailImportExampleRows =>
      'Mojito | Rhum | 1\nMojito | Menthe | 1';

  @override
  String get barNamesMustExistInApp =>
      'Les noms des cocktails et ingrédients doivent déjà exister dans l’application.';

  @override
  String get barCocktailsCompositionTitle => 'Composition cocktails bar';

  @override
  String get createNewCocktailTitle => 'Créer un nouveau cocktail';

  @override
  String get labelCocktailName => 'Nom du cocktail';

  @override
  String get hintCocktailExample => 'Ex : Mojito';

  @override
  String get labelBarItemOrCocktail => 'Cocktail / article du bar';

  @override
  String get errPickBarItem => 'Veuillez choisir un article du bar.';

  @override
  String get barIngredientsTitle => 'Ingrédients du bar';

  @override
  String get actionValidateCocktailComposition =>
      'Valider la composition du cocktail';

  @override
  String get defineCocktailIngredientsTitle =>
      'Définir les ingrédients des cocktails';

  @override
  String get cocktailPhotoTitle => 'Photo du cocktail';

  @override
  String get errPickCocktailOrBarItem =>
      'Veuillez choisir un cocktail ou article du bar.';

  @override
  String get hygieneServiceTitle => 'Service Hygiène';

  @override
  String get butlerHygieneLeadTitle => 'Majordome / Chef service hygiène';

  @override
  String get butlerHygieneLeadSubtitle =>
      'Pilote la préparation des chambres, l’utilisation des produits et les demandes de réapprovisionnement.';

  @override
  String get actionDailyHygiene => 'Hygiène journalière';

  @override
  String get actionAddHotelItem => 'Ajouter article hôtel';

  @override
  String get supplyRequestHotelTitle => 'Demande approvisionnement - Hôtel';

  @override
  String get actionRequestSupplyShort => 'Demander approvisionnement';

  @override
  String get receptionsToConfirmHotelTitle => 'Réceptions à confirmer - Hôtel';

  @override
  String get actionValidateReception => 'Valider réception';

  @override
  String get hotelStockItemsTitle => 'Articles de stock - Hôtel';

  @override
  String get newHotelItemTitle => 'Nouvel article hôtel';

  @override
  String get storeAutoSetToHotel =>
      'Le store est automatiquement défini sur : hotel';

  @override
  String get hotelItemSavedSuccess => 'Article hôtel enregistré avec succès.';

  @override
  String get hintHotelItemNameExample => 'Ex. Serviette blanche';

  @override
  String get hintHotelCategoryExample => 'Ex. Linge, Hygiène, Chambre';

  @override
  String get hintHotelUnitExamples => 'Ex. pièce, carton, litre';

  @override
  String storeNameLine(String store) {
    return 'Magasin : $store';
  }

  @override
  String typeLine(String type) {
    return 'Type : $type';
  }

  @override
  String quantityUnitLine(String quantity, String unit) {
    return 'Quantité : $quantity $unit';
  }

  @override
  String reasonLine(String reason) {
    return 'Motif : $reason';
  }

  @override
  String byLine(String name) {
    return 'Par : $name';
  }

  @override
  String updatedAtLine(String date) {
    return 'Mis à jour : $date';
  }

  @override
  String get noMovementRecorded => 'Aucun mouvement enregistré.';

  @override
  String get noStockForStore => 'Aucun stock enregistré pour ce magasin.';

  @override
  String get labelStoreWord => 'Magasin';

  @override
  String get labelLastUpdate => 'Dernière mise à jour';

  @override
  String get actionTakePhoto => 'Prendre une photo';

  @override
  String get actionChooseFromGallery => 'Choisir dans la galerie';

  @override
  String errPhotoFailed(String error) {
    return 'Erreur photo : $error';
  }

  @override
  String get errSaveDishFirst =>
      'Enregistrez d’abord le plat, puis ajoutez sa photo.';

  @override
  String get errNoDataRowShort => 'Aucune ligne de données.';

  @override
  String rejectedRowMissingNameUnit(int line) {
    return 'Ligne $line : nom ou unité manquant.';
  }

  @override
  String rejectedRowUnknownCategory(int line, String name, String category) {
    return 'Ligne $line ($name) : catégorie inconnue « $category ».';
  }

  @override
  String rejectedRowUnknownStore(int line, String name, String store) {
    return 'Ligne $line ($name) : magasin inconnu « $store ».';
  }

  @override
  String createdItemsCount(int count) {
    return '$count article(s) créé(s)';
  }

  @override
  String ignoredEmptyRowsCount(int count) {
    return '$count ligne(s) vide(s) ignorée(s).';
  }

  @override
  String get existingItemsIgnored => 'Articles déjà existants (ignorés) :';

  @override
  String get rejectedRowsTitle => 'Lignes rejetées :';

  @override
  String get validCategoriesAndStoresHint =>
      'Catégories valides : voir la liste du formulaire. Magasins valides : Hôtel, Restaurant, Bar.';

  @override
  String get itemRegistryTitle => 'Registre des articles';

  @override
  String get itemRegistrySubtitle =>
      'Crée et organise les articles de stock avant approvisionnement.';

  @override
  String get registryImportExampleRows =>
      'Riz | Céréales | sac | restaurant\nCoca | Boissons | bouteille | Bar';

  @override
  String get registryImportHint =>
      'La catégorie doit exister dans la liste. Le magasin : Hôtel, Restaurant ou Bar.';

  @override
  String get hintItemNameExamples => 'Ex : Riz, Huile, Sucre';

  @override
  String get labelStoreField => 'Magasin';

  @override
  String get hintUnitExamplesLong => 'Ex : g, cl, bouteille, sachet, pièce';

  @override
  String get errUnitRequired => 'Veuillez saisir l’unité.';

  @override
  String get savedItemsTitle => 'Articles enregistrés';

  @override
  String get noItemRecordedYet => 'Aucun article enregistré pour le moment.';

  @override
  String get startCreatingItemsHint =>
      'Commence par créer des articles comme riz, huile, sucre, eau minérale, détergent, etc.';

  @override
  String get noClientRecordOrderless =>
      'Aucune fiche client.\nLa commande peut être envoyée sans client.';

  @override
  String get noClientMatchesSearch =>
      'Aucun client ne correspond à cette recherche.';

  @override
  String get accessDeniedTitle => 'Accès refusé';

  @override
  String get unauthorizedMessage =>
      'Votre rôle n’est pas reconnu, votre compte n’est pas rattaché à un établissement, ou vous n’avez pas accès à ce module.';

  @override
  String get orderStatusSent => 'Envoyée';

  @override
  String get orderStatusPartiallyCancelled => 'Partiellement annulée';

  @override
  String get orderStatusCancelled => 'Annulée';

  @override
  String get orderStatusStockError => 'Erreur stock';

  @override
  String get datesNotProvided => 'Dates non renseignées';

  @override
  String departureOnDate(String date) {
    return 'Départ le $date';
  }

  @override
  String arrivalOnDate(String date) {
    return 'Arrivée le $date';
  }

  @override
  String clientHistoryTitle(String name) {
    return 'Historique · $name';
  }

  @override
  String get staysSectionTitle => 'Séjours';

  @override
  String get noStayForClient => 'Aucun séjour enregistré pour ce client.';

  @override
  String get noOrderForClient => 'Aucune commande rattachée à ce client.';

  @override
  String get stayWordSingular => 'séjour';

  @override
  String get stayWordPlural => 'séjours';

  @override
  String get totalSpentExcludingCancellations =>
      'Total dépensé (hors annulations)';

  @override
  String get barRestaurantConsumptionsTitle => 'Consommations bar/restaurant';

  @override
  String get noEstablishmentAvailable => 'Aucun établissement disponible.';

  @override
  String get adminCreatedSuccess => 'Administrateur créé avec succès.';

  @override
  String errAdminCreationFailed(String error) {
    return 'Erreur création administrateur : $error';
  }

  @override
  String get createEstablishmentTitle => 'Créer un établissement';

  @override
  String get editEstablishmentTitle => 'Modifier l’établissement';

  @override
  String get establishmentCreatedSuccess => 'Établissement créé avec succès.';

  @override
  String errEstablishmentCreationFailed(String error) {
    return 'Erreur création établissement : $error';
  }

  @override
  String get establishmentUpdatedSuccess =>
      'Établissement modifié avec succès.';

  @override
  String errEstablishmentUpdateFailed(String error) {
    return 'Erreur modification établissement : $error';
  }

  @override
  String get saasAdministrationTitle => 'Administration SaaS';

  @override
  String get actionCreateAdmin => 'Créer administrateur';

  @override
  String get actionCreateEstablishment => 'Créer établissement';

  @override
  String get noEstablishmentRecorded => 'Aucun établissement enregistré.';

  @override
  String get establishmentInformation => 'Informations établissement';

  @override
  String get labelEstablishmentName => 'Nom de l’établissement';

  @override
  String get labelIfu => 'IFU';

  @override
  String get labelCity => 'Ville';

  @override
  String get labelCountry => 'Pays';

  @override
  String get labelEstablishmentType => 'Type d’établissement';

  @override
  String get typeHotelBarRestaurant => 'Hôtel + Bar + Restaurant';

  @override
  String get labelPlan => 'Plan';

  @override
  String get establishmentStatusActive => 'Actif';

  @override
  String get establishmentStatusSuspended => 'Suspendu';

  @override
  String get establishmentStatusTrial => 'Essai';

  @override
  String get enabledModules => 'Modules activés';

  @override
  String get firstEstablishmentAdmin => 'Premier administrateur établissement';

  @override
  String get labelAdminName => 'Nom administrateur';

  @override
  String get labelAdminEmail => 'Email administrateur';

  @override
  String get labelTemporaryPassword => 'Mot de passe temporaire';

  @override
  String get hintDefaultTemporaryPassword => 'Temp@123456 par défaut';

  @override
  String get globalConsoleTitle => 'Console globale Takapp SaaS';

  @override
  String get globalConsoleSubtitle =>
      'Créer les établissements, activer les modules, gérer les plans et initialiser les administrateurs.';

  @override
  String get unnamedEstablishment => 'Établissement sans nom';

  @override
  String idLine(String id) {
    return 'ID : $id';
  }

  @override
  String ifuLine(String ifu) {
    return 'IFU : $ifu';
  }

  @override
  String planChipLabel(String plan) {
    return 'Plan $plan';
  }

  @override
  String get createEstablishmentAdminTitle =>
      'Créer un administrateur d’établissement';

  @override
  String get labelEstablishment => 'Établissement';

  @override
  String get noStatus => 'Sans statut';
}
