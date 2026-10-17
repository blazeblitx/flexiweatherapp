import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weather.dart';
import '../state/weather_controller.dart';
import 'weather_background.dart';
import 'legal_pages.dart';
import 'weather_theme.dart';
import 'widgets/forecast_sections.dart';
import 'widgets/search_sheet.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeatherController>();
    final snapshot = controller.weather;
    return Scaffold(
      body: WeatherBackground(
        code: snapshot?.weatherCode ?? 2,
        isDay: snapshot?.isDay ?? true,
        child: SafeArea(
          child: _selectedTab == 0
              ? _weatherTab(context, controller, snapshot)
              : _FavoritesTab(
                  favorites: controller.favorites,
                  selectedPlace: controller.selectedPlace,
                  isFavorite: controller.isFavorite,
                  isDarkMode: controller.isDarkMode,
                  onToggleTheme: () =>
                      controller.setDarkMode(!controller.isDarkMode),
                  onSelect: (place) {
                    controller.loadWeather(place);
                    setState(() => _selectedTab = 0);
                  },
                  onRemove: controller.toggleFavorite,
                  onSearch: () => showSearchSheet(context),
                ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.shouldAskStorageConsent) const _WebStorageBanner(),
          NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) =>
                setState(() => _selectedTab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.wb_cloudy_outlined),
                selectedIcon: Icon(Icons.wb_cloudy_rounded),
                label: 'Weather',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: snapshot == null || _selectedTab != 0
          ? null
          : _UnitSwitcher(unit: controller.unit, onChanged: controller.setUnit),
    );
  }

  Widget _weatherTab(
    BuildContext context,
    WeatherController controller,
    WeatherSnapshot? snapshot,
  ) {
    if (snapshot == null && controller.isLoading) {
      return const _LoadingState();
    }
    if (snapshot == null) {
      return _ErrorState(
        message: controller.errorMessage ?? 'The forecast is unavailable.',
        onRetry: () => controller.loadWeather(controller.selectedPlace),
      );
    }
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 380 ? 16.0 : 22.0;
    return RefreshIndicator(
      color: context.weatherColors.accent,
      onRefresh: () => controller.loadWeather(controller.selectedPlace),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 12, horizontalPadding, 36),
            sliver: SliverList.list(children: [
              _TopBar(
                onSearch: () => showSearchSheet(context),
                onLocation: () => _confirmLocationUse(context, controller),
                locating: controller.isLocating,
                isDarkMode: controller.isDarkMode,
                onToggleTheme: () =>
                    controller.setDarkMode(!controller.isDarkMode),
              ),
              if (controller.isLoading || controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                _InlineStatus(
                  isLoading: controller.isLoading,
                  message: controller.errorMessage,
                  onRetry: () =>
                      controller.loadWeather(controller.selectedPlace),
                ),
              ],
              const SizedBox(height: 24),
              _LocationHeading(
                place: snapshot.place,
                isFavorite: controller.isFavorite(snapshot.place),
                onFavorite: () => controller.toggleFavorite(snapshot.place),
              ),
              _CurrentWeather(snapshot: snapshot),
              const SizedBox(height: 28),
              ForecastMetricPicker(
                value: controller.forecastMetric,
                onChanged: controller.setForecastMetric,
              ),
              const SizedBox(height: 12),
              HourlyForecast(
                items: snapshot.hourly,
                unit: controller.unit,
                metric: controller.forecastMetric,
              ),
              const SizedBox(height: 28),
              DailyForecast(
                items: snapshot.daily,
                unit: controller.unit,
                metric: controller.forecastMetric,
              ),
              const SizedBox(height: 28),
              WeatherDetails(snapshot: snapshot),
              const SizedBox(height: 20),
              _SunCard(snapshot: snapshot),
              const SizedBox(height: 25),
              Center(
                child: Text(
                  'Weather data by Open-Meteo',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 12),
              const LegalLinks(),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.onSearch,
      required this.onLocation,
      required this.locating,
      required this.isDarkMode,
      required this.onToggleTheme});

  final VoidCallback onSearch;
  final VoidCallback onLocation;
  final bool locating;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final markWidth = constraints.maxWidth < 340 ? 108.0 : 168.0;
          return Row(
            children: [
              SizedBox(width: markWidth, child: const _BrandMark()),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Search for a city',
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
              ),
              const SizedBox(width: 8),
              _ThemeToggleButton(
                isDarkMode: isDarkMode,
                onPressed: onToggleTheme,
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
        },
      );
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.isDarkMode, required this.onPressed});

  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
        onPressed: onPressed,
        icon: Icon(
            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
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
          color: context.weatherColors.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: context.weatherColors.foreground.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          if (isLoading)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(Icons.cloud_off_rounded,
                size: 18, color: context.weatherColors.accentWarm),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF24505A),
                Color(0xFF32333A),
              ]),
              border: Border.all(
                  color: context.weatherColors.accent.withValues(alpha: 0.34)),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: context.weatherColors.accent.withValues(alpha: 0.10),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(
              top: 5,
              right: 6,
              child: Icon(Icons.wb_sunny_rounded,
                  color: context.weatherColors.accentWarm, size: 15),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 1),
              child: Icon(Icons.cloud_rounded,
                  color: context.weatherColors.accent, size: 27),
            ),
            Positioned(
              bottom: 6,
              left: 7,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      context.weatherColors.foreground.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 11),
        Flexible(
          child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'flexi',
                  style: TextStyle(color: context.weatherColors.accent),
                ),
                TextSpan(
                  text: 'weather',
                  style: TextStyle(color: context.weatherColors.foreground),
                ),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.55,
                  )),
        ),
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
          Icon(Icons.location_on_outlined,
              color: context.weatherColors.accent, size: 18),
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
            tooltip: isFavorite
                ? 'Remove ${place.name} from favorites'
                : 'Add ${place.name} to favorites',
            onPressed: onFavorite,
            icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite
                    ? const Color(0xFFFF9D99)
                    : context.weatherColors.muted),
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
    final accent = _weatherAccent(
      snapshot.weatherCode,
      context.weatherColors.accentWarm,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.13),
            context.weatherColors.surface.withValues(alpha: 0.48),
            context.weatherColors.foreground.withValues(alpha: 0.018),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.075),
            blurRadius: 32,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(children: [
        LayoutBuilder(builder: (context, constraints) {
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 6, color: accent),
              const SizedBox(width: 6),
              Text('CURRENT WEATHER',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      )),
            ]),
          );
          final time = Text(
            now,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign:
                constraints.maxWidth < 280 ? TextAlign.start : TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.weatherColors.muted,
                ),
          );
          if (constraints.maxWidth < 280) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [badge, const SizedBox(height: 6), time],
            );
          }
          return Row(children: [badge, const Spacer(), Flexible(child: time)]);
        }),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final temperatureSize =
              (constraints.maxWidth * .25).clamp(58.0, 82.0).toDouble();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(condition.symbolFor(isDay: snapshot.isDay),
                  style:
                      TextStyle(fontSize: temperatureSize * .73, height: 1.15)),
              SizedBox(width: temperatureSize * .12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(formatTemperature(snapshot.temperature, unit),
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: temperatureSize,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -temperatureSize * .067,
                          height: 1.08)),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 3),
        Text(condition.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: context.weatherColors.shadow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    context.weatherColors.foreground.withValues(alpha: 0.055)),
          ),
          child: Text(
              'Feels like ${formatTemperature(snapshot.feelsLike, unit)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12)),
        ),
      ]),
    );
  }
}

Color _weatherAccent(int code, Color clearWeatherAccent,
    {required bool isDark}) {
  if ([95, 96, 99].contains(code)) {
    return isDark ? const Color(0xFF9AAEED) : const Color(0xFF4F6191);
  }
  if ([71, 73, 75, 77, 85, 86].contains(code)) {
    return isDark ? const Color(0xFFA8DDF2) : const Color(0xFF39738D);
  }
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
    return isDark ? const Color(0xFF83CBE2) : const Color(0xFF24758B);
  }
  if ([3, 45, 48].contains(code)) {
    return isDark ? const Color(0xFFB9C7D4) : const Color(0xFF536773);
  }
  if ([1, 2].contains(code)) {
    return isDark ? const Color(0xFFE7C18E) : const Color(0xFF8A5A16);
  }
  return clearWeatherAccent;
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
              color: context.weatherColors.foreground.withValues(alpha: 0.08)),
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
                context.weatherColors.accent.withValues(alpha: 0.2),
                context.weatherColors.accentWarm,
                context.weatherColors.accent.withValues(alpha: 0.2)
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final labelAndTime = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 3),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          );
          if (constraints.maxWidth < 150) {
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: context.weatherColors.accentWarm, size: 20),
              const SizedBox(height: 6),
              labelAndTime,
            ]);
          }
          return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: context.weatherColors.accentWarm, size: 20),
            const SizedBox(width: 10),
            labelAndTime,
          ]);
        },
      );
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab(
      {required this.favorites,
      required this.selectedPlace,
      required this.isFavorite,
      required this.isDarkMode,
      required this.onToggleTheme,
      required this.onSelect,
      required this.onRemove,
      required this.onSearch});

  final List<WeatherPlace> favorites;
  final WeatherPlace selectedPlace;
  final bool Function(WeatherPlace place) isFavorite;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<WeatherPlace> onSelect;
  final ValueChanged<WeatherPlace> onRemove;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width < 380 ? 16 : 22,
                18,
                MediaQuery.sizeOf(context).width < 380 ? 16 : 22,
                36),
            sliver: SliverList.list(children: [
              Row(children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width < 360 ? 132 : 168,
                  child: const _BrandMark(),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: onSearch,
                  tooltip: 'Search for a city',
                  icon: const Icon(Icons.add_location_alt_outlined),
                ),
                const SizedBox(width: 8),
                _ThemeToggleButton(
                    isDarkMode: isDarkMode, onPressed: onToggleTheme),
              ]),
              const SizedBox(height: 30),
              Text('Your places',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                favorites.isEmpty
                    ? 'Save the cities you want to keep close.'
                    : '${favorites.length} saved ${favorites.length == 1 ? 'place' : 'places'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (favorites.isEmpty)
                _EmptyFavorites(onSearch: onSearch)
              else
                for (final place in favorites) ...[
                  _FavoritePlaceCard(
                    place: place,
                    isSelected: place.latitude == selectedPlace.latitude &&
                        place.longitude == selectedPlace.longitude,
                    isFavorite: isFavorite(place),
                    onSelect: () => onSelect(place),
                    onRemove: () => onRemove(place),
                  ),
                  const SizedBox(height: 12),
                ],
              if (favorites.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add another city'),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Tap a place to view its forecast',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 12),
              const LegalLinks(),
            ]),
          ),
        ],
      );
}

Future<void> _confirmLocationUse(
    BuildContext context, WeatherController controller) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Use your location?'),
      content: const Text(
        'If you continue, FlexiWeather will ask your device for your location and send its coordinates to Open-Meteo to get the local forecast. Your one-time location will not be saved as your selected place unless you add it to favorites.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (proceed == true) await controller.useCurrentLocation();
}

class _WebStorageBanner extends StatelessWidget {
  const _WebStorageBanner();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<WeatherController>();
    return Material(
      color: context.weatherColors.surfaceRaised,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Save favorites and preferences?',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Optional browser storage keeps your favorites, recent selected cities, temperature unit, and theme choice on this device. Your choice is stored so we can remember it.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.weatherColors.muted,
                      height: 1.35,
                    ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: [
                  FilledButton(
                    onPressed: () =>
                        controller.setWebStorageConsent(allowed: true),
                    child: const Text('Allow saving'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        controller.setWebStorageConsent(allowed: false),
                    child: const Text('Continue without saving'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/cookies'),
                    child: const Text('Cookie details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritePlaceCard extends StatelessWidget {
  const _FavoritePlaceCard(
      {required this.place,
      required this.isSelected,
      required this.isFavorite,
      required this.onSelect,
      required this.onRemove});

  final WeatherPlace place;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.weatherColors.accent.withValues(alpha: 0.17)
                      : context.weatherColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected
                      ? Icons.near_me_rounded
                      : Icons.location_city_rounded,
                  color: context.weatherColors.accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      place.subtitle.isEmpty
                          ? (isSelected ? 'Currently showing' : 'Saved city')
                          : place.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'Remove ${place.name} from favorites'
                    : 'Remove favorite',
                onPressed: onRemove,
                icon: const Icon(Icons.favorite_rounded),
                color: const Color(0xFFFF9D99),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.weatherColors.muted),
            ]),
          ),
        ),
      );
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Column(children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: context.weatherColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_border_rounded,
                  size: 28, color: context.weatherColors.accent),
            ),
            const SizedBox(height: 18),
            Text('No favorites yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a city to keep its forecast one tap away.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Find a city'),
            ),
          ]),
        ),
      );
}

class _UnitSwitcher extends StatelessWidget {
  const _UnitSwitcher({required this.unit, required this.onChanged});
  final TemperatureUnit unit;
  final ValueChanged<TemperatureUnit> onChanged;

  @override
  Widget build(BuildContext context) => Material(
        color: context.weatherColors.surfaceRaised,
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
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: value == TemperatureUnit.celsius
                        ? 'Celsius'
                        : 'Fahrenheit',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                          color: selected
                              ? context.weatherColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16)),
                      child: ExcludeSemantics(
                        child: Text(value.symbol,
                            style: TextStyle(
                                color: selected
                                    ? context.weatherColors.background
                                    : context.weatherColors.foreground,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
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
          SizedBox(height: 16),
          LegalLinks(),
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
            Icon(Icons.cloud_off_rounded,
                size: 48, color: context.weatherColors.muted),
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
            const SizedBox(height: 12),
            const LegalLinks(),
          ]),
        ),
      );
}
