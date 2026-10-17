import 'package:silica_clock/src/model/alarms.dart';
import 'package:silica_clock/src/model/settings.dart';
import 'package:silica_clock/src/model/stopwatch.dart';
import 'package:silica_clock/src/model/sounds.dart';
import 'package:silica_clock/src/model/timers.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stopwatch: start, stop, laps, fastest and slowest', () {
    var now = 0;
    final sw = StopwatchModel(clock: () => now);
    expect(sw.used, isFalse);
    sw.start();
    now = 5000000;
    sw.lap();
    now = 7000000;
    sw.lap();
    now = 16000000;
    sw.lap();
    now = 17000000;
    expect(sw.laps, [
      const Duration(seconds: 5),
      const Duration(seconds: 2),
      const Duration(seconds: 9),
    ]);
    expect(sw.currentLap, const Duration(seconds: 1));
    expect(sw.extremes, (1, 2));
    sw.stop();
    now = 30000000;
    expect(sw.elapsed, const Duration(seconds: 17));
    sw.reset();
    expect(sw.elapsed, Duration.zero);
    expect(sw.laps, isEmpty);
  });

  test('stopwatch format: hundredths, hours past an hour', () {
    expect(
      formatStopwatch(const Duration(milliseconds: 65430), decimal: ','),
      '01:05,43',
    );
    expect(formatStopwatch(const Duration(hours: 1, seconds: 2)), '1:00:02.00');
  });

  test('timer: countdown, pause, fraction, finish', () {
    var now = 0;
    final t = CountdownTimer(
      duration: const Duration(seconds: 60),
      clock: () => now,
    )..start();
    now = 15000000;
    expect(t.remaining, const Duration(seconds: 45));
    expect(t.fraction, closeTo(0.75, 1e-9));
    t.pause();
    now = 100000000;
    expect(t.paused, isTrue);
    expect(t.remaining, const Duration(seconds: 45));
    t.start();
    now = 146000000;
    expect(t.finished, isTrue);
    expect(t.remaining, Duration.zero);
    expect(formatCountdown(const Duration(milliseconds: 400)), '00:01');
    expect(
      formatCountdown(const Duration(minutes: 15), alwaysHours: true),
      '00:15:00',
    );
  });

  test('recent timers: newest first, no duplicates, limited', () {
    const a = RecentTimer(Duration(minutes: 1), '');
    const b = RecentTimer(Duration(minutes: 5), 'Tea');
    var list = addRecent(const [], a);
    list = addRecent(list, b);
    list = addRecent(list, a);
    expect(list, [a, b]);
    for (var i = 1; i <= 20; i++) {
      list = addRecent(list, RecentTimer(Duration(minutes: i + 10), ''));
    }
    expect(list.length, 10);
    expect(RecentTimer.fromJson({'seconds': -1}), isNull);
  });

  test('alarm: next fire once and on repeated weekdays', () {
    // Wednesday 14 October 2026, 10:00.
    final now = DateTime(2026, 10, 14, 10);
    const once = Alarm(id: 1, hour: 7, minute: 30);
    expect(once.nextFire(now), DateTime(2026, 10, 15, 7, 30));
    expect(
      const Alarm(id: 2, hour: 10, minute: 30).nextFire(now),
      DateTime(2026, 10, 14, 10, 30),
    );
    const weekend = Alarm(
      id: 3,
      hour: 9,
      minute: 0,
      repeat: {DateTime.saturday, DateTime.sunday},
    );
    expect(weekend.nextFire(now), DateTime(2026, 10, 17, 9));
    expect(once.copyWith(enabled: false).nextFire(now), isNull);
    const ten = Alarm(id: 4, hour: 10, minute: 0);
    expect(
      dueAlarms([once, ten], now.subtract(const Duration(seconds: 1)), now),
      [ten],
    );
  });

  test('alarm json: round trip and hostile values', () {
    const a = Alarm(
      id: 5,
      hour: 6,
      minute: 45,
      repeat: {1, 5},
      label: 'Gym',
      snoozeMinutes: 5,
    );
    expect(Alarm.fromJson(a.toJson()), a);
    expect(Alarm.fromJson({'id': 1, 'hour': 25, 'minute': 0}), isNull);
    expect(Alarm.fromJson('x'), isNull);
    expect(
      Alarm.fromJson({
        'id': 1,
        'hour': 1,
        'minute': 2,
        'repeat': [0, 3, 'x'],
      })!.repeat,
      {3},
    );
  });

  test(
    'sounds: stored with alarms and recent timers, unknown ones fall back',
    () {
      const a = Alarm(id: 1, hour: 6, minute: 0, sound: 'bell');
      expect(Alarm.fromJson(a.toJson())!.sound, 'bell');
      expect(
        Alarm.fromJson({
          'id': 1,
          'hour': 1,
          'minute': 2,
          'sound': 'nope',
        })!.sound,
        defaultSoundId,
      );
      // A file written before sounds existed has none.
      expect(
        Alarm.fromJson({'id': 1, 'hour': 1, 'minute': 2})!.sound,
        defaultSoundId,
      );
      const r = RecentTimer(Duration(minutes: 3), 'Eggs', 'complete');
      expect(RecentTimer.fromJson(r.toJson()), r);
      expect(
        RecentTimer.fromJson({'seconds': 60, 'label': ''})!.sound,
        defaultSoundId,
      );
    },
  );

  test('settings: save and load, a broken file starts empty', () {
    final dir = Directory.systemTemp.createTempSync('clock-settings');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/clock/settings.json';
    final s = Settings(path)
      ..cities = ['Europe/Rome', 'Asia/Tokyo']
      ..alarms = [const Alarm(id: 1, hour: 7, minute: 0, label: 'Up')]
      ..recents = [const RecentTimer(Duration(minutes: 3), 'Eggs')]
      ..section = 2
      ..save();
    final again = Settings(path)..load();
    expect(again.cities, s.cities);
    expect(again.alarms, s.alarms);
    expect(again.recents, s.recents);
    expect(again.section, 2);
    expect(again.nextAlarmId(), 2);
    File(path).writeAsStringSync('{not json');
    final broken = Settings(path)..load();
    expect(broken.cities, isEmpty);
  });
}
