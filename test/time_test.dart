import 'dart:io';
import 'dart:typed_data';

import 'package:silica_clock/src/time/cities.dart';
import 'package:silica_clock/src/time/tzif.dart';
import 'package:flutter_test/flutter_test.dart';

int at(int y, int m, int d, [int h = 12]) =>
    DateTime.utc(y, m, d, h).millisecondsSinceEpoch ~/ 1000;

void main() {
  group('POSIX rules', () {
    test('northern hemisphere: EST5EDT with the US dates', () {
      final rule = PosixRule.parse('EST5EDT,M3.2.0,M11.1.0')!;
      expect(rule.offsetAt(at(2030, 1, 15)).seconds, -5 * 3600);
      final summer = rule.offsetAt(at(2030, 7, 1));
      expect(summer.seconds, -4 * 3600);
      expect(summer.dst, isTrue);
      expect(summer.abbreviation, 'EDT');
      // 2030-03-10 is the second Sunday of March: 02:00 EST = 07:00 UTC.
      expect(rule.offsetAt(at(2030, 3, 10, 6)).dst, isFalse);
      expect(rule.offsetAt(at(2030, 3, 10, 7)).dst, isTrue);
    });

    test('southern hemisphere and a rule time after midnight', () {
      final rule = PosixRule.parse('AEST-10AEDT,M10.1.0,M4.1.0/3')!;
      expect(rule.offsetAt(at(2030, 1, 15)).seconds, 11 * 3600);
      expect(rule.offsetAt(at(2030, 7, 15)).seconds, 10 * 3600);
    });

    test('quoted names, half hours, no daylight saving', () {
      final rule = PosixRule.parse('<+0330>-3:30')!;
      expect(
        rule.offsetAt(at(2030, 6, 1)),
        const ZoneOffset(12600, abbreviation: '+0330'),
      );
      expect(PosixRule.parse('IST-5:30')!.offsetAt(0).seconds, 19800);
    });

    test('hostile rules are rejected', () {
      for (final text in [
        '',
        'X',
        'CET-1CEST,M13.5.0,M10.5.0',
        'CET-999',
        '<abc',
      ]) {
        expect(PosixRule.parse(text), isNull, reason: text);
      }
    });
  });

  group('TZif', () {
    test('a truncated or foreign file is not a zone', () {
      expect(TimeZone.parse('x', Uint8List.fromList([1, 2, 3])), isNull);
      expect(TimeZone.parse('x', Uint8List(100)), isNull);
    });

    final db = ZoneDatabase();
    final hasDb = File('${db.directory}/Europe/Rome').existsSync();

    test('system zones: transitions and the footer rule', () {
      final rome = db.zone('Europe/Rome')!;
      expect(rome.offsetAt(at(2026, 1, 15)).seconds, 3600);
      expect(rome.offsetAt(at(2026, 7, 15)).seconds, 7200);
      // Far after the last transition: the POSIX rule of the footer.
      expect(rome.offsetAt(at(2100, 7, 1)).seconds, 7200);
      expect(rome.offsetAt(at(2100, 12, 1)).seconds, 3600);
      expect(db.zone('Asia/Kolkata')!.offsetAt(at(2026, 1, 1)).seconds, 19800);
      expect(
        db.zone('Australia/Sydney')!.offsetAt(at(2030, 1, 15)).seconds,
        39600,
      );
      expect(db.zone('UTC')!.offsetAt(at(2026, 1, 1)).seconds, 0);
    }, skip: hasDb ? false : 'no system time zone database');

    test('names outside the database are refused', () {
      expect(db.zone('../../etc/passwd'), isNull);
      expect(db.zone('Europe/../../etc'), isNull);
      expect(db.zone('Nowhere/Land'), isNull);
    });
  });

  group('cities', () {
    const tab = '''
# comment
IT,SM,VA\t+4154+01229\tEurope/Rome
US\t+404251-0740023\tAmerica/New_York\tEastern (most areas)
AQ\t-7750+16636\tAntarctica/McMurdo
''';
    final cities = parseCities(
      tab,
      parseCountries('IT\tItaly\nUS\tUnited States\n'),
    );

    test('names, countries and coordinates from the tables', () {
      expect(cities.map((c) => c.name), ['McMurdo', 'New York', 'Rome']);
      final ny = cities[1];
      expect(ny.country, 'United States');
      expect(ny.latitude, closeTo(40.714, 0.001));
      expect(ny.longitude, closeTo(-74.0064, 0.001));
      expect(cities[0].country, 'AQ');
    });

    test('search: names starting with the query first', () {
      expect(searchCities(cities, 'ro').map((c) => c.name), ['Rome']);
      expect(searchCities(cities, 'italy').map((c) => c.name), ['Rome']);
      expect(searchCities(cities, '  ').length, 3);
    });

    test('sunrise and sunset; polar day', () {
      final rome = sunTimes(DateTime.utc(2026, 6, 21), 41.9, 12.48)!;
      expect(rome.$1.hour * 60 + rome.$1.minute, closeTo(3 * 60 + 35, 6));
      expect(rome.$2.hour * 60 + rome.$2.minute, closeTo(18 * 60 + 49, 6));
      expect(sunTimes(DateTime.utc(2026, 6, 21), 69.65, 18.96), isNull);
    });
  });
}
