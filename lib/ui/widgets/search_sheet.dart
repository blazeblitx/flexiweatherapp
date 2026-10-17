import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather.dart';
import '../../state/weather_controller.dart';
import '../weather_theme.dart';

Future<void> showSearchSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.weatherColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const _SearchSheet(),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _field = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) context.read<WeatherController>().search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeatherController>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 18 + bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
                child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.weatherColors.foreground
                            .withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 21),
            Text('Find your forecast',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text('Search cities anywhere in the world.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Your search is sent to Open-Meteo to find matching places.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.weatherColors.muted,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _field,
              autofocus: true,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => controller.search(value),
              decoration: InputDecoration(
                labelText: 'City or place name',
                hintText: 'City or place name',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : _field.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear city search',
                            onPressed: () {
                              _field.clear();
                              controller.clearSearch();
                            },
                            icon: const Icon(Icons.close_rounded)),
              ),
            ),
            const SizedBox(height: 17),
            Expanded(
              child: controller.searchResults.isEmpty
                  ? _SavedPlaces(
                      favorites: controller.favorites,
                      recentSearches: controller.recentSearches,
                      onSelect: _choose,
                      onClearRecentSearches: controller.clearRecentSearches,
                    )
                  : ListView.separated(
                      itemCount: controller.searchResults.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: context.weatherColors.foreground
                              .withValues(alpha: 0.1)),
                      itemBuilder: (context, index) {
                        final place = controller.searchResults[index];
                        return _PlaceTile(
                            place: place, onTap: () => _choose(place));
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  void _choose(WeatherPlace place) {
    final controller = context.read<WeatherController>();
    Navigator.of(context).pop();
    controller.addRecentSearch(place);
    controller.loadWeather(place);
  }
}

class _SavedPlaces extends StatelessWidget {
  const _SavedPlaces({
    required this.favorites,
    required this.recentSearches,
    required this.onSelect,
    required this.onClearRecentSearches,
  });
  final List<WeatherPlace> favorites;
  final List<WeatherPlace> recentSearches;
  final ValueChanged<WeatherPlace> onSelect;
  final VoidCallback onClearRecentSearches;

  @override
  Widget build(BuildContext context) {
    final recentPlaces = recentSearches;
    final otherFavorites = favorites
        .where((favorite) => !recentPlaces.any((recent) =>
            recent.latitude == favorite.latitude &&
            recent.longitude == favorite.longitude))
        .toList();

    return ListView(
      children: [
        _SectionHeading(
          title: 'RECENT SEARCHES',
          action: recentPlaces.isEmpty
              ? null
              : TextButton.icon(
                  onPressed: onClearRecentSearches,
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
        ),
        if (recentPlaces.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 18),
            child: Text(
              'Choose a city from search results and it will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else ...[
          for (final place in recentPlaces)
            _PlaceTile(place: place, onTap: () => onSelect(place)),
          if (otherFavorites.isNotEmpty) const SizedBox(height: 14),
        ],
        if (otherFavorites.isNotEmpty) ...[
          const _SectionHeading(title: 'FAVORITES'),
          for (final place in otherFavorites)
            _PlaceTile(place: place, onTap: () => onSelect(place)),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1)),
            ),
          ),
          if (action != null) action!,
        ],
      );
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});
  final WeatherPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: context.weatherColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.location_city_rounded,
                color: context.weatherColors.accent)),
        title: Text(place.name),
        subtitle:
            Text(place.subtitle.isEmpty ? 'Weather location' : place.subtitle),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 15, color: context.weatherColors.muted),
        onTap: onTap,
      );
}
