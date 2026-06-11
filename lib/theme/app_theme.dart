import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.azulOscuroLogo,
      scaffoldBackgroundColor: AppColors.blancoPuro,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.azulOscuroLogo,
        onPrimary: AppColors.blancoPuro,
        secondary: AppColors.tealTurquesaSanitario,
        onSecondary: AppColors.blancoPuro,
        tertiary: AppColors.naranjaCalido,
        onTertiary: AppColors.blancoPuro,
        error: Colors.red,
        onError: Colors.white,
        background: AppColors.blancoPuro,
        onBackground: AppColors.textoPrincipal,
        surface: AppColors.blancoPuro,
        onSurface: AppColors.textoPrincipal,
        surfaceVariant: AppColors.grisClaro,
        onSurfaceVariant: AppColors.textoSecundario,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azulOscuroLogo,
        foregroundColor: AppColors.blancoPuro,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.blancoPuro,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.blancoPuro),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.naranjaCalido,
          foregroundColor: AppColors.blancoPuro,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.azulOscuroLogo,
          side: const BorderSide(color: AppColors.azulOscuroLogo, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.azulOscuroLogo,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grisClaro,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grisClaro, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.azulOscuroLogo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        labelStyle: const TextStyle(color: AppColors.textoSecundario),
        hintStyle: const TextStyle(color: AppColors.textoSecundario),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.blancoPuro,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.grisClaro,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
