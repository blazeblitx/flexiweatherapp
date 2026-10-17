import 'package:flexiweather/ui/weather_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('background selects effects from the actual weather code',
      (tester) async {
    const cases = <(int, String)>[
      (0, 'sun'),
      (3, 'clouds'),
      (63, 'rain'),
      (73, 'snow'),
      (95, 'storm'),
      (45, 'fog'),
    ];

    for (final (code, effect) in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: WeatherBackground(
            code: code,
            isDay: true,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byKey(ValueKey('weather-effect-$effect')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('clear night uses the moon and a starry sky', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherBackground(
          code: 0,
          isDay: false,
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('weather-effect-moon')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
