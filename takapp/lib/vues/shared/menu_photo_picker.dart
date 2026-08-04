import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takapp/services/menu_image_service.dart';

/// Widget réutilisable pour ajouter/changer la photo d'un plat.
/// Affiche un aperçu (si photo existante) + un bouton pour choisir/prendre
/// une photo. Une fois l'upload terminé, appelle [onUploaded] avec l'URL.
class MenuPhotoPicker extends StatefulWidget {
  final String establishmentId;
  final String menuItemId;
  final String? currentImageUrl;
  final ValueChanged<String> onUploaded;

  const MenuPhotoPicker({
    super.key,
    required this.establishmentId,
    required this.menuItemId,
    required this.onUploaded,
    this.currentImageUrl,
  });

  @override
  State<MenuPhotoPicker> createState() => _MenuPhotoPickerState();
}

class _MenuPhotoPickerState extends State<MenuPhotoPicker> {
  final MenuImageService _service = MenuImageService();
  bool _uploading = false;
  String? _localUrl;

  String? get _displayUrl => _localUrl ?? widget.currentImageUrl;

  Future<void> _choose(ImageSource source) async {
    if (widget.menuItemId.trim().isEmpty) {
      _msg('Enregistrez d\'abord le plat, puis ajoutez sa photo.');
      return;
    }
    try {
      final bytes = await _service.pickImageBytes(source: source);
      if (bytes == null) return; // annulé

      setState(() => _uploading = true);

      final url = await _service.uploadMenuItemImage(
        establishmentId: widget.establishmentId,
        menuItemId: widget.menuItemId,
        imageBytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _localUrl = url;
        _uploading = false;
      });
      widget.onUploaded(url);
      _msg('Photo enregistrée.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _msg('Erreur photo : $e');
    }
  }

  void _openSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _choose(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(sheetContext);
                _choose(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final url = _displayUrl;
    final hasImage = url != null && url.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: _uploading
              ? const Center(child: CircularProgressIndicator())
              : hasImage
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 40),
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 6),
                      Text(
                        'Aucune photo',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _uploading ? null : _openSourceSheet,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(hasImage ? 'Changer la photo' : 'Ajouter une photo'),
        ),
      ],
    );
  }
}
