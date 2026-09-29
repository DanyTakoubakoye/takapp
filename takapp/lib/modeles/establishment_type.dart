/// Types d'établissement : valeurs TECHNIQUES stockées dans Firestore
/// (`establishments/{id}.type`). Les libellés affichés sont traduits à part
/// et ne servent jamais d'identifiant.
class EstablishmentType {
  const EstablishmentType._();

  static const String hotelBarRestaurant = 'hotel_bar_restaurant';
  static const String hotel = 'hotel';
  static const String restaurant = 'restaurant';
  static const String bar = 'bar';

  static const List<String> values = [
    hotelBarRestaurant,
    hotel,
    restaurant,
    bar,
  ];

  /// Valeur utilisée quand le type est absent ou inconnu : c'était déjà la
  /// valeur par défaut d'un établissement sans type.
  static const String fallback = hotelBarRestaurant;

  /// Ramène une valeur Firestore, ancienne ou saisie à la main, à une valeur
  /// technique connue : `Hotel`, `Hôtel`, `HOTEL` → `hotel` ;
  /// `Hôtel + Bar + Restaurant`, `hotel, bar et restaurant` →
  /// `hotel_bar_restaurant`. Toute autre valeur → [fallback].
  static String normalize(Object? raw) {
    final text = (raw ?? '').toString().trim().toLowerCase().replaceAll(
      RegExp('[ôö]'),
      'o',
    );

    final tokens = text
        .split(RegExp('[^a-z]+'))
        .where((t) => t.isNotEmpty && t != 'et' && t != 'and')
        .toSet();

    if (tokens.length == 1 && values.contains(tokens.first)) {
      return tokens.first;
    }

    if (tokens.length == 3 && tokens.containsAll({hotel, bar, restaurant})) {
      return hotelBarRestaurant;
    }

    return fallback;
  }
}
