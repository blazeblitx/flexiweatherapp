import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weather.dart';
import '../weather_theme.dart';

class HourlyForecast extends StatelessWidget {
  const HourlyForecast({required this.items, required this.unit, super.key});

  final List<HourForecast> items;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) => _ForecastSection(
        title: 'NEXT 24 HOURS',
        trailing: 'Hourly',
        child: SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final condition = WeatherCondition.fromCode(item.weatherCode);
              return Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: index == 0
                      ? WeatherPalette.accent.withValues(alpha: 0.12)
                      : WeatherPalette.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: index == 0
                          ? WeatherPalette.accent.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.035)),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          index == 0
                              ? 'Now'
                              : DateFormat('ha')
                                  .format(item.time)
                                  .toLowerCase(),
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(condition.symbol,
                          style: const TextStyle(fontSize: 24)),
                      Text(formatTemperature(item.temperature, unit),
                          style: Theme.of(context).textTheme.titleMedium),
                      if (item.precipitationProbability > 0)
                        Text('${item.precipitationProbability}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: WeatherPalette.accent)),
                    ]),
              );
            },
          ),
        ),
      );
}

class DailyForecast extends StatelessWidget {
  const DailyForecast({required this.items, required this.unit, super.key});

  final List<DayForecast> items;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) => _ForecastSection(
        title: '7-DAY OUTLOOK',
        trailing: 'This week',
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.055)),
            _DayRow(item: items[i], unit: unit, isToday: i == 0),
          ],
        ]),
      );
}

class _DayRow extends StatelessWidget {
  const _DayRow(
      {required this.item, required this.unit, required this.isToday});

  final DayForecast item;
  final TemperatureUnit unit;
  final bool isToday;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          SizedBox(
              width: 70,
              child: Text(
                  isToday ? 'Today' : DateFormat('EEE').format(item.date),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white))),
          Text(WeatherCondition.fromCode(item.weatherCode).symbol,
              style: const TextStyle(fontSize: 22)),
          const Spacer(),
          SizedBox(
              width: 36,
              child: Text('${item.uvIndex.toStringAsFixed(0)} UV',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall)),
          const SizedBox(width: 14),
          SizedBox(
              width: 40,
              child: Text(formatTemperature(item.low, unit),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 10),
          SizedBox(
              width: 40,
              child: Text(formatTemperature(item.high, unit),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium)),
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
          final width = (constraints.maxWidth - 12) / 2;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            _MetricTile(
                width: width,
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${snapshot.humidity}%',
                accent: const Color(0xFF8BC7F4)),
            _MetricTile(
                width: width,
                icon: Icons.air_rounded,
                label: 'Wind',
                value: '${snapshot.windSpeed.round()} km/h',
                accent: const Color(0xFFB4C5D8)),
            _MetricTile(
                width: width,
                icon: Icons.wb_sunny_outlined,
                label: 'UV index',
                value: snapshot.uvIndex.toStringAsFixed(1),
                accent: WeatherPalette.accentWarm),
            _MetricTile(
                width: width,
                icon: Icons.visibility_outlined,
                label: 'Visibility',
                value: '${(snapshot.visibility / 1000).toStringAsFixed(1)} km',
                accent: WeatherPalette.accent),
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
      required this.accent});

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: WeatherPalette.surfaceRaised.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: accent)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium),
              ])),
        ]),
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
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.15)),
            const Spacer(),
            Text(trailing, style: Theme.of(context).textTheme.labelSmall),
          ]),
        ),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: child)),
      ]);
}
