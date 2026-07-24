import 'package:cloud_firestore/cloud_firestore.dart';

class ServeurService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> enregistrerServeur({
    required String nomComplet,
    required String telephone,
    required String email,
  }) async {
    final docRef = _firestore.collection('users').doc();

    await docRef.set({
      'name': nomComplet.trim(),
      'phone': telephone.trim(),
      'email': email.trim(),
      'role': 'serveur',
      "fcmToken": "....",
      'mustChangePassword': false,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
