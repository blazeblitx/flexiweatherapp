import 'package:flexiweather/models/weather.dart';
import 'package:flexiweather/state/weather_controller.dart';
import 'package:flexiweather/ui/weather_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('favorites has a separate tab with add and remove states',
      (tester) async {
    final controller = WeatherController()..isLoading = false;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: WeatherHomePage()),
      ),
    );

    await tester.tap(find.text('Favorites'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Your places'), findsOneWidget);
    expect(find.text('No favorites yet'), findsOneWidget);
    expect(find.text('Find a city'), findsOneWidget);

    const place = WeatherPlace(
      name: 'Lisbon',
      latitude: 38.72,
      longitude: -9.14,
      country: 'Portugal',
    );
    await controller.toggleFavorite(place);
    await tester.pump();

    expect(find.text('Lisbon'), findsOneWidget);
    expect(find.text('1 saved place'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Lisbon from favorites'));
    await tester.pump();
    expect(find.text('No favorites yet'), findsOneWidget);
  });
}
