import 'package:flutter/material.dart';

class AppColors {
  static const black = Color(0xFF000000);
  static const ink = Color(0xFF0D0D0D);
  static const white = Color(0xFFFFFFFF);
  static const gray900 = Color(0xFF1A1A1A);
  static const gray700 = Color(0xFF404040);
  static const gray500 = Color(0xFF8A8A8A);
  static const gray300 = Color(0xFFD0D0D0);
  static const gray100 = Color(0xFFECECEC);
  static const gray50 = Color(0xFFF6F6F6);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? AppColors.white : AppColors.ink,
      onPrimary: dark ? AppColors.ink : AppColors.white,
      secondary: AppColors.gray700,
      onSecondary: AppColors.white,
      error: const Color(0xFF8C2F2F),
      onError: AppColors.white,
      surface: dark ? AppColors.ink : AppColors.white,
      onSurface: dark ? AppColors.white : AppColors.ink,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: dark ? AppColors.gray900 : AppColors.gray100,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.gray900 : AppColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dark ? AppColors.gray700 : AppColors.gray100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dark ? AppColors.gray700 : AppColors.gray100),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.4),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        bodySmall: TextStyle(fontSize: 12, height: 1.35),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}
