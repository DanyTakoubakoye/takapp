import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception("Utilisateur Firebase introuvable après connexion.");
    }

    final user = await _loadUserProfile(firebaseUser.uid);

    if (!user.isActive) {
      await _auth.signOut();
      throw Exception("Ce compte est désactivé.");
    }

    if (!_hasValidSaasAccess(user)) {
      await _auth.signOut();
      throw Exception("Ce compte n’est rattaché à aucun établissement.");
    }

    if (!_isGlobalAdmin(user)) {
      await NotificationService().registerTokenForCurrentUser();

      if (user.establishmentId.trim().isNotEmpty) {
        NotificationService().startServerNotificationListener(
          establishmentId: user.establishmentId.trim(),
          serveurId: firebaseUser.uid,
        );
      }
    }

    return user;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    final user = await _loadUserProfile(firebaseUser.uid);

    if (!user.isActive) {
      await _auth.signOut();
      return null;
    }

    if (!_hasValidSaasAccess(user)) {
      await _auth.signOut();
      return null;
    }

    if (!_isGlobalAdmin(user)) {
      await NotificationService().registerTokenForCurrentUser();

      if (user.establishmentId.trim().isNotEmpty) {
        NotificationService().startServerNotificationListener(
          establishmentId: user.establishmentId.trim(),
          serveurId: firebaseUser.uid,
        );
      }
    }

    return user;
  }

  Future<void> signOut() async {
    NotificationService().stopServerNotificationListener();
    await _auth.signOut();
  }

  Future<UserModel> _loadUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception("Le profil utilisateur est introuvable dans Firestore.");
    }

    final data = doc.data()!;
    final establishmentId = (data['establishmentId'] ?? '').toString().trim();

    // Abonnement de l'établissement : plafonne les droits du rôle.
    // En cas d'absence d'établissement ou d'échec de lecture, on laisse
    // establishmentModules à null => fail-open (aucune restriction ajoutée).
    Map<String, dynamic>? establishmentModules;

    if (establishmentId.isNotEmpty) {
      try {
        final estabDoc = await _firestore
            .collection('establishments')
            .doc(establishmentId)
            .get();

        final estabData = estabDoc.data();
        final rawModules = estabData?['modules'];

        if (rawModules is Map) {
          establishmentModules = Map<String, dynamic>.from(rawModules);
        }
      } catch (_) {
        establishmentModules = null;
      }
    }

    return UserModel.fromMap(
      data,
      doc.id,
      establishmentModules: establishmentModules,
    );
  }

  bool _isGlobalAdmin(UserModel user) {
    final role = user.role.trim();
    return role == 'global_admin' || role == 'super_admin';
  }

  bool _hasValidSaasAccess(UserModel user) {
    if (_isGlobalAdmin(user)) {
      return true;
    }

    return user.establishmentId.trim().isNotEmpty;
  }
}
