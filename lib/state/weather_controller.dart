import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';
import '../services/open_meteo_service.dart';
import '../services/web_storage_consent_stub.dart'
    if (dart.library.html) '../services/web_storage_consent_web.dart'
    as web_storage_consent;

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
  List<WeatherPlace> recentSearches = const [];
  WeatherPlace selectedPlace = _defaultPlace;
  TemperatureUnit unit = TemperatureUnit.celsius;
  ForecastMetric forecastMetric = ForecastMetric.temperature;
  bool isDarkMode = true;
  bool isLoading = true;
  bool isSearching = false;
  bool isLocating = false;
  bool? storageConsent;
  String? errorMessage;
  int _weatherRequestId = 0;
  int _searchRequestId = 0;

  bool get isWeb => kIsWeb;
  bool get shouldAskStorageConsent => kIsWeb && storageConsent == null;
  String get storageChoiceLabel => storageConsent == null
      ? 'Not chosen'
      : storageConsent!
          ? 'Saving preferences is allowed'
          : 'Session only';
  bool get _canPersist => !kIsWeb || storageConsent == true;

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        storageConsent = switch (web_storage_consent.readWebStorageChoice()) {
          'allow' => true,
          'decline' => false,
          _ => null,
        };
      } else {
        storageConsent = true;
      }
      if (_canPersist) {
        _preferences = await SharedPreferences.getInstance();
        await _loadSavedPreferences();
      }
    } catch (_) {
      // Storage is optional; the app remains usable with session-only settings.
      _preferences = null;
      storageConsent = kIsWeb ? storageConsent : true;
      selectedPlace = _defaultPlace;
    }
    await loadWeather(selectedPlace);
  }

  Future<void> _loadSavedPreferences() async {
    final savedUnit = _preferences?.getString('temperature_unit');
    unit = savedUnit == TemperatureUnit.fahrenheit.name
        ? TemperatureUnit.fahrenheit
        : TemperatureUnit.celsius;
    isDarkMode = _preferences?.getBool('is_dark_mode') ?? isDarkMode;
    forecastMetric = ForecastMetric.values.firstWhere(
      (metric) => metric.name == _preferences?.getString('forecast_metric'),
      orElse: () => ForecastMetric.temperature,
    );
    final favoriteNames =
        _preferences?.getStringList('favorite_places') ?? const [];
    favorites =
        favoriteNames.map(_decodePlace).whereType<WeatherPlace>().toList();
    final recentNames =
        _preferences?.getStringList('recent_places') ?? const [];
    recentSearches =
        recentNames.map(_decodePlace).whereType<WeatherPlace>().toList();
    // Do not restore the last searched or device location. Older builds saved
    // it automatically; remove that historical value as part of migration.
    selectedPlace = _defaultPlace;
    await _preferences?.remove('selected_place');
  }

  Future<void> setWebStorageConsent({required bool allowed}) async {
    if (!kIsWeb) return;
    try {
      web_storage_consent.writeWebStorageChoice(allowed);
    } catch (_) {
      if (allowed) {
        storageConsent = false;
        notifyListeners();
        return;
      }
    }
    storageConsent = allowed;
    if (allowed) {
      try {
        _preferences ??= await SharedPreferences.getInstance();
        final previousSelection = selectedPlace;
        await _loadSavedPreferences();
        notifyListeners();
        if (selectedPlace != previousSelection) {
          await loadWeather(selectedPlace);
        }
      } catch (_) {
        _preferences = null;
        storageConsent = false;
      }
    } else {
      // A decline also clears any app preferences from an earlier version.
      try {
        _preferences ??= await SharedPreferences.getInstance();
        await _clearStoredAppData();
      } catch (_) {
        // Browser storage may be unavailable; keep the app usable in memory.
      }
      _preferences = null;
      favorites = const [];
      recentSearches = const [];
      unit = TemperatureUnit.celsius;
      isDarkMode = true;
      forecastMetric = ForecastMetric.temperature;
      notifyListeners();
    }
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
    if (_canPersist) {
      await _preferences?.setString('temperature_unit', next.name);
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    isDarkMode = enabled;
    if (_canPersist) {
      await _preferences?.setBool('is_dark_mode', enabled);
    }
    notifyListeners();
  }

  Future<void> setForecastMetric(ForecastMetric metric) async {
    forecastMetric = metric;
    if (_canPersist) {
      await _preferences?.setString('forecast_metric', metric.name);
    }
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
    if (_canPersist) {
      await _preferences?.setStringList(
          'favorite_places', favorites.map(_encodePlace).toList());
    }
    notifyListeners();
  }

  Future<void> addRecentSearch(WeatherPlace place) async {
    recentSearches = [
      place,
      ...recentSearches.where((item) => !_samePlace(item, place)),
    ].take(8).toList();
    if (_canPersist) {
      await _preferences?.setStringList(
          'recent_places', recentSearches.map(_encodePlace).toList());
    }
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    recentSearches = const [];
    if (_canPersist) await _preferences?.remove('recent_places');
    notifyListeners();
  }

  bool _samePlace(WeatherPlace first, WeatherPlace second) =>
      first.latitude == second.latitude && first.longitude == second.longitude;

  Future<void> clearSavedAppData() async {
    if (_preferences == null && !kIsWeb) {
      _preferences = await SharedPreferences.getInstance();
    }
    await _clearStoredAppData();
    favorites = const [];
    recentSearches = const [];
    unit = TemperatureUnit.celsius;
    isDarkMode = true;
    forecastMetric = ForecastMetric.temperature;
    if (selectedPlace.name != 'Current location') {
      selectedPlace = _defaultPlace;
      await loadWeather(_defaultPlace);
    } else {
      notifyListeners();
    }
  }

  Future<void> _clearStoredAppData() async {
    await _preferences?.remove('temperature_unit');
    await _preferences?.remove('is_dark_mode');
    await _preferences?.remove('forecast_metric');
    await _preferences?.remove('selected_place');
    await _preferences?.remove('favorite_places');
    await _preferences?.remove('recent_places');
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
