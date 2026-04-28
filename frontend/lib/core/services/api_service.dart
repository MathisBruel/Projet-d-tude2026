import 'dart:convert';
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
}
