import 'package:flutter/material.dart';

import '../models/weather.dart';
import 'weather_theme.dart';

class WeatherBackground extends StatefulWidget {
  const WeatherBackground(
      {required this.code,
      required this.isDay,
      required this.child,
      super.key});

  final int code;
  final bool isDay;
  final Widget child;

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 16))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final condition = WeatherCondition.fromCode(widget.code);
    final glow = condition.isStormy
        ? const Color(0xFF5577A5)
        : condition.isWet
            ? const Color(0xFF3D8B9A)
            : widget.isDay
                ? const Color(0xFFC68B5C)
                : const Color(0xFF5277A8);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shift = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                    WeatherPalette.background, glow, 0.24 + shift * 0.05)!,
                WeatherPalette.background,
                const Color(0xFF0D1C2C)
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -190.0 + shift * 38,
                right: -110.0 - shift * 30,
                child: Container(
                  width: 390,
                  height: 390,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      glow.withValues(alpha: 0.24),
                      glow.withValues(alpha: 0)
                    ]),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
