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

  /// No description provided for @actionBack.
  ///
  /// In fr, this message translates to:
  /// **'Revenir'**
  String get actionBack;

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
