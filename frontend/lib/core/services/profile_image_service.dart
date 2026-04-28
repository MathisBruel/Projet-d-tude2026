import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service global pour persister et partager l'image de profil
class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();

  factory ProfileImageService() {
    return _instance;
  }

  ProfileImageService._internal();

  File? _profileImage;
  static const String _profileImageFileName = 'profile_image.png';

  /// Initialiser le service et charger l'image persistée
  Future<void> initialize() async {
    _profileImage = await _loadProfileImage();
  }

  /// Charger l'image persistée depuis le stockage local
  Future<File?> _loadProfileImage() async {
    try {
      final appDocDir = await getApplicationCacheDirectory();
      final profileImageFile = File('${appDocDir.path}/$_profileImageFileName');

      if (await profileImageFile.exists()) {
        return profileImageFile;
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'image de profil: $e');
    }
    return null;
  }

  /// Sauvegarder l'image de profil
  Future<void> setProfileImage(File sourceImage) async {
    try {
      final appDocDir = await getApplicationCacheDirectory();
      final targetFile = File('${appDocDir.path}/$_profileImageFileName');

      // Copier l'image vers le dossier cache de l'app
      await sourceImage.copy(targetFile.path);

      _profileImage = targetFile;
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'image de profil: $e');
    }
  }

  /// Obtenir l'image de profil
  File? getProfileImage() {
    return _profileImage;
  }

  /// Vérifier si une image de profil existe
  bool hasProfileImage() {
    return _profileImage != null;
  }

  /// Effacer l'image de profil
  Future<void> clearProfileImage() async {
    try {
      if (_profileImage != null && await _profileImage!.exists()) {
        await _profileImage!.delete();
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'image de profil: $e');
    }
    _profileImage = null;
  }
}
