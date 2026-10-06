import 'package:flutter/material.dart';

Color hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

enum Mood { all, beach, mountain, culture }

extension MoodLabel on Mood {
  String get label {
    switch (this) {
      case Mood.all:
        return 'All';
      case Mood.beach:
        return 'Beach';
      case Mood.mountain:
        return 'Mountains';
      case Mood.culture:
        return 'Culture';
    }
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.country,
    required this.tagline,
    required this.season,
    required this.flightTime,
    required this.temp,
    required this.perDay,
    required this.flight,
    required this.mood,
    required this.peaks,
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.layers,
    required this.pack,
  });

  final String id, name, country, tagline, season, flightTime;
  final int temp, perDay, flight;
  final Mood mood;
  final bool peaks;
  final Color skyTop, skyBottom, sun;
  final List<Color> layers;
  final List<String> pack;

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        name: j['name'] as String,
        country: j['country'] as String,
        tagline: j['tagline'] as String,
        season: j['season'] as String,
        flightTime: j['flight_time'] as String,
        temp: (j['temp'] as num).toInt(),
        perDay: (j['per_day'] as num).toInt(),
        flight: (j['flight'] as num).toInt(),
        mood: Mood.values.firstWhere(
          (m) => m.name == j['mood'],
          orElse: () => Mood.all,
        ),
        peaks: j['peaks'] as bool,
        skyTop: hexColor(j['sky_top'] as String),
        skyBottom: hexColor(j['sky_bottom'] as String),
        sun: hexColor(j['sun'] as String),
        layers: (j['layers'] as List).map((e) => hexColor(e as String)).toList(),
        pack: (j['pack'] as List).cast<String>(),
      );

  /// A very dark version of the sky, used as the page background.
  Color get ink => Color.lerp(skyBottom, Colors.black, 0.82)!;

  /// Rough total: stay plus return flight.
  int estimate(int days) => days * perDay + flight;
}

class Trip {
  const Trip({
    required this.destinationId,
    required this.days,
    required this.packed,
    required this.total,
    required this.updatedAt,
  });

  final String destinationId;
  final int days;
  final List<String> packed;
  final int total;
  final double updatedAt;

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        destinationId: j['destination_id'] as String,
        days: (j['days'] as num).toInt(),
        packed: (j['packed'] as List).cast<String>(),
        total: (j['total'] as num).toInt(),
        updatedAt: (j['updated_at'] as num).toDouble(),
      );
}
