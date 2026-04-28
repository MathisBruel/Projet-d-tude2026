import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late String apiUrl;
  static late String googleMapsApiKey;

  static Future<void> init() async {
    await dotenv.load();

    apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:5000';
    googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  static bool get isDebug => kDebugMode;
}
