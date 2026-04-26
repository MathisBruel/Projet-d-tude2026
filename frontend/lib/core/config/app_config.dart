import 'package:flutter/foundation.dart';

class AppConfig {
  /// URL de base de l'API. 
  /// Peut être surchargée à la compilation avec --dart-define=API_URL=...
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5000', // IP par défaut pour l'émulateur Android vers le localhost PC
  );

  static bool get isDebug => kDebugMode;
}
