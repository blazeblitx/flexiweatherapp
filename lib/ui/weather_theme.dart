import 'package:flutter/material.dart';

/// Dark palette retained for weather-specific accents and older call sites.
abstract final class WeatherPalette {
  static const background = Color(0xFF080F18);
  static const surface = Color(0xFF101B27);
  static const surfaceRaised = Color(0xFF172635);
  static const accent = Color(0xFF9ADBD2);
  static const accentWarm = Color(0xFFF2C58F);
  static const muted = Color(0xFFA5B2BF);
  static const outline = Color(0xFF304150);
}

@immutable
class WeatherColors extends ThemeExtension<WeatherColors> {
  const WeatherColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.accent,
    required this.accentWarm,
    required this.muted,
    required this.outline,
    required this.foreground,
    required this.shadow,
  });

  static const dark = WeatherColors(
    background: Color(0xFF080F18),
    surface: Color(0xFF101B27),
    surfaceRaised: Color(0xFF172635),
    accent: Color(0xFF9ADBD2),
    accentWarm: Color(0xFFF2C58F),
    muted: Color(0xFFA5B2BF),
    outline: Color(0xFF304150),
    foreground: Color(0xFFE4EBEF),
    shadow: Color(0xFF000000),
  );

  static const light = WeatherColors(
    background: Color(0xFFF1F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE6EFF2),
    accent: Color(0xFF176E70),
    accentWarm: Color(0xFF9A5717),
    muted: Color(0xFF536773),
    outline: Color(0xFFC5D3D9),
    foreground: Color(0xFF172B36),
    shadow: Color(0xFF45606C),
  );

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color accent;
  final Color accentWarm;
  final Color muted;
  final Color outline;
  final Color foreground;
  final Color shadow;

  @override
  WeatherColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? accent,
    Color? accentWarm,
    Color? muted,
    Color? outline,
    Color? foreground,
    Color? shadow,
  }) =>
      WeatherColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        accent: accent ?? this.accent,
        accentWarm: accentWarm ?? this.accentWarm,
        muted: muted ?? this.muted,
        outline: outline ?? this.outline,
        foreground: foreground ?? this.foreground,
        shadow: shadow ?? this.shadow,
      );

  @override
  WeatherColors lerp(ThemeExtension<WeatherColors>? other, double t) {
    if (other is! WeatherColors) return this;
    return WeatherColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension WeatherColorsContext on BuildContext {
  WeatherColors get weatherColors =>
      Theme.of(this).extension<WeatherColors>() ?? WeatherColors.dark;
}

abstract final class WeatherTheme {
  static ThemeData get dark => _build(WeatherColors.dark, Brightness.dark);
  static ThemeData get light => _build(WeatherColors.light, Brightness.light);

  static ThemeData _build(WeatherColors palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      surface: palette.surface,
    ).copyWith(
      primary: palette.accent,
      onPrimary: isDark ? palette.background : Colors.white,
      secondary: palette.accentWarm,
      onSecondary: isDark ? palette.background : Colors.white,
      surface: palette.surface,
      onSurface: palette.foreground,
      onSurfaceVariant: palette.muted,
      outline: palette.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Avenir Next',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.2,
            color: palette.foreground),
        headlineMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
            color: palette.foreground),
        titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: palette.foreground),
        titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: palette.foreground),
        bodyMedium: TextStyle(fontSize: 14, color: palette.muted, height: 1.4),
        labelSmall:
            TextStyle(fontSize: 11, color: palette.muted, letterSpacing: 0.5),
      ),
      cardTheme: CardThemeData(
        color: palette.surface.withValues(alpha: isDark ? 0.9 : 0.96),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.outline.withValues(alpha: 0.65)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.055)
              : palette.surfaceRaised,
          foregroundColor: palette.accent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceRaised,
        hintStyle: TextStyle(color: palette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.accent, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.surface),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface.withValues(alpha: isDark ? 0.98 : 1),
        indicatorColor: palette.accent.withValues(alpha: isDark ? 0.18 : 0.14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
