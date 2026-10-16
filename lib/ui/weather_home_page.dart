import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weather.dart';
import '../state/weather_controller.dart';
import 'weather_background.dart';
import 'weather_theme.dart';
import 'widgets/forecast_sections.dart';
import 'widgets/search_sheet.dart';

class WeatherHomePage extends StatelessWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeatherController>();
    final snapshot = controller.weather;
    return Scaffold(
      body: WeatherBackground(
        code: snapshot?.weatherCode ?? 2,
        isDay: snapshot?.isDay ?? true,
        child: SafeArea(
          child: snapshot == null && controller.isLoading
              ? const _LoadingState()
              : snapshot == null
                  ? _ErrorState(
                      message: controller.errorMessage ??
                          'The forecast is unavailable.',
                      onRetry: () =>
                          controller.loadWeather(controller.selectedPlace))
                  : RefreshIndicator(
                      color: WeatherPalette.accent,
                      onRefresh: () =>
                          controller.loadWeather(controller.selectedPlace),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
                            sliver: SliverList.list(children: [
                              _TopBar(
                                onSearch: () => showSearchSheet(context),
                                onLocation: controller.useCurrentLocation,
                                locating: controller.isLocating,
                              ),
                              if (controller.isLoading ||
                                  controller.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                _InlineStatus(
                                  isLoading: controller.isLoading,
                                  message: controller.errorMessage,
                                  onRetry: () => controller
                                      .loadWeather(controller.selectedPlace),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _LocationHeading(
                                place: snapshot.place,
                                isFavorite:
                                    controller.isFavorite(snapshot.place),
                                onFavorite: () =>
                                    controller.toggleFavorite(snapshot.place),
                              ),
                              _CurrentWeather(snapshot: snapshot),
                              const SizedBox(height: 28),
                              HourlyForecast(
                                  items: snapshot.hourly,
                                  unit: controller.unit),
                              const SizedBox(height: 28),
                              DailyForecast(
                                  items: snapshot.daily, unit: controller.unit),
                              const SizedBox(height: 28),
                              WeatherDetails(snapshot: snapshot),
                              const SizedBox(height: 20),
                              _SunCard(snapshot: snapshot),
                              const SizedBox(height: 20),
                              _FavoritesSection(
                                favorites: controller.favorites,
                                selected: snapshot.place,
                                onSelect: controller.loadWeather,
                                onAdd: () => showSearchSheet(context),
                              ),
                              const SizedBox(height: 25),
                              Center(
                                child: Text(
                                  'Weather data by Open-Meteo',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
      floatingActionButton: snapshot == null
          ? null
          : _UnitSwitcher(unit: controller.unit, onChanged: controller.setUnit),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.onSearch,
      required this.onLocation,
      required this.locating});

  final VoidCallback onSearch;
  final VoidCallback onLocation;
  final bool locating;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const _BrandMark(),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: 'Search for a city',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Use current location',
            onPressed: locating ? null : onLocation,
            icon: locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.near_me_rounded),
          ),
        ],
      );
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus(
      {required this.isLoading, required this.message, required this.onRetry});

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: WeatherPalette.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          if (isLoading)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            const Icon(Icons.cloud_off_rounded,
                size: 18, color: WeatherPalette.accentWarm),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  isLoading
                      ? 'Updating your forecast…'
                      : message ?? 'Forecast unavailable.',
                  style: Theme.of(context).textTheme.bodyMedium)),
          if (!isLoading)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: WeatherPalette.accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.cloud_rounded,
              color: WeatherPalette.accent, size: 20),
        ),
        const SizedBox(width: 10),
        Text('flexiweather',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(letterSpacing: -0.3)),
      ]);
}

class _LocationHeading extends StatelessWidget {
  const _LocationHeading(
      {required this.place,
      required this.isFavorite,
      required this.onFavorite});

  final WeatherPlace place;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined,
              color: WeatherPalette.accent, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(place.name, style: Theme.of(context).textTheme.titleLarge),
              if (place.subtitle.isNotEmpty)
                Text(place.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          IconButton(
            tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: onFavorite,
            icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite
                    ? const Color(0xFFFF9D99)
                    : WeatherPalette.muted),
          ),
        ],
      );
}

class _CurrentWeather extends StatelessWidget {
  const _CurrentWeather({required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final condition = WeatherCondition.fromCode(snapshot.weatherCode);
    final unit = context.watch<WeatherController>().unit;
    final now = DateFormat('EEEE, h:mm a').format(snapshot.observedAt);
    return Column(children: [
      const SizedBox(height: 18),
      Text(now.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(letterSpacing: 1.3)),
      const SizedBox(height: 5),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(condition.symbol,
                style: const TextStyle(fontSize: 66, height: 1.15)),
            const SizedBox(width: 15),
            Text(formatTemperature(snapshot.temperature, unit),
                style: const TextStyle(
                    fontSize: 78,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -5,
                    height: 1.1)),
          ]),
      Text(condition.label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text('Feels like ${formatTemperature(snapshot.feelsLike, unit)}',
          style: Theme.of(context).textTheme.bodyMedium),
    ]);
  }
}

class _SunCard extends StatelessWidget {
  const _SunCard({required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    String clock(DateTime? value) =>
        value == null ? '--:--' : DateFormat('h:mm a').format(value);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DAYLIGHT',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: _SunTime(
                  icon: Icons.wb_twilight_rounded,
                  label: 'Sunrise',
                  value: clock(snapshot.sunrise))),
          Container(
              width: 1,
              height: 42,
              color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
              child: _SunTime(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Sunset',
                  value: clock(snapshot.sunset))),
        ]),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                WeatherPalette.accent.withValues(alpha: 0.2),
                WeatherPalette.accentWarm,
                WeatherPalette.accent.withValues(alpha: 0.2)
              ])),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SunTime extends StatelessWidget {
  const _SunTime(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: WeatherPalette.accentWarm, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ]),
      ]);
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection(
      {required this.favorites,
      required this.selected,
      required this.onSelect,
      required this.onAdd});
  final List<WeatherPlace> favorites;
  final WeatherPlace selected;
  final ValueChanged<WeatherPlace> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('SAVED PLACES',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.2)),
          const Spacer(),
          TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Add place')),
        ]),
        if (favorites.isEmpty)
          Text('Your favorite places will be ready here.',
              style: Theme.of(context).textTheme.bodyMedium)
        else
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favorites.map((place) {
                final active = selected.latitude == place.latitude &&
                    selected.longitude == place.longitude;
                return ActionChip(
                  avatar: Icon(Icons.place_rounded,
                      size: 16,
                      color: active
                          ? WeatherPalette.background
                          : WeatherPalette.accent),
                  label: Text(place.name),
                  backgroundColor:
                      active ? WeatherPalette.accent : WeatherPalette.surface,
                  labelStyle: TextStyle(
                      color: active ? WeatherPalette.background : Colors.white),
                  onPressed: () => onSelect(place),
                );
              }).toList()),
      ]);
}

class _UnitSwitcher extends StatelessWidget {
  const _UnitSwitcher({required this.unit, required this.onChanged});
  final TemperatureUnit unit;
  final ValueChanged<TemperatureUnit> onChanged;

  @override
  Widget build(BuildContext context) => Material(
        color: WeatherPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: TemperatureUnit.values.map((value) {
                final selected = value == unit;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                        color: selected
                            ? WeatherPalette.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(value.symbol,
                        style: TextStyle(
                            color: selected
                                ? WeatherPalette.background
                                : Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList()),
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: const EdgeInsets.all(19), child: child));
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
          SizedBox(height: 16),
          Text('Gathering your forecast…'),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: WeatherPalette.muted),
            const SizedBox(height: 16),
            Text('Weather is taking a pause',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again')),
          ]),
        ),
      );
}
