import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class OpenMeteoService {
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<WeatherPlace>> searchPlaces(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '8',
      'language': 'en',
      'format': 'json',
    });
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const WeatherServiceException(
          'City search is unavailable right now.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(WeatherPlace.fromGeocodingJson)
        .toList(growable: false);
  }

  Future<WeatherSnapshot> fetchWeather(WeatherPlace place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': place.latitude.toString(),
      'longitude': place.longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,uv_index,visibility',
      'hourly':
          'temperature_2m,precipitation,precipitation_probability,weather_code,is_day,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,wind_speed_10m_max,precipitation_sum',
      'forecast_days': '7',
      'timezone': 'auto',
      'wind_speed_unit': 'kmh',
    });
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const WeatherServiceException('Weather data could not be loaded.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherSnapshot.fromOpenMeteo(payload, place: place);
  }

  void close() => _client.close();
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
