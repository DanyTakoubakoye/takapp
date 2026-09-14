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

  /// No description provided for @labelQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get labelQuantity;

  /// No description provided for @periodLine.
  ///
  /// In fr, this message translates to:
  /// **'Période : {start} → {end}'**
  String periodLine(String start, String end);

  /// No description provided for @actionMarkPaid.
  ///
  /// In fr, this message translates to:
  /// **'Marquer payée'**
  String get actionMarkPaid;

  /// No description provided for @actionPrintNormalized.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer normalisée'**
  String get actionPrintNormalized;

  /// No description provided for @filterAllInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAllInvoices;

  /// No description provided for @filterPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payées'**
  String get filterPaid;

  /// No description provided for @filterUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non payées'**
  String get filterUnpaid;

  /// No description provided for @noInvoiceFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture trouvée.'**
  String get noInvoiceFound;

  /// No description provided for @searchClientOrRoom.
  ///
  /// In fr, this message translates to:
  /// **'Recherche client / chambre'**
  String get searchClientOrRoom;

  /// No description provided for @roomInvoicesListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Liste des factures chambres'**
  String get roomInvoicesListTitle;

  /// No description provided for @errInvoiceDatesInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Les dates de la facture sont invalides.'**
  String get errInvoiceDatesInvalid;

  /// No description provided for @errInvoiceNotFiscalizedYet.
  ///
  /// In fr, this message translates to:
  /// **'Cette facture n’est pas encore fiscalisée.'**
  String get errInvoiceNotFiscalizedYet;

  /// No description provided for @errSetIfuFirst.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez d’abord l’IFU de l’établissement (console admin).'**
  String get errSetIfuFirst;

  /// No description provided for @errInvoiceAlreadyFiscalized.
  ///
  /// In fr, this message translates to:
  /// **'Cette facture est déjà fiscalisée.'**
  String get errInvoiceAlreadyFiscalized;

  /// No description provided for @managerWorkspaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace de supervision et validation'**
  String get managerWorkspaceSubtitle;

  /// No description provided for @moduleStocksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stocks & Approvisionnements'**
  String get moduleStocksTitle;

  /// No description provided for @moduleStocksSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Stocks, demandes, seuils, articles et approvisionnements'**
  String get moduleStocksSubtitle;

  /// No description provided for @actionStockRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes stock'**
  String get actionStockRequests;

  /// No description provided for @lowStockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stocks faibles'**
  String get lowStockTitle;

  /// No description provided for @actionSupplyRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionner Restaurant'**
  String get actionSupplyRestaurant;

  /// No description provided for @actionSupplyBar.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionner Bar'**
  String get actionSupplyBar;

  /// No description provided for @actionSupplyHotel.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionner Hôtel'**
  String get actionSupplyHotel;

  /// No description provided for @directSupplyRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement direct - Restaurant'**
  String get directSupplyRestaurantTitle;

  /// No description provided for @directSupplyBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement direct - Bar'**
  String get directSupplyBarTitle;

  /// No description provided for @directSupplyHotelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement direct - Hôtel'**
  String get directSupplyHotelTitle;

  /// No description provided for @actionItemRegistry.
  ///
  /// In fr, this message translates to:
  /// **'Registre des articles'**
  String get actionItemRegistry;

  /// No description provided for @actionCreateStock.
  ///
  /// In fr, this message translates to:
  /// **'Créer un stock'**
  String get actionCreateStock;

  /// No description provided for @moduleServersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs & Encaissements'**
  String get moduleServersTitle;

  /// No description provided for @moduleServersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs, versements et encaissements'**
  String get moduleServersSubtitle;

  /// No description provided for @actionValidateHandovers.
  ///
  /// In fr, this message translates to:
  /// **'Valider les versements'**
  String get actionValidateHandovers;

  /// No description provided for @actionServerCollections.
  ///
  /// In fr, this message translates to:
  /// **'Encaissements serveurs'**
  String get actionServerCollections;

  /// No description provided for @moduleBillingRoomsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturation & Chambres'**
  String get moduleBillingRoomsTitle;

  /// No description provided for @moduleBillingRoomsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Factures, chambres et versement comptable'**
  String get moduleBillingRoomsSubtitle;

  /// No description provided for @actionRoomBilling.
  ///
  /// In fr, this message translates to:
  /// **'Facturation chambres'**
  String get actionRoomBilling;

  /// No description provided for @actionInvoicesList.
  ///
  /// In fr, this message translates to:
  /// **'Liste des factures'**
  String get actionInvoicesList;

  /// No description provided for @actionAccountingTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Versement compta'**
  String get actionAccountingTransfer;

  /// No description provided for @moduleMenuTitle.
  ///
  /// In fr, this message translates to:
  /// **'Menu & Exploitation'**
  String get moduleMenuTitle;

  /// No description provided for @moduleMenuSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du menu restaurant et bar'**
  String get moduleMenuSubtitle;

  /// No description provided for @actionManageMenu.
  ///
  /// In fr, this message translates to:
  /// **'Gérer le menu'**
  String get actionManageMenu;

  /// No description provided for @createStockPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Création stock gérante'**
  String get createStockPageTitle;

  /// No description provided for @createStockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Création / import de stock'**
  String get createStockTitle;

  /// No description provided for @createStockSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un article actif, saisissez la quantité, ou importez plusieurs lignes depuis un fichier.'**
  String get createStockSubtitle;

  /// No description provided for @manualEntry.
  ///
  /// In fr, this message translates to:
  /// **'Saisie manuelle'**
  String get manualEntry;

  /// No description provided for @noActiveItemFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article actif trouvé dans stock_items.'**
  String get noActiveItemFound;

  /// No description provided for @labelStockItem.
  ///
  /// In fr, this message translates to:
  /// **'Article de stock'**
  String get labelStockItem;

  /// No description provided for @hintQuantityExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 25'**
  String get hintQuantityExample;

  /// No description provided for @errQuantityRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir une quantité'**
  String get errQuantityRequired;

  /// No description provided for @errQuantityMustBeInteger.
  ///
  /// In fr, this message translates to:
  /// **'La quantité doit être un entier.'**
  String get errQuantityMustBeInteger;

  /// No description provided for @errQuantityNegative.
  ///
  /// In fr, this message translates to:
  /// **'La quantité ne peut pas être négative'**
  String get errQuantityNegative;

  /// No description provided for @errChooseAnItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un article'**
  String get errChooseAnItem;

  /// No description provided for @errSelectAnItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un article.'**
  String get errSelectAnItem;

  /// No description provided for @stockSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Stock enregistré avec succès.'**
  String get stockSavedSuccess;

  /// No description provided for @errLoadItemsFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement articles : {error}'**
  String errLoadItemsFailed(String error);

  /// No description provided for @errSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l’enregistrement : {error}'**
  String errSaveFailed(String error);

  /// No description provided for @errImportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur import : {error}'**
  String errImportFailed(String error);

  /// No description provided for @importCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Import annulé.'**
  String get importCancelled;

  /// No description provided for @errFileUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le fichier sélectionné.'**
  String get errFileUnreadable;

  /// No description provided for @errUnsupportedFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format non supporté. Utilise CSV ou XLSX.'**
  String get errUnsupportedFormat;

  /// No description provided for @errNoUsableRow.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ligne exploitable trouvée.'**
  String get errNoUsableRow;

  /// No description provided for @errItemNameMissing.
  ///
  /// In fr, this message translates to:
  /// **'nom d’article manquant'**
  String get errItemNameMissing;

  /// No description provided for @errQuantityInvalidShort.
  ///
  /// In fr, this message translates to:
  /// **'quantité invalide'**
  String get errQuantityInvalidShort;

  /// No description provided for @errItemNotInStockItems.
  ///
  /// In fr, this message translates to:
  /// **'article « {name} » introuvable dans stock_items'**
  String errItemNotInStockItems(String name);

  /// No description provided for @lineErrorLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line}: {message}'**
  String lineErrorLine(int line, String message);

  /// No description provided for @importSuccessCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} stock(s) importé(s) avec succès.'**
  String importSuccessCount(int count);

  /// No description provided for @importPartialResult.
  ///
  /// In fr, this message translates to:
  /// **'{success} import(s) réussi(s), {errors} erreur(s).'**
  String importPartialResult(int success, int errors);

  /// No description provided for @importedCountShort.
  ///
  /// In fr, this message translates to:
  /// **'{count} stock(s) importé(s).'**
  String importedCountShort(int count);

  /// No description provided for @importingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Import en cours...'**
  String get importingInProgress;

  /// No description provided for @actionImportCsvExcel.
  ///
  /// In fr, this message translates to:
  /// **'Importer CSV / Excel'**
  String get actionImportCsvExcel;

  /// No description provided for @importRecommendedFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format d’import recommandé'**
  String get importRecommendedFormat;

  /// No description provided for @expectedColumns.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes attendues :'**
  String get expectedColumns;

  /// No description provided for @exampleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Exemple :'**
  String get exampleLabel;

  /// No description provided for @importExampleRow1.
  ///
  /// In fr, this message translates to:
  /// **'Eau minérale | 48'**
  String get importExampleRow1;

  /// No description provided for @importExampleRow2.
  ///
  /// In fr, this message translates to:
  /// **'Riz local | 120'**
  String get importExampleRow2;

  /// No description provided for @fieldsSavedInStoreStocks.
  ///
  /// In fr, this message translates to:
  /// **'Champs enregistrés dans store_stocks'**
  String get fieldsSavedInStoreStocks;

  /// No description provided for @storeLine.
  ///
  /// In fr, this message translates to:
  /// **'Store : {store}'**
  String storeLine(String store);

  /// No description provided for @unitLine.
  ///
  /// In fr, this message translates to:
  /// **'Unité : {unit}'**
  String unitLine(String unit);

  /// No description provided for @actionCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get actionClose;

  /// No description provided for @confirmationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmationTitle;

  /// No description provided for @labelClient.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get labelClient;

  /// No description provided for @labelClientIfu.
  ///
  /// In fr, this message translates to:
  /// **'IFU client'**
  String get labelClientIfu;

  /// No description provided for @labelAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get labelAddress;

  /// No description provided for @labelRoomWord.
  ///
  /// In fr, this message translates to:
  /// **'Chambre'**
  String get labelRoomWord;

  /// No description provided for @labelEntry.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get labelEntry;

  /// No description provided for @labelExit.
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get labelExit;

  /// No description provided for @labelNights.
  ///
  /// In fr, this message translates to:
  /// **'Nuitées'**
  String get labelNights;

  /// No description provided for @labelPricePerNightShort.
  ///
  /// In fr, this message translates to:
  /// **'Prix / nuit'**
  String get labelPricePerNightShort;

  /// No description provided for @labelExtras.
  ///
  /// In fr, this message translates to:
  /// **'Extras'**
  String get labelExtras;

  /// No description provided for @labelServices.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get labelServices;

  /// No description provided for @labelPaymentStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut paiement'**
  String get labelPaymentStatus;

  /// No description provided for @labelFiscalStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut fiscal'**
  String get labelFiscalStatus;

  /// No description provided for @statusCertified.
  ///
  /// In fr, this message translates to:
  /// **'Certifiée'**
  String get statusCertified;

  /// No description provided for @statusNotCertified.
  ///
  /// In fr, this message translates to:
  /// **'Non certifiée'**
  String get statusNotCertified;

  /// No description provided for @labelMecefCode.
  ///
  /// In fr, this message translates to:
  /// **'Code MECeF'**
  String get labelMecefCode;

  /// No description provided for @labelCounters.
  ///
  /// In fr, this message translates to:
  /// **'Compteurs'**
  String get labelCounters;

  /// No description provided for @labelFiscalDate.
  ///
  /// In fr, this message translates to:
  /// **'Date fiscale'**
  String get labelFiscalDate;

  /// No description provided for @paymentBank.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get paymentBank;

  /// No description provided for @paymentCheque.
  ///
  /// In fr, this message translates to:
  /// **'Chèque'**
  String get paymentCheque;

  /// No description provided for @aibNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun AIB'**
  String get aibNone;

  /// No description provided for @errInvoiceDatesInvalidShort.
  ///
  /// In fr, this message translates to:
  /// **'Dates de facture invalides.'**
  String get errInvoiceDatesInvalidShort;

  /// No description provided for @actionFiscalizeWithCertilink.
  ///
  /// In fr, this message translates to:
  /// **'Fiscaliser avec Certilink'**
  String get actionFiscalizeWithCertilink;

  /// No description provided for @roomInvoiceDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail facture chambre'**
  String get roomInvoiceDetailTitle;

  /// No description provided for @errInvoiceNotCertifiedYet.
  ///
  /// In fr, this message translates to:
  /// **'Cette facture n’est pas encore certifiée.'**
  String get errInvoiceNotCertifiedYet;

  /// No description provided for @errInvoiceAlreadyCertified.
  ///
  /// In fr, this message translates to:
  /// **'Cette facture est déjà certifiée.'**
  String get errInvoiceAlreadyCertified;

  /// No description provided for @invoiceCertifiedWithCode.
  ///
  /// In fr, this message translates to:
  /// **'Facture certifiée avec Certilink Code MECeF : {code}'**
  String invoiceCertifiedWithCode(String code);

  /// No description provided for @tooltipPrintClassic.
  ///
  /// In fr, this message translates to:
  /// **'Impression classique'**
  String get tooltipPrintClassic;

  /// No description provided for @tooltipPrintNormalized.
  ///
  /// In fr, this message translates to:
  /// **'Impression normalisée'**
  String get tooltipPrintNormalized;

  /// No description provided for @actionPrintClassicMode.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer en mode classique'**
  String get actionPrintClassicMode;

  /// No description provided for @actionPrintNormalizedMode.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer en mode normalisé'**
  String get actionPrintNormalizedMode;

  /// No description provided for @roomBillingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturation Chambre'**
  String get roomBillingTitle;

  /// No description provided for @errSaveInvoiceFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez d’abord enregistrer la facture.'**
  String get errSaveInvoiceFirst;

  /// No description provided for @errFiscalizeFirst.
  ///
  /// In fr, this message translates to:
  /// **'Cette facture n’est pas encore fiscalisée. Fiscalisez-la d’abord.'**
  String get errFiscalizeFirst;

  /// No description provided for @errFillRoomAndPeriodFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez d’abord renseigner la chambre et la période.'**
  String get errFillRoomAndPeriodFirst;

  /// No description provided for @extrasDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails Extras'**
  String get extrasDetailsTitle;

  /// No description provided for @noConsumptionFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune consommation trouvée.'**
  String get noConsumptionFound;

  /// No description provided for @extrasTotalLine.
  ///
  /// In fr, this message translates to:
  /// **'Total extras : {amount} FCFA'**
  String extrasTotalLine(String amount);

  /// No description provided for @errRequiredFieldsMissing.
  ///
  /// In fr, this message translates to:
  /// **'Champs obligatoires manquants'**
  String get errRequiredFieldsMissing;

  /// No description provided for @errStartBeforeEnd.
  ///
  /// In fr, this message translates to:
  /// **'La date d’entrée doit être antérieure ou égale à la date de sortie.'**
  String get errStartBeforeEnd;

  /// No description provided for @errInvalidNightPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de nuitée invalide'**
  String get errInvalidNightPrice;

  /// No description provided for @errInvoiceAlreadyExistsForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Une facture existe déjà pour cette chambre et cette période.'**
  String get errInvoiceAlreadyExistsForPeriod;

  /// No description provided for @invoiceCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Facture créée avec succès. Vous pouvez maintenant l’encaisser ou la fiscaliser.'**
  String get invoiceCreatedSuccess;

  /// No description provided for @errSaveInvoiceFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l’enregistrement de la facture : {error}'**
  String errSaveInvoiceFailed(String error);

  /// No description provided for @actionChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get actionChoose;

  /// No description provided for @paymentDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaissement'**
  String get paymentDialogTitle;

  /// No description provided for @clientInfoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations client'**
  String get clientInfoTitle;

  /// No description provided for @labelClientAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse client'**
  String get labelClientAddress;

  /// No description provided for @labelClientPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone client'**
  String get labelClientPhone;

  /// No description provided for @startLine.
  ///
  /// In fr, this message translates to:
  /// **'Début : {date}'**
  String startLine(String date);

  /// No description provided for @endLine.
  ///
  /// In fr, this message translates to:
  /// **'Fin : {date}'**
  String endLine(String date);

  /// No description provided for @labelOtherServices.
  ///
  /// In fr, this message translates to:
  /// **'Autres services'**
  String get labelOtherServices;

  /// No description provided for @actionSaveInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer facture'**
  String get actionSaveInvoice;

  /// No description provided for @actionSearchInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une facture'**
  String get actionSearchInvoice;

  /// No description provided for @actionNewInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle facture'**
  String get actionNewInvoice;

  /// No description provided for @summaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get summaryTitle;

  /// No description provided for @labelBarRestoConsumptions.
  ///
  /// In fr, this message translates to:
  /// **'Consommations bar/resto'**
  String get labelBarRestoConsumptions;

  /// No description provided for @invoiceAlreadyFiscalizedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Facture déjà fiscalisée'**
  String get invoiceAlreadyFiscalizedLabel;

  /// No description provided for @invoiceSavedAndFiscalized.
  ///
  /// In fr, this message translates to:
  /// **'Facture enregistrée et fiscalisée.'**
  String get invoiceSavedAndFiscalized;

  /// No description provided for @invoiceSavedReady.
  ///
  /// In fr, this message translates to:
  /// **'Facture enregistrée. Prête à être encaissée ou fiscalisée.'**
  String get invoiceSavedReady;

  /// No description provided for @menuManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du menu'**
  String get menuManagementTitle;

  /// No description provided for @errItemNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le nom de l’article.'**
  String get errItemNameRequired;

  /// No description provided for @errCategoryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner la catégorie.'**
  String get errCategoryRequired;

  /// No description provided for @errValidPriceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner un prix valide.'**
  String get errValidPriceRequired;

  /// No description provided for @errItemMustBelongToBarOrKitchen.
  ///
  /// In fr, this message translates to:
  /// **'L’article doit appartenir au bar, à la cuisine, ou aux deux.'**
  String get errItemMustBelongToBarOrKitchen;

  /// No description provided for @errAtLeastOneIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez définir au moins un ingrédient pour cet article.'**
  String get errAtLeastOneIngredient;

  /// No description provided for @menuItemSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Article enregistré avec succès.'**
  String get menuItemSavedSuccess;

  /// No description provided for @photoSaved.
  ///
  /// In fr, this message translates to:
  /// **'Photo enregistrée.'**
  String get photoSaved;

  /// No description provided for @errPhotoSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur enregistrement photo : {error}'**
  String errPhotoSaveFailed(String error);

  /// No description provided for @addIngredientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ingrédient'**
  String get addIngredientTitle;

  /// No description provided for @labelQuantityPerUnitSold.
  ///
  /// In fr, this message translates to:
  /// **'Quantité consommée par unité vendue'**
  String get labelQuantityPerUnitSold;

  /// No description provided for @errFileEmptyOrUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Fichier vide ou illisible.'**
  String get errFileEmptyOrUnreadable;

  /// No description provided for @errUnsupportedFormatExcel.
  ///
  /// In fr, this message translates to:
  /// **'Format non supporté. Utilisez CSV ou Excel.'**
  String get errUnsupportedFormatExcel;

  /// No description provided for @errNoUsableRowInFile.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ligne exploitable trouvée dans le fichier.'**
  String get errNoUsableRowInFile;

  /// No description provided for @rowSkippedInvalidFields.
  ///
  /// In fr, this message translates to:
  /// **'Ligne ignorée : nom/catégorie/prix invalide(s).'**
  String get rowSkippedInvalidFields;

  /// No description provided for @rowSkippedNoDepartment.
  ///
  /// In fr, this message translates to:
  /// **'Article « {name} » ignoré : ni bar ni cuisine.'**
  String rowSkippedNoDepartment(String name);

  /// No description provided for @rowSkippedWithReason.
  ///
  /// In fr, this message translates to:
  /// **'Ligne ignorée : {reason}'**
  String rowSkippedWithReason(String reason);

  /// No description provided for @importedItemsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} article(s) importé(s)'**
  String importedItemsCount(int count);

  /// No description provided for @skippedSuffix.
  ///
  /// In fr, this message translates to:
  /// **' • {count} ignoré(s)'**
  String skippedSuffix(int count);

  /// No description provided for @importResultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résultat de l’import'**
  String get importResultTitle;

  /// No description provided for @departmentKitchenAndBar.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine + Bar'**
  String get departmentKitchenAndBar;

  /// No description provided for @newItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel article'**
  String get newItemTitle;

  /// No description provided for @labelItemName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’article'**
  String get labelItemName;

  /// No description provided for @helperNewOrExistingDish.
  ///
  /// In fr, this message translates to:
  /// **'Tapez un nouveau nom, ou choisissez un plat existant'**
  String get helperNewOrExistingDish;

  /// No description provided for @helperExistingDishPriceOnly.
  ///
  /// In fr, this message translates to:
  /// **'Plat existant : seul le prix est modifiable'**
  String get helperExistingDishPriceOnly;

  /// No description provided for @tooltipNewDish.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau plat'**
  String get tooltipNewDish;

  /// No description provided for @labelCompositionFree.
  ///
  /// In fr, this message translates to:
  /// **'Composition (texte libre)'**
  String get labelCompositionFree;

  /// No description provided for @labelCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get labelCategory;

  /// No description provided for @hintCategoryExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex: boisson, plat, dessert, snack...'**
  String get hintCategoryExample;

  /// No description provided for @labelPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get labelPrice;

  /// No description provided for @dishPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo du plat'**
  String get dishPhotoTitle;

  /// No description provided for @labelAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get labelAvailable;

  /// No description provided for @labelForKitchen.
  ///
  /// In fr, this message translates to:
  /// **'Destiné à la cuisine'**
  String get labelForKitchen;

  /// No description provided for @labelForBar.
  ///
  /// In fr, this message translates to:
  /// **'Destiné au bar'**
  String get labelForBar;

  /// No description provided for @labelFreeAccompaniment.
  ///
  /// In fr, this message translates to:
  /// **'Donne droit à un accompagnement gratuit'**
  String get labelFreeAccompaniment;

  /// No description provided for @labelFreeAccompanimentHint.
  ///
  /// In fr, this message translates to:
  /// **'Le client pourra choisir 1 accompagnement offert.'**
  String get labelFreeAccompanimentHint;

  /// No description provided for @recipeIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recette / ingrédients'**
  String get recipeIngredientsTitle;

  /// No description provided for @noIngredientAdded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ingrédient ajouté.'**
  String get noIngredientAdded;

  /// No description provided for @actionImportExcelCsv.
  ///
  /// In fr, this message translates to:
  /// **'Importer Excel / CSV'**
  String get actionImportExcelCsv;

  /// No description provided for @acceptedColumnsHint.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes acceptées : nom, composition, catégorie, prix, disponible, cuisine, bar.'**
  String get acceptedColumnsHint;

  /// No description provided for @noItemRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article enregistré.'**
  String get noItemRecorded;

  /// No description provided for @menuItemsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Articles du menu'**
  String get menuItemsTitle;

  /// No description provided for @confirmDeleteItem.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’article « {name} » ?'**
  String confirmDeleteItem(String name);

  /// No description provided for @ingredientsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} ingrédient(s)'**
  String ingredientsCount(int count);

  /// No description provided for @errAccessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé.'**
  String get errAccessDenied;

  /// No description provided for @accountingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comptabilité'**
  String get accountingTitle;

  /// No description provided for @accountantWorkspaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réception, contrôle, dépenses, soldes et rapports'**
  String get accountantWorkspaceSubtitle;

  /// No description provided for @moduleReceptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réceptions & Contrôles'**
  String get moduleReceptionsTitle;

  /// No description provided for @moduleReceptionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Versements serveurs, gérante et factures non versées'**
  String get moduleReceptionsSubtitle;

  /// No description provided for @actionReceiveHandovers.
  ///
  /// In fr, this message translates to:
  /// **'Réception des versements'**
  String get actionReceiveHandovers;

  /// No description provided for @actionReceiveHandoversSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôler les versements des serveurs'**
  String get actionReceiveHandoversSubtitle;

  /// No description provided for @actionManagerReception.
  ///
  /// In fr, this message translates to:
  /// **'Réception gérante'**
  String get actionManagerReception;

  /// No description provided for @actionManagerReceptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir les versements transmis par la gérante'**
  String get actionManagerReceptionSubtitle;

  /// No description provided for @actionTrackUntransferred.
  ///
  /// In fr, this message translates to:
  /// **'Suivi non versés'**
  String get actionTrackUntransferred;

  /// No description provided for @actionTrackUntransferredSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivre les factures non encore versées'**
  String get actionTrackUntransferredSubtitle;

  /// No description provided for @moduleExpensesBalancesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses & Soldes'**
  String get moduleExpensesBalancesTitle;

  /// No description provided for @moduleExpensesBalancesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses courantes et soldes précédents'**
  String get moduleExpensesBalancesSubtitle;

  /// No description provided for @expensesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get expensesTitle;

  /// No description provided for @actionExpensesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer et consulter les dépenses'**
  String get actionExpensesSubtitle;

  /// No description provided for @previousBalancesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Soldes précédents'**
  String get previousBalancesTitle;

  /// No description provided for @actionPreviousBalancesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les soldes d’ouverture ou antérieurs'**
  String get actionPreviousBalancesSubtitle;

  /// No description provided for @moduleReportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapports & Points'**
  String get moduleReportsTitle;

  /// No description provided for @moduleReportsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse hebdomadaire et suivi comptable'**
  String get moduleReportsSubtitle;

  /// No description provided for @weeklyReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Point hebdomadaire'**
  String get weeklyReportTitle;

  /// No description provided for @actionWeeklyReportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Produire le point hebdomadaire de comptabilité'**
  String get actionWeeklyReportSubtitle;

  /// No description provided for @expenseSaved.
  ///
  /// In fr, this message translates to:
  /// **'Dépense enregistrée.'**
  String get expenseSaved;

  /// No description provided for @newExpenseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dépense'**
  String get newExpenseTitle;

  /// No description provided for @labelDesignation.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get labelDesignation;

  /// No description provided for @labelAccountType.
  ///
  /// In fr, this message translates to:
  /// **'Type de compte'**
  String get labelAccountType;

  /// No description provided for @expenseHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des dépenses'**
  String get expenseHistoryTitle;

  /// No description provided for @noExpenseRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense enregistrée.'**
  String get noExpenseRecorded;

  /// No description provided for @enteredByLine.
  ///
  /// In fr, this message translates to:
  /// **'Saisi par : {name}'**
  String enteredByLine(String name);

  /// No description provided for @previousBalanceSaved.
  ///
  /// In fr, this message translates to:
  /// **'Solde précédent enregistré.'**
  String get previousBalanceSaved;

  /// No description provided for @newPreviousBalanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde précédent'**
  String get newPreviousBalanceTitle;

  /// No description provided for @balanceHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des soldes'**
  String get balanceHistoryTitle;

  /// No description provided for @noPreviousBalance.
  ///
  /// In fr, this message translates to:
  /// **'Aucun solde précédent.'**
  String get noPreviousBalance;

  /// No description provided for @untransferredFullTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivi factures / encaissements non versés'**
  String get untransferredFullTitle;

  /// No description provided for @noUntransferredInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture non versée.'**
  String get noUntransferredInvoice;

  /// No description provided for @transferStatusLine.
  ///
  /// In fr, this message translates to:
  /// **'Statut transfert : {status}'**
  String transferStatusLine(String status);

  /// No description provided for @statusNotDeclared.
  ///
  /// In fr, this message translates to:
  /// **'non déclaré'**
  String get statusNotDeclared;

  /// No description provided for @untransferredServerCollections.
  ///
  /// In fr, this message translates to:
  /// **'Encaissements serveurs non versés'**
  String get untransferredServerCollections;

  /// No description provided for @noUntransferredServerCollection.
  ///
  /// In fr, this message translates to:
  /// **'Aucun encaissement serveur non versé.'**
  String get noUntransferredServerCollection;

  /// No description provided for @errWeeklySummaryLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement point hebdo : {error}'**
  String errWeeklySummaryLoadFailed(String error);

  /// No description provided for @errPrintFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur impression : {error}'**
  String errPrintFailed(String error);

  /// No description provided for @handoversReceived.
  ///
  /// In fr, this message translates to:
  /// **'Versements reçus'**
  String get handoversReceived;

  /// No description provided for @labelOutflows.
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get labelOutflows;

  /// No description provided for @theoreticalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde théorique'**
  String get theoreticalBalance;

  /// No description provided for @noHandoverAwaitingReception.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement en attente de réception.'**
  String get noHandoverAwaitingReception;

  /// No description provided for @receptionConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Réception confirmée.'**
  String get receptionConfirmed;

  /// No description provided for @actionConfirmReception.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer réception'**
  String get actionConfirmReception;

  /// No description provided for @receptionValidatedQuitusPrinted.
  ///
  /// In fr, this message translates to:
  /// **'Réception validée et quitus imprimé.'**
  String get receptionValidatedQuitusPrinted;

  /// No description provided for @managerHandoverReceptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réception versements gérante'**
  String get managerHandoverReceptionTitle;

  /// No description provided for @pendingHandoversTitle.
  ///
  /// In fr, this message translates to:
  /// **'Versements en attente'**
  String get pendingHandoversTitle;

  /// No description provided for @serversRoomsCounts.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs: {servers} • Chambres: {rooms}'**
  String serversRoomsCounts(int servers, int rooms);

  /// No description provided for @noHandoverReceived.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement reçu.'**
  String get noHandoverReceived;

  /// No description provided for @receivedByLine.
  ///
  /// In fr, this message translates to:
  /// **'Reçu par : {name}'**
  String receivedByLine(String name);

  /// No description provided for @stockItemsManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des articles de stock'**
  String get stockItemsManagementTitle;

  /// No description provided for @labelName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get labelName;

  /// No description provided for @labelUnit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get labelUnit;

  /// No description provided for @labelStore.
  ///
  /// In fr, this message translates to:
  /// **'Store'**
  String get labelStore;

  /// No description provided for @labelActiveItem.
  ///
  /// In fr, this message translates to:
  /// **'Article actif'**
  String get labelActiveItem;

  /// No description provided for @errRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get errRequiredField;

  /// No description provided for @hintItemNameExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Eau minérale 50cl'**
  String get hintItemNameExample;

  /// No description provided for @hintCategoryDrink.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Boisson'**
  String get hintCategoryDrink;

  /// No description provided for @hintUnitExamples.
  ///
  /// In fr, this message translates to:
  /// **'Ex. bouteille, kg, carton'**
  String get hintUnitExamples;

  /// No description provided for @excelExpectedFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format Excel attendu'**
  String get excelExpectedFormat;

  /// No description provided for @recommendedColumns.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes recommandées :'**
  String get recommendedColumns;

  /// No description provided for @exampleRowLabel.
  ///
  /// In fr, this message translates to:
  /// **'Exemple de ligne :'**
  String get exampleRowLabel;

  /// No description provided for @stockImportExampleRow.
  ///
  /// In fr, this message translates to:
  /// **'Eau minérale | Boisson | bouteille | bar | true'**
  String get stockImportExampleRow;

  /// No description provided for @errCannotReadFile.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le fichier. Sélectionne un fichier valide.'**
  String get errCannotReadFile;

  /// No description provided for @errUnsupportedFormatXlsx.
  ///
  /// In fr, this message translates to:
  /// **'Format non supporté. Utilise .xlsx ou .xls'**
  String get errUnsupportedFormatXlsx;

  /// No description provided for @errNoValidRowAfterNormalization.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ligne valide après normalisation. Vérifie les colonnes.'**
  String get errNoValidRowAfterNormalization;

  /// No description provided for @errXlsNotSupportedWeb.
  ///
  /// In fr, this message translates to:
  /// **'Le support .xls hérité n’est pas prévu ici pour Flutter Web. Utilise plutôt un fichier .xlsx sur le web.'**
  String get errXlsNotSupportedWeb;

  /// No description provided for @importedItemsSuccessCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} article(s) importé(s) avec succès.'**
  String importedItemsSuccessCount(int count);

  /// No description provided for @excelImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Import Excel'**
  String get excelImportTitle;

  /// No description provided for @excelImportStockDescription.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier peut être en .xlsx ou .xls. Chaque ligne valide sera ajoutée dans stock_items de cet établissement avec un id Firestore automatique.'**
  String get excelImportStockDescription;

  /// No description provided for @actionImportFromExcel.
  ///
  /// In fr, this message translates to:
  /// **'Importer depuis Excel'**
  String get actionImportFromExcel;

  /// No description provided for @kitchenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get kitchenTitle;

  /// No description provided for @establishmentKitchenTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} - Cuisine'**
  String establishmentKitchenTitle(String name);

  /// No description provided for @newKitchenOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande cuisine'**
  String get newKitchenOrderTitle;

  /// No description provided for @orderNumberLine.
  ///
  /// In fr, this message translates to:
  /// **'Commande {number}'**
  String orderNumberLine(String number);

  /// No description provided for @orderNumberWithClient.
  ///
  /// In fr, this message translates to:
  /// **'Commande {number} - {client}'**
  String orderNumberWithClient(String number, String client);

  /// No description provided for @kitchenOrdersFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Suivi des commandes cuisine de tous les serveurs'**
  String get kitchenOrdersFollowUp;

  /// No description provided for @kitchenStockManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion stock cuisine'**
  String get kitchenStockManagementTitle;

  /// No description provided for @stockManagementCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de Stocks'**
  String get stockManagementCardTitle;

  /// No description provided for @stockManagementCardSubtitleMobile.
  ///
  /// In fr, this message translates to:
  /// **'Composer menu • Ajouter article\nDéclarer consommation • Demander approvisionnement'**
  String get stockManagementCardSubtitleMobile;

  /// No description provided for @stockManagementCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Composer menu • Ajouter article • Déclarer consommation • Demander approvisionnement'**
  String get stockManagementCardSubtitle;

  /// No description provided for @stockConsultationCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Consulter Stocks'**
  String get stockConsultationCardTitle;

  /// No description provided for @stockConsultationCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir les stocks • Confirmer réception • Historique stocks'**
  String get stockConsultationCardSubtitle;

  /// No description provided for @actionComposeMenu.
  ///
  /// In fr, this message translates to:
  /// **'Composer menu'**
  String get actionComposeMenu;

  /// No description provided for @actionAddArticle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter article'**
  String get actionAddArticle;

  /// No description provided for @actionDeclareConsumption.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer une consommation'**
  String get actionDeclareConsumption;

  /// No description provided for @actionRequestSupply.
  ///
  /// In fr, this message translates to:
  /// **'Demander un approvisionnement'**
  String get actionRequestSupply;

  /// No description provided for @actionViewStocks.
  ///
  /// In fr, this message translates to:
  /// **'Voir les stocks'**
  String get actionViewStocks;

  /// No description provided for @actionConfirmAReception.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer une réception'**
  String get actionConfirmAReception;

  /// No description provided for @actionStockHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique stocks'**
  String get actionStockHistory;

  /// No description provided for @stockOutRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sortie de stock - Restaurant'**
  String get stockOutRestaurantTitle;

  /// No description provided for @reasonKitchenPreparation.
  ///
  /// In fr, this message translates to:
  /// **'Préparation cuisine'**
  String get reasonKitchenPreparation;

  /// No description provided for @supplyRequestRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande approvisionnement - Restaurant'**
  String get supplyRequestRestaurantTitle;

  /// No description provided for @stockRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stock Restaurant'**
  String get stockRestaurantTitle;

  /// No description provided for @receptionsToConfirmRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réceptions à confirmer - Restaurant'**
  String get receptionsToConfirmRestaurantTitle;

  /// No description provided for @movementHistoryRestaurantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique mouvements - Restaurant'**
  String get movementHistoryRestaurantTitle;

  /// No description provided for @kitchenOrderReadyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commande cuisine prête'**
  String get kitchenOrderReadyTitle;

  /// No description provided for @kitchenOrderReadyBody.
  ///
  /// In fr, this message translates to:
  /// **'La commande de {client} est prête en cuisine.'**
  String kitchenOrderReadyBody(String client);

  /// No description provided for @clientGeneric.
  ///
  /// In fr, this message translates to:
  /// **'client'**
  String get clientGeneric;

  /// No description provided for @roomLowercaseLine.
  ///
  /// In fr, this message translates to:
  /// **'la chambre {number}'**
  String roomLowercaseLine(String number);

  /// No description provided for @tableLowercaseLine.
  ///
  /// In fr, this message translates to:
  /// **'la table {number}'**
  String tableLowercaseLine(String number);

  /// No description provided for @noKitchenItems.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article cuisine.'**
  String get noKitchenItems;

  /// No description provided for @accompanimentPlainLine.
  ///
  /// In fr, this message translates to:
  /// **'Accompagnement : {name}'**
  String accompanimentPlainLine(String name);

  /// No description provided for @actionServed.
  ///
  /// In fr, this message translates to:
  /// **'Servi'**
  String get actionServed;

  /// No description provided for @statusReadyPlural.
  ///
  /// In fr, this message translates to:
  /// **'Prêtes'**
  String get statusReadyPlural;

  /// No description provided for @errPickKitchenItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un article cuisine.'**
  String get errPickKitchenItem;

  /// No description provided for @errPickAllIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir tous les ingrédients.'**
  String get errPickAllIngredients;

  /// No description provided for @errQuantityMustBePositiveInteger.
  ///
  /// In fr, this message translates to:
  /// **'Chaque quantité doit être un nombre entier positif.'**
  String get errQuantityMustBePositiveInteger;

  /// No description provided for @kitchenIngredientsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients cuisine enregistrés avec succès.'**
  String get kitchenIngredientsSaved;

  /// No description provided for @dishCreatedCompose.
  ///
  /// In fr, this message translates to:
  /// **'Plat « {name} » créé. Vous pouvez maintenant le composer.'**
  String dishCreatedCompose(String name);

  /// No description provided for @errEmptyExcelFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier Excel vide.'**
  String get errEmptyExcelFile;

  /// No description provided for @errNoDataRow.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier ne contient aucune ligne de données.'**
  String get errNoDataRow;

  /// No description provided for @importReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport d’import'**
  String get importReportTitle;

  /// No description provided for @importedRecipesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} recette(s) importée(s)'**
  String importedRecipesCount(int count);

  /// No description provided for @ignoredRowsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} ligne(s) ignorée(s) (incomplètes).'**
  String ignoredRowsCount(int count);

  /// No description provided for @dishesNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Plats non trouvés :'**
  String get dishesNotFound;

  /// No description provided for @ingredientsNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients non trouvés :'**
  String get ingredientsNotFound;

  /// No description provided for @checkNamesMatchApp.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que ces noms correspondent exactement à ceux saisis dans l’application.'**
  String get checkNamesMatchApp;

  /// No description provided for @kitchenItemsCompositionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Composition articles cuisine'**
  String get kitchenItemsCompositionTitle;

  /// No description provided for @errMenuItemsStream.
  ///
  /// In fr, this message translates to:
  /// **'Erreur menuItems : {error}'**
  String errMenuItemsStream(String error);

  /// No description provided for @errStockItemsStream.
  ///
  /// In fr, this message translates to:
  /// **'Erreur stock_items : {error}'**
  String errStockItemsStream(String error);

  /// No description provided for @createNewDishTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau plat'**
  String get createNewDishTitle;

  /// No description provided for @priceSetByManager.
  ///
  /// In fr, this message translates to:
  /// **'Le prix sera fixé par la gérante.'**
  String get priceSetByManager;

  /// No description provided for @labelDishName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du plat'**
  String get labelDishName;

  /// No description provided for @hintDishExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Poulet braisé'**
  String get hintDishExample;

  /// No description provided for @labelKitchenItem.
  ///
  /// In fr, this message translates to:
  /// **'Article cuisine'**
  String get labelKitchenItem;

  /// No description provided for @labelCompositionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Composition (optionnel)'**
  String get labelCompositionOptional;

  /// No description provided for @hintCompositionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Laissez vide pour afficher la liste des ingrédients'**
  String get hintCompositionEmpty;

  /// No description provided for @kitchenIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients cuisine'**
  String get kitchenIngredientsTitle;

  /// No description provided for @actionValidateKitchenComposition.
  ///
  /// In fr, this message translates to:
  /// **'Valider la composition cuisine'**
  String get actionValidateKitchenComposition;

  /// No description provided for @defineKitchenIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Définir les ingrédients cuisine'**
  String get defineKitchenIngredientsTitle;

  /// No description provided for @actionImportExcel.
  ///
  /// In fr, this message translates to:
  /// **'Importer Excel'**
  String get actionImportExcel;

  /// No description provided for @oneRowPerIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Une ligne par ingrédient (le nom du plat est répété).'**
  String get oneRowPerIngredient;

  /// No description provided for @columnsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes :'**
  String get columnsLabel;

  /// No description provided for @recipeImportExampleRows.
  ///
  /// In fr, this message translates to:
  /// **'Poulet braisé | Poulet | 1\nPoulet braisé | Oignon | 2'**
  String get recipeImportExampleRows;

  /// No description provided for @namesMustExistInApp.
  ///
  /// In fr, this message translates to:
  /// **'Les noms des plats et ingrédients doivent déjà exister dans l’application.'**
  String get namesMustExistInApp;

  /// No description provided for @labelIngredientIndex.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient {index}'**
  String labelIngredientIndex(int index);

  /// No description provided for @errChooseIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un ingrédient'**
  String get errChooseIngredient;

  /// No description provided for @errInvalidQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité invalide'**
  String get errInvalidQuantity;

  /// No description provided for @tooltipRemoveLine.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette ligne'**
  String get tooltipRemoveLine;

  /// No description provided for @barTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bar'**
  String get barTitle;

  /// No description provided for @establishmentBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} - Bar'**
  String establishmentBarTitle(String name);

  /// No description provided for @newBarOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande bar'**
  String get newBarOrderTitle;

  /// No description provided for @barOrdersFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Suivi des commandes bar de tous les serveurs'**
  String get barOrdersFollowUp;

  /// No description provided for @barStockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stock Bar'**
  String get barStockTitle;

  /// No description provided for @actionSupply.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement'**
  String get actionSupply;

  /// No description provided for @supplyRequestBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande approvisionnement Bar'**
  String get supplyRequestBarTitle;

  /// No description provided for @actionStockOut.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Stock'**
  String get actionStockOut;

  /// No description provided for @stockOutBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Stock Bar'**
  String get stockOutBarTitle;

  /// No description provided for @reasonBarConsumption.
  ///
  /// In fr, this message translates to:
  /// **'Consommation Bar'**
  String get reasonBarConsumption;

  /// No description provided for @actionMovements.
  ///
  /// In fr, this message translates to:
  /// **'Mouvements'**
  String get actionMovements;

  /// No description provided for @movementHistoryBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique mouvements Bar'**
  String get movementHistoryBarTitle;

  /// No description provided for @actionReceptions.
  ///
  /// In fr, this message translates to:
  /// **'Réceptions'**
  String get actionReceptions;

  /// No description provided for @receptionsBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réceptions Bar'**
  String get receptionsBarTitle;

  /// No description provided for @actionBarItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles Bar'**
  String get actionBarItems;

  /// No description provided for @actionIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get actionIngredients;

  /// No description provided for @errBarItemsLoad.
  ///
  /// In fr, this message translates to:
  /// **'Erreur articles bar : {error}'**
  String errBarItemsLoad(String error);

  /// No description provided for @barStockItemsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Articles de stock - Bar'**
  String get barStockItemsTitle;

  /// No description provided for @newBarItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel article du bar'**
  String get newBarItemTitle;

  /// No description provided for @storeAutoSetToBar.
  ///
  /// In fr, this message translates to:
  /// **'Le store est automatiquement défini sur : bar'**
  String get storeAutoSetToBar;

  /// No description provided for @errItemAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Cet article existe déjà.'**
  String get errItemAlreadyExists;

  /// No description provided for @barItemSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Article du bar enregistré avec succès.'**
  String get barItemSavedSuccess;

  /// No description provided for @actionSaveItem.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l’article'**
  String get actionSaveItem;

  /// No description provided for @hintBarItemNameExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Coca-Cola 33cl'**
  String get hintBarItemNameExample;

  /// No description provided for @hintBarCategoryExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Boisson gazeuse'**
  String get hintBarCategoryExample;

  /// No description provided for @hintBarUnitExamples.
  ///
  /// In fr, this message translates to:
  /// **'Ex. bouteille, canette, carton'**
  String get hintBarUnitExamples;

  /// No description provided for @cocktailCreatedCompose.
  ///
  /// In fr, this message translates to:
  /// **'Cocktail « {name} » créé. Vous pouvez maintenant le composer.'**
  String cocktailCreatedCompose(String name);

  /// No description provided for @barIngredientsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients du cocktail enregistrés avec succès.'**
  String get barIngredientsSaved;

  /// No description provided for @importedCompositionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} composition(s) importée(s)'**
  String importedCompositionsCount(int count);

  /// No description provided for @cocktailsNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cocktails / articles non trouvés :'**
  String get cocktailsNotFound;

  /// No description provided for @oneRowPerBarIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Une ligne par ingrédient (le nom du cocktail est répété).'**
  String get oneRowPerBarIngredient;

  /// No description provided for @cocktailImportExampleRows.
  ///
  /// In fr, this message translates to:
  /// **'Mojito | Rhum | 1\nMojito | Menthe | 1'**
  String get cocktailImportExampleRows;

  /// No description provided for @barNamesMustExistInApp.
  ///
  /// In fr, this message translates to:
  /// **'Les noms des cocktails et ingrédients doivent déjà exister dans l’application.'**
  String get barNamesMustExistInApp;

  /// No description provided for @barCocktailsCompositionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Composition cocktails bar'**
  String get barCocktailsCompositionTitle;

  /// No description provided for @createNewCocktailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau cocktail'**
  String get createNewCocktailTitle;

  /// No description provided for @labelCocktailName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du cocktail'**
  String get labelCocktailName;

  /// No description provided for @hintCocktailExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Mojito'**
  String get hintCocktailExample;

  /// No description provided for @labelBarItemOrCocktail.
  ///
  /// In fr, this message translates to:
  /// **'Cocktail / article du bar'**
  String get labelBarItemOrCocktail;

  /// No description provided for @errPickBarItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un article du bar.'**
  String get errPickBarItem;

  /// No description provided for @barIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients du bar'**
  String get barIngredientsTitle;

  /// No description provided for @actionValidateCocktailComposition.
  ///
  /// In fr, this message translates to:
  /// **'Valider la composition du cocktail'**
  String get actionValidateCocktailComposition;

  /// No description provided for @defineCocktailIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Définir les ingrédients des cocktails'**
  String get defineCocktailIngredientsTitle;

  /// No description provided for @cocktailPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo du cocktail'**
  String get cocktailPhotoTitle;

  /// No description provided for @errPickCocktailOrBarItem.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir un cocktail ou article du bar.'**
  String get errPickCocktailOrBarItem;

  /// No description provided for @hygieneServiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Service Hygiène'**
  String get hygieneServiceTitle;

  /// No description provided for @butlerHygieneLeadTitle.
  ///
  /// In fr, this message translates to:
  /// **'Majordome / Chef service hygiène'**
  String get butlerHygieneLeadTitle;

  /// No description provided for @butlerHygieneLeadSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pilote la préparation des chambres, l’utilisation des produits et les demandes de réapprovisionnement.'**
  String get butlerHygieneLeadSubtitle;

  /// No description provided for @actionDailyHygiene.
  ///
  /// In fr, this message translates to:
  /// **'Hygiène journalière'**
  String get actionDailyHygiene;

  /// No description provided for @actionAddHotelItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter article hôtel'**
  String get actionAddHotelItem;

  /// No description provided for @supplyRequestHotelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande approvisionnement - Hôtel'**
  String get supplyRequestHotelTitle;

  /// No description provided for @actionRequestSupplyShort.
  ///
  /// In fr, this message translates to:
  /// **'Demander approvisionnement'**
  String get actionRequestSupplyShort;

  /// No description provided for @receptionsToConfirmHotelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réceptions à confirmer - Hôtel'**
  String get receptionsToConfirmHotelTitle;

  /// No description provided for @actionValidateReception.
  ///
  /// In fr, this message translates to:
  /// **'Valider réception'**
  String get actionValidateReception;

  /// No description provided for @hotelStockItemsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Articles de stock - Hôtel'**
  String get hotelStockItemsTitle;

  /// No description provided for @newHotelItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel article hôtel'**
  String get newHotelItemTitle;

  /// No description provided for @storeAutoSetToHotel.
  ///
  /// In fr, this message translates to:
  /// **'Le store est automatiquement défini sur : hotel'**
  String get storeAutoSetToHotel;

  /// No description provided for @hotelItemSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Article hôtel enregistré avec succès.'**
  String get hotelItemSavedSuccess;

  /// No description provided for @hintHotelItemNameExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Serviette blanche'**
  String get hintHotelItemNameExample;

  /// No description provided for @hintHotelCategoryExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Linge, Hygiène, Chambre'**
  String get hintHotelCategoryExample;

  /// No description provided for @hintHotelUnitExamples.
  ///
  /// In fr, this message translates to:
  /// **'Ex. pièce, carton, litre'**
  String get hintHotelUnitExamples;

  /// No description provided for @storeNameLine.
  ///
  /// In fr, this message translates to:
  /// **'Magasin : {store}'**
  String storeNameLine(String store);

  /// No description provided for @typeLine.
  ///
  /// In fr, this message translates to:
  /// **'Type : {type}'**
  String typeLine(String type);

  /// No description provided for @quantityUnitLine.
  ///
  /// In fr, this message translates to:
  /// **'Quantité : {quantity} {unit}'**
  String quantityUnitLine(String quantity, String unit);

  /// No description provided for @reasonLine.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String reasonLine(String reason);

  /// No description provided for @byLine.
  ///
  /// In fr, this message translates to:
  /// **'Par : {name}'**
  String byLine(String name);

  /// No description provided for @updatedAtLine.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour : {date}'**
  String updatedAtLine(String date);

  /// No description provided for @noMovementRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mouvement enregistré.'**
  String get noMovementRecorded;

  /// No description provided for @noStockForStore.
  ///
  /// In fr, this message translates to:
  /// **'Aucun stock enregistré pour ce magasin.'**
  String get noStockForStore;

  /// No description provided for @labelStoreWord.
  ///
  /// In fr, this message translates to:
  /// **'Magasin'**
  String get labelStoreWord;

  /// No description provided for @labelLastUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour'**
  String get labelLastUpdate;

  /// No description provided for @actionTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get actionTakePhoto;

  /// No description provided for @actionChooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get actionChooseFromGallery;

  /// No description provided for @errPhotoFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur photo : {error}'**
  String errPhotoFailed(String error);

  /// No description provided for @errSaveDishFirst.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez d’abord le plat, puis ajoutez sa photo.'**
  String get errSaveDishFirst;

  /// No description provided for @errNoDataRowShort.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ligne de données.'**
  String get errNoDataRowShort;

  /// No description provided for @rejectedRowMissingNameUnit.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line} : nom ou unité manquant.'**
  String rejectedRowMissingNameUnit(int line);

  /// No description provided for @rejectedRowUnknownCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line} ({name}) : catégorie inconnue « {category} ».'**
  String rejectedRowUnknownCategory(int line, String name, String category);

  /// No description provided for @rejectedRowUnknownStore.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line} ({name}) : magasin inconnu « {store} ».'**
  String rejectedRowUnknownStore(int line, String name, String store);

  /// No description provided for @createdItemsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} article(s) créé(s)'**
  String createdItemsCount(int count);

  /// No description provided for @ignoredEmptyRowsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} ligne(s) vide(s) ignorée(s).'**
  String ignoredEmptyRowsCount(int count);

  /// No description provided for @existingItemsIgnored.
  ///
  /// In fr, this message translates to:
  /// **'Articles déjà existants (ignorés) :'**
  String get existingItemsIgnored;

  /// No description provided for @rejectedRowsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lignes rejetées :'**
  String get rejectedRowsTitle;

  /// No description provided for @validCategoriesAndStoresHint.
  ///
  /// In fr, this message translates to:
  /// **'Catégories valides : voir la liste du formulaire. Magasins valides : Hôtel, Restaurant, Bar.'**
  String get validCategoriesAndStoresHint;

  /// No description provided for @itemRegistryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Registre des articles'**
  String get itemRegistryTitle;

  /// No description provided for @itemRegistrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Crée et organise les articles de stock avant approvisionnement.'**
  String get itemRegistrySubtitle;

  /// No description provided for @registryImportExampleRows.
  ///
  /// In fr, this message translates to:
  /// **'Riz | Céréales | sac | restaurant\nCoca | Boissons | bouteille | Bar'**
  String get registryImportExampleRows;

  /// No description provided for @registryImportHint.
  ///
  /// In fr, this message translates to:
  /// **'La catégorie doit exister dans la liste. Le magasin : Hôtel, Restaurant ou Bar.'**
  String get registryImportHint;

  /// No description provided for @hintItemNameExamples.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Riz, Huile, Sucre'**
  String get hintItemNameExamples;

  /// No description provided for @labelStoreField.
  ///
  /// In fr, this message translates to:
  /// **'Magasin'**
  String get labelStoreField;

  /// No description provided for @hintUnitExamplesLong.
  ///
  /// In fr, this message translates to:
  /// **'Ex : g, cl, bouteille, sachet, pièce'**
  String get hintUnitExamplesLong;

  /// No description provided for @errUnitRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir l’unité.'**
  String get errUnitRequired;

  /// No description provided for @savedItemsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Articles enregistrés'**
  String get savedItemsTitle;

  /// No description provided for @noItemRecordedYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article enregistré pour le moment.'**
  String get noItemRecordedYet;

  /// No description provided for @startCreatingItemsHint.
  ///
  /// In fr, this message translates to:
  /// **'Commence par créer des articles comme riz, huile, sucre, eau minérale, détergent, etc.'**
  String get startCreatingItemsHint;

  /// No description provided for @noClientRecordOrderless.
  ///
  /// In fr, this message translates to:
  /// **'Aucune fiche client.\nLa commande peut être envoyée sans client.'**
  String get noClientRecordOrderless;

  /// No description provided for @noClientMatchesSearch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client ne correspond à cette recherche.'**
  String get noClientMatchesSearch;

  /// No description provided for @accessDeniedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé'**
  String get accessDeniedTitle;

  /// No description provided for @unauthorizedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle n’est pas reconnu, votre compte n’est pas rattaché à un établissement, ou vous n’avez pas accès à ce module.'**
  String get unauthorizedMessage;

  /// No description provided for @orderStatusSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée'**
  String get orderStatusSent;

  /// No description provided for @orderStatusPartiallyCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Partiellement annulée'**
  String get orderStatusPartiallyCancelled;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusStockError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur stock'**
  String get orderStatusStockError;

  /// No description provided for @datesNotProvided.
  ///
  /// In fr, this message translates to:
  /// **'Dates non renseignées'**
  String get datesNotProvided;

  /// No description provided for @departureOnDate.
  ///
  /// In fr, this message translates to:
  /// **'Départ le {date}'**
  String departureOnDate(String date);

  /// No description provided for @arrivalOnDate.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée le {date}'**
  String arrivalOnDate(String date);

  /// No description provided for @clientHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique · {name}'**
  String clientHistoryTitle(String name);

  /// No description provided for @staysSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Séjours'**
  String get staysSectionTitle;

  /// No description provided for @noStayForClient.
  ///
  /// In fr, this message translates to:
  /// **'Aucun séjour enregistré pour ce client.'**
  String get noStayForClient;

  /// No description provided for @noOrderForClient.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande rattachée à ce client.'**
  String get noOrderForClient;

  /// No description provided for @stayWordSingular.
  ///
  /// In fr, this message translates to:
  /// **'séjour'**
  String get stayWordSingular;

  /// No description provided for @stayWordPlural.
  ///
  /// In fr, this message translates to:
  /// **'séjours'**
  String get stayWordPlural;

  /// No description provided for @totalSpentExcludingCancellations.
  ///
  /// In fr, this message translates to:
  /// **'Total dépensé (hors annulations)'**
  String get totalSpentExcludingCancellations;

  /// No description provided for @barRestaurantConsumptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Consommations bar/restaurant'**
  String get barRestaurantConsumptionsTitle;

  /// No description provided for @noEstablishmentAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement disponible.'**
  String get noEstablishmentAvailable;

  /// No description provided for @adminCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur créé avec succès.'**
  String get adminCreatedSuccess;

  /// No description provided for @errAdminCreationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur création administrateur : {error}'**
  String errAdminCreationFailed(String error);

  /// No description provided for @createEstablishmentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un établissement'**
  String get createEstablishmentTitle;

  /// No description provided for @editEstablishmentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’établissement'**
  String get editEstablishmentTitle;

  /// No description provided for @establishmentCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Établissement créé avec succès.'**
  String get establishmentCreatedSuccess;

  /// No description provided for @errEstablishmentCreationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur création établissement : {error}'**
  String errEstablishmentCreationFailed(String error);

  /// No description provided for @establishmentUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Établissement modifié avec succès.'**
  String get establishmentUpdatedSuccess;

  /// No description provided for @errEstablishmentUpdateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur modification établissement : {error}'**
  String errEstablishmentUpdateFailed(String error);

  /// No description provided for @saasAdministrationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Administration SaaS'**
  String get saasAdministrationTitle;

  /// No description provided for @actionCreateAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Créer administrateur'**
  String get actionCreateAdmin;

  /// No description provided for @actionCreateEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Créer établissement'**
  String get actionCreateEstablishment;

  /// No description provided for @noEstablishmentRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement enregistré.'**
  String get noEstablishmentRecorded;

  /// No description provided for @establishmentInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations établissement'**
  String get establishmentInformation;

  /// No description provided for @labelEstablishmentName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’établissement'**
  String get labelEstablishmentName;

  /// No description provided for @labelIfu.
  ///
  /// In fr, this message translates to:
  /// **'IFU'**
  String get labelIfu;

  /// No description provided for @labelCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get labelCity;

  /// No description provided for @labelCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get labelCountry;

  /// No description provided for @labelEstablishmentType.
  ///
  /// In fr, this message translates to:
  /// **'Type d’établissement'**
  String get labelEstablishmentType;

  /// No description provided for @typeHotelBarRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Hôtel + Bar + Restaurant'**
  String get typeHotelBarRestaurant;

  /// No description provided for @labelPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan'**
  String get labelPlan;

  /// No description provided for @establishmentStatusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get establishmentStatusActive;

  /// No description provided for @establishmentStatusSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get establishmentStatusSuspended;

  /// No description provided for @establishmentStatusTrial.
  ///
  /// In fr, this message translates to:
  /// **'Essai'**
  String get establishmentStatusTrial;

  /// No description provided for @enabledModules.
  ///
  /// In fr, this message translates to:
  /// **'Modules activés'**
  String get enabledModules;

  /// No description provided for @firstEstablishmentAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Premier administrateur établissement'**
  String get firstEstablishmentAdmin;

  /// No description provided for @labelAdminName.
  ///
  /// In fr, this message translates to:
  /// **'Nom administrateur'**
  String get labelAdminName;

  /// No description provided for @labelAdminEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email administrateur'**
  String get labelAdminEmail;

  /// No description provided for @labelTemporaryPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe temporaire'**
  String get labelTemporaryPassword;

  /// No description provided for @hintDefaultTemporaryPassword.
  ///
  /// In fr, this message translates to:
  /// **'Temp@123456 par défaut'**
  String get hintDefaultTemporaryPassword;

  /// No description provided for @globalConsoleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Console globale Takapp SaaS'**
  String get globalConsoleTitle;

  /// No description provided for @globalConsoleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer les établissements, activer les modules, gérer les plans et initialiser les administrateurs.'**
  String get globalConsoleSubtitle;

  /// No description provided for @unnamedEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Établissement sans nom'**
  String get unnamedEstablishment;

  /// No description provided for @idLine.
  ///
  /// In fr, this message translates to:
  /// **'ID : {id}'**
  String idLine(String id);

  /// No description provided for @ifuLine.
  ///
  /// In fr, this message translates to:
  /// **'IFU : {ifu}'**
  String ifuLine(String ifu);

  /// No description provided for @planChipLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plan {plan}'**
  String planChipLabel(String plan);

  /// No description provided for @createEstablishmentAdminTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un administrateur d’établissement'**
  String get createEstablishmentAdminTitle;

  /// No description provided for @labelEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get labelEstablishment;

  /// No description provided for @noStatus.
  ///
  /// In fr, this message translates to:
  /// **'Sans statut'**
  String get noStatus;

  /// No description provided for @pdfPhoneLine.
  ///
  /// In fr, this message translates to:
  /// **'Tél : {phone}'**
  String pdfPhoneLine(String phone);

  /// No description provided for @pdfIfuLine.
  ///
  /// In fr, this message translates to:
  /// **'IFU : {ifu}'**
  String pdfIfuLine(String ifu);

  /// No description provided for @pdfHandoverValidationTitle.
  ///
  /// In fr, this message translates to:
  /// **'VALIDATION DE VERSEMENT'**
  String get pdfHandoverValidationTitle;

  /// No description provided for @pdfDeclaredAmountLine.
  ///
  /// In fr, this message translates to:
  /// **'Montant déclaré : {amount}'**
  String pdfDeclaredAmountLine(String amount);

  /// No description provided for @pdfPaymentsCountLine.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de paiements : {count}'**
  String pdfPaymentsCountLine(int count);

  /// No description provided for @pdfColMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get pdfColMethod;

  /// No description provided for @pdfColMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode'**
  String get pdfColMode;

  /// No description provided for @pdfColQty.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get pdfColQty;

  /// No description provided for @pdfTotalCapsLine.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL : {amount}'**
  String pdfTotalCapsLine(String amount);

  /// No description provided for @pdfSimpleAccountingReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'RAPPORT COMPTABLE SIMPLE'**
  String get pdfSimpleAccountingReportTitle;

  /// No description provided for @pdfPeriodLine.
  ///
  /// In fr, this message translates to:
  /// **'Période : {start} - {end}'**
  String pdfPeriodLine(String start, String end);

  /// No description provided for @pdfEntriesLine.
  ///
  /// In fr, this message translates to:
  /// **'Entrées : {amount}'**
  String pdfEntriesLine(String amount);

  /// No description provided for @pdfExitsLine.
  ///
  /// In fr, this message translates to:
  /// **'Sorties : {amount}'**
  String pdfExitsLine(String amount);

  /// No description provided for @pdfTheoreticalBalanceLine.
  ///
  /// In fr, this message translates to:
  /// **'Solde théorique : {amount}'**
  String pdfTheoreticalBalanceLine(String amount);

  /// No description provided for @pdfEstablishmentIdLine.
  ///
  /// In fr, this message translates to:
  /// **'Établissement ID : {id}'**
  String pdfEstablishmentIdLine(String id);

  /// No description provided for @pdfOrderTicketTitle.
  ///
  /// In fr, this message translates to:
  /// **'TICKET DE COMMANDE'**
  String get pdfOrderTicketTitle;

  /// No description provided for @pdfOrderLine.
  ///
  /// In fr, this message translates to:
  /// **'Commande : {number}'**
  String pdfOrderLine(String number);

  /// No description provided for @pdfClientTypeLine.
  ///
  /// In fr, this message translates to:
  /// **'Type client : {type}'**
  String pdfClientTypeLine(String type);

  /// No description provided for @pdfTableLine.
  ///
  /// In fr, this message translates to:
  /// **'Table : {number}'**
  String pdfTableLine(String number);

  /// No description provided for @pdfRoomLine.
  ///
  /// In fr, this message translates to:
  /// **'Chambre : {number}'**
  String pdfRoomLine(String number);

  /// No description provided for @pdfNoteLine.
  ///
  /// In fr, this message translates to:
  /// **'Note : {note}'**
  String pdfNoteLine(String note);

  /// No description provided for @pdfSubtotalLine.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total : {amount}'**
  String pdfSubtotalLine(String amount);

  /// No description provided for @pdfTotalLine.
  ///
  /// In fr, this message translates to:
  /// **'Total : {amount}'**
  String pdfTotalLine(String amount);

  /// No description provided for @pdfPaymentReceiptTitle.
  ///
  /// In fr, this message translates to:
  /// **'REÇU D’ENCAISSEMENT'**
  String get pdfPaymentReceiptTitle;

  /// No description provided for @pdfCashierLine.
  ///
  /// In fr, this message translates to:
  /// **'Encaisseur : {name}'**
  String pdfCashierLine(String name);

  /// No description provided for @pdfPaymentMethodLine.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement : {method}'**
  String pdfPaymentMethodLine(String method);

  /// No description provided for @pdfAmountReceived.
  ///
  /// In fr, this message translates to:
  /// **'Montant reçu'**
  String get pdfAmountReceived;

  /// No description provided for @pdfThanksForVisit.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre visite.'**
  String get pdfThanksForVisit;

  /// No description provided for @pdfServerHandoverSlipTitle.
  ///
  /// In fr, this message translates to:
  /// **'BORDEREAU DE VERSEMENT SERVEUR'**
  String get pdfServerHandoverSlipTitle;

  /// No description provided for @pdfDeclarationDateLine.
  ///
  /// In fr, this message translates to:
  /// **'Date déclaration : {date}'**
  String pdfDeclarationDateLine(String date);

  /// No description provided for @pdfStatusLine.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {status}'**
  String pdfStatusLine(String status);

  /// No description provided for @pdfIncludedPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements inclus'**
  String get pdfIncludedPayments;

  /// No description provided for @pdfQuitusTitle.
  ///
  /// In fr, this message translates to:
  /// **'QUITUS DE VALIDATION'**
  String get pdfQuitusTitle;

  /// No description provided for @pdfAccountLine.
  ///
  /// In fr, this message translates to:
  /// **'Compte : {account}'**
  String pdfAccountLine(String account);

  /// No description provided for @pdfTheoreticalAmountLine.
  ///
  /// In fr, this message translates to:
  /// **'Montant théorique : {amount}'**
  String pdfTheoreticalAmountLine(String amount);

  /// No description provided for @pdfPhysicalAmountLine.
  ///
  /// In fr, this message translates to:
  /// **'Montant physique : {amount}'**
  String pdfPhysicalAmountLine(String amount);

  /// No description provided for @pdfValidatedByLine.
  ///
  /// In fr, this message translates to:
  /// **'Validé par : {name}'**
  String pdfValidatedByLine(String name);

  /// No description provided for @pdfAmountsRecognizedEquivalent.
  ///
  /// In fr, this message translates to:
  /// **'Les montants théorique et physique ont été reconnus équivalents.'**
  String get pdfAmountsRecognizedEquivalent;

  /// No description provided for @labelTotalWord.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get labelTotalWord;

  /// No description provided for @managerHandoverAccountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Versement gérante'**
  String get managerHandoverAccountLabel;

  /// No description provided for @catCereals.
  ///
  /// In fr, this message translates to:
  /// **'Céréales'**
  String get catCereals;

  /// No description provided for @catDrinks.
  ///
  /// In fr, this message translates to:
  /// **'Boissons'**
  String get catDrinks;

  /// No description provided for @catCondiments.
  ///
  /// In fr, this message translates to:
  /// **'Condiments'**
  String get catCondiments;

  /// No description provided for @catMeats.
  ///
  /// In fr, this message translates to:
  /// **'Viandes'**
  String get catMeats;

  /// No description provided for @catMeat.
  ///
  /// In fr, this message translates to:
  /// **'viande'**
  String get catMeat;

  /// No description provided for @catVegetablesFruits.
  ///
  /// In fr, this message translates to:
  /// **'Légumes et fruits'**
  String get catVegetablesFruits;

  /// No description provided for @catDairy.
  ///
  /// In fr, this message translates to:
  /// **'Produits laitiers'**
  String get catDairy;

  /// No description provided for @catCleaningProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits d’entretien'**
  String get catCleaningProducts;

  /// No description provided for @catHotelConsumables.
  ///
  /// In fr, this message translates to:
  /// **'Consommables hôtel'**
  String get catHotelConsumables;

  /// No description provided for @catFishPlural.
  ///
  /// In fr, this message translates to:
  /// **'Poissons'**
  String get catFishPlural;

  /// No description provided for @catFish.
  ///
  /// In fr, this message translates to:
  /// **'poisson'**
  String get catFish;

  /// No description provided for @catSideDishes.
  ///
  /// In fr, this message translates to:
  /// **'Accompagnements'**
  String get catSideDishes;

  /// No description provided for @catBread.
  ///
  /// In fr, this message translates to:
  /// **'Pain'**
  String get catBread;

  /// No description provided for @catBreads.
  ///
  /// In fr, this message translates to:
  /// **'Pains'**
  String get catBreads;

  /// No description provided for @catCheese.
  ///
  /// In fr, this message translates to:
  /// **'fromage'**
  String get catCheese;

  /// No description provided for @catBurger.
  ///
  /// In fr, this message translates to:
  /// **'Hamberger'**
  String get catBurger;

  /// No description provided for @catPasta.
  ///
  /// In fr, this message translates to:
  /// **'pate'**
  String get catPasta;

  /// No description provided for @catSauce.
  ///
  /// In fr, this message translates to:
  /// **'sauce'**
  String get catSauce;

  /// No description provided for @catSauces.
  ///
  /// In fr, this message translates to:
  /// **'Sauces'**
  String get catSauces;

  /// No description provided for @catEgg.
  ///
  /// In fr, this message translates to:
  /// **'œuf'**
  String get catEgg;

  /// No description provided for @catBlanket.
  ///
  /// In fr, this message translates to:
  /// **'couverture'**
  String get catBlanket;

  /// No description provided for @catConsumable.
  ///
  /// In fr, this message translates to:
  /// **'consommable'**
  String get catConsumable;

  /// No description provided for @catReusable.
  ///
  /// In fr, this message translates to:
  /// **'reutilisable'**
  String get catReusable;

  /// No description provided for @catMeatAndFish.
  ///
  /// In fr, this message translates to:
  /// **'Viandes et poissons'**
  String get catMeatAndFish;

  /// No description provided for @catOther.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get catOther;

  /// No description provided for @catMainDish.
  ///
  /// In fr, this message translates to:
  /// **'plat'**
  String get catMainDish;

  /// No description provided for @catPoultry.
  ///
  /// In fr, this message translates to:
  /// **'Volailles'**
  String get catPoultry;

  /// No description provided for @catPastaPlural.
  ///
  /// In fr, this message translates to:
  /// **'Pates'**
  String get catPastaPlural;

  /// No description provided for @catSeafood.
  ///
  /// In fr, this message translates to:
  /// **'Fruits de mer'**
  String get catSeafood;

  /// No description provided for @catAfricanSpecialties.
  ///
  /// In fr, this message translates to:
  /// **'Spécialités africaines'**
  String get catAfricanSpecialties;

  /// No description provided for @catBurgersSandwiches.
  ///
  /// In fr, this message translates to:
  /// **'Burger et Sandwichs'**
  String get catBurgersSandwiches;

  /// No description provided for @catLebaneseStarters.
  ///
  /// In fr, this message translates to:
  /// **'Etrées libanaises'**
  String get catLebaneseStarters;

  /// No description provided for @catColdStarters.
  ///
  /// In fr, this message translates to:
  /// **'Entrées froides'**
  String get catColdStarters;

  /// No description provided for @catPizzas.
  ///
  /// In fr, this message translates to:
  /// **'Pizzas'**
  String get catPizzas;

  /// No description provided for @catFastFood.
  ///
  /// In fr, this message translates to:
  /// **'Fast food'**
  String get catFastFood;

  /// No description provided for @catDesserts.
  ///
  /// In fr, this message translates to:
  /// **'Desserts'**
  String get catDesserts;

  /// No description provided for @catBarDrink.
  ///
  /// In fr, this message translates to:
  /// **'boisson'**
  String get catBarDrink;

  /// No description provided for @catCocktails.
  ///
  /// In fr, this message translates to:
  /// **'Cocktails'**
  String get catCocktails;

  /// No description provided for @catAlcoholicCocktails.
  ///
  /// In fr, this message translates to:
  /// **'Cocktails alcoolisés'**
  String get catAlcoholicCocktails;

  /// No description provided for @catNonAlcoholic.
  ///
  /// In fr, this message translates to:
  /// **'Sans alcool'**
  String get catNonAlcoholic;

  /// No description provided for @catShots.
  ///
  /// In fr, this message translates to:
  /// **'Shots et shots composés'**
  String get catShots;

  /// No description provided for @catBeers.
  ///
  /// In fr, this message translates to:
  /// **'Bières'**
  String get catBeers;

  /// No description provided for @catSparkling.
  ///
  /// In fr, this message translates to:
  /// **'Bulles'**
  String get catSparkling;

  /// No description provided for @catWinesChampagnes.
  ///
  /// In fr, this message translates to:
  /// **'Vins et Champagnes'**
  String get catWinesChampagnes;

  /// No description provided for @catRedWines.
  ///
  /// In fr, this message translates to:
  /// **'Vins rouges'**
  String get catRedWines;

  /// No description provided for @catWhiteWines.
  ///
  /// In fr, this message translates to:
  /// **'Vins blancs'**
  String get catWhiteWines;

  /// No description provided for @catRoses.
  ///
  /// In fr, this message translates to:
  /// **'Rosés'**
  String get catRoses;

  /// No description provided for @catChampagnes.
  ///
  /// In fr, this message translates to:
  /// **'Champagnes'**
  String get catChampagnes;

  /// No description provided for @catSpirits.
  ///
  /// In fr, this message translates to:
  /// **'Spiritueux'**
  String get catSpirits;

  /// No description provided for @catCognacs.
  ///
  /// In fr, this message translates to:
  /// **'Cognacs'**
  String get catCognacs;

  /// No description provided for @catVodkas.
  ///
  /// In fr, this message translates to:
  /// **'Vodkas'**
  String get catVodkas;

  /// No description provided for @catBittersAnise.
  ///
  /// In fr, this message translates to:
  /// **'Betters/Anisées'**
  String get catBittersAnise;

  /// No description provided for @catRumGinTequila.
  ///
  /// In fr, this message translates to:
  /// **'Rhum/Gin-Tequila'**
  String get catRumGinTequila;

  /// No description provided for @catCreamLiqueurs.
  ///
  /// In fr, this message translates to:
  /// **'Liqueurs crèmes'**
  String get catCreamLiqueurs;

  /// No description provided for @catWhiskeys.
  ///
  /// In fr, this message translates to:
  /// **'Whiskeys'**
  String get catWhiskeys;

  /// No description provided for @catJuices.
  ///
  /// In fr, this message translates to:
  /// **'Jus'**
  String get catJuices;

  /// No description provided for @catPlainJuices.
  ///
  /// In fr, this message translates to:
  /// **'Jus natures'**
  String get catPlainJuices;

  /// No description provided for @catSmoothies.
  ///
  /// In fr, this message translates to:
  /// **'Smoothies'**
  String get catSmoothies;

  /// No description provided for @catSyrup.
  ///
  /// In fr, this message translates to:
  /// **'Sirop'**
  String get catSyrup;

  /// No description provided for @catHotDrinks.
  ///
  /// In fr, this message translates to:
  /// **'Boissons chaudes'**
  String get catHotDrinks;

  /// No description provided for @catSodas.
  ///
  /// In fr, this message translates to:
  /// **'Sodas'**
  String get catSodas;

  /// No description provided for @catWaters.
  ///
  /// In fr, this message translates to:
  /// **'Eaux'**
  String get catWaters;

  /// No description provided for @reasonSupplyValidated.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement validé'**
  String get reasonSupplyValidated;

  /// No description provided for @reasonRoomPreparation.
  ///
  /// In fr, this message translates to:
  /// **'Préparation chambre {room}'**
  String reasonRoomPreparation(String room);

  /// No description provided for @reasonAutoOrderConsumption.
  ///
  /// In fr, this message translates to:
  /// **'Consommation automatique commande {order}'**
  String reasonAutoOrderConsumption(String order);

  /// No description provided for @reasonAutoOrderRestock.
  ///
  /// In fr, this message translates to:
  /// **'Restitution automatique annulation commande {order}'**
  String reasonAutoOrderRestock(String order);

  /// No description provided for @categorySubcategorySeparator.
  ///
  /// In fr, this message translates to:
  /// **'{parent} › {child}'**
  String categorySubcategorySeparator(String parent, String child);

  /// No description provided for @userCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur créé avec succès.'**
  String get userCreatedSuccess;

  /// No description provided for @errUserCreationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur création utilisateur : {error}'**
  String errUserCreationFailed(String error);

  /// No description provided for @errAmountsNotEquivalent.
  ///
  /// In fr, this message translates to:
  /// **'Montants non équivalents.'**
  String get errAmountsNotEquivalent;

  /// No description provided for @quitusGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Quitus généré.'**
  String get quitusGenerated;

  /// No description provided for @establishmentOwnerTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} - Propriétaire'**
  String establishmentOwnerTitle(String name);

  /// No description provided for @actionCreateUser.
  ///
  /// In fr, this message translates to:
  /// **'Créer utilisateur'**
  String get actionCreateUser;

  /// No description provided for @createUserTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un utilisateur'**
  String get createUserTitle;

  /// No description provided for @labelPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get labelPeriod;

  /// No description provided for @labelAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get labelAccount;

  /// No description provided for @labelRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get labelRole;

  /// No description provided for @physicalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde physique'**
  String get physicalBalance;

  /// No description provided for @theoreticalBalanceAmount.
  ///
  /// In fr, this message translates to:
  /// **'Solde théorique : {amount} FCFA'**
  String theoreticalBalanceAmount(String amount);

  /// No description provided for @totalTheoreticalBalanceAmount.
  ///
  /// In fr, this message translates to:
  /// **'Solde théorique total : {amount} FCFA'**
  String totalTheoreticalBalanceAmount(String amount);

  /// No description provided for @errNameEmailPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom, email et mot de passe temporaire obligatoires.'**
  String get errNameEmailPasswordRequired;

  /// No description provided for @labelAction.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get labelAction;

  /// No description provided for @hygieneRoomsToPrepareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hygiène — chambres à préparer'**
  String get hygieneRoomsToPrepareTitle;

  /// No description provided for @noRoomSimple.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chambre.'**
  String get noRoomSimple;

  /// No description provided for @roomsToCleanHint.
  ///
  /// In fr, this message translates to:
  /// **'{count} chambre(s) à nettoyer. Touchez une chambre pour déclarer le ménage.'**
  String roomsToCleanHint(int count);

  /// No description provided for @noRoomToCleanHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chambre à nettoyer pour le moment. Touchez une chambre pour déclarer un ménage.'**
  String get noRoomToCleanHint;

  /// No description provided for @errSelectProductAtLine.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne le produit à la ligne {line}.'**
  String errSelectProductAtLine(int line);

  /// No description provided for @errProductNotFoundAtLine.
  ///
  /// In fr, this message translates to:
  /// **'Produit introuvable à la ligne {line}.'**
  String errProductNotFoundAtLine(int line);

  /// No description provided for @errAddAtLeastOneProductUsed.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins un produit utilisé.'**
  String get errAddAtLeastOneProductUsed;

  /// No description provided for @cleaningRecordedForRoom.
  ///
  /// In fr, this message translates to:
  /// **'Ménage enregistré pour la chambre {room}.'**
  String cleaningRecordedForRoom(String room);

  /// No description provided for @declareCleaningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer le ménage'**
  String get declareCleaningTitle;

  /// No description provided for @labelPreparedRoomNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de chambre préparée'**
  String get labelPreparedRoomNumber;

  /// No description provided for @hintCleaningNotes.
  ///
  /// In fr, this message translates to:
  /// **'Ex: draps changés, serviettes renouvelées'**
  String get hintCleaningNotes;

  /// No description provided for @noProductInHotelStock.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit dans le stock hôtel.'**
  String get noProductInHotelStock;

  /// No description provided for @canSaveWithoutItem.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez tout de même enregistrer sans article (sauf si un article est requis).'**
  String get canSaveWithoutItem;

  /// No description provided for @labelProductUsed.
  ///
  /// In fr, this message translates to:
  /// **'Produit utilisé'**
  String get labelProductUsed;

  /// No description provided for @labelQuantityUsed.
  ///
  /// In fr, this message translates to:
  /// **'Quantité utilisée'**
  String get labelQuantityUsed;

  /// No description provided for @actionAddProduct.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un produit'**
  String get actionAddProduct;

  /// No description provided for @actionSaveCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le ménage'**
  String get actionSaveCleaning;

  /// No description provided for @labelProductIndex.
  ///
  /// In fr, this message translates to:
  /// **'Produit {index}'**
  String labelProductIndex(int index);

  /// No description provided for @labelNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get labelNote;

  /// No description provided for @disableClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver ce client ?'**
  String get disableClientTitle;

  /// No description provided for @disableClientBody.
  ///
  /// In fr, this message translates to:
  /// **'La fiche de « {name} » ne sera plus proposée, mais les séjours et factures existants ne sont pas supprimés.'**
  String disableClientBody(String name);

  /// No description provided for @actionAddClient.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un client'**
  String get actionAddClient;

  /// No description provided for @noClientRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client enregistré.\nCréez votre première fiche client.'**
  String get noClientRegistered;

  /// No description provided for @actionViewHistory.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’historique'**
  String get actionViewHistory;

  /// No description provided for @clientUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Client modifié.'**
  String get clientUpdated;

  /// No description provided for @editClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le client'**
  String get editClientTitle;

  /// No description provided for @newClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau client'**
  String get newClientTitle;

  /// No description provided for @labelNameOrCompany.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou raison sociale'**
  String get labelNameOrCompany;

  /// No description provided for @hintClientNameExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Kossi ADJOVI, SARL BENIN TRADE...'**
  String get hintClientNameExample;

  /// No description provided for @clientTypeIndividual.
  ///
  /// In fr, this message translates to:
  /// **'Particulier'**
  String get clientTypeIndividual;

  /// No description provided for @clientTypeCompany.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get clientTypeCompany;

  /// No description provided for @hintPhoneExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 97 00 00 00'**
  String get hintPhoneExample;

  /// No description provided for @labelIfuOptional.
  ///
  /// In fr, this message translates to:
  /// **'IFU (optionnel)'**
  String get labelIfuOptional;

  /// No description provided for @hintIfuPurpose.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant fiscal, surtout pour les entreprises'**
  String get hintIfuPurpose;

  /// No description provided for @labelAddressOptional.
  ///
  /// In fr, this message translates to:
  /// **'Adresse (optionnel)'**
  String get labelAddressOptional;

  /// No description provided for @labelEmailOptional.
  ///
  /// In fr, this message translates to:
  /// **'Email (optionnel)'**
  String get labelEmailOptional;

  /// No description provided for @duplicateClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Client déjà existant ?'**
  String get duplicateClientTitle;

  /// No description provided for @duplicateClientBody.
  ///
  /// In fr, this message translates to:
  /// **'Un ou plusieurs clients ressemblent à celui que vous créez :'**
  String get duplicateClientBody;

  /// No description provided for @nameDotPhone.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {phone}'**
  String nameDotPhone(String name, String phone);

  /// No description provided for @homonymsExistHint.
  ///
  /// In fr, this message translates to:
  /// **'Les homonymes existent : vous pouvez créer quand même.'**
  String get homonymsExistHint;

  /// No description provided for @actionCreateAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Créer quand même'**
  String get actionCreateAnyway;
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
