// The stopwatch: elapsed time from a monotonic clock, laps, fastest and slowest lap.

/// A monotonic clock in microseconds (tests pass their own).
typedef Ticker = int Function();

final Stopwatch _monotonic = Stopwatch()..start();
int monotonicMicros() => _monotonic.elapsedMicroseconds;

class StopwatchModel {
  StopwatchModel({Ticker? clock}) : _clock = clock ?? monotonicMicros;

  final Ticker _clock;
  int _accumulated = 0;
  int? _since;

  /// Lap totals (end of each completed lap), oldest first.
  final List<Duration> _laps = [];

  bool get running => _since != null;

  /// Started at least once and not reset.
  bool get used => running || _accumulated > 0 || _laps.isNotEmpty;

  Duration get elapsed {
    final since = _since;
    return Duration(
      microseconds: _accumulated + (since == null ? 0 : _clock() - since),
    );
  }

  void start() {
    _since ??= _clock();
  }

  void stop() {
    final since = _since;
    if (since == null) return;
    _accumulated += _clock() - since;
    _since = null;
  }

  /// Ends the current lap (only while running).
  void lap() {
    if (!running) return;
    _laps.add(elapsed);
  }

  void reset() {
    if (running) return;
    _accumulated = 0;
    _laps.clear();
  }

  /// The completed laps' durations, oldest first.
  List<Duration> get laps => [
    for (var i = 0; i < _laps.length; i++)
      _laps[i] - (i == 0 ? Duration.zero : _laps[i - 1]),
  ];

  /// The current lap: since the end of the last completed one.
  Duration get currentLap =>
      elapsed - (_laps.isEmpty ? Duration.zero : _laps.last);

  /// The completed lap totals, oldest first.
  List<Duration> get lapTotals => List.unmodifiable(_laps);

  /// Indexes of the fastest and slowest completed laps; only with two or more laps.
  (int, int)? get extremes {
    final l = laps;
    if (l.length < 2) return null;
    var fast = 0, slow = 0;
    for (var i = 1; i < l.length; i++) {
      if (l[i] < l[fast]) fast = i;
      if (l[i] > l[slow]) slow = i;
    }
    return (fast, slow);
  }
}

/// `mm:ss,cc` (or `h:mm:ss,cc` past an hour), with the locale's decimal separator.
String formatStopwatch(Duration d, {String decimal = '.'}) {
  final cs = (d.inMilliseconds ~/ 10) % 100;
  final s = d.inSeconds % 60;
  final m = d.inMinutes % 60;
  final h = d.inHours;
  String two(int n) => n.toString().padLeft(2, '0');
  final head = h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  return '$head$decimal${two(cs)}';
}
