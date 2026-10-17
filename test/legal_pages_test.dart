import 'package:flexiweather/state/weather_controller.dart';
import 'package:flexiweather/ui/legal_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('policy links open a named page route', (tester) async {
    final controller = WeatherController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        home: const Scaffold(body: Center(child: LegalLinks())),
        routes: legalPageRoutes,
      ),
    ));
    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalPage), findsOneWidget);
    expect(find.text('What the app handles'), findsOneWidget);
  });

  testWidgets('privacy policy identifies the data flow and launch fields',
      (tester) async {
    final controller = WeatherController()..isLoading = false;
    addTearDown(controller.dispose);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: const MaterialApp(
        home: LegalPage(document: LegalDocument.privacy),
      ),
    ));
    await tester.scrollUntilVisible(
      find.text('What the app handles'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('What the app handles'), findsOneWidget);
    expect(find.textContaining('Operator legal name required before launch'),
        findsOneWidget);
  });

  testWidgets('cookie policy explains optional browser storage',
      (tester) async {
    final controller = WeatherController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: const MaterialApp(
        home: LegalPage(document: LegalDocument.cookies),
      ),
    ));

    expect(find.text('Cookies and tracking'), findsOneWidget);
    expect(find.textContaining('browser local storage'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('not legal advice'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('not legal advice'), findsOneWidget);
  });
}
