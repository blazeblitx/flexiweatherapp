import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/weather_controller.dart';
import 'ui/legal_pages.dart';
import 'ui/weather_home_page.dart';
import 'ui/weather_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = WeatherController();
  runApp(FlexiWeatherApp(controller: controller));
  unawaited(controller.initialize());
}

class FlexiWeatherApp extends StatelessWidget {
  const FlexiWeatherApp({required this.controller, super.key});

  final WeatherController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<WeatherController>(
        builder: (context, controller, _) => MaterialApp(
          title: 'FlexiWeather',
          debugShowCheckedModeBanner: false,
          theme: WeatherTheme.light,
          darkTheme: WeatherTheme.dark,
          themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const WeatherHomePage(),
          routes: legalPageRoutes,
        ),
      ),
    );
  }
}
