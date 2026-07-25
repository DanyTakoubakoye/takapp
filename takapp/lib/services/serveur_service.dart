import 'package:cloud_firestore/cloud_firestore.dart';

class ServeurService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _usersCol({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('users');
  }

  void _validateEstablishmentId(String establishmentId) {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }
  }

  /// =========================
  /// CREATE SERVER USER
  /// =========================

  Future<void> enregistrerServeur({
    required String establishmentId,
    required String nomComplet,
    required String telephone,
    required String email,
  }) async {
    _validateEstablishmentId(establishmentId);

    final cleanName = nomComplet.trim();

    final cleanPhone = telephone.trim();

    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw Exception('Nom du serveur invalide.');
    }

    if (cleanEmail.isEmpty) {
      throw Exception('Email invalide.');
    }

    /// =========================
    /// CHECK EXISTING EMAIL
    /// =========================

    final existing = await _usersCol(
      establishmentId: establishmentId,
    ).where('email', isEqualTo: cleanEmail).limit(1).get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Un utilisateur avec cet email existe déjà.');
    }

    /// =========================
    /// CREATE USER
    /// =========================

    final docRef = _usersCol(establishmentId: establishmentId).doc();

    await docRef.set({
      'uid': docRef.id,

      'establishmentId': establishmentId,

      'name': cleanName,

      'phone': cleanPhone,

      'email': cleanEmail,

      'role': 'serveur',

      'fcmToken': '',

      'mustChangePassword': false,

      'isActive': true,

      'isDeleted': false,

      'createdAt': FieldValue.serverTimestamp(),

      'updatedAt': FieldValue.serverTimestamp(),

      'pendingSync': false,

      'syncError': false,
    });
  }
}
