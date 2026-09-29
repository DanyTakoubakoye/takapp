import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/stock_mode.dart';

class EstablishmentConfigService {
  final FirebaseFirestore _firestore;

  EstablishmentConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mode de stock d'un document établissement : document absent, champ
  /// absent (établissement ancien) ou valeur inconnue => strict.
  static StockMode stockModeFromData(Map<String, dynamic>? data) {
    return StockMode.fromValue(data?['stockMode']);
  }

  /// Flux temps réel : chaque modification du Global Admin est reçue sans
  /// reconnexion. Le document Firestore reste l'unique source de vérité.
  Stream<StockMode> watchStockMode(String establishmentId) {
    final id = establishmentId.trim();
    if (id.isEmpty) return Stream.value(StockMode.strict);

    return _firestore
        .collection('establishments')
        .doc(id)
        .snapshots()
        .map((snapshot) => stockModeFromData(snapshot.data()));
  }
}
