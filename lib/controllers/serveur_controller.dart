import 'package:flutter/material.dart';
import '../services/serveur_service.dart';

class ServeurController extends ChangeNotifier {
  final ServeurService _serveurService;

  ServeurController({ServeurService? serveurService})
    : _serveurService = serveurService ?? ServeurService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> enregistrerServeur({
    required String nomComplet,
    required String telephone,
    required String email,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _serveurService.enregistrerServeur(
        nomComplet: nomComplet,
        telephone: telephone,
        email: email,
      );

      return null;
    } catch (e) {
      return "Erreur lors de l'enregistrement du serveur : $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
