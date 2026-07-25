import 'package:takapp/modeles/menu_item_model.dart';
import 'package:takapp/modeles/user_model.dart';

/// Filtrage À L'AFFICHAGE des contenus selon les modules souscrits.
///
/// Masquer les tuiles/points d'entrée ne suffit pas : à l'intérieur d'écrans
/// partagés (prise de commande, magasins de stock…), du contenu d'un module
/// non souscrit peut rester visible. Ces helpers centralisent la règle.
///
/// INVARIANT : un établissement abonné à tout se comporte EXACTEMENT comme
/// avant. Chaque fonction fait un court-circuit (ou renvoie `true`) quand tous
/// les modules concernés sont accessibles, donc aucun contenu n'est retiré.
///
/// Aucun modèle ni service de base n'est modifié : le filtrage est purement UI.
extension ModuleVisibility on UserModel {
  /// Un article du menu est-il visible compte tenu des modules souscrits ?
  ///
  /// - article bar uniquement (`isForBar && !isForKitchen`) : visible ssi
  ///   [canAccessBar]
  /// - article restaurant uniquement (`isForKitchen && !isForBar`) : visible
  ///   ssi [canAccessRestaurant]
  /// - article mixte (les deux drapeaux) : visible si AU MOINS un des deux
  ///   modules est accessible (il reste un article restaurant légitime)
  /// - article sans destination (aucun drapeau) : toujours visible
  ///   (comportement historique préservé)
  bool canSeeMenuItem(MenuItemModel item) {
    final bar = item.isForBar;
    final kitchen = item.isForKitchen;

    if (bar && !kitchen) return canAccessBar;
    if (kitchen && !bar) return canAccessRestaurant;
    if (bar && kitchen) return canAccessBar || canAccessRestaurant;
    return true;
  }

  /// Filtre une liste d'articles pour n'afficher que ceux des modules souscrits.
  ///
  /// Court-circuit : bar ET restaurant accessibles ⇒ liste renvoyée telle
  /// quelle (comportement identique à aujourd'hui).
  List<MenuItemModel> visibleMenuItems(List<MenuItemModel> items) {
    if (canAccessBar && canAccessRestaurant) return items;
    return items.where(canSeeMenuItem).toList();
  }

  /// Un magasin de stock est-il visible ?
  /// `store` ∈ {`restaurant`, `bar`, `hotel`, `divers`}.
  ///
  /// `divers` et toute valeur inconnue restent toujours visibles.
  bool canSeeStore(String store) {
    switch (store.trim().toLowerCase()) {
      case 'bar':
        return canAccessBar;
      case 'restaurant':
        return canAccessRestaurant;
      case 'hotel':
        return canAccessHotel;
      default:
        return true;
    }
  }

  /// Un type de client (`bar`/`restaurant`/`hotel`) est-il proposable dans un
  /// sélecteur de prise de commande ?
  bool canUseClientType(String clientType) {
    switch (clientType.trim().toLowerCase()) {
      case 'bar':
        return canAccessBar;
      case 'restaurant':
        return canAccessRestaurant;
      case 'hotel':
        return canAccessHotel;
      default:
        return true;
    }
  }
}
