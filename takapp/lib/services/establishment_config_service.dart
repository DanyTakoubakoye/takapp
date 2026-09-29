import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/modeles/stock_mode.dart';

class EstablishmentConfigService {
  final FirebaseFirestore _firestore;

  EstablishmentConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<StockMode> watchStockMode(String establishmentId) {
    final id = establishmentId.trim();
    if (id.isEmpty) return Stream.value(StockMode.strict);

    return _firestore
        .collection('establishments')
        .doc(id)
        .snapshots()
        .map((snapshot) => StockMode.fromValue(snapshot.data()?['stockMode']));
  }
}
