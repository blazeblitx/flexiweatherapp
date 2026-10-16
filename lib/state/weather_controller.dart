import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';
import '../services/open_meteo_service.dart';

class WeatherController extends ChangeNotifier {
  WeatherController({OpenMeteoService? service})
      : _service = service ?? OpenMeteoService();

  static const _defaultPlace = WeatherPlace(
    name: 'San Francisco',
    latitude: 37.7749,
    longitude: -122.4194,
    country: 'United States',
    admin1: 'California',
  );

  final OpenMeteoService _service;
  SharedPreferences? _preferences;
  WeatherSnapshot? weather;
  List<WeatherPlace> searchResults = const [];
  List<WeatherPlace> favorites = const [];
  WeatherPlace selectedPlace = _defaultPlace;
  TemperatureUnit unit = TemperatureUnit.celsius;
  bool isLoading = true;
  bool isSearching = false;
  bool isLocating = false;
  String? errorMessage;
  int _weatherRequestId = 0;
  int _searchRequestId = 0;

  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final savedUnit = _preferences?.getString('temperature_unit');
      if (savedUnit == TemperatureUnit.fahrenheit.name) {
        unit = TemperatureUnit.fahrenheit;
      }
      final favoriteNames =
          _preferences?.getStringList('favorite_places') ?? const [];
      favorites =
          favoriteNames.map(_decodePlace).whereType<WeatherPlace>().toList();
      final savedPlace =
          _decodePlace(_preferences?.getString('selected_place'));
      selectedPlace = savedPlace ?? _defaultPlace;
    } catch (_) {
      // Storage is optional; the app remains usable with session-only settings.
      selectedPlace = _defaultPlace;
    }
    await loadWeather(selectedPlace);
  }

  Future<void> loadWeather(WeatherPlace place) async {
    final requestId = ++_weatherRequestId;
    isLoading = true;
    errorMessage = null;
    selectedPlace = place;
    notifyListeners();
    try {
      final result = await _service.fetchWeather(place);
      if (requestId != _weatherRequestId) return;
      weather = result;
      await _preferences?.setString('selected_place', _encodePlace(place));
    } catch (error) {
      if (requestId != _weatherRequestId) return;
      errorMessage = error is WeatherServiceException
          ? error.message
          : 'We couldn’t reach the forecast. Check your connection and try again.';
    } finally {
      if (requestId == _weatherRequestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> search(String query) async {
    final requestId = ++_searchRequestId;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      isSearching = false;
      searchResults = const [];
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    try {
      final results = await _service.searchPlaces(trimmed);
      if (requestId != _searchRequestId) return;
      searchResults = results;
    } catch (_) {
      if (requestId != _searchRequestId) return;
      searchResults = const [];
    } finally {
      if (requestId == _searchRequestId) {
        isSearching = false;
        notifyListeners();
      }
    }
  }

  void clearSearch() {
    _searchRequestId++;
    isSearching = false;
    searchResults = const [];
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    isLocating = true;
    errorMessage = null;
    notifyListeners();
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw const WeatherServiceException(
            'Turn on location services to use your current location.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const WeatherServiceException(
            'Allow location access in Settings to find nearby weather.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15)),
      );
      await loadWeather(WeatherPlace(
        name: 'Current location',
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (error) {
      errorMessage = error is WeatherServiceException
          ? error.message
          : 'Could not get your location. Please try again.';
      notifyListeners();
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  Future<void> setUnit(TemperatureUnit next) async {
    unit = next;
    await _preferences?.setString('temperature_unit', next.name);
    notifyListeners();
  }

  bool isFavorite(WeatherPlace place) => favorites.any((item) =>
      item.latitude == place.latitude && item.longitude == place.longitude);

  Future<void> toggleFavorite(WeatherPlace place) async {
    final updated = [...favorites];
    if (isFavorite(place)) {
      updated.removeWhere((item) =>
          item.latitude == place.latitude && item.longitude == place.longitude);
    } else {
      updated.add(place);
    }
    favorites = updated;
    await _preferences?.setStringList(
        'favorite_places', favorites.map(_encodePlace).toList());
    notifyListeners();
  }

  String _encodePlace(WeatherPlace place) =>
      '${Uri.encodeComponent(place.name)}|${place.latitude}|${place.longitude}|${Uri.encodeComponent(place.country ?? '')}|${Uri.encodeComponent(place.admin1 ?? '')}';

  WeatherPlace? _decodePlace(String? value) {
    if (value == null) return null;
    final parts = value.split('|');
    if (parts.length != 5) return null;
    final latitude = double.tryParse(parts[1]);
    final longitude = double.tryParse(parts[2]);
    if (latitude == null || longitude == null) return null;
    return WeatherPlace(
      name: Uri.decodeComponent(parts[0]),
      latitude: latitude,
      longitude: longitude,
      country: Uri.decodeComponent(parts[3]).isEmpty
          ? null
          : Uri.decodeComponent(parts[3]),
      admin1: Uri.decodeComponent(parts[4]).isEmpty
          ? null
          : Uri.decodeComponent(parts[4]),
    );
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }
}
