// The state of the app: the section, the world clocks, the alarms, the stopwatch and the
// timers, and the checks that ring alarms and timers while the app runs.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../l10n/gen/app_localizations.dart';
import 'model/alarms.dart';
import 'model/settings.dart';
import 'model/stopwatch.dart';
import 'model/timers.dart';
import 'system/notifier.dart';
import 'time/cities.dart';
import 'time/tzif.dart';

enum Section { world, alarms, stopwatch, timers }

/// A running (or paused) timer and the notification it raised when it ended.
class RunningTimer {
  RunningTimer(this.timer);
  final CountdownTimer timer;
}

class ClockController extends ChangeNotifier {
  ClockController({
    required this.settings,
    required this.zones,
    required this.cities,
    Notifier? notifier,
    Ringer? ringer,
    DateTime Function()? now,
  }) : notifier = notifier ?? Notifier(),
       ringer = ringer ?? Ringer(),
       _now = now ?? DateTime.now {
    section = Section.values[settings.section];
    _lastCheck = _now();
  }

  final Settings settings;
  final ZoneDatabase zones;
  final List<City> cities;
  final Notifier notifier;
  final Ringer ringer;
  final DateTime Function() _now;

  /// The texts for notifications, set by the app once it knows the locale.
  AppLocalizations? strings;

  late Section section;
  final StopwatchModel stopwatch = StopwatchModel();
  final List<RunningTimer> timers = [];
  int selectedTimer = 0;
  Timer? _ticker;
  late DateTime _lastCheck;
  int? _ringingNotification;
  final Map<int, DateTime> _snoozed = {};

  DateTime now() => _now();

  void start() {
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => check(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    ringer.stop();
    super.dispose();
  }

  void select(Section s) {
    if (s == section) return;
    section = s;
    settings
      ..section = s.index
      ..save();
    notifyListeners();
  }

  // World clocks.

  List<City> get worldCities => [
    for (final zone in settings.cities)
      cities.firstWhere(
        (c) => c.zone == zone,
        orElse: () => City(
          zone: zone,
          name: zone.split('/').last.replaceAll('_', ' '),
          country: '',
          latitude: 0,
          longitude: 0,
        ),
      ),
  ];

  void addCity(City city) {
    if (settings.cities.contains(city.zone)) return;
    settings
      ..cities = [...settings.cities, city.zone]
      ..save();
    notifyListeners();
  }

  void removeCity(String zone) {
    settings
      ..cities = [
        for (final z in settings.cities)
          if (z != zone) z,
      ]
      ..save();
    notifyListeners();
  }

  /// The local wall time in `zone` now (fields of a UTC DateTime).
  DateTime timeIn(String zone) =>
      (zones.zone(zone) ?? TimeZone.utc).wallTime(_now());

  // Alarms.

  List<Alarm> get alarms => settings.alarms;

  void saveAlarm(Alarm alarm) {
    final list = [...settings.alarms];
    final i = list.indexWhere((a) => a.id == alarm.id);
    i < 0 ? list.add(alarm) : list[i] = alarm;
    list.sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    settings
      ..alarms = list
      ..save();
    notifyListeners();
  }

  void deleteAlarm(int id) {
    settings
      ..alarms = [
        for (final a in settings.alarms)
          if (a.id != id) a,
      ]
      ..save();
    notifyListeners();
  }

  void toggleAlarm(Alarm alarm) =>
      saveAlarm(alarm.copyWith(enabled: !alarm.enabled));

  // Stopwatch.

  void stopwatchStartStop() {
    stopwatch.running ? stopwatch.stop() : stopwatch.start();
    notifyListeners();
  }

  void stopwatchLapReset() {
    stopwatch.running ? stopwatch.lap() : stopwatch.reset();
    notifyListeners();
  }

  // Timers.

  bool get hasTimerList => timers.isNotEmpty || settings.recents.isNotEmpty;

  RunningTimer? get currentTimer =>
      timers.isEmpty ? null : timers[selectedTimer.clamp(0, timers.length - 1)];

  void startTimer(Duration duration, {String label = ''}) {
    if (duration <= Duration.zero) return;
    final timer = CountdownTimer(duration: duration, label: label)..start();
    timers.insert(0, RunningTimer(timer));
    selectedTimer = 0;
    settings
      ..recents = addRecent(settings.recents, RecentTimer(duration, label))
      ..save();
    notifyListeners();
  }

  void pauseResume(RunningTimer t) {
    t.timer.running ? t.timer.pause() : t.timer.start();
    notifyListeners();
  }

  void cancelTimer(RunningTimer t) {
    timers.remove(t);
    selectedTimer = 0;
    notifyListeners();
  }

  void removeRecent(RecentTimer r) {
    settings
      ..recents = [
        for (final x in settings.recents)
          if (x != r) x,
      ]
      ..save();
    notifyListeners();
  }

  // Ringing.

  /// Runs every 250 ms: finished timers and due alarms ring.
  void check() {
    final now = _now();
    var changed = stopwatch.running;
    for (final t in [...timers]) {
      if (t.timer.running) changed = true;
      if (t.timer.finished) {
        timers.remove(t);
        selectedTimer = 0;
        _ring(
          summary: strings?.timerDone ?? 'Timer done',
          body: t.timer.label.isEmpty
              ? formatCountdown(t.timer.duration)
              : t.timer.label,
          snoozable: false,
        );
        changed = true;
      }
    }
    for (final alarm in dueAlarms(alarms, _lastCheck, now)) {
      _fireAlarm(alarm, now);
      changed = true;
    }
    for (final entry in [..._snoozed.entries]) {
      if (!entry.value.isAfter(now)) {
        _snoozed.remove(entry.key);
        final alarm = alarms.where((a) => a.id == entry.key).firstOrNull;
        if (alarm != null) _fireAlarm(alarm, now, snoozed: true);
      }
    }
    _lastCheck = now;
    if (changed) notifyListeners();
  }

  void _fireAlarm(Alarm alarm, DateTime now, {bool snoozed = false}) {
    // A one-off alarm turns itself off after ringing.
    if (alarm.repeat.isEmpty && !snoozed) {
      saveAlarm(alarm.copyWith(enabled: false));
    }
    final label = alarm.label.isEmpty
        ? (strings?.alarmDefaultLabel ?? 'Alarm')
        : alarm.label;
    final time =
        '${alarm.hour.toString().padLeft(2, '0')}:'
        '${alarm.minute.toString().padLeft(2, '0')}';
    _ring(
      summary: label,
      body: strings?.alarmRinging(label, time) ?? '$label · $time',
      snoozable: alarm.snooze,
      onSnooze: () => _snoozed[alarm.id] = _now().add(
        Duration(minutes: alarm.snoozeMinutes),
      ),
    );
  }

  void _ring({
    required String summary,
    required String body,
    required bool snoozable,
    VoidCallback? onSnooze,
  }) {
    ringer.start();
    final s = strings;
    notifier
        .show(
          app: s?.appTitle ?? 'Clock',
          summary: summary,
          body: body,
          actions: [
            if (snoozable) ...['snooze', s?.snooze ?? 'Snooze'],
            'stop',
            s?.dismiss ?? 'Stop',
          ],
          onAction: (action) {
            stopRinging();
            if (action == 'snooze') onSnooze?.call();
          },
        )
        .then((id) => _ringingNotification = id);
  }

  bool get ringing => ringer.ringing;

  /// Stops the sound and closes the notification.
  void stopRinging() {
    ringer.stop();
    final id = _ringingNotification;
    _ringingNotification = null;
    if (id != null) notifier.close(id);
    notifyListeners();
  }
}
