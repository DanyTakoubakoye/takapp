import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MenuImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Laisse l'utilisateur choisir une photo (caméra ou galerie).
  /// Retourne les octets de l'image (compatibles web + mobile),
  /// ou null si annulé.
  Future<Uint8List?> pickImageBytes({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return await picked.readAsBytes();
  }

  /// Envoie la photo d'un plat vers Storage (chemin fixe par plat →
  /// remplace l'ancienne) et retourne l'URL de téléchargement.
  /// Multi-tenant : la photo est rangée sous l'établissement.
  Future<String> uploadMenuItemImage({
    required String establishmentId,
    required String menuItemId,
    required Uint8List imageBytes,
  }) async {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }
    if (menuItemId.trim().isEmpty) {
      throw Exception('Identifiant du plat invalide.');
    }

    final path = 'establishments/$establishmentId/menuItems/$menuItemId.jpg';
    final ref = _storage.ref(path);

    await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));

    final url = await ref.getDownloadURL();

    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Supprime la photo d'un plat (pour un futur bouton "retirer").
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
