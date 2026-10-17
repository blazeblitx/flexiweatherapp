import 'package:flexiweather/models/weather.dart';
import 'package:flexiweather/state/weather_controller.dart';
import 'package:flexiweather/ui/weather_home_page.dart';
import 'package:flexiweather/ui/weather_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('weather and favorites screens fit a narrow phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const city = WeatherPlace(
      name: 'San Francisco',
      latitude: 37.77,
      longitude: -122.42,
      country: 'United States',
      admin1: 'California',
    );
    final controller = WeatherController()
      ..weather = WeatherSnapshot(
        place: city,
        observedAt: DateTime(2026, 10, 16, 21),
        temperature: -8.5,
        feelsLike: -10.2,
        weatherCode: 63,
        isDay: false,
        humidity: 86,
        windSpeed: 34,
        uvIndex: 0,
        visibility: 4200,
        hourly: [
          HourForecast(
            time: DateTime(2026, 10, 16, 21),
            temperature: -8.5,
            weatherCode: 63,
            precipitationProbability: 80,
          ),
        ],
        daily: [
          DayForecast(
            date: DateTime(2026, 10, 16),
            high: -5,
            low: -12,
            weatherCode: 63,
            uvIndex: 0,
            windSpeed: 34,
            sunrise: DateTime(2026, 10, 16, 7, 20),
            sunset: DateTime(2026, 10, 16, 18, 10),
          ),
        ],
      )
      ..selectedPlace = city
      ..favorites = [city]
      ..unit = TemperatureUnit.fahrenheit
      ..isLoading = false;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          theme: WeatherTheme.dark,
          home: const WeatherHomePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final layoutError = tester.takeException();
    if (layoutError is FlutterError) {
      for (final diagnostic in layoutError.diagnostics) {
        debugPrint(diagnostic.toString());
      }
    }
    expect(layoutError, isNull);

    await tester.scrollUntilVisible(
      find.text('DAYLIGHT'),
      450,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('DAYLIGHT'), findsOneWidget);
    final scrollError = tester.takeException();
    for (final renderFlex in tester.allRenderObjects.whereType<RenderFlex>()) {
      if (renderFlex.direction == Axis.horizontal) {
        var width = 0.0;
        var child = renderFlex.firstChild;
        while (child != null) {
          width += child.size.width;
          child = renderFlex.childAfter(child!);
        }
        if (width > renderFlex.size.width + 1) {
          debugPrint('OVERFLOW ${renderFlex.size} children=$width ${renderFlex.debugCreator}');
        }
      }
    }
    if (scrollError is FlutterError) {
      for (final diagnostic in scrollError.diagnostics) {
        debugPrint(diagnostic.toString());
      }
    }
    expect(scrollError, isNull);

    await tester.tap(find.text('Favorites'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Your places'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
