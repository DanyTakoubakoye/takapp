import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final userService = FirebaseAuth.instance.currentUser;
    if (userService != null) {
      await NotificationService().registerTokenForCurrentUser();
      NotificationService().startServerNotificationListener(userService.uid);
    }

    final uid = credential.user!.uid;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception("Le profil utilisateur est introuvable dans Firestore.");
    }

    final user = UserModel.fromMap(doc.data()!, doc.id);

    if (!user.isActive) {
      await _auth.signOut();
      throw Exception("Ce compte est désactivé.");
    }

    return user;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> signOut() async {
  NotificationService().stopServerNotificationListener();
    await _auth.signOut();
  }
}
