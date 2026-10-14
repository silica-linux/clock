// The cities a world clock can show: one per zone of `zone1970.tab` (the zone's principal
// location, with its coordinates), named after the last part of the zone and the country of
// `iso3166.tab`. Both files are in the public domain and ship with the system database.

import 'dart:io';
import 'dart:math' as math;

/// A city of the catalog.
class City {
  const City({
    required this.zone,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  /// The IANA zone (`Europe/Rome`).
  final String zone;

  /// `Rome`, from the zone name.
  final String name;

  /// `Italy`, from `iso3166.tab` (English names: the database has no translations).
  final String country;
  final double latitude;
  final double longitude;

  /// The search text: city and country, lower case.
  String get key => '${name.toLowerCase()} ${country.toLowerCase()}';

  @override
  bool operator ==(Object other) => other is City && other.zone == zone;

  @override
  int get hashCode => zone.hashCode;
}

/// Parses `iso3166.tab`: code → country name.
Map<String, String> parseCountries(String text) => {
  for (final line in text.split('\n'))
    if (line.isNotEmpty && !line.startsWith('#'))
      if (line.split('\t') case [final code, final name, ...])
        code.trim(): name.trim(),
};

/// `+DDMM[SS]` or `+DDDMM[SS]` in degrees.
double? _degrees(String text, int degreeDigits) {
  if (text.isEmpty) return null;
  final sign = text[0] == '-' ? -1.0 : (text[0] == '+' ? 1.0 : 0.0);
  if (sign == 0) return null;
  final digits = text.substring(1);
  if (digits.length < degreeDigits + 2) return null;
  final d = int.tryParse(digits.substring(0, degreeDigits));
  final m = int.tryParse(digits.substring(degreeDigits, degreeDigits + 2));
  final s = digits.length >= degreeDigits + 4
      ? int.tryParse(digits.substring(degreeDigits + 2, degreeDigits + 4))
      : 0;
  if (d == null || m == null || s == null) return null;
  return sign * (d + m / 60 + s / 3600);
}

/// Parses `zone1970.tab` into cities, using the first country code of each line.
List<City> parseCities(String zoneTab, Map<String, String> countries) {
  final cities = <City>[];
  for (final line in zoneTab.split('\n')) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('\t');
    if (parts.length < 3) continue;
    final coordinates = parts[1];
    final split = coordinates.indexOf(RegExp('[+-]'), 1);
    if (split < 0) continue;
    final lat = _degrees(coordinates.substring(0, split), 2);
    final lon = _degrees(coordinates.substring(split), 3);
    if (lat == null || lon == null) continue;
    final zone = parts[2];
    final code = parts[0].split(',').first;
    cities.add(
      City(
        zone: zone,
        name: zone.split('/').last.replaceAll('_', ' '),
        country: countries[code] ?? code,
        latitude: lat,
        longitude: lon,
      ),
    );
  }
  cities.sort((a, b) => a.name.compareTo(b.name));
  return cities;
}

/// The catalog from the system database directory: `zone.tab` (one line per country zone,
/// links included: Reykjavík is there, while `zone1970.tab` merges it into Abidjan), completed
/// by `zone1970.tab`; empty if the files are missing.
List<City> loadCities({String directory = '/usr/share/zoneinfo'}) {
  try {
    final iso = File('$directory/iso3166.tab');
    final countries = iso.existsSync()
        ? parseCountries(iso.readAsStringSync())
        : const <String, String>{};
    final byZone = <String, City>{};
    for (final name in ['zone1970.tab', 'zone.tab']) {
      final file = File('$directory/$name');
      if (!file.existsSync()) continue;
      for (final city in parseCities(file.readAsStringSync(), countries)) {
        byZone[city.zone] = city;
      }
    }
    return byZone.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  } on FileSystemException {
    return const [];
  }
}

/// The cities whose name or country contains `query` (case-insensitive), best first: names
/// that start with the query, then the others.
List<City> searchCities(List<City> cities, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return cities;
  final starts = <City>[], contains = <City>[];
  for (final c in cities) {
    if (c.name.toLowerCase().startsWith(q)) {
      starts.add(c);
    } else if (c.key.contains(q)) {
      contains.add(c);
    }
  }
  return [...starts, ...contains];
}

/// Sunrise and sunset in UTC on the UTC date of `day` (NOAA solar calculation, zenith
/// 90.833°); null for polar day or night.
(DateTime, DateTime)? sunTimes(
  DateTime day,
  double latitude,
  double longitude,
) {
  final date = DateTime.utc(day.year, day.month, day.day);
  final n = date.difference(DateTime.utc(date.year)).inDays + 1;
  double rad(double d) => d * math.pi / 180;
  double deg(double r) => r * 180 / math.pi;
  final gamma = 2 * math.pi / 365 * (n - 1);
  final eqTime =
      229.18 *
      (0.000075 +
          0.001868 * math.cos(gamma) -
          0.032077 * math.sin(gamma) -
          0.014615 * math.cos(2 * gamma) -
          0.040849 * math.sin(2 * gamma));
  final decl =
      0.006918 -
      0.399912 * math.cos(gamma) +
      0.070257 * math.sin(gamma) -
      0.006758 * math.cos(2 * gamma) +
      0.000907 * math.sin(2 * gamma) -
      0.002697 * math.cos(3 * gamma) +
      0.00148 * math.sin(3 * gamma);
  final lat = rad(latitude);
  final cosHa =
      math.cos(rad(90.833)) / (math.cos(lat) * math.cos(decl)) -
      math.tan(lat) * math.tan(decl);
  if (cosHa.abs() > 1) return null;
  final ha = deg(math.acos(cosHa));
  final rise = 720 - 4 * (longitude + ha) - eqTime;
  final set = 720 - 4 * (longitude - ha) - eqTime;
  Duration minutes(double m) => Duration(milliseconds: (m * 60000).round());
  return (date.add(minutes(rise)), date.add(minutes(set)));
}
