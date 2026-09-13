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
}
