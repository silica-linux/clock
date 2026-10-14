// Timers: a countdown that can pause and resume, the recent timers and the presets.

import 'stopwatch.dart' show Ticker, monotonicMicros;

/// The presets of the "+" menu (minutes), CL-01.
const List<int> timerPresetMinutes = [
  1,
  2,
  3,
  4,
  5,
  10,
  15,
  20,
  30,
  45,
  60,
  120,
];

class CountdownTimer {
  CountdownTimer({required this.duration, this.label = '', Ticker? clock})
    : _clock = clock ?? monotonicMicros;

  final Duration duration;
  final String label;
  final Ticker _clock;
  int _spent = 0;
  int? _since;

  bool get running => _since != null;
  bool get paused => _since == null && _spent > 0 && !finished;

  Duration get spent {
    final since = _since;
    return Duration(
      microseconds: _spent + (since == null ? 0 : _clock() - since),
    );
  }

  Duration get remaining {
    final left = duration - spent;
    return left.isNegative ? Duration.zero : left;
  }

  bool get finished => spent >= duration;

  /// The fraction left, 1 at the start and 0 at the end (the ring).
  double get fraction => duration.inMicroseconds == 0
      ? 0
      : remaining.inMicroseconds / duration.inMicroseconds;

  void start() {
    if (finished) return;
    _since ??= _clock();
  }

  void pause() {
    final since = _since;
    if (since == null) return;
    _spent += _clock() - since;
    _since = null;
  }

  /// The wall-clock time it ends, if running.
  DateTime? endsAt(DateTime now) => running ? now.add(remaining) : null;
}

/// A timer the user ran before: its duration and label, newest first in the list.
class RecentTimer {
  const RecentTimer(this.duration, this.label);
  final Duration duration;
  final String label;

  Map<String, Object?> toJson() => {
    'seconds': duration.inSeconds,
    'label': label,
  };

  static RecentTimer? fromJson(Object? json) {
    if (json is! Map) return null;
    final seconds = json['seconds'];
    final label = json['label'];
    if (seconds is! int || seconds <= 0 || seconds > 100 * 3600) return null;
    return RecentTimer(
      Duration(seconds: seconds),
      label is String ? label : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RecentTimer &&
      other.duration == duration &&
      other.label == label;

  @override
  int get hashCode => Object.hash(duration, label);
}

/// Adds `timer` at the top of `recents`, without duplicates, at most `limit` entries.
List<RecentTimer> addRecent(
  List<RecentTimer> recents,
  RecentTimer timer, {
  int limit = 10,
}) => [
  timer,
  for (final r in recents)
    if (r != timer) r,
].take(limit).toList();

/// `hh:mm:ss`, or `mm:ss` under an hour.
String formatCountdown(Duration d, {bool alwaysHours = false}) {
  // Round up: a timer at 0.4 s left still shows 00:01.
  final total = (d.inMilliseconds + 999) ~/ 1000;
  final h = total ~/ 3600, m = (total ~/ 60) % 60, s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 || alwaysHours
      ? '${two(h)}:${two(m)}:${two(s)}'
      : '${two(m)}:${two(s)}';
}
