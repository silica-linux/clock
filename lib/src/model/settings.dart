// What the app keeps between launches, in `$XDG_CONFIG_HOME/clock/settings.json`: the cities of
// the world clock, the alarms, the recent timers and the last section.

import 'dart:convert';
import 'dart:io';

import 'alarms.dart';
import 'timers.dart';

class Settings {
  Settings(this.path);

  /// `$XDG_CONFIG_HOME/clock/settings.json` (or `~/.config/clock/…`).
  factory Settings.forUser(Map<String, String> env) {
    final config = env['XDG_CONFIG_HOME'] ?? '${env['HOME'] ?? '.'}/.config';
    return Settings('$config/clock/settings.json')..load();
  }

  /// The file; null keeps everything in memory (tests).
  final String? path;

  List<String> cities = [];
  List<Alarm> alarms = [];
  List<RecentTimer> recents = [];
  int section = 0;

  void load() {
    final p = path;
    if (p == null) return;
    try {
      final file = File(p);
      if (!file.existsSync()) return;
      final json = jsonDecode(file.readAsStringSync());
      if (json is! Map) return;
      final c = json['cities'];
      cities = [
        if (c is List)
          for (final z in c)
            if (z is String) z,
      ];
      final a = json['alarms'];
      alarms = [
        if (a is List)
          for (final item in a) ?Alarm.fromJson(item),
      ];
      final r = json['recentTimers'];
      recents = [
        if (r is List)
          for (final item in r) ?RecentTimer.fromJson(item),
      ];
      final s = json['section'];
      if (s is int && s >= 0 && s < 4) section = s;
    } on FileSystemException {
      // Unreadable: start empty.
    } on FormatException {
      // Not JSON: start empty, the next save rewrites it.
    }
  }

  void save() {
    final p = path;
    if (p == null) return;
    try {
      final file = File(p);
      file.parent.createSync(recursive: true);
      final tmp = File('$p.tmp');
      tmp.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'cities': cities,
          'alarms': [for (final a in alarms) a.toJson()],
          'recentTimers': [for (final r in recents) r.toJson()],
          'section': section,
        }),
      );
      tmp.renameSync(p);
    } on FileSystemException {
      // A read-only home: the app keeps working without saving.
    }
  }

  /// A new alarm id.
  int nextAlarmId() => alarms.fold(0, (max, a) => a.id > max ? a.id : max) + 1;
}
