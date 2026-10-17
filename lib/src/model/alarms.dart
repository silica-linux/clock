// Alarms: a time of day, the weekdays it repeats on, a label, snooze, on or off. Times are
// local wall-clock times in the system zone.

import 'sounds.dart';

/// An alarm.
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.repeat = const {},
    this.label = '',
    this.snooze = true,
    this.snoozeMinutes = 9,
    this.enabled = true,
    this.sound = defaultSoundId,
  });

  final int id;
  final int hour;
  final int minute;

  /// Weekdays (DateTime.monday … DateTime.sunday); empty: once.
  final Set<int> repeat;
  final String label;
  final bool snooze;
  final int snoozeMinutes;
  final bool enabled;

  /// The theme name of the ringing sound ([soundIds]).
  final String sound;

  Alarm copyWith({
    int? hour,
    int? minute,
    Set<int>? repeat,
    String? label,
    bool? snooze,
    int? snoozeMinutes,
    bool? enabled,
    String? sound,
  }) => Alarm(
    id: id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    repeat: repeat ?? this.repeat,
    label: label ?? this.label,
    snooze: snooze ?? this.snooze,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    enabled: enabled ?? this.enabled,
    sound: sound ?? this.sound,
  );

  /// The next time it fires strictly after `now` (local wall time), or null when off.
  DateTime? nextFire(DateTime now) {
    if (!enabled) return null;
    for (var days = 0; days <= 7; days++) {
      final day = DateTime(now.year, now.month, now.day + days, hour, minute);
      if (!day.isAfter(now)) continue;
      if (repeat.isEmpty || repeat.contains(day.weekday)) return day;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'repeat': repeat.toList()..sort(),
    'label': label,
    'snooze': snooze,
    'snoozeMinutes': snoozeMinutes,
    'enabled': enabled,
    'sound': sound,
  };

  /// From the settings file; null for anything invalid.
  static Alarm? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], hour = json['hour'], minute = json['minute'];
    if (id is! int || hour is! int || minute is! int) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final repeat = json['repeat'];
    final label = json['label'];
    final snoozeMinutes = json['snoozeMinutes'];
    return Alarm(
      id: id,
      hour: hour,
      minute: minute,
      repeat: {
        if (repeat is List)
          for (final d in repeat)
            if (d is int && d >= 1 && d <= 7) d,
      },
      label: label is String ? label : '',
      snooze: json['snooze'] != false,
      snoozeMinutes:
          snoozeMinutes is int && snoozeMinutes > 0 && snoozeMinutes <= 60
          ? snoozeMinutes
          : 9,
      enabled: json['enabled'] != false,
      sound: validSound(json['sound']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Alarm &&
      other.id == id &&
      other.hour == hour &&
      other.minute == minute &&
      other.label == label &&
      other.snooze == snooze &&
      other.snoozeMinutes == snoozeMinutes &&
      other.enabled == enabled &&
      other.sound == sound &&
      other.repeat.length == repeat.length &&
      other.repeat.containsAll(repeat);

  @override
  int get hashCode => Object.hash(id, hour, minute, label, enabled);
}

/// The alarms that should fire between `from` (excluded) and `to` (included): the checker runs
/// every second and passes the previous check as `from`.
List<Alarm> dueAlarms(List<Alarm> alarms, DateTime from, DateTime to) => [
  for (final a in alarms)
    if (a.nextFire(from) case final next? when !next.isAfter(to)) a,
];
