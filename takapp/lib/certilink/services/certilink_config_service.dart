import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/certilink_config_model.dart';

class CertilinkConfigService {
  final FirebaseFirestore _firestore;

  CertilinkConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _configRef(String establishmentId) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('certilink_config')
        .doc('config');
  }

  Future<CertilinkConfigModel> getConfig(String establishmentId) async {
    final doc = await _configRef(establishmentId).get();

    if (!doc.exists) {
      return CertilinkConfigModel.empty();
    }

    return CertilinkConfigModel.fromMap(doc.data());
  }

  Stream<CertilinkConfigModel> streamConfig(String establishmentId) {
    return _configRef(establishmentId).snapshots().map((doc) {
      if (!doc.exists) {
        return CertilinkConfigModel.empty();
      }

      return CertilinkConfigModel.fromMap(doc.data());
    });
  }

  Future<void> saveConfig({
    required String establishmentId,
    required CertilinkConfigModel config,
  }) async {
    await _configRef(establishmentId).set({
      ...config.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> disableConfig(String establishmentId) async {
    await _configRef(establishmentId).set({
      'enabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
