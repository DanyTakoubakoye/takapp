import 'package:flutter/material.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import '../services/serveur_service.dart';

class ServeurController extends ChangeNotifier {
  final ServeurService _serveurService;

  ServeurController({ServeurService? serveurService})
    : _serveurService = serveurService ?? ServeurService();

  bool _isLoading = false;

  /// Erreur courante : un [AppError] traduisible, ou une exception brute
  /// pas encore migrée. Jamais un texte destiné à l'affichage.
  Object? _error;

  bool get isLoading => _isLoading;

  bool get hasError => _error != null;

  /// Message traduit dans la langue active, ou `null` s'il n'y a pas
  /// d'erreur. Appelé par l'UI, seule à disposer d'un `BuildContext`.
  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  /// Renvoie `null` en cas de succès, sinon l'erreur à traduire par l'UI
  /// (via `localizedError()`). Ne renvoie jamais de texte déjà formaté :
  /// le contrôleur ne connaît pas la langue de l'utilisateur.
  Future<Object?> enregistrerServeur({
    required String establishmentId,
    required String nomComplet,
    required String telephone,
    required String email,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _error = const AppError(AppErrorCode.establishmentNotFound);
      notifyListeners();
      return _error;
    }

    if (nomComplet.trim().isEmpty) {
      _error = const AppError(AppErrorCode.serverNameRequired);
      notifyListeners();
      return _error;
    }

    if (telephone.trim().isEmpty) {
      _error = const AppError(AppErrorCode.phoneRequired);
      notifyListeners();
      return _error;
    }

    if (email.trim().isEmpty) {
      _error = const AppError(AppErrorCode.emailRequired);
      notifyListeners();
      return _error;
    }

    try {
      _isLoading = true;
      _error = null;

      notifyListeners();

      await _serveurService.enregistrerServeur(
        establishmentId: establishmentId,
        nomComplet: nomComplet.trim(),
        telephone: telephone.trim(),
        email: email.trim(),
      );

      return null;
    } catch (e) {
      _error = AppError(
        AppErrorCode.serverRegistrationFailed,
        name: e.toString().replaceFirst('Exception: ', ''),
      );

      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
