import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flexiweather/models/weather.dart';
import 'package:flexiweather/ui/widgets/forecast_sections.dart';
import 'package:flexiweather/state/weather_controller.dart';

void main() {
  group('recent city searches', () {
    const paris = WeatherPlace(
        name: 'Paris', latitude: 48.8566, longitude: 2.3522, country: 'France');

    test('keeps newest selections first without duplicate places', () async {
      final controller = WeatherController();
      addTearDown(controller.dispose);

      await controller.addRecentSearch(paris);
      await controller.addRecentSearch(const WeatherPlace(
          name: 'Tokyo', latitude: 35.6762, longitude: 139.6503));
      await controller.addRecentSearch(const WeatherPlace(
          name: 'Paris', latitude: 48.8566, longitude: 2.3522));

      expect(controller.recentSearches, hasLength(2));
      expect(controller.recentSearches.first.name, 'Paris');
      expect(controller.recentSearches.last.name, 'Tokyo');
    });

    test('limits history to eight and can clear it', () async {
      final controller = WeatherController();
      addTearDown(controller.dispose);

      for (var index = 0; index < 10; index++) {
        await controller.addRecentSearch(WeatherPlace(
          name: 'Place $index',
          latitude: index.toDouble(),
          longitude: -index.toDouble(),
        ));
      }

      expect(controller.recentSearches, hasLength(8));
      expect(controller.recentSearches.first.name, 'Place 9');
      expect(controller.recentSearches.last.name, 'Place 2');

      await controller.clearRecentSearches();
      expect(controller.recentSearches, isEmpty);
    });
  });

  group('temperature conversion', () {
    test('keeps Celsius values unchanged', () {
      expect(convertTemperature(21.5, TemperatureUnit.celsius), 21.5);
      expect(formatTemperature(21.5, TemperatureUnit.celsius), '22°C');
    });

    test('converts Celsius to Fahrenheit before rounding for display', () {
      expect(convertTemperature(0, TemperatureUnit.fahrenheit), 32);
      expect(convertTemperature(100, TemperatureUnit.fahrenheit), 212);
      expect(formatTemperature(20, TemperatureUnit.fahrenheit), '68°F');
    });
  });

  group('Open-Meteo weather parsing', () {
    const place = WeatherPlace(
        name: 'Lisbon', latitude: 38.72, longitude: -9.14, country: 'Portugal');

    test('maps current conditions and hourly and daily forecasts', () {
      final data = {
        'current': {
          'time': '2026-10-16T12:00',
          'temperature_2m': 19.2,
          'apparent_temperature': 18.4,
          'weather_code': 2,
          'is_day': 1,
          'relative_humidity_2m': 68,
          'wind_speed_10m': 14.0,
          'uv_index': 4.2,
          'visibility': 10000,
        },
        'hourly': {
          'time': ['2026-10-16T12:00', '2026-10-16T13:00', '2026-10-16T14:00'],
          'temperature_2m': [19.2, 20.0, 20.4],
          'weather_code': [2, 1, 0],
          'is_day': [1, 0, 0],
          'precipitation_probability': [10, 5, 0],
          'precipitation': [0.0, 0.4, 0.0],
          'wind_speed_10m': [12.0, 18.5, 8.0],
        },
        'daily': {
          'time': ['2026-10-16', '2026-10-17'],
          'temperature_2m_max': [21.0, 22.0],
          'temperature_2m_min': [15.0, 16.0],
          'weather_code': [2, 0],
          'uv_index_max': [5.0, 6.0],
          'wind_speed_10m_max': [18.0, 16.0],
          'precipitation_sum': [1.2, 0.0],
          'sunrise': ['2026-10-16T07:45', '2026-10-17T07:46'],
          'sunset': ['2026-10-16T18:52', '2026-10-17T18:50'],
        },
      };

      final weather = WeatherSnapshot.fromOpenMeteo(data, place: place);

      expect(weather.place.name, 'Lisbon');
      expect(weather.temperature, 19.2);
      expect(weather.humidity, 68);
      expect(weather.windSpeed, 14.0);
      expect(weather.hourly, hasLength(3));
      expect(weather.hourly[1].precipitationProbability, 5);
      expect(weather.hourly[1].precipitationMm, 0.4);
      expect(weather.hourly[1].windSpeed, 18.5);
      expect(weather.hourly[1].isDay, isFalse);
      expect(WeatherCondition.fromCode(0).symbolFor(isDay: false), '🌙');
      expect(weather.daily, hasLength(2));
      expect(weather.daily.first.high, 21.0);
      expect(weather.daily.first.precipitationMm, 1.2);
      expect(weather.sunrise?.hour, 7);
      expect(weather.sunset?.hour, 18);
    });

    test('describes common weather codes with a safe fallback', () {
      expect(WeatherCondition.fromCode(0).label, 'Clear sky');
      expect(WeatherCondition.fromCode(95).isStormy, isTrue);
      expect(WeatherCondition.fromCode(999).symbol, '🌥️');
    });
  });

  group('hourly forecast selection', () {
    testWidgets('selecting a card updates the weather detail from its code',
        (tester) async {
      final items = [
        HourForecast(
          time: DateTime(2026, 10, 16, 12),
          temperature: 22,
          weatherCode: 0,
        ),
        HourForecast(
          time: DateTime(2026, 10, 16, 13),
          temperature: 17,
          weatherCode: 71,
          precipitationProbability: 65,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: HourlyForecast(items: items, unit: TemperatureUnit.celsius),
          ),
        ),
      ));

      expect(find.text('Clear skies ahead'), findsOneWidget);
      expect(find.text('22°C'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('hourly-forecast-1')));
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text('Snowfall expected'), findsOneWidget);
      expect(
          find.text('65% chance of precipitation · Snowfall'), findsOneWidget);
      expect(find.text('17°C'), findsWidgets);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('hourly-forecast-1'))),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasSelectedState: true,
          isFocusable: true,
        ),
      );
    });
  });
}
