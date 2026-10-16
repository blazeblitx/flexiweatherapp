import 'dart:math' as math;

enum TemperatureUnit { celsius, fahrenheit }

extension TemperatureUnitLabel on TemperatureUnit {
  String get symbol => this == TemperatureUnit.celsius ? '°C' : '°F';
}

double convertTemperature(double celsius, TemperatureUnit unit) =>
    unit == TemperatureUnit.celsius ? celsius : celsius * 9 / 5 + 32;

String formatTemperature(double celsius, TemperatureUnit unit) =>
    '${convertTemperature(celsius, unit).round()}${unit.symbol}';

class WeatherPlace {
  const WeatherPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1;

  String get subtitle => [admin1, country]
      .whereType<String>()
      .where((part) => part.isNotEmpty)
      .toSet()
      .join(', ');

  factory WeatherPlace.fromGeocodingJson(Map<String, dynamic> json) {
    return WeatherPlace(
      name: json['name'] as String? ?? 'Unknown place',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
    );
  }
}

class HourForecast {
  const HourForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    this.precipitationProbability = 0,
  });

  final DateTime time;
  final double temperature;
  final int weatherCode;
  final int precipitationProbability;
}

class DayForecast {
  const DayForecast({
    required this.date,
    required this.high,
    required this.low,
    required this.weatherCode,
    required this.uvIndex,
    required this.windSpeed,
    this.sunrise,
    this.sunset,
  });

  final DateTime date;
  final double high;
  final double low;
  final int weatherCode;
  final double uvIndex;
  final double windSpeed;
  final DateTime? sunrise;
  final DateTime? sunset;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.place,
    required this.observedAt,
    required this.temperature,
    required this.feelsLike,
    required this.weatherCode,
    required this.isDay,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.visibility,
    required this.hourly,
    required this.daily,
  });

  final WeatherPlace place;
  final DateTime observedAt;
  final double temperature;
  final double feelsLike;
  final int weatherCode;
  final bool isDay;
  final int humidity;
  final double windSpeed;
  final double uvIndex;
  final double visibility;
  final List<HourForecast> hourly;
  final List<DayForecast> daily;

  DateTime? get sunrise => daily.isEmpty ? null : daily.first.sunrise;
  DateTime? get sunset => daily.isEmpty ? null : daily.first.sunset;

  factory WeatherSnapshot.fromOpenMeteo(
    Map<String, dynamic> json, {
    required WeatherPlace place,
  }) {
    final current = json['current'] as Map<String, dynamic>;
    final hourlyJson = json['hourly'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;
    final times = (hourlyJson['time'] as List<dynamic>).cast<String>();
    final temperatures = (hourlyJson['temperature_2m'] as List<dynamic>)
        .map((value) => (value as num).toDouble())
        .toList();
    final codes = (hourlyJson['weather_code'] as List<dynamic>)
        .map((value) => (value as num).toInt())
        .toList();
    final precipitation =
        (hourlyJson['precipitation_probability'] as List<dynamic>?)
                ?.map((value) => (value as num?)?.toInt() ?? 0)
                .toList() ??
            List<int>.filled(times.length, 0);
    final now = DateTime.parse(current['time'] as String);
    var startIndex =
        times.indexWhere((time) => !DateTime.parse(time).isBefore(now));
    if (startIndex < 0) startIndex = 0;
    final hourly = <HourForecast>[];
    for (var i = startIndex; i < math.min(startIndex + 24, times.length); i++) {
      hourly.add(HourForecast(
        time: DateTime.parse(times[i]),
        temperature: temperatures[i],
        weatherCode: codes[i],
        precipitationProbability: precipitation[i],
      ));
    }

    final dayTimes = (dailyJson['time'] as List<dynamic>).cast<String>();
    List<T> dailyValues<T>(
        String key, T Function(dynamic value) convert, T fallback) {
      final values = dailyJson[key] as List<dynamic>?;
      return values == null
          ? List<T>.filled(dayTimes.length, fallback)
          : values.map(convert).toList();
    }

    final highs = dailyValues<double>(
        'temperature_2m_max', (v) => (v as num).toDouble(), 0);
    final lows = dailyValues<double>(
        'temperature_2m_min', (v) => (v as num).toDouble(), 0);
    final dayCodes =
        dailyValues<int>('weather_code', (v) => (v as num).toInt(), 0);
    final uvValues =
        dailyValues<double>('uv_index_max', (v) => (v as num).toDouble(), 0);
    final windValues = dailyValues<double>(
        'wind_speed_10m_max', (v) => (v as num).toDouble(), 0);
    final sunrises = dailyValues<String?>('sunrise', (v) => v as String?, null);
    final sunsets = dailyValues<String?>('sunset', (v) => v as String?, null);
    final daily = <DayForecast>[];
    for (var i = 0; i < dayTimes.length; i++) {
      daily.add(DayForecast(
        date: DateTime.parse(dayTimes[i]),
        high: highs[i],
        low: lows[i],
        weatherCode: dayCodes[i],
        uvIndex: uvValues[i],
        windSpeed: windValues[i],
        sunrise: sunrises[i] == null ? null : DateTime.parse(sunrises[i]!),
        sunset: sunsets[i] == null ? null : DateTime.parse(sunsets[i]!),
      ));
    }

    return WeatherSnapshot(
      place: place,
      observedAt: now,
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      isDay: (current['is_day'] as num? ?? 1).toInt() == 1,
      humidity: (current['relative_humidity_2m'] as num? ?? 0).toInt(),
      windSpeed: (current['wind_speed_10m'] as num? ?? 0).toDouble(),
      uvIndex: (current['uv_index'] as num? ?? 0).toDouble(),
      visibility: (current['visibility'] as num? ?? 0).toDouble(),
      hourly: List.unmodifiable(hourly),
      daily: List.unmodifiable(daily),
    );
  }
}

class WeatherCondition {
  const WeatherCondition(this.label, this.symbol, this.isStormy, this.isWet);

  final String label;
  final String symbol;
  final bool isStormy;
  final bool isWet;

  factory WeatherCondition.fromCode(int code) {
    if (code == 0) {
      return const WeatherCondition('Clear sky', '☀️', false, false);
    }
    if (code == 1) {
      return const WeatherCondition('Mainly clear', '🌤️', false, false);
    }
    if (code == 2) {
      return const WeatherCondition('Partly cloudy', '⛅', false, false);
    }
    if (code == 3) {
      return const WeatherCondition('Overcast', '☁️', false, false);
    }
    if ([45, 48].contains(code)) {
      return const WeatherCondition('Foggy', '🌫️', false, false);
    }
    if ([51, 53, 55, 56, 57].contains(code)) {
      return const WeatherCondition('Drizzle', '🌦️', false, true);
    }
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
      return const WeatherCondition('Rain showers', '🌧️', false, true);
    }
    if ([71, 73, 75, 77, 85, 86].contains(code)) {
      return const WeatherCondition('Snowfall', '❄️', false, true);
    }
    if ([95, 96, 99].contains(code)) {
      return const WeatherCondition('Thunderstorm', '⛈️', true, true);
    }
    return const WeatherCondition('Variable conditions', '🌥️', false, false);
  }
}
