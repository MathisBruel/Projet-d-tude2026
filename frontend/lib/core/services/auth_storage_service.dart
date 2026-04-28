import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorageService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';

  static const _secureStorage = FlutterSecureStorage();

  /// Sauvegarde le JWT token
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Récupère le JWT token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Sauvegarde l'ID utilisateur
  static Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }

  /// Récupère l'ID utilisateur
  static Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Efface le token et l'ID utilisateur (logout)
  static Future<void> clearAuth() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  /// Vérifie si l'utilisateur est authentifié
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
