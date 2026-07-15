import 'package:flutter/material.dart';
import '../services/serveur_service.dart';

class ServeurController extends ChangeNotifier {
  final ServeurService _serveurService;

  ServeurController({ServeurService? serveurService})
    : _serveurService = serveurService ?? ServeurService();

  bool _isLoading = false;

  String? _errorMessage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<String?> enregistrerServeur({
    required String establishmentId,
    required String nomComplet,
    required String telephone,
    required String email,
  }) async {
    if (establishmentId.trim().isEmpty) {
      _errorMessage = 'Établissement introuvable.';
      notifyListeners();
      return _errorMessage;
    }

    if (nomComplet.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir le nom du serveur.';
      notifyListeners();
      return _errorMessage;
    }

    if (telephone.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir le numéro de téléphone.';
      notifyListeners();
      return _errorMessage;
    }

    if (email.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir une adresse email.';
      notifyListeners();
      return _errorMessage;
    }

    try {
      _isLoading = true;
      _errorMessage = null;

      notifyListeners();

      await _serveurService.enregistrerServeur(
        establishmentId: establishmentId,
        nomComplet: nomComplet.trim(),
        telephone: telephone.trim(),
        email: email.trim(),
      );

      return null;
    } catch (e) {
      _errorMessage =
          "Erreur lors de l'enregistrement du serveur : ${e.toString().replaceFirst('Exception: ', '')}";

      return _errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
