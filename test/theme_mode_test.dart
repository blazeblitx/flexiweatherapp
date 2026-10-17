import 'package:flexiweather/main.dart';
import 'package:flexiweather/models/weather.dart';
import 'package:flexiweather/state/weather_controller.dart';
import 'package:flexiweather/ui/weather_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes provide distinct readable palettes', () {
    expect(WeatherTheme.dark.brightness, Brightness.dark);
    expect(WeatherTheme.light.brightness, Brightness.light);
    expect(WeatherTheme.dark.scaffoldBackgroundColor,
        isNot(WeatherTheme.light.scaffoldBackgroundColor));
    expect(WeatherTheme.light.colorScheme.onSurface,
        WeatherColors.light.foreground);
  });

  testWidgets('top-bar control switches between light and dark mode',
      (tester) async {
    final controller = WeatherController()
      ..isLoading = false
      ..weather = WeatherSnapshot(
        place: const WeatherPlace(
          name: 'Lisbon',
          latitude: 38.72,
          longitude: -9.14,
          country: 'Portugal',
        ),
        observedAt: DateTime(2026, 10, 17, 12),
        temperature: 22,
        feelsLike: 22,
        weatherCode: 0,
        isDay: true,
        humidity: 50,
        windSpeed: 8,
        uvIndex: 3,
        visibility: 12000,
        hourly: const [],
        daily: const [],
      );
    addTearDown(controller.dispose);

    await tester.pumpWidget(FlexiWeatherApp(controller: controller));
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Favorites'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);
  });
}
