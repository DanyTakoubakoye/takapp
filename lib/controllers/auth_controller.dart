import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController(this._authService);

  UserModel? _currentUser;
  bool _isLoading = false; // pour login/logout/initialisation
  bool _isResetLoading = false; // uniquement pour mot de passe oublié
  String? _errorMessage;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isResetLoading => _isResetLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.getCurrentUserProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isResetLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}');
      debugPrint('FirebaseAuthException message: ${e.message}');
      _errorMessage = e.message ?? 'Erreur lors de l’envoi du mail';
      return false;
    } catch (e) {
      debugPrint('Erreur générale reset password: $e');
      _errorMessage = 'Une erreur est survenue';
      return false;
    } finally {
      _isResetLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.contains('invalid-credential')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (text.contains('user-not-found')) {
      return 'Utilisateur introuvable.';
    }
    if (text.contains('wrong-password')) {
      return 'Mot de passe incorrect.';
    }
    if (text.contains('network-request-failed')) {
      return 'Problème réseau. Vérifiez votre connexion.';
    }

    return text.replaceFirst('Exception: ', '');
  }
}
