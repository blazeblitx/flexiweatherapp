import 'package:flutter/material.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';
import 'package:intl/intl.dart';

import '../../models/weather.dart';
import '../weather_background.dart';
import '../weather_theme.dart';

/// A compact, condition-specific animation from flutter_weather_bg.
class _WeatherTabEffect extends StatelessWidget {
  const _WeatherTabEffect({required this.weatherCode, this.isDay = true});

  final int weatherCode;
  final bool isDay;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final type = weatherTypeFor(weatherCode, isDay: isDay);
          final effect = weatherEffectName(weatherCode, isDay: isDay);
          final key = effect == 'moon' ? 'night' : effect;
          final opacity = constraints.maxHeight < 100 ? .2 : .3;
          return KeyedSubtree(
            key: ValueKey('weather-tab-effect-$key'),
            child: Opacity(
              opacity: opacity,
              child: WeatherBg(
                weatherType: type,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
          );
        },
      );
}

class ForecastMetricPicker extends StatelessWidget {
  const ForecastMetricPicker(
      {required this.value, required this.onChanged, super.key});

  final ForecastMetric value;
  final ValueChanged<ForecastMetric> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Forecast metric',
        child: Container(
          key: const ValueKey('forecast-metric-picker'),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.weatherColors.surface.withValues(alpha: .86),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: context.weatherColors.outline.withValues(alpha: .4)),
          ),
          child: Row(children: [
            for (final metric in ForecastMetric.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: metric == value,
                  label: _metricName(metric),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onChanged(metric),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 9),
                        decoration: BoxDecoration(
                          color: metric == value
                              ? context.weatherColors.accent
                                  .withValues(alpha: .16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: metric == value
                                ? context.weatherColors.accent
                                    .withValues(alpha: .48)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            switch (metric) {
                              ForecastMetric.temperature => 'Temp',
                              ForecastMetric.precipitation => 'Rain',
                              ForecastMetric.wind => 'Wind',
                            },
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: metric == value
                                      ? context.weatherColors.accent
                                      : null,
                                  fontWeight:
                                      metric == value ? FontWeight.w700 : null,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class _MetricMotion extends StatefulWidget {
  const _MetricMotion({required this.metric, required this.active});

  final ForecastMetric metric;
  final bool active;

  @override
  State<_MetricMotion> createState() => _MetricMotionState();
}

class _MetricMotionState extends State<_MetricMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _MetricMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) _controller.repeat();
    if (!widget.active && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion ||
        !widget.active ||
        widget.metric == ForecastMetric.temperature) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              key: ValueKey('forecast-metric-animation-${widget.metric.name}'),
              painter: _MetricMotionPainter(
                metric: widget.metric,
                phase: _controller.value,
                color: context.weatherColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricMotionPainter extends CustomPainter {
  const _MetricMotionPainter(
      {required this.metric, required this.phase, required this.color});

  final ForecastMetric metric;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = color.withValues(alpha: .25)
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (metric == ForecastMetric.precipitation) {
      for (var i = 0; i < 5; i++) {
        final x = size.width * ((i * .239 + .08) % 1);
        final y = ((phase + i * .197) % 1) * (size.height + 16) - 8;
        canvas.drawLine(Offset(x, y), Offset(x - 2.3, y + 7), paint);
      }
    } else if (metric == ForecastMetric.wind) {
      for (var i = 0; i < 3; i++) {
        final y = size.height * (.34 + i * .18);
        final progress = (phase + i / 3) % 1;
        final startX = progress * (size.width + 22) - 22;
        final path = Path()
          ..moveTo(startX, y)
          ..quadraticBezierTo(startX + 8, y - 3, startX + 16, y)
          ..quadraticBezierTo(startX + 21, y + 2, startX + 27, y);
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MetricMotionPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.metric != metric ||
      oldDelegate.color != color;
}

String _metricValue({
  required ForecastMetric metric,
  required double temperature,
  required double precipitationMm,
  required double windSpeed,
  required TemperatureUnit unit,
}) =>
    switch (metric) {
      ForecastMetric.temperature => formatTemperature(temperature, unit),
      ForecastMetric.precipitation =>
        '${precipitationMm.toStringAsFixed(1)} mm',
      ForecastMetric.wind => '${windSpeed.round()} km/h',
    };

String _metricName(ForecastMetric metric) => switch (metric) {
      ForecastMetric.temperature => 'Temperature',
      ForecastMetric.precipitation => 'Precipitation',
      ForecastMetric.wind => 'Wind',
    };

bool _hasPrecipitation({required double amount, required int probability}) =>
    amount > 0 || probability > 0;

class HourlyForecast extends StatefulWidget {
  const HourlyForecast(
      {required this.items,
      required this.unit,
      this.metric = ForecastMetric.temperature,
      super.key});

  final List<HourForecast> items;
  final TemperatureUnit unit;
  final ForecastMetric metric;

  @override
  State<HourlyForecast> createState() => _HourlyForecastState();
}

class _HourlyForecastState extends State<HourlyForecast> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant HourlyForecast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.items.length) _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final selected = widget.items[_selectedIndex];
    return _ForecastSection(
      title: 'NEXT 24 HOURS',
      trailing: 'Hourly',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final condition = WeatherCondition.fromCode(item.weatherCode);
              final isSelected = index == _selectedIndex;
              final time = index == 0
                  ? 'Now'
                  : DateFormat('ha').format(item.time).toLowerCase();
              return Semantics(
                button: true,
                selected: isSelected,
                label: '$time, ${condition.label}, '
                    '${_metricValue(metric: widget.metric, temperature: item.temperature, precipitationMm: item.precipitationMm, windSpeed: item.windSpeed, unit: widget.unit)}'
                    '${item.precipitationProbability > 0 ? ', ${item.precipitationProbability}% chance of precipitation' : ''}',
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                  child: InkWell(
                    key: ValueKey('hourly-forecast-$index'),
                    borderRadius: BorderRadius.circular(19),
                    onTap: () => setState(() => _selectedIndex = index),
                    child: ExcludeSemantics(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 70,
                        height: 138,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.weatherColors.accent
                                  .withValues(alpha: 0.18)
                              : context.weatherColors.surfaceRaised
                                  .withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                              color: isSelected
                                  ? context.weatherColors.accent
                                      .withValues(alpha: 0.75)
                                  : context.weatherColors.outline
                                      .withValues(alpha: 0.38),
                              width: isSelected ? 1.5 : 1),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: context.weatherColors.accent
                                          .withValues(alpha: 0.10),
                                      blurRadius: 16)
                                ]
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(children: [
                          Positioned.fill(
                            child: _WeatherTabEffect(
                              weatherCode: item.weatherCode,
                              isDay: item.isDay,
                            ),
                          ),
                          _MetricMotion(
                            metric: widget.metric,
                            active: widget.metric !=
                                    ForecastMetric.precipitation ||
                                _hasPrecipitation(
                                    amount: item.precipitationMm,
                                    probability: item.precipitationProbability),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(time,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: isSelected
                                                ? context.weatherColors.accent
                                                : null,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : null,
                                          )),
                                  Text(condition.symbolFor(isDay: item.isDay),
                                      style: const TextStyle(fontSize: 24)),
                                  Text(
                                      _metricValue(
                                          metric: widget.metric,
                                          temperature: item.temperature,
                                          precipitationMm: item.precipitationMm,
                                          windSpeed: item.windSpeed,
                                          unit: widget.unit),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  if (widget.metric ==
                                          ForecastMetric.precipitation &&
                                      item.precipitationProbability > 0)
                                    Text('${item.precipitationProbability}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                                color: context
                                                    .weatherColors.accent)),
                                ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SelectedHourDetails(
            item: selected, unit: widget.unit, metric: widget.metric),
      ]),
    );
  }
}

class _SelectedHourDetails extends StatelessWidget {
  const _SelectedHourDetails(
      {required this.item, required this.unit, required this.metric});

  final HourForecast item;
  final TemperatureUnit unit;
  final ForecastMetric metric;

  @override
  Widget build(BuildContext context) {
    final condition = WeatherCondition.fromCode(item.weatherCode);
    final colors = _conditionColors(item.weatherCode);
    final time = DateFormat('EEEE, h:mm a').format(item.time);
    final headline = switch (item.weatherCode) {
      0 => item.isDay ? 'Clear skies ahead' : 'A clear night ahead',
      1 => item.isDay ? 'Mainly clear skies' : 'A mostly clear night',
      2 => item.isDay ? 'A little sunshine' : 'Clouds in the night sky',
      3 || 45 || 48 => 'Clouds move in',
      51 || 53 || 55 || 56 || 57 => 'Light rain possible',
      61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => 'Rain in the forecast',
      71 || 73 || 75 || 77 || 85 || 86 => 'Snowfall expected',
      95 || 96 || 99 => 'Stormy conditions',
      _ => 'Changing conditions',
    };
    final detail = switch (metric) {
      ForecastMetric.temperature => item.precipitationProbability > 0
          ? '${item.precipitationProbability}% chance of precipitation'
          : 'A dry hour is expected',
      ForecastMetric.precipitation => item.precipitationMm > 0
          ? '${item.precipitationMm.toStringAsFixed(1)} mm of expected precipitation · ${item.precipitationProbability}% chance'
          : 'No measurable precipitation expected · ${item.precipitationProbability}% chance',
      ForecastMetric.wind => 'Wind speed · ${item.windSpeed.round()} km/h',
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.$1.withValues(alpha: 0.22),
              colors.$2.withValues(alpha: 0.08)
            ],
          ),
          border: Border.all(color: colors.$1.withValues(alpha: 0.34)),
        ),
        child: Row(children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.$1.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(condition.symbolFor(isDay: item.isDay),
                style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(time, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 3),
              Text(headline, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text('$detail · ${condition.label}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          const SizedBox(width: 8),
          Text(
              _metricValue(
                  metric: metric,
                  temperature: item.temperature,
                  precipitationMm: item.precipitationMm,
                  windSpeed: item.windSpeed,
                  unit: unit),
              style: Theme.of(context).textTheme.headlineMedium),
        ]),
      ),
    );
  }
}

(Color, Color) _conditionColors(int code) {
  if ([95, 96, 99].contains(code)) {
    return (const Color(0xFF91A8E8), const Color(0xFF667EB5));
  }
  if ([71, 73, 75, 77, 85, 86].contains(code)) {
    return (const Color(0xFFA8DDF2), const Color(0xFF6BA7C8));
  }
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
    return (const Color(0xFF83CBE2), const Color(0xFF4F8FAC));
  }
  if ([3, 45, 48].contains(code)) {
    return (const Color(0xFFBECBD9), const Color(0xFF8294A9));
  }
  if ([1, 2].contains(code)) {
    return (const Color(0xFFF2C58F), const Color(0xFF9ADBD2));
  }
  return (const Color(0xFFFFD27A), const Color(0xFFF29C5B));
}

class DailyForecast extends StatefulWidget {
  const DailyForecast(
      {required this.items,
      required this.unit,
      this.metric = ForecastMetric.temperature,
      super.key});

  final List<DayForecast> items;
  final TemperatureUnit unit;
  final ForecastMetric metric;

  @override
  State<DailyForecast> createState() => _DailyForecastState();
}

class _DailyForecastState extends State<DailyForecast> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant DailyForecast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) ||
        _selectedIndex >= widget.items.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final selected = widget.items[_selectedIndex];
    return _ForecastSection(
      title: '7-DAY OUTLOOK',
      trailing: 'This week',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < widget.items.length; i++) ...[
          if (i > 0)
            Divider(
                height: 1,
                color:
                    context.weatherColors.foreground.withValues(alpha: 0.055)),
          _DayRow(
            item: widget.items[i],
            unit: widget.unit,
            metric: widget.metric,
            isToday: i == 0,
            isSelected: i == _selectedIndex,
            onTap: () => setState(() => _selectedIndex = i),
            index: i,
          ),
        ],
        const SizedBox(height: 12),
        _SelectedDayDetails(
            item: selected, unit: widget.unit, metric: widget.metric),
      ]),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow(
      {required this.item,
      required this.unit,
      required this.metric,
      required this.isToday,
      required this.isSelected,
      required this.onTap,
      required this.index});

  final DayForecast item;
  final TemperatureUnit unit;
  final ForecastMetric metric;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final condition = WeatherCondition.fromCode(item.weatherCode);
    final day = isToday ? 'Today' : DateFormat('EEE').format(item.date);
    final label = '$day, ${condition.label}, ${_metricName(metric)} '
        '${_metricValue(metric: metric, temperature: item.high, precipitationMm: item.precipitationMm, windSpeed: item.windSpeed, unit: unit)}, high '
        '${formatTemperature(item.high, unit)}, low '
        '${formatTemperature(item.low, unit)}, UV '
        '${item.uvIndex.toStringAsFixed(0)}, wind ${item.windSpeed.round()} km/h';

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('daily-forecast-$index'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.weatherColors.accent.withValues(alpha: 0.075)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? context.weatherColors.accent.withValues(alpha: 0.32)
                    : Colors.transparent,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              return Stack(children: [
                if (metric == ForecastMetric.precipitation &&
                    item.precipitationMm > 0)
                  const _MetricMotion(
                      metric: ForecastMetric.precipitation, active: true),
                if (metric == ForecastMetric.wind)
                  const _MetricMotion(
                      metric: ForecastMetric.wind, active: true),
                Positioned.fill(
                  child: _WeatherTabEffect(weatherCode: item.weatherCode),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(children: [
                    SizedBox(
                      width: compact ? 52 : 70,
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.weatherColors.foreground,
                            fontWeight: isSelected ? FontWeight.w700 : null),
                      ),
                    ),
                    SizedBox(
                      width: compact ? 26 : null,
                      child: Text(condition.symbol,
                          style: const TextStyle(fontSize: 22)),
                    ),
                    const Spacer(),
                    if (metric == ForecastMetric.temperature) ...[
                      SizedBox(
                        width: compact ? 36 : 40,
                        child: Text(formatTemperature(item.low, unit),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      SizedBox(width: compact ? 6 : 10),
                      SizedBox(
                        width: compact ? 36 : 40,
                        child: Text(formatTemperature(item.high, unit),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ] else ...[
                      SizedBox(
                        width: compact ? 50 : 78,
                        child: Text(
                          _metricValue(
                              metric: metric,
                              temperature: item.high,
                              precipitationMm: item.precipitationMm,
                              windSpeed: item.windSpeed,
                              unit: unit),
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ]),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

class _SelectedDayDetails extends StatelessWidget {
  const _SelectedDayDetails(
      {required this.item, required this.unit, required this.metric});

  final DayForecast item;
  final TemperatureUnit unit;
  final ForecastMetric metric;

  @override
  Widget build(BuildContext context) {
    final condition = WeatherCondition.fromCode(item.weatherCode);
    final colors = _conditionColors(item.weatherCode);
    final title = switch (item.weatherCode) {
      0 || 1 => 'A bright day ahead',
      2 || 3 || 45 || 48 => 'Clouds set the tone',
      51 || 53 || 55 || 56 || 57 => 'Drizzle in the forecast',
      61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => 'Rain in the forecast',
      71 || 73 || 75 || 77 || 85 || 86 => 'Snowfall expected',
      95 || 96 || 99 => 'Stormy day ahead',
      _ => 'Changing conditions',
    };
    final date = DateFormat('EEEE, MMM d').format(item.date);
    String clock(DateTime? value) =>
        value == null ? '—' : DateFormat('h:mm a').format(value);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.$1.withValues(alpha: 0.22),
              colors.$2.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: colors.$1.withValues(alpha: 0.34)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.$1.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child:
                  Text(condition.symbol, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 3),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(condition.label,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                  _metricValue(
                      metric: metric,
                      temperature: item.high,
                      precipitationMm: item.precipitationMm,
                      windSpeed: item.windSpeed,
                      unit: unit),
                  style: Theme.of(context).textTheme.headlineMedium),
              Text(
                  metric == ForecastMetric.temperature
                      ? 'Low ${formatTemperature(item.low, unit)}'
                      : _metricName(metric),
                  style: Theme.of(context).textTheme.labelSmall),
            ]),
          ]),
          const SizedBox(height: 16),
          Divider(
              height: 1,
              color: context.weatherColors.foreground.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _DayDetailMetric(
                icon: Icons.wb_sunny_outlined,
                label: 'UV index',
                value: item.uvIndex.toStringAsFixed(0)),
            _DayDetailMetric(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: '${item.windSpeed.round()} km/h'),
            _DayDetailMetric(
                icon: Icons.water_drop_outlined,
                label: 'Precipitation',
                value: '${item.precipitationMm.toStringAsFixed(1)} mm'),
            if (item.sunrise != null)
              _DayDetailMetric(
                  icon: Icons.wb_twilight_rounded,
                  label: 'Sunrise',
                  value: clock(item.sunrise)),
            if (item.sunset != null)
              _DayDetailMetric(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Sunset',
                  value: clock(item.sunset)),
          ]),
        ]),
      ),
    );
  }
}

class _DayDetailMetric extends StatelessWidget {
  const _DayDetailMetric(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: context.weatherColors.foreground.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: context.weatherColors.accentWarm),
          const SizedBox(width: 6),
          Text('$label  $value', style: Theme.of(context).textTheme.labelSmall),
        ]),
      );
}

class WeatherDetails extends StatelessWidget {
  const WeatherDetails({required this.snapshot, super.key});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) => _ForecastSection(
        title: 'AT A GLANCE',
        trailing: 'Live conditions',
        child: LayoutBuilder(builder: (context, constraints) {
          final singleColumn = constraints.maxWidth < 300;
          final width = singleColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
              spacing: singleColumn ? 0 : 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                    width: width,
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '${snapshot.humidity}%',
                    explanation:
                        'Humidity is how much moisture is in the air. Higher humidity can make warm weather feel muggy.',
                    accent: const Color(0xFF8BC7F4)),
                _MetricTile(
                    width: width,
                    icon: Icons.air_rounded,
                    label: 'Wind',
                    value: '${snapshot.windSpeed.round()} km/h',
                    explanation:
                        'Wind speed tells you how quickly air is moving. Stronger wind can make it feel cooler and affect outdoor plans.',
                    accent: const Color(0xFFB4C5D8)),
                _MetricTile(
                    width: width,
                    icon: Icons.wb_sunny_outlined,
                    label: 'UV index',
                    value: snapshot.uvIndex.toStringAsFixed(1),
                    explanation:
                        'The UV index measures the sun’s ultraviolet strength. Higher readings mean sun protection is more important.',
                    accent: context.weatherColors.accentWarm),
                _MetricTile(
                    width: width,
                    icon: Icons.visibility_outlined,
                    label: 'Visibility',
                    value:
                        '${(snapshot.visibility / 1000).toStringAsFixed(1)} km',
                    explanation:
                        'Visibility is how far you can see clearly. Fog, rain, and haze can reduce it.',
                    accent: context.weatherColors.accent),
              ]);
        }),
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
      {required this.width,
      required this.icon,
      required this.label,
      required this.value,
      required this.explanation,
      required this.accent});

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String explanation;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Material(
          color: context.weatherColors.surfaceRaised.withValues(alpha: 0.76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: context.weatherColors.outline.withValues(alpha: 0.38)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(label),
                content: Text(explanation),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: accent.withValues(alpha: 0.8)),
                      ]),
                      const SizedBox(height: 2),
                      Text(value,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _ForecastSection extends StatelessWidget {
  const _ForecastSection(
      {required this.title, required this.trailing, required this.child});
  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
          child: Row(children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.15),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ]),
        ),
        Card(
          child: LayoutBuilder(builder: (context, constraints) {
            final inset = constraints.maxWidth < 360 ? 12.0 : 16.0;
            return Padding(padding: EdgeInsets.all(inset), child: child);
          }),
        ),
      ]);
}
