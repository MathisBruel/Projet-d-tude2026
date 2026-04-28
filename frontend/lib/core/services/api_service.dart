import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_storage_service.dart';

class ApiService {
  /// Obtient les headers avec le JWT
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorageService.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Teste la connexion avec le backend
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Erreur HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Erreur: $e'};
    }
  }

  /// Inscription d'un nouvel utilisateur
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur de connexion : $e'};
    }
  }

  /// Connexion
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur de connexion : $e'};
    }
  }

  /// Récupère la liste des parcelles de l'utilisateur
  static Future<Map<String, dynamic>> getParcels() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/v1/parcels'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la récupération des parcelles : $e'};
    }
  }

  /// Crée une nouvelle parcelle
  static Future<Map<String, dynamic>> createParcel(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/v1/parcels'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la création de la parcelle : $e'};
    }
  }

  /// Récupère les détails d'une parcelle
  static Future<Map<String, dynamic>> getParcel(String parcelId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/v1/parcels/$parcelId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la récupération de la parcelle : $e'};
    }
  }

  /// Met à jour une parcelle
  static Future<Map<String, dynamic>> updateParcel(
    String parcelId,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl}/api/v1/parcels/$parcelId'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la mise à jour de la parcelle : $e'};
    }
  }

  /// Supprime une parcelle
  static Future<Map<String, dynamic>> deleteParcel(String parcelId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('${AppConfig.apiUrl}/api/v1/parcels/$parcelId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la suppression de la parcelle : $e'};
    }
  }

  /// Récupère les posts de la communauté
  static Future<Map<String, dynamic>> getCommunityPosts({String? tag, String? search}) async {
    try {
      final headers = await _authHeaders();
      final queryParameters = <String, String>{};
      if (tag != null && tag.isNotEmpty) {
        queryParameters['tag'] = tag;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      final uri = Uri.parse('${AppConfig.apiUrl}/api/v1/community/posts')
          .replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la récupération des posts : $e'};
    }
  }

  /// Récupère le détail d'un post
  static Future<Map<String, dynamic>> getCommunityPost(String postId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/v1/community/posts/$postId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la récupération du post : $e'};
    }
  }

  /// Crée un post
  static Future<Map<String, dynamic>> createCommunityPost(
    Map<String, dynamic> data, {
    File? imageFile,
  }
  ) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${AppConfig.apiUrl}/api/v1/community/posts');
      final request = http.MultipartRequest('POST', uri);

      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
      }

      request.fields['title'] = data['title']?.toString() ?? '';
      request.fields['content'] = data['content']?.toString() ?? '';
      final tags = (data['tags'] as List<dynamic>? ?? []).map((tag) => tag.toString()).toList();
      request.fields['tags'] = tags.join(',');

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la creation du post : $e'};
    }
  }

  /// Ajoute une réponse
  static Future<Map<String, dynamic>> addCommunityReply(
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/v1/community/posts/$postId/replies'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la reponse : $e'};
    }
  }

  /// Ajoute un like sur un post
  static Future<Map<String, dynamic>> likeCommunityPost(String postId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/v1/community/posts/$postId/like'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors du like : $e'};
    }
  }

  /// Récupère le profil utilisateur
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/v1/profile'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la recuperation du profil : $e'};
    }
  }

  /// Met à jour le profil utilisateur (first_name, last_name, phone, location_*)
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl}/api/v1/profile'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur lors de la mise à jour du profil : $e'};
    }
  }

  /// Upload l'avatar de profil
  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final token = await AuthStorageService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiUrl}/api/v1/profile/avatar'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        return {'error': 'Erreur HTTP ${response.statusCode}', 'body': responseBody};
      }
    } catch (e) {
      return {'error': 'Erreur lors de l\'upload de l\'avatar : $e'};
    }
  }

  /// Récupère la météo actuelle + prévisions 7 jours pour une position GPS
  static Future<Map<String, dynamic>> getWeather(double lat, double lng) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/v1/weather?lat=$lat&lng=$lng'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur météo : $e'};
    }
  }

  /// Génère des alertes agronomiques sur 7 jours pour une position GPS
  static Future<Map<String, dynamic>> getWeatherAlerts({
    required double lat,
    required double lng,
    String? cultureType,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = <String, dynamic>{'lat': lat, 'lng': lng};
      if (cultureType != null && cultureType.isNotEmpty) {
        body['culture_type'] = cultureType;
      }
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/v1/alerts/weather'),
        headers: headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur alertes météo : $e'};
    }
  }

  /// Récupère l'historique des prédictions
  static Future<Map<String, dynamic>> getPredictions({int limit = 20}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/v1/predictions/history?limit=$limit'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur prédictions : $e'};
    }
  }

  /// Lance une prédiction de rendement IA
  static Future<Map<String, dynamic>> predict({
    required double lat,
    required double lng,
    required String cultureType,
    String? parcelId,
    double? pesticidesTonnes,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'culture_type': cultureType,
      };
      if (parcelId != null) body['parcel_id'] = parcelId;
      if (pesticidesTonnes != null) body['pesticides_tonnes'] = pesticidesTonnes;

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/v1/predictions/predict'),
        headers: headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur prédiction IA : $e'};
    }
  }

  /// Récupère la liste des cultures supportées par le modèle ML
  static Future<Map<String, dynamic>> getSupportedCrops() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/v1/predictions/crops'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Erreur récupération cultures : $e'};
    }
  }

  /// Géocode une adresse via Nominatim (OpenStreetMap, sans clé)
  static Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}&limit=1',
      );
      final response = await http.get(uri, headers: {'User-Agent': 'AgriSense/1.0'});
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      // Simplify display_name to city, department/country
      final displayName = first['display_name'] as String? ?? address;
      final parts = displayName.split(',');
      final shortName = parts.take(2).map((s) => s.trim()).join(', ');
      return {
        'lat': double.parse(first['lat'] as String),
        'lng': double.parse(first['lon'] as String),
        'display_name': shortName,
      };
    } catch (e) {
      return null;
    }
  }
}
