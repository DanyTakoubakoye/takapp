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
  String errStockInsufficient(String name) {
    return 'Stock insuffisant pour $name.';
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
