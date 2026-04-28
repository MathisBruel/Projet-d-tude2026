import 'package:flutter/material.dart';

class AppColors {
  // Palette principale
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color surfacePrimary = Color(0xFFE8F5E9);
  
  // Accents
  static const Color secondary = Color(0xFFF9A825);
  static const Color surfaceAmber = Color(0xFFFFF8E1);

  // Neutres
  static const Color neutreDark = Color(0xFF1C2B2D);
  static const Color neutreMedium = Color(0xFF546E7A);
  static const Color neutreLight = Color(0xFFECEFF1);
  static const Color background = Color(0xFFF4F6F4);
  static const Color white = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF388E3C);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);

  // Utiles
  static const Color border = Color(0xFFE0E0E0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        error: AppColors.error,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // Typographie
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.neutreDark),
        displayMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.neutreDark),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.neutreDark),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.neutreMedium),
        labelLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),

      // Décoration des Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.neutreMedium, fontSize: 14),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
