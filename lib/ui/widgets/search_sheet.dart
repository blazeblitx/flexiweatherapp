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
    backgroundColor: WeatherPalette.surface,
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
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 21),
            Text('Find your forecast',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text('Search cities anywhere in the world.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            TextField(
              controller: _field,
              autofocus: true,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => controller.search(value),
              decoration: InputDecoration(
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
                      favorites: controller.favorites, onSelect: _choose)
                  : ListView.separated(
                      itemCount: controller.searchResults.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Colors.white10),
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
    controller.loadWeather(place);
  }
}

class _SavedPlaces extends StatelessWidget {
  const _SavedPlaces({required this.favorites, required this.onSelect});
  final List<WeatherPlace> favorites;
  final ValueChanged<WeatherPlace> onSelect;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(favorites.isEmpty ? 'Start exploring' : 'SAVED PLACES',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 1)),
        const SizedBox(height: 8),
        if (favorites.isEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Text('Your recent and favorite cities will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium))
        else
          Expanded(
              child: ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) => _PlaceTile(
                      place: favorites[index],
                      onTap: () => onSelect(favorites[index])))),
      ]);
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
                color: WeatherPalette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.location_city_rounded,
                color: WeatherPalette.accent)),
        title: Text(place.name),
        subtitle:
            Text(place.subtitle.isEmpty ? 'Weather location' : place.subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 15, color: WeatherPalette.muted),
        onTap: onTap,
      );
}
