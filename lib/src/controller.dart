// The state of the app: the section, the world clocks, the alarms, the stopwatch and the
// timers, and the checks that ring alarms and timers while the app runs.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../l10n/gen/app_localizations.dart';
import 'model/alarms.dart';
import 'model/settings.dart';
import 'model/sounds.dart';
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
    MicrosClock? micros,
  }) : notifier = notifier ?? Notifier(),
       ringer = ringer ?? Ringer(),
       _now = now ?? DateTime.now,
       _micros = micros,
       stopwatch = StopwatchModel(clock: micros) {
    section = Section.values[settings.section];
    _lastCheck = _now();
  }

  final Settings settings;
  final ZoneDatabase zones;
  final List<City> cities;
  final Notifier notifier;
  final Ringer ringer;
  final DateTime Function() _now;
  final MicrosClock? _micros;

  /// The texts for notifications, set by the app once it knows the locale.
  AppLocalizations? strings;

  late Section section;
  final StopwatchModel stopwatch;
  final List<RunningTimer> timers = [];
  int selectedTimer = 0;
  Timer? _ticker;
  late DateTime _lastCheck;
  Timer? _due;
  final List<Timer> _pending = [];
  final Set<int> _open = {};
  final Map<int, DateTime> _snoozed = {};

  DateTime now() => _now();

  void start() {
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => check(),
    );
    _schedule();
  }

  /// Every change reschedules the precise wake-up for the next alarm, snooze or timer end.
  @override
  void notifyListeners() {
    _schedule();
    super.notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _due?.cancel();
    for (final t in _pending) {
      t.cancel();
    }
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
    if (!alarm.enabled) _snoozed.remove(alarm.id);
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
    _snoozed.remove(id);
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

  void startTimer(
    Duration duration, {
    String label = '',
    String sound = defaultSoundId,
  }) {
    if (duration <= Duration.zero) return;
    final timer = CountdownTimer(
      duration: duration,
      label: label,
      sound: validSound(sound),
      clock: _micros,
    )..start();
    timers.insert(0, RunningTimer(timer));
    selectedTimer = 0;
    settings
      ..recents = addRecent(
        settings.recents,
        RecentTimer(duration, label, validSound(sound)),
      )
      ..save();
    notifyListeners();
  }

  /// Changes the sound a running timer rings with.
  void setTimerSound(RunningTimer t, String sound) {
    t.timer.sound = validSound(sound);
    notifyListeners();
  }

  /// Plays [sound] once: the Sound pop-ups preview what they select.
  void previewSound(String sound) => ringer.preview(sound);

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

  /// The ringing delays measured on the reference (CL-02): an alarm turns its switch off at
  /// once, shows the notification after 227 ms and starts the sound after 389 ms; a timer
  /// goes back to the picker, notifies after 147 ms and sounds after about 290 ms.
  static const alarmNotifyDelay = Duration(milliseconds: 227);
  static const alarmSoundDelay = Duration(milliseconds: 389);
  static const timerNotifyDelay = Duration(milliseconds: 147);
  static const timerSoundDelay = Duration(milliseconds: 290);

  /// Arms one timer for the earliest alarm, snooze or timer end, so they ring on time and
  /// not up to a poll interval late.
  void _schedule() {
    _due?.cancel();
    _due = null;
    if (_ticker == null) return;
    final now = _now();
    DateTime? next;
    void consider(DateTime? at) {
      if (at != null && (next == null || at.isBefore(next!))) next = at;
    }

    for (final a in alarms) {
      consider(a.nextFire(now));
    }
    _snoozed.values.forEach(consider);
    for (final t in timers) {
      consider(t.timer.endsAt(now));
    }
    final at = next;
    if (at == null) return;
    final wait = at.difference(now);
    _due = Timer(wait.isNegative ? Duration.zero : wait, check);
  }

  /// Runs every 250 ms and at each due time: finished timers and due alarms ring.
  void check() {
    final now = _now();
    var changed = stopwatch.running;
    for (final t in [...timers]) {
      if (t.timer.running) changed = true;
      if (t.timer.finished) {
        timers.remove(t);
        selectedTimer = 0;
        _timerEnded(t.timer);
        changed = true;
      }
    }
    for (final alarm in dueAlarms(alarms, _lastCheck, now)) {
      _fireAlarm(alarm);
      changed = true;
    }
    for (final entry in [..._snoozed.entries]) {
      if (!entry.value.isAfter(now)) {
        _snoozed.remove(entry.key);
        final alarm = alarms.where((a) => a.id == entry.key).firstOrNull;
        if (alarm != null) _fireAlarm(alarm);
        changed = true;
      }
    }
    _lastCheck = now;
    if (changed) notifyListeners();
  }

  void _fireAlarm(Alarm alarm) {
    // A one-off alarm turns itself off as it rings; Snooze turns it back on.
    if (alarm.repeat.isEmpty) saveAlarm(alarm.copyWith(enabled: false));
    final s = strings;
    _ring(
      body: alarm.label.isEmpty
          ? (s?.alarmDefaultLabel ?? 'Alarm')
          : alarm.label,
      actions: [
        'stop',
        s?.dismiss ?? 'Stop',
        if (alarm.snooze) ...['snooze', s?.snooze ?? 'Snooze'],
      ],
      notifyAfter: alarmNotifyDelay,
      soundAfter: alarmSoundDelay,
      sound: alarm.sound,
      onAction: (action) {
        if (action != 'snooze') return;
        final current = alarms.where((a) => a.id == alarm.id).firstOrNull;
        if (current == null) return;
        if (!current.enabled) saveAlarm(current.copyWith(enabled: true));
        _snoozed[alarm.id] = _now().add(
          Duration(minutes: current.snoozeMinutes),
        );
        notifyListeners();
      },
    );
  }

  void _timerEnded(CountdownTimer timer) {
    final s = strings;
    _ring(
      body: timer.label.isEmpty ? (s?.timerDone ?? 'Timer done') : timer.label,
      actions: [
        'stop',
        s?.dismiss ?? 'Stop',
        'repeat',
        s?.restart ?? 'Restart',
      ],
      notifyAfter: timerNotifyDelay,
      soundAfter: timerSoundDelay,
      sound: timer.sound,
      onAction: (action) {
        if (action == 'repeat') {
          startTimer(timer.duration, label: timer.label, sound: timer.sound);
        }
      },
    );
  }

  void _later(Duration delay, VoidCallback action) {
    late final Timer t;
    t = Timer(delay, () {
      _pending.remove(t);
      action();
    });
    _pending.add(t);
  }

  void _ring({
    required String body,
    required List<String> actions,
    required Duration notifyAfter,
    required Duration soundAfter,
    required String sound,
    required void Function(String action) onAction,
  }) {
    _later(soundAfter, () {
      ringer.start(sound: sound);
      notifyListeners();
    });
    _later(notifyAfter, () {
      notifier
          .show(
            app: strings?.appTitle ?? 'Clock',
            summary: strings?.appTitle ?? 'Clock',
            body: body,
            actions: actions,
            onAction: (action) {
              stopRinging();
              onAction(action);
            },
          )
          .then((id) {
            if (id != null) _open.add(id);
          });
    });
  }

  bool get ringing => ringer.ringing;

  /// Stops the sound and closes the notifications.
  void stopRinging() {
    for (final t in _pending) {
      t.cancel();
    }
    _pending.clear();
    ringer.stop();
    for (final id in [..._open]) {
      notifier.close(id);
    }
    _open.clear();
    notifyListeners();
  }
}
