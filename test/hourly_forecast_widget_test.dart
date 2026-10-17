import 'package:flexiweather/models/weather.dart';
import 'package:flexiweather/ui/weather_theme.dart';
import 'package:flexiweather/ui/widgets/forecast_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clear night hours show the moon rather than the sun',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HourlyForecast(
            items: [
              HourForecast(
                time: DateTime(2026, 10, 16, 22),
                temperature: 31,
                weatherCode: 0,
                isDay: false,
              ),
            ],
            unit: TemperatureUnit.celsius,
          ),
        ),
      ),
    ));

    expect(find.text('🌙'), findsWidgets);
    expect(find.text('A clear night ahead'), findsOneWidget);
    expect(find.text('☀️'), findsNothing);
    expect(
        find.byKey(const ValueKey('weather-tab-effect-night')), findsOneWidget);
  });

  final hours = [
    HourForecast(
      time: DateTime(2026, 10, 16, 12),
      temperature: 22,
      weatherCode: 0,
    ),
    HourForecast(
      time: DateTime(2026, 10, 16, 13),
      temperature: 17,
      weatherCode: 63,
      precipitationProbability: 80,
      precipitationMm: 2.4,
      windSpeed: 17,
    ),
    HourForecast(
      time: DateTime(2026, 10, 16, 14),
      temperature: -2,
      weatherCode: 73,
      precipitationProbability: 60,
      precipitationMm: 0.8,
      windSpeed: 12,
    ),
  ];

  Widget buildSubject({double width = 390}) => MaterialApp(
        theme: WeatherTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: width,
                child: HourlyForecast(
                  items: hours,
                  unit: TemperatureUnit.celsius,
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('selecting an hour shows details for its actual condition',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Clear skies ahead'), findsOneWidget);
    expect(find.text('A dry hour is expected · Clear sky'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hourly-forecast-1')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Rain in the forecast'), findsOneWidget);
    expect(find.text('80% chance of precipitation · Rain showers'),
        findsOneWidget);
  });

  testWidgets('snow hour selection updates detail and selected semantics',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byKey(const ValueKey('hourly-forecast-2')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Snowfall expected'), findsOneWidget);
    expect(find.text('60% chance of precipitation · Snowfall'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('hourly-forecast-2'))),
      matchesSemantics(
        label: '2pm, Snowfall, -2°C, 60% chance of precipitation',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasSelectedState: true,
        isFocusable: true,
      ),
    );
  });

  testWidgets('hourly selection stays usable at a narrow screen width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject(width: 280));

    await tester.tap(find.byKey(const ValueKey('hourly-forecast-1')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Rain in the forecast'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a day shows its condition and daily details',
      (tester) async {
    final days = [
      DayForecast(
        date: DateTime(2026, 10, 16),
        high: 22,
        low: 14,
        weatherCode: 0,
        uvIndex: 5,
        windSpeed: 12,
        sunrise: DateTime(2026, 10, 16, 7, 10),
        sunset: DateTime(2026, 10, 16, 18, 40),
      ),
      DayForecast(
        date: DateTime(2026, 10, 17),
        high: 18,
        low: 11,
        weatherCode: 63,
        uvIndex: 2,
        windSpeed: 24,
        sunrise: DateTime(2026, 10, 17, 7, 11),
        sunset: DateTime(2026, 10, 17, 18, 38),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: WeatherTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DailyForecast(items: days, unit: TemperatureUnit.celsius),
          ),
        ),
      ),
    );

    expect(find.text('A bright day ahead'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('daily-forecast-1')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Rain in the forecast'), findsOneWidget);
    expect(find.text('Rain showers'), findsOneWidget);
    expect(find.text('18°C'), findsWidgets);
    expect(find.text('Wind  24 km/h'), findsOneWidget);
    expect(find.text('Sunrise  7:11 AM'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('daily-forecast-1'))),
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

  testWidgets('hourly and daily tabs receive matching animated weather fills',
      (tester) async {
    final days = [
      DayForecast(
        date: DateTime(2026, 10, 16),
        high: 22,
        low: 14,
        weatherCode: 0,
        uvIndex: 5,
        windSpeed: 12,
      ),
      DayForecast(
        date: DateTime(2026, 10, 17),
        high: 18,
        low: 11,
        weatherCode: 71,
        uvIndex: 2,
        windSpeed: 24,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: WeatherTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              HourlyForecast(items: hours, unit: TemperatureUnit.celsius),
              DailyForecast(items: days, unit: TemperatureUnit.celsius),
            ]),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('weather-tab-effect-sun')), findsWidgets);
    expect(
        find.byKey(const ValueKey('weather-tab-effect-rain')), findsOneWidget);
    expect(find.byKey(const ValueKey('weather-tab-effect-snow')), findsWidgets);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'metric switch updates hourly and daily values with matching effects',
      (tester) async {
    final days = [
      DayForecast(
        date: DateTime(2026, 10, 16),
        high: 22,
        low: 14,
        weatherCode: 63,
        uvIndex: 5,
        windSpeed: 12,
        precipitationMm: 3.6,
      ),
    ];
    var metric = ForecastMetric.temperature;
    await tester.pumpWidget(MaterialApp(
      theme: WeatherTheme.dark,
      home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
                body: SingleChildScrollView(
                    child: Column(children: [
                  ForecastMetricPicker(
                    value: metric,
                    onChanged: (value) => setState(() => metric = value),
                  ),
                  HourlyForecast(
                      items: hours,
                      unit: TemperatureUnit.celsius,
                      metric: metric),
                  DailyForecast(
                      items: days,
                      unit: TemperatureUnit.celsius,
                      metric: metric),
                ])),
              )),
    ));

    await tester.tap(find.text('Rain'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('2.4 mm'), findsWidgets);
    expect(
        find.byKey(const ValueKey('forecast-metric-animation-precipitation')),
        findsWidgets);

    await tester.tap(find.text('Wind'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('17 km/h'), findsWidgets);
    expect(find.byKey(const ValueKey('forecast-metric-animation-wind')),
        findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
