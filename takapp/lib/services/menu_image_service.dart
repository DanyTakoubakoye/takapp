import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MenuImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Laisse l'utilisateur choisir une photo (caméra ou galerie).
  /// Retourne le fichier sélectionné, ou null si annulé.
  Future<File?> pickImage({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200, // compression : on limite la taille
      maxHeight: 1200,
      imageQuality: 80, // qualité JPEG (0-100), 80 = bon compromis
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Envoie la photo d'un plat vers Storage (chemin fixe par plat →
  /// remplace l'ancienne) et retourne l'URL de téléchargement.
  /// On ajoute un paramètre anti-cache pour forcer le rafraîchissement.
  Future<String> uploadMenuItemImage({
    required String establishmentId,
    required String menuItemId,
    required File imageFile,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }
    if (menuItemId.trim().isEmpty) {
      throw Exception('Identifiant du plat invalide.');
    }

    final path = 'establishments/$establishmentId/menuItems/$menuItemId.jpg';
    final ref = _storage.ref(path);

    await ref.putData(
      await imageFile.readAsBytes(),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await ref.getDownloadURL();

    // Anti-cache : l'URL du chemin fixe ne change pas quand on remplace
    // la photo, donc on ajoute un timestamp pour forcer le rechargement.
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Supprime la photo d'un plat (optionnel, pour un futur bouton "retirer").
  Future<void> deleteMenuItemImage({
    required String establishmentId,
    required String menuItemId,
  }) async {
    final path = 'establishments/$establishmentId/menuItems/$menuItemId.jpg';
    try {
      await _storage.ref(path).delete();
    } catch (_) {
      // Silencieux : si la photo n'existe pas, rien à supprimer.
    }
  }
}
