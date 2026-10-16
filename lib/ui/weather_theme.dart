import 'package:flutter/material.dart';

abstract final class WeatherPalette {
  static const background = Color(0xFF07111F);
  static const surface = Color(0xFF111E2D);
  static const surfaceRaised = Color(0xFF172638);
  static const accent = Color(0xFF8ED8D2);
  static const accentWarm = Color(0xFFFFC98B);
  static const muted = Color(0xFF9BAABC);
}

abstract final class WeatherTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: WeatherPalette.accent,
      brightness: Brightness.dark,
      surface: WeatherPalette.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: WeatherPalette.background,
      fontFamily: 'Avenir Next',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 38, fontWeight: FontWeight.w600, letterSpacing: -1.2),
        headlineMedium: TextStyle(
            fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: -0.7),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        bodyMedium:
            TextStyle(fontSize: 14, color: WeatherPalette.muted, height: 1.4),
        labelSmall: TextStyle(
            fontSize: 11, color: WeatherPalette.muted, letterSpacing: 0.5),
      ),
      cardTheme: CardThemeData(
        color: WeatherPalette.surface.withValues(alpha: 0.84),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme:
          const DialogThemeData(backgroundColor: WeatherPalette.surface),
    );
  }
}
