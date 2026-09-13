import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController(this._authService);

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isResetLoading = false;
  bool _isInitialized = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isResetLoading => _isResetLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;

  bool get hasError => _error != null;

  /// Message d'erreur traduit dans la langue active, ou `null` s'il n'y a
  /// pas d'erreur. C'est l'UI qui appelle cette méthode, car elle seule
  /// dispose d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  String get establishmentId => _currentUser?.establishmentId ?? '';
  String get establishmentName => _currentUser?.establishmentName ?? '';
  String get currentUserId => _currentUser?.uid ?? '';
  String get currentUserName => _currentUser?.name ?? '';
  String get currentUserRole => _currentUser?.role ?? '';

  bool get hasValidEstablishment {
    return establishmentId.trim().isNotEmpty;
  }

  bool get isGlobalAdmin => currentUserRole == 'global_admin';

  bool get isSuperAdmin => currentUserRole == 'super_admin';

  bool get isPlatformAdmin => isGlobalAdmin || isSuperAdmin;

  bool get isProprietaire => currentUserRole == 'proprietaire';

  bool get isGerante => currentUserRole == 'gerante';

  bool get isComptable => currentUserRole == 'comptable';

  bool get isServeur => currentUserRole == 'serveur';

  bool get isChefCuisine => currentUserRole == 'chef_cuisine';

  bool get isBarman => currentUserRole == 'barman';

  bool get isServiceHygiene {
    return currentUserRole == 'service_hygiene' ||
        currentUserRole == 'majordhomme';
  }

  bool get canAccessRestaurant {
    return _currentUser?.canAccessRestaurant == true;
  }

  bool get canAccessBar {
    return _currentUser?.canAccessBar == true;
  }

  bool get canAccessHotel {
    return _currentUser?.canAccessHotel == true;
  }

  bool get canAccessStock {
    return _currentUser?.canAccessStock == true;
  }

  bool get canAccessFiscalization {
    return _currentUser?.canAccessFiscalization == true;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.getCurrentUserProfile();

      if (_currentUser != null && !isPlatformAdmin && !hasValidEstablishment) {
        await _authService.signOut();
        _currentUser = null;
        _error = const AppError(AppErrorCode.accountWithoutEstablishment);
      }
    } catch (e) {
      _error = _mapError(e);
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

      if (_currentUser != null && !isPlatformAdmin && !hasValidEstablishment) {
        await _authService.signOut();
        _currentUser = null;
        _error = const AppError(AppErrorCode.accountWithoutEstablishment);
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isResetLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseAuthCode(e.code) ??
          const AppError(AppErrorCode.resetEmailFailed);
      return false;
    } catch (e) {
      debugPrint('Erreur générale reset password: $e');
      _error = const AppError(AppErrorCode.unknown);
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
      _error = _mapError(e);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// =========================
  /// MAPPING DES ERREURS
  /// =========================
  ///
  /// Traduit les codes Firebase en [AppError]. Une erreur non reconnue est
  /// renvoyée telle quelle : `localizedError()` affichera son texte brut
  /// plutôt que de masquer l'information.
  static AppError? _mapFirebaseAuthCode(String code) {
    switch (code) {
      case 'invalid-credential':
        return const AppError(AppErrorCode.invalidCredential);
      case 'user-not-found':
        return const AppError(AppErrorCode.userNotFound);
      case 'wrong-password':
        return const AppError(AppErrorCode.wrongPassword);
      case 'network-request-failed':
        return const AppError(AppErrorCode.networkRequestFailed);
      case 'permission-denied':
        return const AppError(AppErrorCode.permissionDenied);
      default:
        return null;
    }
  }

  static Object _mapError(Object error) {
    if (error is AppError) return error;

    if (error is FirebaseAuthException) {
      final mapped = _mapFirebaseAuthCode(error.code);
      if (mapped != null) return mapped;
    }

    /// Repli : certaines erreurs n'exposent pas de code exploitable et
    /// n'arrivent ici que sous forme de texte.
    final text = error.toString();

    if (text.contains('invalid-credential')) {
      return const AppError(AppErrorCode.invalidCredential);
    }
    if (text.contains('user-not-found')) {
      return const AppError(AppErrorCode.userNotFound);
    }
    if (text.contains('wrong-password')) {
      return const AppError(AppErrorCode.wrongPassword);
    }
    if (text.contains('network-request-failed')) {
      return const AppError(AppErrorCode.networkRequestFailed);
    }
    if (text.contains('permission-denied')) {
      return const AppError(AppErrorCode.permissionDenied);
    }

    return error;
  }
}
