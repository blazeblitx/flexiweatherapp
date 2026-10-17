import 'package:flutter/material.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';

import '../models/weather.dart';
import 'weather_theme.dart';

class WeatherBackground extends StatelessWidget {
  const WeatherBackground({
    required this.code,
    required this.isDay,
    required this.child,
    super.key,
  });

  final int code;
  final bool isDay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final screen = MediaQuery.sizeOf(context);
      final width =
          constraints.maxWidth.isFinite ? constraints.maxWidth : screen.width;
      final height = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : screen.height;
      final type = weatherTypeFor(code, isDay: isDay);
      final effectKey = weatherEffectName(code, isDay: isDay);
      final isSnow = WeatherCondition.fromCode(code).label == 'Snowfall';

      return TickerMode(
        enabled: !reduceMotion,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: context.weatherColors.background),
            KeyedSubtree(
              key: ValueKey('weather-effect-$effectKey'),
              child: Opacity(
                // The package scenes are vivid; keep the app's dark palette
                // dominant while letting the condition animation show through.
                opacity: .18,
                child: WeatherBg(
                  weatherType: type,
                  width: width,
                  height: height,
                ),
              ),
            ),
            if (!isDay && type == WeatherType.cloudyNight)
              const Positioned.fill(
                child: IgnorePointer(child: _CloudyNightStars()),
              ),
            if (isSnow && !reduceMotion)
              const Positioned.fill(
                child: IgnorePointer(
                  child: SnowFallAnimation(
                    config: SnowfallConfig(
                      numberOfSnowflakes: 50,
                      speed: .65,
                      useEmoji: true,
                      customEmojis: ['❄️', '❅', '❆'],
                      holdSnowAtBottom: false,
                      enableSnowDrift: true,
                      windForce: .12,
                      enableRandomOpacity: true,
                      minOpacity: .18,
                      maxOpacity: .55,
                      minSnowflakeSize: 2.5,
                      maxSnowflakeSize: 6,
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      );
    });
  }
}

WeatherType weatherTypeFor(int code, {required bool isDay}) {
  if ([95, 96, 99].contains(code)) return WeatherType.thunder;
  if ([71, 73, 75, 77, 85, 86].contains(code)) {
    if ([75, 86].contains(code)) return WeatherType.heavySnow;
    if ([73, 85].contains(code)) return WeatherType.middleSnow;
    return WeatherType.lightSnow;
  }
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
    if ([65, 67, 82].contains(code)) return WeatherType.heavyRainy;
    if ([53, 55, 63, 66, 81].contains(code)) return WeatherType.middleRainy;
    return WeatherType.lightRainy;
  }
  if ([45, 48].contains(code)) return WeatherType.foggy;
  if (code == 3) return WeatherType.overcast;
  if (code == 2) return isDay ? WeatherType.cloudy : WeatherType.cloudyNight;
  if (code <= 1) return isDay ? WeatherType.sunny : WeatherType.sunnyNight;
  return WeatherType.cloudy;
}

String weatherEffectName(int code, {required bool isDay}) {
  if (!isDay && code <= 1) return 'moon';
  if ([95, 96, 99].contains(code)) return 'storm';
  if ([71, 73, 75, 77, 85, 86].contains(code)) return 'snow';
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
    return 'rain';
  }
  if ([45, 48].contains(code)) return 'fog';
  if ([2, 3].contains(code)) return 'clouds';
  return 'sun';
}

class _CloudyNightStars extends StatelessWidget {
  const _CloudyNightStars();

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _NightStarsPainter(),
        size: Size.infinite,
      );
}

class _NightStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8DAFF).withValues(alpha: .54);
    for (var index = 0; index < 46; index++) {
      final x = (index * 79.31 + 17) % size.width;
      final y = (index * 137.17 + 29) % size.height;
      canvas.drawCircle(Offset(x, y), index % 11 == 0 ? 1.5 : .85, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NightStarsPainter oldDelegate) => false;
}
