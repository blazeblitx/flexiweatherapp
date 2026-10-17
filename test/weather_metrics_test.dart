import 'package:flexiweather/models/weather.dart';
import 'package:flexiweather/ui/weather_theme.dart';
import 'package:flexiweather/ui/widgets/forecast_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('weather metrics open short explanations when tapped',
      (tester) async {
    final snapshot = WeatherSnapshot(
      place:
          const WeatherPlace(name: 'Lisbon', latitude: 38.72, longitude: -9.14),
      observedAt: DateTime(2026, 10, 16, 12),
      temperature: 21,
      feelsLike: 21,
      weatherCode: 1,
      isDay: true,
      humidity: 66,
      windSpeed: 10,
      uvIndex: 2.1,
      visibility: 27200,
      hourly: const [],
      daily: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: WeatherTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: WeatherDetails(snapshot: snapshot),
            ),
          ),
        ),
      ),
    );

    const explanations = {
      'Humidity': 'Humidity is how much moisture is in the air.',
      'Wind': 'Wind speed tells you how quickly air is moving.',
      'UV index': 'The UV index measures the sun’s ultraviolet strength.',
      'Visibility': 'Visibility is how far you can see clearly.',
    };

    for (final entry in explanations.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.key), findsNWidgets(2));
      expect(find.textContaining(entry.value), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }
  });
}
