import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Libellé du sélecteur de langue
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabel;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get commonLogout;

  /// Message d'erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String commonError(String error);

  /// Encadre un message d'erreur déjà traduit
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String errorPrefixed(String message);

  /// No description provided for @errUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue.'**
  String get errUnknown;

  /// No description provided for @errEstablishmentNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Établissement introuvable.'**
  String get errEstablishmentNotFound;

  /// No description provided for @errEstablishmentNotFoundReconnect.
  ///
  /// In fr, this message translates to:
  /// **'Établissement introuvable. Reconnectez-vous.'**
  String get errEstablishmentNotFoundReconnect;

  /// No description provided for @errAccountWithoutEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n’est rattaché à aucun établissement.'**
  String get errAccountWithoutEstablishment;

  /// No description provided for @errInvalidCredential.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get errInvalidCredential;

  /// No description provided for @errUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur introuvable.'**
  String get errUserNotFound;

  /// No description provided for @errWrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get errWrongPassword;

  /// No description provided for @errNetworkRequestFailed.
  ///
  /// In fr, this message translates to:
  /// **'Problème réseau. Vérifiez votre connexion.'**
  String get errNetworkRequestFailed;

  /// No description provided for @errPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé par les règles Firestore.'**
  String get errPermissionDenied;

  /// No description provided for @errResetEmailFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’envoyer le mail de réinitialisation.'**
  String get errResetEmailFailed;

  /// No description provided for @errOrderNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Commande introuvable.'**
  String get errOrderNotFound;

  /// No description provided for @errInvoiceNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Facture introuvable.'**
  String get errInvoiceNotFound;

  /// No description provided for @errReservationNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Réservation introuvable.'**
  String get errReservationNotFound;

  /// No description provided for @errRoomNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Chambre introuvable.'**
  String get errRoomNotFound;

  /// No description provided for @errClientNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Client introuvable.'**
  String get errClientNotFound;

  /// No description provided for @errStockNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Stock introuvable.'**
  String get errStockNotFound;

  /// No description provided for @errStockDocumentNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Document de stock introuvable.'**
  String get errStockDocumentNotFound;

  /// No description provided for @errHandoverNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Versement introuvable.'**
  String get errHandoverNotFound;

  /// No description provided for @errRequestNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Demande introuvable.'**
  String get errRequestNotFound;

  /// No description provided for @errClientNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client obligatoire.'**
  String get errClientNameRequired;

  /// No description provided for @errClientTypeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Type de client invalide.'**
  String get errClientTypeInvalid;

  /// No description provided for @errAmountMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être supérieur à 0.'**
  String get errAmountMustBePositive;

  /// No description provided for @errQuantityMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'La quantité doit être supérieure à 0.'**
  String get errQuantityMustBePositive;

  /// No description provided for @errAddAtLeastOneItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins un article.'**
  String get errAddAtLeastOneItem;

  /// No description provided for @errSelectAtLeastOneItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner au moins un article.'**
  String get errSelectAtLeastOneItem;

  /// No description provided for @errSelectPaymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un mode de paiement.'**
  String get errSelectPaymentMethod;

  /// No description provided for @errRoomNumberRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez préciser le numéro de chambre.'**
  String get errRoomNumberRequired;

  /// No description provided for @errTableNumberRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez préciser le numéro de table.'**
  String get errTableNumberRequired;

  /// No description provided for @errAddAtLeastOneUsedItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins un article utilisé.'**
  String get errAddAtLeastOneUsedItem;

  /// No description provided for @errSelectAtLeastOnePayment.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner au moins un paiement.'**
  String get errSelectAtLeastOnePayment;

  /// No description provided for @errSelectAtLeastOneOrderOrPayment.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner au moins une commande/paiement.'**
  String get errSelectAtLeastOneOrderOrPayment;

  /// No description provided for @errLabelRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un libellé.'**
  String get errLabelRequired;

  /// No description provided for @errStoreRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez préciser le magasin.'**
  String get errStoreRequired;

  /// No description provided for @errServerNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir le nom du serveur.'**
  String get errServerNameRequired;

  /// No description provided for @errPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir le numéro de téléphone.'**
  String get errPhoneRequired;

  /// No description provided for @errEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir une adresse email.'**
  String get errEmailRequired;

  /// No description provided for @errMinThresholdNegative.
  ///
  /// In fr, this message translates to:
  /// **'Le seuil minimum ne peut pas être négatif.'**
  String get errMinThresholdNegative;

  /// No description provided for @errCertilinkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur CertiLink'**
  String get errCertilinkError;

  /// No description provided for @errFiscalizationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de fiscalisation'**
  String get errFiscalizationFailed;

  /// No description provided for @errCertificationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de certification'**
  String get errCertificationFailed;

  /// No description provided for @errStockInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'Stock insuffisant pour {name}.'**
  String errStockInsufficient(String name);

  /// {name} porte le detail technique de l'echec
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l’enregistrement du serveur : {name}'**
  String errServerRegistrationFailed(String name);

  /// No description provided for @errFirebaseUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur Firebase introuvable après connexion.'**
  String get errFirebaseUserNotFound;

  /// No description provided for @errAccountDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est désactivé.'**
  String get errAccountDisabled;

  /// No description provided for @errUserProfileNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Le profil utilisateur est introuvable dans Firestore.'**
  String get errUserProfileNotFound;

  /// No description provided for @errInvalidMenuId.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant menu invalide.'**
  String get errInvalidMenuId;

  /// No description provided for @errInvalidDishId.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant du plat invalide.'**
  String get errInvalidDishId;

  /// No description provided for @errDishNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom du plat obligatoire.'**
  String get errDishNameRequired;

  /// No description provided for @errCocktailNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom du cocktail obligatoire.'**
  String get errCocktailNameRequired;

  /// No description provided for @errMenuItemNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Article menu introuvable : {name}'**
  String errMenuItemNotFound(String name);

  /// No description provided for @errNoRecipeDefined.
  ///
  /// In fr, this message translates to:
  /// **'L’article « {name} » n’a pas de recette définie.'**
  String errNoRecipeDefined(String name);

  /// No description provided for @errNoOrderSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande sélectionnée.'**
  String get errNoOrderSelected;

  /// No description provided for @errNoPaymentSelectedForHandover.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement sélectionné pour le versement.'**
  String get errNoPaymentSelectedForHandover;

  /// No description provided for @errOrderAlreadyCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande est déjà annulée.'**
  String get errOrderAlreadyCancelled;

  /// No description provided for @errStockAlreadyRestored.
  ///
  /// In fr, this message translates to:
  /// **'Le stock de cette commande a déjà été restitué.'**
  String get errStockAlreadyRestored;

  /// No description provided for @errCannotCancelPaidOrder.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’annuler une commande déjà encaissée.'**
  String get errCannotCancelPaidOrder;

  /// No description provided for @errCannotCancelPaidOrderItems.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’annuler des articles d’une commande déjà encaissée.'**
  String get errCannotCancelPaidOrderItems;

  /// No description provided for @errCannotCancelKitchenReady.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’annuler : la partie cuisine est déjà prête ou servie.'**
  String get errCannotCancelKitchenReady;

  /// No description provided for @errCannotCancelBarReady.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’annuler : la partie bar est déjà prête ou servie.'**
  String get errCannotCancelBarReady;

  /// No description provided for @errOrderHasNoItems.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande ne contient aucun article.'**
  String get errOrderHasNoItems;

  /// No description provided for @errNoItemsFoundInOrder.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article trouvé dans cette commande.'**
  String get errNoItemsFoundInOrder;

  /// No description provided for @errNoItemSelectedForCancellation.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article sélectionné pour annulation.'**
  String get errNoItemSelectedForCancellation;

  /// No description provided for @errKitchenNotReady.
  ///
  /// In fr, this message translates to:
  /// **'Commande {name} : cuisine non prête.'**
  String errKitchenNotReady(String name);

  /// No description provided for @errBarNotReady.
  ///
  /// In fr, this message translates to:
  /// **'Commande {name} : bar non prêt.'**
  String errBarNotReady(String name);

  /// No description provided for @errItemAlreadyCancelled.
  ///
  /// In fr, this message translates to:
  /// **'L’article « {name} » est déjà annulé.'**
  String errItemAlreadyCancelled(String name);

  /// No description provided for @errCannotCancelItemKitchenReady.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’annuler « {name} » : la cuisine est déjà prête ou servie.'**
  String errCannotCancelItemKitchenReady(String name);

  /// No description provided for @errCannotCancelItemBarReady.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’annuler « {name} » : le bar est déjà prêt ou servi.'**
  String errCannotCancelItemBarReady(String name);

  /// No description provided for @errInvalidQuantityForItem.
  ///
  /// In fr, this message translates to:
  /// **'Quantité invalide pour l’article « {name} ».'**
  String errInvalidQuantityForItem(String name);

  /// No description provided for @errInvalidQuantityInOrder.
  ///
  /// In fr, this message translates to:
  /// **'Quantité invalide dans la commande pour « {name} ».'**
  String errInvalidQuantityInOrder(String name);

  /// No description provided for @errInvalidRoomNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de chambre invalide.'**
  String get errInvalidRoomNumber;

  /// No description provided for @errRoomTypeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Type de chambre requis.'**
  String get errRoomTypeRequired;

  /// No description provided for @errRoomNumberAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Une chambre avec ce numéro existe déjà.'**
  String get errRoomNumberAlreadyExists;

  /// No description provided for @errInvalidRoomStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut de chambre invalide.'**
  String get errInvalidRoomStatus;

  /// No description provided for @errInvalidRoomTypeName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du type invalide.'**
  String get errInvalidRoomTypeName;

  /// No description provided for @errPricePerNightMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'Le prix par nuit doit être supérieur à 0.'**
  String get errPricePerNightMustBePositive;

  /// No description provided for @errRoomTypeAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Ce type de chambre existe déjà.'**
  String get errRoomTypeAlreadyExists;

  /// No description provided for @errReservationNotAwaitingArrival.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation n’est pas en attente d’arrivée.'**
  String get errReservationNotAwaitingArrival;

  /// No description provided for @errReservationNotInStay.
  ///
  /// In fr, this message translates to:
  /// **'Cette réservation n’est pas en cours de séjour.'**
  String get errReservationNotInStay;

  /// No description provided for @errRoomNoLongerAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Cette chambre n’est plus disponible.'**
  String get errRoomNoLongerAvailable;

  /// No description provided for @errRoomNotOfReservedType.
  ///
  /// In fr, this message translates to:
  /// **'Cette chambre n’est pas du type réservé.'**
  String get errRoomNotOfReservedType;

  /// No description provided for @errCheckOutAfterCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'La date de départ doit être après la date d’arrivée.'**
  String get errCheckOutAfterCheckIn;

  /// No description provided for @errNoRoomOfTypeAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chambre de ce type disponible sur cette période. Vous pouvez forcer la réservation si nécessaire.'**
  String get errNoRoomOfTypeAvailable;

  /// No description provided for @errInvalidStockItemMissingId.
  ///
  /// In fr, this message translates to:
  /// **'Article de stock invalide : itemId manquant.'**
  String get errInvalidStockItemMissingId;

  /// No description provided for @errItemNotFoundInStock.
  ///
  /// In fr, this message translates to:
  /// **'Article introuvable dans le stock.'**
  String get errItemNotFoundInStock;

  /// No description provided for @errNoItemDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article livré.'**
  String get errNoItemDelivered;

  /// No description provided for @errInvalidItemName.
  ///
  /// In fr, this message translates to:
  /// **'Nom article invalide.'**
  String get errInvalidItemName;

  /// No description provided for @errInvalidStore.
  ///
  /// In fr, this message translates to:
  /// **'Magasin invalide.'**
  String get errInvalidStore;

  /// No description provided for @errItemAlreadyExistsInStore.
  ///
  /// In fr, this message translates to:
  /// **'Cet article existe déjà dans ce magasin.'**
  String get errItemAlreadyExistsInStore;

  /// No description provided for @errItemNotFoundInStockFor.
  ///
  /// In fr, this message translates to:
  /// **'Article introuvable dans le stock : {name}'**
  String errItemNotFoundInStockFor(String name);

  /// No description provided for @errInvalidServerName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du serveur invalide.'**
  String get errInvalidServerName;

  /// No description provided for @errInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide.'**
  String get errInvalidEmail;

  /// No description provided for @errUserEmailAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Un utilisateur avec cet email existe déjà.'**
  String get errUserEmailAlreadyExists;

  /// No description provided for @errTotalAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant total invalide.'**
  String get errTotalAmountInvalid;

  /// No description provided for @errPaymentAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant de paiement invalide.'**
  String get errPaymentAmountInvalid;

  /// No description provided for @errEmptyPdfDocument.
  ///
  /// In fr, this message translates to:
  /// **'Document PDF vide.'**
  String get errEmptyPdfDocument;

  /// No description provided for @errFirestoreError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur Firestore : {name}'**
  String errFirestoreError(String name);

  /// No description provided for @errConsumptionLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des consommations : {name}'**
  String errConsumptionLoadFailed(String name);

  /// No description provided for @errStockNotFoundFor.
  ///
  /// In fr, this message translates to:
  /// **'Stock introuvable pour « {name} ».'**
  String errStockNotFoundFor(String name);

  /// No description provided for @errInconsistentUnit.
  ///
  /// In fr, this message translates to:
  /// **'Unité incohérente pour « {name} » : stock en « {stockUnit} » mais recette en « {recipeUnit} ».'**
  String errInconsistentUnit(String name, String stockUnit, String recipeUnit);

  /// No description provided for @errInsufficientStockDetailed.
  ///
  /// In fr, this message translates to:
  /// **'Stock insuffisant pour « {name} » : disponible {available}, requis {required}.'**
  String errInsufficientStockDetailed(
    String name,
    String available,
    String required,
  );

  /// No description provided for @navNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @serverNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Serveur introuvable.'**
  String get serverNotFound;

  /// No description provided for @noNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification.'**
  String get noNotifications;

  /// No description provided for @notificationFallbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notification'**
  String get notificationFallbackTitle;

  /// No description provided for @departmentKitchen.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get departmentKitchen;

  /// No description provided for @departmentBar.
  ///
  /// In fr, this message translates to:
  /// **'Bar'**
  String get departmentBar;

  /// No description provided for @labelTable.
  ///
  /// In fr, this message translates to:
  /// **'Table {number}'**
  String labelTable(String number);

  /// No description provided for @labelRoom.
  ///
  /// In fr, this message translates to:
  /// **'Chambre {number}'**
  String labelRoom(String number);

  /// No description provided for @labelBarClient.
  ///
  /// In fr, this message translates to:
  /// **'Client Bar'**
  String get labelBarClient;

  /// No description provided for @clientLine.
  ///
  /// In fr, this message translates to:
  /// **'Client : {client}'**
  String clientLine(String client);

  /// No description provided for @cancelPartialTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annulation partielle {orderNumber}'**
  String cancelPartialTitle(String orderNumber);

  /// No description provided for @cancelItemAlreadyCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Déjà annulé'**
  String get cancelItemAlreadyCancelled;

  /// No description provided for @cancelItemKitchenDone.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine déjà prête/servie'**
  String get cancelItemKitchenDone;

  /// No description provided for @cancelItemBarDone.
  ///
  /// In fr, this message translates to:
  /// **'Bar déjà prêt/servi'**
  String get cancelItemBarDone;

  /// No description provided for @cancelItemCancelable.
  ///
  /// In fr, this message translates to:
  /// **'Annulable'**
  String get cancelItemCancelable;

  /// No description provided for @cancelItemsDone.
  ///
  /// In fr, this message translates to:
  /// **'Articles annulés et stock restitué.'**
  String get cancelItemsDone;

  /// No description provided for @cancelLoadOrderError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement commande : {error}'**
  String cancelLoadOrderError(String error);

  /// No description provided for @cancelLoadItemsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement articles : {error}'**
  String cancelLoadItemsError(String error);

  /// No description provided for @cancelDepartmentLine.
  ///
  /// In fr, this message translates to:
  /// **'Département : {department}'**
  String cancelDepartmentLine(String department);

  /// No description provided for @cancelReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif d’annulation'**
  String get cancelReasonLabel;

  /// No description provided for @cancelAmountToDeduct.
  ///
  /// In fr, this message translates to:
  /// **'Montant à retrancher : {amount} FCFA'**
  String cancelAmountToDeduct(String amount);

  /// No description provided for @cancelInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Annulation en cours...'**
  String get cancelInProgress;

  /// No description provided for @cancelValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider l’annulation'**
  String get cancelValidate;

  /// No description provided for @myInvoicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes factures'**
  String get myInvoicesTitle;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get today;

  /// No description provided for @todayWithDate.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui ({date})'**
  String todayWithDate(String date);

  /// No description provided for @pickDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get pickDate;

  /// No description provided for @noInvoiceForDate.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture pour cette date.'**
  String get noInvoiceForDate;

  /// No description provided for @statusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Encaissée'**
  String get statusPaid;

  /// No description provided for @statusUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non encaissée'**
  String get statusUnpaid;

  /// No description provided for @statusFiscalized.
  ///
  /// In fr, this message translates to:
  /// **'Fiscalisée'**
  String get statusFiscalized;

  /// No description provided for @statusNotFiscalized.
  ///
  /// In fr, this message translates to:
  /// **'Non fiscalisée'**
  String get statusNotFiscalized;

  /// No description provided for @actionCollectInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser la facture'**
  String get actionCollectInvoice;

  /// No description provided for @actionPrintInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer facture'**
  String get actionPrintInvoice;

  /// No description provided for @actionFiscalize.
  ///
  /// In fr, this message translates to:
  /// **'Fiscaliser'**
  String get actionFiscalize;

  /// No description provided for @actionPrintFiscalizedInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer facture fiscalisée'**
  String get actionPrintFiscalizedInvoice;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get commonValidate;

  /// No description provided for @clientFallback.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get clientFallback;

  /// No description provided for @noOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande'**
  String get noOrders;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusPending;

  /// No description provided for @statusPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get statusPreparing;

  /// No description provided for @statusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get statusReady;

  /// No description provided for @statusServed.
  ///
  /// In fr, this message translates to:
  /// **'Servie'**
  String get statusServed;

  /// No description provided for @statusPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Récupérée'**
  String get statusPickedUp;

  /// No description provided for @columnPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get columnPending;

  /// No description provided for @columnPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get columnPreparing;

  /// No description provided for @columnReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêtes'**
  String get columnReady;

  /// No description provided for @suiviBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivi Bar'**
  String get suiviBarTitle;

  /// No description provided for @suiviCuisineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivi Cuisine'**
  String get suiviCuisineTitle;

  /// No description provided for @barItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles bar'**
  String get barItems;

  /// No description provided for @kitchenItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles cuisine'**
  String get kitchenItems;

  /// No description provided for @waiterLine.
  ///
  /// In fr, this message translates to:
  /// **'Serveur : {name}'**
  String waiterLine(String name);

  /// No description provided for @orderTotalLine.
  ///
  /// In fr, this message translates to:
  /// **'Total commande : {amount} FCFA'**
  String orderTotalLine(String amount);

  /// No description provided for @totalLine.
  ///
  /// In fr, this message translates to:
  /// **'Total : {amount} FCFA'**
  String totalLine(String amount);

  /// No description provided for @noteLine.
  ///
  /// In fr, this message translates to:
  /// **'Note : {note}'**
  String noteLine(String note);

  /// No description provided for @barItemsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur articles bar : {error}'**
  String barItemsError(String error);

  /// No description provided for @kitchenItemsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur articles cuisine : {error}'**
  String kitchenItemsError(String error);

  /// No description provided for @actionSetPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Passer en préparation'**
  String get actionSetPreparing;

  /// No description provided for @actionMarkReady.
  ///
  /// In fr, this message translates to:
  /// **'Marquer prête'**
  String get actionMarkReady;

  /// No description provided for @actionBackToPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Revenir en préparation'**
  String get actionBackToPreparing;

  /// No description provided for @actionRevert.
  ///
  /// In fr, this message translates to:
  /// **'Revenir'**
  String get actionRevert;

  /// No description provided for @actionPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Récupéré'**
  String get actionPickedUp;

  /// No description provided for @encaissementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaissement'**
  String get encaissementTitle;

  /// No description provided for @noUnpaidOrder.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande non encaissée.'**
  String get noUnpaidOrder;

  /// No description provided for @ordersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} commandes'**
  String ordersCount(String count);

  /// No description provided for @openedAt.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte à {time}'**
  String openedAt(String time);

  /// No description provided for @createdByLine.
  ///
  /// In fr, this message translates to:
  /// **'Créée par : {name}'**
  String createdByLine(String name);

  /// No description provided for @totalToCollect.
  ///
  /// In fr, this message translates to:
  /// **'Total à encaisser : {amount} FCFA'**
  String totalToCollect(String amount);

  /// No description provided for @actionShowAndPrint.
  ///
  /// In fr, this message translates to:
  /// **'Afficher et Imprimer'**
  String get actionShowAndPrint;

  /// No description provided for @actionCollect.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser'**
  String get actionCollect;

  /// No description provided for @invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide.'**
  String get invalidAmount;

  /// No description provided for @paymentRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Paiement enregistré avec succès.'**
  String get paymentRecorded;

  /// No description provided for @collectForTicket.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser — {label}'**
  String collectForTicket(String label);

  /// No description provided for @groupedOrders.
  ///
  /// In fr, this message translates to:
  /// **'{count} commandes regroupées : {numbers}'**
  String groupedOrders(String count, String numbers);

  /// No description provided for @paymentMethodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMethodLabel;

  /// No description provided for @amountReceived.
  ///
  /// In fr, this message translates to:
  /// **'Montant reçu'**
  String get amountReceived;

  /// No description provided for @roomConsumptionInvoiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facture Consommation Chambre'**
  String get roomConsumptionInvoiceTitle;

  /// No description provided for @noConsumptionForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune consommation trouvée pour cette période.'**
  String get noConsumptionForPeriod;

  /// No description provided for @roomNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro chambre'**
  String get roomNumberLabel;

  /// No description provided for @startDate.
  ///
  /// In fr, this message translates to:
  /// **'Date début'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In fr, this message translates to:
  /// **'Date fin'**
  String get endDate;

  /// No description provided for @actionShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get actionShow;

  /// No description provided for @pickBothDates.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir les dates de début et de fin.'**
  String get pickBothDates;

  /// No description provided for @startDateBeforeEndDate.
  ///
  /// In fr, this message translates to:
  /// **'La date de début doit être antérieure ou égale à la date de fin.'**
  String get startDateBeforeEndDate;

  /// No description provided for @handoverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Versement à la gérante'**
  String get handoverTitle;

  /// No description provided for @paymentsToHandOver.
  ///
  /// In fr, this message translates to:
  /// **'Paiements à verser'**
  String get paymentsToHandOver;

  /// No description provided for @selectionAmount.
  ///
  /// In fr, this message translates to:
  /// **'Sélection : {amount} FCFA'**
  String selectionAmount(String amount);

  /// No description provided for @noPaymentAvailableForHandover.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement disponible pour versement.'**
  String get noPaymentAvailableForHandover;

  /// No description provided for @handoverDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Versement déclaré avec succès.'**
  String get handoverDeclared;

  /// No description provided for @clearSelection.
  ///
  /// In fr, this message translates to:
  /// **'Vider la sélection'**
  String get clearSelection;

  /// No description provided for @declareHandover.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer le versement'**
  String get declareHandover;

  /// No description provided for @statusValidated.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get statusValidated;

  /// No description provided for @statusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get statusRejected;

  /// No description provided for @handoverHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des versements'**
  String get handoverHistory;

  /// No description provided for @noHandoverRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement enregistré.'**
  String get noHandoverRecorded;

  /// No description provided for @includedPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements inclus : {count}'**
  String includedPayments(String count);

  /// No description provided for @actionPrint.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get actionPrint;

  /// No description provided for @attachClientOptional.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher un client (optionnel)'**
  String get attachClientOptional;

  /// No description provided for @detachClient.
  ///
  /// In fr, this message translates to:
  /// **'Détacher le client'**
  String get detachClient;

  /// No description provided for @orderSentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Commande envoyée avec succès.'**
  String get orderSentSuccess;

  /// No description provided for @newOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande'**
  String get newOrderTitle;

  /// No description provided for @labelRestaurantClient.
  ///
  /// In fr, this message translates to:
  /// **'Client Restaurant'**
  String get labelRestaurantClient;

  /// No description provided for @labelHotelClient.
  ///
  /// In fr, this message translates to:
  /// **'Client Hôtel'**
  String get labelHotelClient;

  /// No description provided for @clientTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de client'**
  String get clientTypeLabel;

  /// No description provided for @tableNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de table'**
  String get tableNumberLabel;

  /// No description provided for @roomNumberFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de chambre'**
  String get roomNumberFieldLabel;

  /// No description provided for @noItemAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article disponible.'**
  String get noItemAvailable;

  /// No description provided for @actionAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get actionAdd;

  /// No description provided for @cartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cartTitle;

  /// No description provided for @noItemAdded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article ajouté.'**
  String get noItemAdded;

  /// No description provided for @actionSendOrder.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la commande'**
  String get actionSendOrder;

  /// No description provided for @subtotalLine.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total : {amount} FCFA'**
  String subtotalLine(String amount);

  /// No description provided for @serveurSpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace serveur - {establishment}'**
  String serveurSpaceTitle(String establishment);

  /// No description provided for @welcomeName.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue {name}'**
  String welcomeName(String name);

  /// No description provided for @serveurSpaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace de prise de commande et de suivi serveur'**
  String get serveurSpaceSubtitle;

  /// No description provided for @moduleOrdersRoomsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commandes & Chambres'**
  String get moduleOrdersRoomsTitle;

  /// No description provided for @moduleOrdersRoomsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prendre les commandes et gérer les consommations chambre'**
  String get moduleOrdersRoomsSubtitle;

  /// No description provided for @actionMenuOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Menu et Commande'**
  String get actionMenuOrderTitle;

  /// No description provided for @actionMenuOrderSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une commande restaurant, bar ou chambre'**
  String get actionMenuOrderSubtitle;

  /// No description provided for @actionRoomConsumptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Consommations Chambre'**
  String get actionRoomConsumptionTitle;

  /// No description provided for @actionRoomConsumptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturer les consommations liées à une chambre'**
  String get actionRoomConsumptionSubtitle;

  /// No description provided for @modulePaymentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiements & Versements'**
  String get modulePaymentsTitle;

  /// No description provided for @modulePaymentsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser les factures et remettre les fonds'**
  String get modulePaymentsSubtitle;

  /// No description provided for @actionCollectSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser les factures non payées'**
  String get actionCollectSubtitle;

  /// No description provided for @actionMyInvoicesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Toutes mes factures : encaisser, fiscaliser, imprimer'**
  String get actionMyInvoicesSubtitle;

  /// No description provided for @actionHandoverSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Remettre les encaissements à la gérante'**
  String get actionHandoverSubtitle;

  /// No description provided for @moduleTrackingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivi Préparation'**
  String get moduleTrackingTitle;

  /// No description provided for @moduleTrackingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivre l’avancement des commandes bar et cuisine'**
  String get moduleTrackingSubtitle;

  /// No description provided for @actionSuiviBarSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’état des commandes envoyées au bar'**
  String get actionSuiviBarSubtitle;

  /// No description provided for @actionSuiviCuisineSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’état des commandes envoyées en cuisine'**
  String get actionSuiviCuisineSubtitle;

  /// No description provided for @categoryAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get categoryAll;

  /// No description provided for @menuTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notre menu'**
  String get menuTitle;

  /// No description provided for @searchDishHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un plat…'**
  String get searchDishHint;

  /// No description provided for @noAccompanimentAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun accompagnement disponible. Plat ajouté sans accompagnement.'**
  String get noAccompanimentAvailable;

  /// No description provided for @freeAccompaniment.
  ///
  /// In fr, this message translates to:
  /// **'Accompagnement offert'**
  String get freeAccompaniment;

  /// No description provided for @chooseOneFreeAccompaniment.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez 1 accompagnement offert'**
  String get chooseOneFreeAccompaniment;

  /// No description provided for @labelFree.
  ///
  /// In fr, this message translates to:
  /// **'Offert'**
  String get labelFree;

  /// No description provided for @paidExtraPortions.
  ///
  /// In fr, this message translates to:
  /// **'Portions supplémentaires (payantes)'**
  String get paidExtraPortions;

  /// No description provided for @orderRecapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif de la commande'**
  String get orderRecapTitle;

  /// No description provided for @sendingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours...'**
  String get sendingInProgress;

  /// No description provided for @confirmAndSend.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et envoyer'**
  String get confirmAndSend;

  /// No description provided for @recapWithCount.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif ({count})'**
  String recapWithCount(String count);

  /// No description provided for @pricePerPortion.
  ///
  /// In fr, this message translates to:
  /// **'{price} FCFA / portion'**
  String pricePerPortion(String price);

  /// No description provided for @accompanimentLine.
  ///
  /// In fr, this message translates to:
  /// **'Accompagnement : {name} (offert)'**
  String accompanimentLine(String name);

  /// No description provided for @consumptionDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la Consommation'**
  String get consumptionDetailsTitle;

  /// No description provided for @certifiedInvoiceBadge.
  ///
  /// In fr, this message translates to:
  /// **'FACTURE CERTIFIEE'**
  String get certifiedInvoiceBadge;

  /// No description provided for @generalInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations générales'**
  String get generalInformation;

  /// No description provided for @labelOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get labelOrders;

  /// No description provided for @labelOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get labelOrder;

  /// No description provided for @labelDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @labelType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @labelAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get labelAmount;

  /// No description provided for @clientInfoOptional.
  ///
  /// In fr, this message translates to:
  /// **'Informations client (facultatives)'**
  String get clientInfoOptional;

  /// No description provided for @clientNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client'**
  String get clientNameLabel;

  /// No description provided for @clientAddressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du client'**
  String get clientAddressLabel;

  /// No description provided for @clientIfuLabel.
  ///
  /// In fr, this message translates to:
  /// **'IFU du client'**
  String get clientIfuLabel;

  /// No description provided for @consumedItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles consommés'**
  String get consumedItems;

  /// No description provided for @simpleInvoicePrinted.
  ///
  /// In fr, this message translates to:
  /// **'Facture simple imprimée et encaissement enregistré.'**
  String get simpleInvoicePrinted;

  /// No description provided for @normalizedInvoicePrinted.
  ///
  /// In fr, this message translates to:
  /// **'Facture normalisée imprimée et encaissement enregistré.'**
  String get normalizedInvoicePrinted;

  /// No description provided for @invoiceAlreadyCertified.
  ///
  /// In fr, this message translates to:
  /// **'Cette facture est déjà certifiée.'**
  String get invoiceAlreadyCertified;

  /// No description provided for @fiscalizeInvoiceFirst.
  ///
  /// In fr, this message translates to:
  /// **'Fiscalisez d’abord la facture.'**
  String get fiscalizeInvoiceFirst;

  /// No description provided for @fillEstablishmentIfuFirst.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez d’abord l’IFU de l’établissement (console admin).'**
  String get fillEstablishmentIfuFirst;

  /// No description provided for @actionPrintNormalizedInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer facture normalisée'**
  String get actionPrintNormalizedInvoice;

  /// No description provided for @actionPrintSimpleInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer facture simple'**
  String get actionPrintSimpleInvoice;

  /// No description provided for @quantityLine.
  ///
  /// In fr, this message translates to:
  /// **'Qté : {quantity}'**
  String quantityLine(String quantity);

  /// No description provided for @unitPriceLine.
  ///
  /// In fr, this message translates to:
  /// **'P.U : {price} FCFA'**
  String unitPriceLine(String price);

  /// No description provided for @invoiceFiscalizedWithCode.
  ///
  /// In fr, this message translates to:
  /// **'Facture fiscalisée avec certilink. Code MECeF : {code}'**
  String invoiceFiscalizedWithCode(String code);

  /// No description provided for @paymentCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get paymentCash;

  /// No description provided for @paymentMobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get paymentMobileMoney;

  /// No description provided for @paymentCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get paymentCard;

  /// No description provided for @paymentBankTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Virement bancaire'**
  String get paymentBankTransfer;

  /// No description provided for @paymentMixed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement mixte'**
  String get paymentMixed;

  /// No description provided for @paymentCredit.
  ///
  /// In fr, this message translates to:
  /// **'Vente à crédit'**
  String get paymentCredit;

  /// No description provided for @paymentBeninResto.
  ///
  /// In fr, this message translates to:
  /// **'Bénin Resto'**
  String get paymentBeninResto;

  /// No description provided for @accountCash.
  ///
  /// In fr, this message translates to:
  /// **'Cash'**
  String get accountCash;

  /// No description provided for @accountMobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get accountMobileMoney;

  /// No description provided for @accountBankTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get accountBankTransfer;

  /// No description provided for @accountCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte Bancaire'**
  String get accountCard;

  /// No description provided for @accountCredit.
  ///
  /// In fr, this message translates to:
  /// **'Crédit'**
  String get accountCredit;

  /// No description provided for @accountBeninResto.
  ///
  /// In fr, this message translates to:
  /// **'Bénin Resto'**
  String get accountBeninResto;

  /// No description provided for @accountMixed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement Mixte'**
  String get accountMixed;

  /// No description provided for @actionEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get actionDelete;

  /// No description provided for @actionDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get actionDisable;

  /// No description provided for @actionSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get actionSave;

  /// No description provided for @savingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get savingInProgress;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get fieldRequired;

  /// No description provided for @receptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réception'**
  String get receptionTitle;

  /// No description provided for @receptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace réception : chambres, séjours et factures'**
  String get receptionSubtitle;

  /// No description provided for @tileRoomsBoardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan des chambres'**
  String get tileRoomsBoardTitle;

  /// No description provided for @tileRoomsBoardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’état des chambres en temps réel'**
  String get tileRoomsBoardSubtitle;

  /// No description provided for @tileReservationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get tileReservationsTitle;

  /// No description provided for @tileReservationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer et gérer les réservations'**
  String get tileReservationsSubtitle;

  /// No description provided for @tileRoomInvoicingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturation chambre'**
  String get tileRoomInvoicingTitle;

  /// No description provided for @tileRoomInvoicingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturer et certifier un séjour'**
  String get tileRoomInvoicingSubtitle;

  /// No description provided for @tileInvoicesListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Liste des factures'**
  String get tileInvoicesListTitle;

  /// No description provided for @tileInvoicesListSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Consulter les factures chambres'**
  String get tileInvoicesListSubtitle;

  /// No description provided for @tileClientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get tileClientsTitle;

  /// No description provided for @tileClientsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiches clients et historique'**
  String get tileClientsSubtitle;

  /// No description provided for @roomsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chambres'**
  String get roomsTitle;

  /// No description provided for @tileRoomsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les chambres'**
  String get tileRoomsSubtitle;

  /// No description provided for @roomTypesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Types de chambres'**
  String get roomTypesTitle;

  /// No description provided for @tileRoomTypesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Configurer les catégories'**
  String get tileRoomTypesSubtitle;

  /// No description provided for @disableTypeConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver ce type ?'**
  String get disableTypeConfirmTitle;

  /// No description provided for @disableTypeConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Le type « {name} » ne sera plus proposé, mais les chambres existantes ne sont pas supprimées.'**
  String disableTypeConfirmBody(String name);

  /// No description provided for @typeDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Type désactivé.'**
  String get typeDisabled;

  /// No description provided for @typeUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Type modifié.'**
  String get typeUpdated;

  /// No description provided for @typeAdded.
  ///
  /// In fr, this message translates to:
  /// **'Type ajouté.'**
  String get typeAdded;

  /// No description provided for @addRoomType.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un type'**
  String get addRoomType;

  /// No description provided for @noRoomType.
  ///
  /// In fr, this message translates to:
  /// **'Aucun type de chambre.\nAjoutez vos catégories (Simple, Suite, Bungalow...).'**
  String get noRoomType;

  /// No description provided for @roomTypeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{price} FCFA / nuit · {capacity} pers.'**
  String roomTypeSubtitle(String price, String capacity);

  /// No description provided for @editTypeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le type'**
  String get editTypeTitle;

  /// No description provided for @newTypeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau type de chambre'**
  String get newTypeTitle;

  /// No description provided for @typeNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du type'**
  String get typeNameLabel;

  /// No description provided for @typeNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Suite Présidentielle, Bungalow...'**
  String get typeNameHint;

  /// No description provided for @pricePerNightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix par nuit (FCFA)'**
  String get pricePerNightLabel;

  /// No description provided for @pricePerNightHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 25000'**
  String get pricePerNightHint;

  /// No description provided for @invalidPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get invalidPrice;

  /// No description provided for @capacityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Capacité (personnes)'**
  String get capacityLabel;

  /// No description provided for @capacityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 2'**
  String get capacityHint;

  /// No description provided for @invalidCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité invalide'**
  String get invalidCapacity;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get descriptionOptionalLabel;

  /// No description provided for @amenitiesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Équipements (séparés par des virgules)'**
  String get amenitiesLabel;

  /// No description provided for @amenitiesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Clim, Wifi, TV, Minibar'**
  String get amenitiesHint;

  /// No description provided for @roomStatusAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Libre'**
  String get roomStatusAvailable;

  /// No description provided for @roomStatusOccupied.
  ///
  /// In fr, this message translates to:
  /// **'Occupée'**
  String get roomStatusOccupied;

  /// No description provided for @roomStatusCleaning.
  ///
  /// In fr, this message translates to:
  /// **'À nettoyer'**
  String get roomStatusCleaning;

  /// No description provided for @roomStatusMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance'**
  String get roomStatusMaintenance;

  /// No description provided for @changeRoomStateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chambre {number} — changer l’état'**
  String changeRoomStateTitle(String number);

  /// No description provided for @roomOccupiedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chambre {number} (occupée)'**
  String roomOccupiedTitle(String number);

  /// No description provided for @actionCheckOut.
  ///
  /// In fr, this message translates to:
  /// **'Check-out (départ du client)'**
  String get actionCheckOut;

  /// No description provided for @actionChangeStateManually.
  ///
  /// In fr, this message translates to:
  /// **'Changer l’état manuellement'**
  String get actionChangeStateManually;

  /// No description provided for @roomStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Chambre {number} : {status}'**
  String roomStatusChanged(String number, String status);

  /// No description provided for @noActiveReservationForRoom.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation active trouvée pour cette chambre. Vous pouvez changer son état manuellement.'**
  String get noActiveReservationForRoom;

  /// No description provided for @checkOutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Check-out'**
  String get checkOutTitle;

  /// No description provided for @checkOutConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le départ de {client} (chambre {number}) ?\n\nLa chambre passera « à nettoyer ».'**
  String checkOutConfirmBody(String client, String number);

  /// No description provided for @actionConfirmDeparture.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le départ'**
  String get actionConfirmDeparture;

  /// No description provided for @checkOutDone.
  ///
  /// In fr, this message translates to:
  /// **'Check-out effectué.'**
  String get checkOutDone;

  /// No description provided for @billStayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturer le séjour ?'**
  String get billStayTitle;

  /// No description provided for @billStayBody.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous établir la facture de {client} maintenant ?'**
  String billStayBody(String client);

  /// No description provided for @actionLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get actionLater;

  /// No description provided for @actionBill.
  ///
  /// In fr, this message translates to:
  /// **'Facturer'**
  String get actionBill;

  /// No description provided for @noRoomBoard.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chambre.\nAjoutez vos chambres pour voir le plan.'**
  String get noRoomBoard;

  /// No description provided for @roomsCountSummary.
  ///
  /// In fr, this message translates to:
  /// **'{total} chambres · {free} libres · {occupied} occupées · {toClean} à nettoyer'**
  String roomsCountSummary(
    String total,
    String free,
    String occupied,
    String toClean,
  );

  /// No description provided for @createRoomTypeFirst.
  ///
  /// In fr, this message translates to:
  /// **'Créez d’abord au moins un type de chambre.'**
  String get createRoomTypeFirst;

  /// No description provided for @deleteRoomConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette chambre ?'**
  String get deleteRoomConfirmTitle;

  /// No description provided for @deleteRoomConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'La chambre « {number} » sera retirée de la liste.'**
  String deleteRoomConfirmBody(String number);

  /// No description provided for @roomDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Chambre supprimée.'**
  String get roomDeleted;

  /// No description provided for @addRoom.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une chambre'**
  String get addRoom;

  /// No description provided for @noRoomTypeThenRooms.
  ///
  /// In fr, this message translates to:
  /// **'Créez d’abord un type de chambre,\npuis ajoutez vos chambres.'**
  String get noRoomTypeThenRooms;

  /// No description provided for @noRoomYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chambre.\nAjoutez vos chambres avec le bouton +.'**
  String get noRoomYet;

  /// No description provided for @floorSuffix.
  ///
  /// In fr, this message translates to:
  /// **' · Étage {floor}'**
  String floorSuffix(String floor);

  /// No description provided for @pickRoomType.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un type de chambre.'**
  String get pickRoomType;

  /// No description provided for @chooseRoomType.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un type'**
  String get chooseRoomType;

  /// No description provided for @roomUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Chambre modifiée.'**
  String get roomUpdated;

  /// No description provided for @roomAdded.
  ///
  /// In fr, this message translates to:
  /// **'Chambre ajoutée.'**
  String get roomAdded;

  /// No description provided for @editRoomTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la chambre'**
  String get editRoomTitle;

  /// No description provided for @newRoomTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle chambre'**
  String get newRoomTitle;

  /// No description provided for @roomNumberOrNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro / nom de la chambre'**
  String get roomNumberOrNameLabel;

  /// No description provided for @roomNumberOrNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 101, Jasmin, A2'**
  String get roomNumberOrNameHint;

  /// No description provided for @roomTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de chambre'**
  String get roomTypeLabel;

  /// No description provided for @roomTypeOption.
  ///
  /// In fr, this message translates to:
  /// **'{name} ({price} FCFA)'**
  String roomTypeOption(String name, String price);

  /// No description provided for @floorOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étage (optionnel)'**
  String get floorOptionalLabel;

  /// No description provided for @floorHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 1, RDC'**
  String get floorHint;

  /// No description provided for @specificPriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix spécifique (optionnel)'**
  String get specificPriceLabel;

  /// No description provided for @specificPriceHint.
  ///
  /// In fr, this message translates to:
  /// **'Laisser vide = prix du type'**
  String get specificPriceHint;

  /// No description provided for @reservationStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get reservationStatusConfirmed;

  /// No description provided for @reservationStatusCheckedIn.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get reservationStatusCheckedIn;

  /// No description provided for @reservationStatusCheckedOut.
  ///
  /// In fr, this message translates to:
  /// **'Partie'**
  String get reservationStatusCheckedOut;

  /// No description provided for @reservationStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get reservationStatusCancelled;

  /// No description provided for @cancelReservationConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette réservation ?'**
  String get cancelReservationConfirmTitle;

  /// No description provided for @cancelReservationConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'La réservation de {client} sera marquée annulée.'**
  String cancelReservationConfirmBody(String client);

  /// No description provided for @actionBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get actionBack;

  /// No description provided for @actionCancelReservation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation'**
  String get actionCancelReservation;

  /// No description provided for @reservationCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Réservation annulée.'**
  String get reservationCancelled;

  /// No description provided for @noFreeRoomOfType.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chambre libre pour le type « {type} ». Libérez ou préparez une chambre d’abord.'**
  String noFreeRoomOfType(String type);

  /// No description provided for @assignRoomTo.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer une chambre à {client}'**
  String assignRoomTo(String client);

  /// No description provided for @floorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étage {floor}'**
  String floorLabel(String floor);

  /// No description provided for @checkInDone.
  ///
  /// In fr, this message translates to:
  /// **'Check-in effectué : chambre {number}.'**
  String checkInDone(String number);

  /// No description provided for @actionCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Check-in'**
  String get actionCheckIn;

  /// No description provided for @newReservation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réservation'**
  String get newReservation;

  /// No description provided for @noReservation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation.\nCréez-en une avec le bouton +.'**
  String get noReservation;

  /// No description provided for @roomShortSuffix.
  ///
  /// In fr, this message translates to:
  /// **' · Ch. {number}'**
  String roomShortSuffix(String number);

  /// No description provided for @nightsCount.
  ///
  /// In fr, this message translates to:
  /// **'{nights} nuit(s)'**
  String nightsCount(String nights);

  /// No description provided for @editReservationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la réservation'**
  String get editReservationTitle;

  /// No description provided for @dateHintDdMmYyyy.
  ///
  /// In fr, this message translates to:
  /// **'jj/mm/aaaa'**
  String get dateHintDdMmYyyy;

  /// No description provided for @invalidDate.
  ///
  /// In fr, this message translates to:
  /// **'Date invalide'**
  String get invalidDate;

  /// No description provided for @pickStayDates.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez les dates du séjour.'**
  String get pickStayDates;

  /// No description provided for @phoneOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get phoneOptionalLabel;

  /// No description provided for @ifuOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'IFU (optionnel, pour la facture)'**
  String get ifuOptionalLabel;

  /// No description provided for @labelArrival.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get labelArrival;

  /// No description provided for @labelDeparture.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get labelDeparture;

  /// No description provided for @pickFromCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Choisir au calendrier'**
  String get pickFromCalendar;

  /// No description provided for @pricePerNightShortLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix / nuit'**
  String get pricePerNightShortLabel;

  /// No description provided for @noteOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note (optionnel)'**
  String get noteOptionalLabel;

  /// No description provided for @reservationUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Réservation modifiée.'**
  String get reservationUpdated;

  /// No description provided for @totalWithNights.
  ///
  /// In fr, this message translates to:
  /// **'Total : {amount} FCFA ({nights} nuit(s))'**
  String totalWithNights(String amount, String nights);

  /// No description provided for @chooseExistingClient.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un client existant'**
  String get chooseExistingClient;

  /// No description provided for @attachedClient.
  ///
  /// In fr, this message translates to:
  /// **'Client rattaché : {name}'**
  String attachedClient(String name);

  /// No description provided for @detachRecord.
  ///
  /// In fr, this message translates to:
  /// **'Détacher la fiche'**
  String get detachRecord;

  /// No description provided for @checkingAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de la disponibilité...'**
  String get checkingAvailability;

  /// No description provided for @typeFullOnPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Type complet sur cette période (vous pourrez forcer).'**
  String get typeFullOnPeriod;

  /// No description provided for @roomsAvailableCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} chambre(s) disponible(s).'**
  String roomsAvailableCount(String count);

  /// No description provided for @typeFullTitle.
  ///
  /// In fr, this message translates to:
  /// **'Type complet'**
  String get typeFullTitle;

  /// No description provided for @typeFullBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chambre de ce type n’est disponible sur cette période. Voulez-vous forcer la réservation malgré tout ?'**
  String get typeFullBody;

  /// No description provided for @actionNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get actionNo;

  /// No description provided for @actionForce.
  ///
  /// In fr, this message translates to:
  /// **'Forcer'**
  String get actionForce;

  /// No description provided for @guestsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get guestsLabel;

  /// No description provided for @reservationCreated.
  ///
  /// In fr, this message translates to:
  /// **'Réservation créée.'**
  String get reservationCreated;

  /// No description provided for @creatingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Création...'**
  String get creatingInProgress;

  /// No description provided for @actionCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get actionCreate;

  /// No description provided for @chooseClient.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un client'**
  String get chooseClient;

  /// No description provided for @searchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get searchLabel;

  /// No description provided for @searchNameOrPhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou téléphone'**
  String get searchNameOrPhoneHint;

  /// No description provided for @noClientRecord.
  ///
  /// In fr, this message translates to:
  /// **'Aucune fiche client.\nVous pouvez saisir le client à la main.'**
  String get noClientRecord;

  /// No description provided for @noClientMatches.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client ne correspond à cette recherche.'**
  String get noClientMatches;

  /// No description provided for @ifuPrefix.
  ///
  /// In fr, this message translates to:
  /// **'IFU {ifu}'**
  String ifuPrefix(String ifu);

  /// No description provided for @serverPaymentsNotHandedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaissements serveurs non versés'**
  String get serverPaymentsNotHandedTitle;

  /// No description provided for @noPendingPayment.
  ///
  /// In fr, this message translates to:
  /// **'Aucun encaissement en attente'**
  String get noPendingPayment;

  /// No description provided for @methodLine.
  ///
  /// In fr, this message translates to:
  /// **'Mode : {method}'**
  String methodLine(String method);

  /// No description provided for @stockManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des stocks'**
  String get stockManagementTitle;

  /// No description provided for @supplyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes d’approvisionnement'**
  String get supplyRequests;

  /// No description provided for @storesOverview.
  ///
  /// In fr, this message translates to:
  /// **'Pilotage des magasins'**
  String get storesOverview;

  /// No description provided for @storesOverviewSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Consulte les stocks, traite les demandes et valide les approvisionnements.'**
  String get storesOverviewSubtitle;

  /// No description provided for @storeHotelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Magasin Hôtel'**
  String get storeHotelTitle;

  /// No description provided for @storeHotelSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Produits d’hygiène, entretien, consommables chambre'**
  String get storeHotelSubtitle;

  /// No description provided for @storeRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Magasin Restaurant'**
  String get storeRestaurantTitle;

  /// No description provided for @storeRestaurantSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Denrées, cuisine, matières premières'**
  String get storeRestaurantSubtitle;

  /// No description provided for @storeBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Magasin Bar'**
  String get storeBarTitle;

  /// No description provided for @storeBarSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Boissons, snacks, accessoires bar'**
  String get storeBarSubtitle;

  /// No description provided for @actionViewStock.
  ///
  /// In fr, this message translates to:
  /// **'Voir stock'**
  String get actionViewStock;

  /// No description provided for @actionRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get actionRequests;

  /// No description provided for @clientDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Client désactivé.'**
  String get clientDisabled;

  /// No description provided for @clientAdded.
  ///
  /// In fr, this message translates to:
  /// **'Client ajouté.'**
  String get clientAdded;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre espace de travail'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'exemple@domaine.com'**
  String get loginEmailHint;

  /// No description provided for @loginEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre email'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordEmailFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un email complet d’abord'**
  String get loginPasswordEmailFirst;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre mot de passe'**
  String get loginPasswordRequired;

  /// No description provided for @loginPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get loginPasswordTooShort;

  /// No description provided for @loginForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get loginForgotPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginSubmit;

  /// No description provided for @loginResetNeedsEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez d’abord saisir votre adresse email pour recevoir le lien de réinitialisation.'**
  String get loginResetNeedsEmail;

  /// No description provided for @loginResetInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un email valide.'**
  String get loginResetInvalidEmail;

  /// No description provided for @loginResetSent.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de réinitialisation a été envoyé à {email}. Vérifiez aussi vos spams/indésirables.'**
  String loginResetSent(String email);

  /// No description provided for @loginResetFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’envoyer le mail de réinitialisation.'**
  String get loginResetFailed;

  /// No description provided for @loginResetError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l’envoi du mail : {error}'**
  String loginResetError(String error);

  /// No description provided for @roleGlobalAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur global'**
  String get roleGlobalAdmin;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Super Administrateur'**
  String get roleSuperAdmin;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In fr, this message translates to:
  /// **'Gérante'**
  String get roleManager;

  /// No description provided for @roleAccountant.
  ///
  /// In fr, this message translates to:
  /// **'Comptable'**
  String get roleAccountant;

  /// No description provided for @roleHeadChef.
  ///
  /// In fr, this message translates to:
  /// **'Chef Cuisine'**
  String get roleHeadChef;

  /// No description provided for @roleWaiter.
  ///
  /// In fr, this message translates to:
  /// **'Serveur'**
  String get roleWaiter;

  /// No description provided for @roleHousekeeping.
  ///
  /// In fr, this message translates to:
  /// **'Service Hygiène'**
  String get roleHousekeeping;

  /// No description provided for @roleBartender.
  ///
  /// In fr, this message translates to:
  /// **'Barman'**
  String get roleBartender;

  /// No description provided for @roleButler.
  ///
  /// In fr, this message translates to:
  /// **'Majordhomme'**
  String get roleButler;

  /// No description provided for @roleReceptionist.
  ///
  /// In fr, this message translates to:
  /// **'Réceptionniste'**
  String get roleReceptionist;

  /// No description provided for @labelReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get labelReason;

  /// No description provided for @labelItem.
  ///
  /// In fr, this message translates to:
  /// **'Article'**
  String get labelItem;

  /// No description provided for @labelItemIndex.
  ///
  /// In fr, this message translates to:
  /// **'Article {index}'**
  String labelItemIndex(int index);

  /// No description provided for @labelQuantitySupplied.
  ///
  /// In fr, this message translates to:
  /// **'Quantité approvisionnée'**
  String get labelQuantitySupplied;

  /// No description provided for @actionAddItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article'**
  String get actionAddItem;

  /// No description provided for @actionValidateSupply.
  ///
  /// In fr, this message translates to:
  /// **'Valider l’approvisionnement'**
  String get actionValidateSupply;

  /// No description provided for @reasonDirectSupplyDefault.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement direct gérante'**
  String get reasonDirectSupplyDefault;

  /// No description provided for @selectItemAtLine.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne l’article à la ligne {line}.'**
  String selectItemAtLine(int line);

  /// No description provided for @invalidQuantityAtLine.
  ///
  /// In fr, this message translates to:
  /// **'Quantité invalide à la ligne {line}.'**
  String invalidQuantityAtLine(int line);

  /// No description provided for @directSupplyRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement direct enregistré avec succès.'**
  String get directSupplyRecorded;

  /// No description provided for @registerServerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un serveur'**
  String get registerServerTitle;

  /// No description provided for @newServerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau serveur'**
  String get newServerTitle;

  /// No description provided for @labelFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get labelFullName;

  /// No description provided for @labelPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get labelPhone;

  /// No description provided for @labelEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @errFullNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le nom complet'**
  String get errFullNameRequired;

  /// No description provided for @errPhoneTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Numéro trop court'**
  String get errPhoneTooShort;

  /// No description provided for @serverRegisteredSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Serveur enregistré avec succès.'**
  String get serverRegisteredSuccess;

  /// No description provided for @storeNameHotel.
  ///
  /// In fr, this message translates to:
  /// **'Hôtel'**
  String get storeNameHotel;

  /// No description provided for @storeNameRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get storeNameRestaurant;

  /// No description provided for @storeNameBar.
  ///
  /// In fr, this message translates to:
  /// **'Bar'**
  String get storeNameBar;

  /// No description provided for @statusDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get statusDelivered;

  /// No description provided for @statusReceived.
  ///
  /// In fr, this message translates to:
  /// **'Réceptionnée'**
  String get statusReceived;

  /// No description provided for @deliveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livraison / Approvisionnement'**
  String get deliveryTitle;

  /// No description provided for @requestAlreadyProcessed.
  ///
  /// In fr, this message translates to:
  /// **'Cette demande a déjà été traitée.'**
  String get requestAlreadyProcessed;

  /// No description provided for @requestAlreadyProcessedShort.
  ///
  /// In fr, this message translates to:
  /// **'Demande déjà traitée'**
  String get requestAlreadyProcessedShort;

  /// No description provided for @invalidDeliveredQuantityAtLine.
  ///
  /// In fr, this message translates to:
  /// **'Quantité livrée invalide à la ligne {line}.'**
  String invalidDeliveredQuantityAtLine(int line);

  /// No description provided for @supplyValidatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement validé avec succès.'**
  String get supplyValidatedSuccess;

  /// No description provided for @requestedByLine.
  ///
  /// In fr, this message translates to:
  /// **'Demandé par : {name}'**
  String requestedByLine(String name);

  /// No description provided for @roleLine.
  ///
  /// In fr, this message translates to:
  /// **'Rôle : {role}'**
  String roleLine(String role);

  /// No description provided for @statusLine.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {status}'**
  String statusLine(String status);

  /// No description provided for @quantitiesToDeliver.
  ///
  /// In fr, this message translates to:
  /// **'Quantités à livrer'**
  String get quantitiesToDeliver;

  /// No description provided for @requestedQuantityLine.
  ///
  /// In fr, this message translates to:
  /// **'Demandé : {quantity} {unit}'**
  String requestedQuantityLine(String quantity, String unit);

  /// No description provided for @labelQuantityDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Quantité livrée'**
  String get labelQuantityDelivered;

  /// No description provided for @actionValidateDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Valider la livraison'**
  String get actionValidateDelivery;

  /// No description provided for @amountLine.
  ///
  /// In fr, this message translates to:
  /// **'Montant : {amount} FCFA'**
  String amountLine(String amount);

  /// No description provided for @labelTotalCaps.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL'**
  String get labelTotalCaps;

  /// No description provided for @labelStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get labelStatus;

  /// No description provided for @actionOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get actionOpen;

  /// No description provided for @noResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResult;

  /// No description provided for @dateLine.
  ///
  /// In fr, this message translates to:
  /// **'Date : {date}'**
  String dateLine(String date);

  /// No description provided for @roomLine.
  ///
  /// In fr, this message translates to:
  /// **'Chambre : {number}'**
  String roomLine(String number);

  /// No description provided for @labelClientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client'**
  String get labelClientName;

  /// No description provided for @labelRoomNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de chambre'**
  String get labelRoomNumber;

  /// No description provided for @actionViewDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir détails'**
  String get actionViewDetails;

  /// No description provided for @statusDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Déclaré'**
  String get statusDeclared;

  /// No description provided for @noElementSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément sélectionné.'**
  String get noElementSelected;

  /// No description provided for @transferDeclaredToAccounting.
  ///
  /// In fr, this message translates to:
  /// **'Versement déclaré à la comptabilité.'**
  String get transferDeclaredToAccounting;

  /// No description provided for @managerToAccountingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Versement gérante → comptabilité'**
  String get managerToAccountingTitle;

  /// No description provided for @validatedServerHandovers.
  ///
  /// In fr, this message translates to:
  /// **'Versements serveurs validés'**
  String get validatedServerHandovers;

  /// No description provided for @noServerHandoverAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement serveur disponible.'**
  String get noServerHandoverAvailable;

  /// No description provided for @paidRoomInvoicesNotTransferred.
  ///
  /// In fr, this message translates to:
  /// **'Factures chambres encaissées non versées'**
  String get paidRoomInvoicesNotTransferred;

  /// No description provided for @noRoomInvoiceAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture chambre disponible.'**
  String get noRoomInvoiceAvailable;

  /// No description provided for @transferSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé du versement'**
  String get transferSummary;

  /// No description provided for @serverHandoversLabel.
  ///
  /// In fr, this message translates to:
  /// **'Versements serveurs'**
  String get serverHandoversLabel;

  /// No description provided for @roomInvoicesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Factures chambres'**
  String get roomInvoicesLabel;

  /// No description provided for @actionDeclareToAccounting.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer à la comptabilité'**
  String get actionDeclareToAccounting;

  /// No description provided for @managerTransferHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique versements gérante'**
  String get managerTransferHistory;

  /// No description provided for @noTransferRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement enregistré.'**
  String get noTransferRecorded;

  /// No description provided for @statusPaidShort.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get statusPaidShort;

  /// No description provided for @statusUnpaidShort.
  ///
  /// In fr, this message translates to:
  /// **'Non payée'**
  String get statusUnpaidShort;

  /// No description provided for @errSearchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la recherche : {error}'**
  String errSearchFailed(String error);

  /// No description provided for @searchByClientOption.
  ///
  /// In fr, this message translates to:
  /// **'Recherche par client'**
  String get searchByClientOption;

  /// No description provided for @searchByRoomOption.
  ///
  /// In fr, this message translates to:
  /// **'Recherche par chambre'**
  String get searchByRoomOption;

  /// No description provided for @searchByClientShort.
  ///
  /// In fr, this message translates to:
  /// **'Par client'**
  String get searchByClientShort;

  /// No description provided for @searchByRoomShort.
  ///
  /// In fr, this message translates to:
  /// **'Par chambre'**
  String get searchByRoomShort;

  /// No description provided for @arrivalLine.
  ///
  /// In fr, this message translates to:
  /// **'Entrée : {date}'**
  String arrivalLine(String date);

  /// No description provided for @departureLine.
  ///
  /// In fr, this message translates to:
  /// **'Sortie : {date}'**
  String departureLine(String date);

  /// No description provided for @mecefCodeLine.
  ///
  /// In fr, this message translates to:
  /// **'Code MECeF : {code}'**
  String mecefCodeLine(String code);

  /// No description provided for @searchRoomInvoicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche factures chambre'**
  String get searchRoomInvoicesTitle;

  /// No description provided for @serverHandoversTitle.
  ///
  /// In fr, this message translates to:
  /// **'Versements des serveurs'**
  String get serverHandoversTitle;

  /// No description provided for @noPendingHandover.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement en attente.'**
  String get noPendingHandover;

  /// No description provided for @declaredAmountLine.
  ///
  /// In fr, this message translates to:
  /// **'Montant déclaré : {amount} FCFA'**
  String declaredAmountLine(String amount);

  /// No description provided for @includedPaymentsLine.
  ///
  /// In fr, this message translates to:
  /// **'Paiements inclus : {count}'**
  String includedPaymentsLine(int count);

  /// No description provided for @errObservedAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant constaté invalide.'**
  String get errObservedAmountInvalid;

  /// No description provided for @ordersValidated.
  ///
  /// In fr, this message translates to:
  /// **'Commandes validées.'**
  String get ordersValidated;

  /// No description provided for @ordersRejected.
  ///
  /// In fr, this message translates to:
  /// **'Commandes rejetées.'**
  String get ordersRejected;

  /// No description provided for @handoverTitleFor.
  ///
  /// In fr, this message translates to:
  /// **'Versement - {name}'**
  String handoverTitleFor(String name);

  /// No description provided for @labelObservedAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant constaté'**
  String get labelObservedAmount;

  /// No description provided for @noPaymentFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement trouvé.'**
  String get noPaymentFound;

  /// No description provided for @methodAmountLine.
  ///
  /// In fr, this message translates to:
  /// **'{method} • {amount} FCFA'**
  String methodAmountLine(String method, String amount);

  /// No description provided for @suffixAlreadyValidated.
  ///
  /// In fr, this message translates to:
  /// **' • déjà validée'**
  String get suffixAlreadyValidated;

  /// No description provided for @suffixRejected.
  ///
  /// In fr, this message translates to:
  /// **' • rejetée'**
  String get suffixRejected;

  /// No description provided for @actionRejectSelection.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter sélection'**
  String get actionRejectSelection;

  /// No description provided for @actionValidateSelection.
  ///
  /// In fr, this message translates to:
  /// **'Valider sélection'**
  String get actionValidateSelection;

  /// No description provided for @supplyRequestsForStore.
  ///
  /// In fr, this message translates to:
  /// **'Demandes - {store}'**
  String supplyRequestsForStore(String store);

  /// No description provided for @filterRequests.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les demandes'**
  String get filterRequests;

  /// No description provided for @filterDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get filterDelivered;

  /// No description provided for @filterReceived.
  ///
  /// In fr, this message translates to:
  /// **'Réceptionnées'**
  String get filterReceived;

  /// No description provided for @noRequestFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande trouvée.'**
  String get noRequestFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
