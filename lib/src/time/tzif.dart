// Time zones from the system database (`/usr/share/zoneinfo`, or `$TZDIR`): the TZif files
// (RFC 8536) with their transitions, and the POSIX TZ rule of the footer for the instants after
// the last transition. No bundled database: the system one is updated with the OS.

import 'dart:io';
import 'dart:typed_data';

/// The offset from UTC at an instant.
class ZoneOffset {
  const ZoneOffset(this.seconds, {this.dst = false, this.abbreviation = ''});

  /// Seconds east of UTC (Rome in winter: 3600).
  final int seconds;
  final bool dst;
  final String abbreviation;

  @override
  bool operator ==(Object other) =>
      other is ZoneOffset &&
      other.seconds == seconds &&
      other.dst == dst &&
      other.abbreviation == abbreviation;

  @override
  int get hashCode => Object.hash(seconds, dst, abbreviation);

  @override
  String toString() => 'ZoneOffset($seconds, dst: $dst, $abbreviation)';
}

/// A POSIX TZ rule (`CET-1CEST,M3.5.0,M10.5.0/3`): standard offset, optional daylight saving
/// offset and the two yearly transitions.
class PosixRule {
  PosixRule._(this.std, this.dst, this.start, this.end);

  final ZoneOffset std;
  final ZoneOffset? dst;
  final _RuleDate? start;
  final _RuleDate? end;

  /// Parses a rule; null if it is not one.
  static PosixRule? parse(String text) {
    final p = _Parser(text.trim());
    final stdName = p.name();
    if (stdName == null) return null;
    final stdOffset = p.offset();
    if (stdOffset == null) return null;
    // POSIX offsets are west of UTC: "CET-1" is one hour east.
    final std = ZoneOffset(-stdOffset, abbreviation: stdName);
    if (p.done) return PosixRule._(std, null, null, null);
    final dstName = p.name();
    if (dstName == null) return null;
    var dstSeconds = std.seconds + 3600;
    if (!p.done && p.peek != ',') {
      final o = p.offset();
      if (o == null) return null;
      dstSeconds = -o;
    }
    final dst = ZoneOffset(dstSeconds, dst: true, abbreviation: dstName);
    if (p.done) {
      // No rule: the US default of the old POSIX standard.
      return PosixRule._(
        std,
        dst,
        const _RuleDate.weekday(3, 2, 0, 7200),
        const _RuleDate.weekday(11, 1, 0, 7200),
      );
    }
    if (!p.take(',')) return null;
    final start = p.ruleDate();
    if (start == null || !p.take(',')) return null;
    final end = p.ruleDate();
    if (end == null || !p.done) return null;
    return PosixRule._(std, dst, start, end);
  }

  /// The offset at `utc` (seconds since the epoch).
  ZoneOffset offsetAt(int utc) {
    final dst = this.dst;
    final start = this.start, end = this.end;
    if (dst == null || start == null || end == null) return std;
    final year = DateTime.fromMillisecondsSinceEpoch(
      (utc + std.seconds) * 1000,
      isUtc: true,
    ).year;
    // The start is in standard local time, the end in daylight saving local time.
    final on = start.utcIn(year, std.seconds);
    final off = end.utcIn(year, dst.seconds);
    final inDst = on < off ? utc >= on && utc < off : !(utc >= off && utc < on);
    return inDst ? dst : std;
  }
}

/// A date of a POSIX rule: `Jn`, `n` or `Mm.w.d`, with the time of day in seconds.
class _RuleDate {
  const _RuleDate.julian(this.day, this.time, {required this.countsLeap})
    : month = 0,
      week = 0,
      weekday = 0;
  const _RuleDate.weekday(this.month, this.week, this.weekday, this.time)
    : day = 0,
      countsLeap = false;

  final int day;
  final bool countsLeap;
  final int month;
  final int week;
  final int weekday;
  final int time;

  /// The UTC instant of this date in `year`, for a local time `offset` seconds east of UTC.
  int utcIn(int year, int offset) {
    final int dayStart;
    if (month == 0) {
      final jan1 = DateTime.utc(year).millisecondsSinceEpoch ~/ 1000;
      var d = day;
      // Jn counts 1…365 and never the 29th of February.
      if (!countsLeap) {
        d = day - 1;
        if (_isLeap(year) && day >= 60) d += 1;
      }
      dayStart = jan1 + d * 86400;
    } else {
      final first = DateTime.utc(year, month);
      // DateTime: Monday 1 … Sunday 7; POSIX: Sunday 0 … Saturday 6.
      final firstWeekday = first.weekday % 7;
      var date = 1 + (weekday - firstWeekday + 7) % 7 + (week - 1) * 7;
      final days = DateTime.utc(year, month + 1, 0).day;
      while (date > days) {
        date -= 7;
      }
      dayStart = DateTime.utc(year, month, date).millisecondsSinceEpoch ~/ 1000;
    }
    return dayStart + time - offset;
  }
}

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

class _Parser {
  _Parser(this.s);
  final String s;
  int i = 0;

  bool get done => i >= s.length;
  String get peek => done ? '' : s[i];

  bool take(String c) {
    if (peek != c) return false;
    i++;
    return true;
  }

  String? name() {
    if (take('<')) {
      final close = s.indexOf('>', i);
      if (close < 0) return null;
      final n = s.substring(i, close);
      i = close + 1;
      return n.isEmpty ? null : n;
    }
    final from = i;
    while (!done && RegExp('[A-Za-z]').hasMatch(peek)) {
      i++;
    }
    return i - from >= 3 ? s.substring(from, i) : null;
  }

  int? number() {
    final from = i;
    while (!done && RegExp('[0-9]').hasMatch(peek)) {
      i++;
    }
    return from == i ? null : int.tryParse(s.substring(from, i));
  }

  /// `[+-]hh[:mm[:ss]]` in seconds.
  int? offset() {
    var sign = 1;
    if (take('-')) {
      sign = -1;
    } else {
      take('+');
    }
    final h = number();
    if (h == null || h > 167) return null;
    var total = h * 3600;
    if (take(':')) {
      final m = number();
      if (m == null || m > 59) return null;
      total += m * 60;
      if (take(':')) {
        final sec = number();
        if (sec == null || sec > 59) return null;
        total += sec;
      }
    }
    return sign * total;
  }

  _RuleDate? ruleDate() {
    _RuleDate? date;
    if (take('J')) {
      final n = number();
      if (n == null || n < 1 || n > 365) return null;
      date = _RuleDate.julian(n, 7200, countsLeap: false);
    } else if (take('M')) {
      final m = number();
      if (m == null || m < 1 || m > 12 || !take('.')) return null;
      final w = number();
      if (w == null || w < 1 || w > 5 || !take('.')) return null;
      final d = number();
      if (d == null || d > 6) return null;
      date = _RuleDate.weekday(m, w, d, 7200);
    } else {
      final n = number();
      if (n == null || n > 365) return null;
      date = _RuleDate.julian(n, 7200, countsLeap: true);
    }
    if (take('/')) {
      // Version 3 allows -167…167 hours.
      final t = offset();
      if (t == null) return null;
      date = date.month == 0
          ? _RuleDate.julian(date.day, t, countsLeap: date.countsLeap)
          : _RuleDate.weekday(date.month, date.week, date.weekday, t);
    }
    return date;
  }
}

/// A time zone read from a TZif file.
class TimeZone {
  TimeZone._(this.name, this._times, this._typeOf, this._types, this._rule);

  /// The IANA name (`Europe/Rome`).
  final String name;
  final List<int> _times;
  final List<int> _typeOf;
  final List<ZoneOffset> _types;
  final PosixRule? _rule;

  /// A zone that is always UTC (fallback when the database is missing).
  static final TimeZone utc = TimeZone._('UTC', const [], const [], const [
    ZoneOffset(0, abbreviation: 'UTC'),
  ], null);

  /// Parses a TZif file; null if it is not one.
  static TimeZone? parse(String name, Uint8List bytes) {
    final r = _Reader(bytes);
    if (bytes.length < 44 || r.ascii(4) != 'TZif') return null;
    final version = bytes[4];
    final v1 = r.counts(20);
    if (v1 == null) return null;
    var at = 44;
    var timeSize = 4;
    var counts = v1;
    if (version >= 0x32) {
      // Skip the version 1 block, read the 64-bit one.
      at += v1.blockSize(4);
      if (bytes.length < at + 44 || r.asciiAt(at, 4) != 'TZif') return null;
      final v2 = r.counts(at + 20);
      if (v2 == null) return null;
      counts = v2;
      at += 44;
      timeSize = 8;
    }
    if (bytes.length < at + counts.blockSize(timeSize)) return null;
    final times = <int>[];
    for (var k = 0; k < counts.time; k++) {
      times.add(timeSize == 8 ? r.int64(at) : r.int32(at));
      at += timeSize;
    }
    final typeOf = <int>[];
    for (var k = 0; k < counts.time; k++) {
      typeOf.add(bytes[at++]);
    }
    final raw = <(int, bool, int)>[];
    for (var k = 0; k < counts.type; k++) {
      raw.add((r.int32(at), bytes[at + 4] != 0, bytes[at + 5]));
      at += 6;
    }
    final chars = bytes.sublist(at, at + counts.char);
    at += counts.char;
    String abbreviation(int index) {
      if (index >= chars.length) return '';
      var end = chars.indexOf(0, index);
      if (end < 0) end = chars.length;
      return String.fromCharCodes(chars.sublist(index, end));
    }

    final types = [
      for (final (offset, dst, index) in raw)
        ZoneOffset(offset, dst: dst, abbreviation: abbreviation(index)),
    ];
    if (types.isEmpty || typeOf.any((t) => t >= types.length)) return null;
    at += counts.leap * (timeSize + 4) + counts.isStd + counts.isUt;
    PosixRule? rule;
    if (timeSize == 8 && at < bytes.length && bytes[at] == 0x0a) {
      final end = bytes.indexOf(0x0a, at + 1);
      if (end > at + 1) {
        rule = PosixRule.parse(
          String.fromCharCodes(bytes.sublist(at + 1, end)),
        );
      }
    }
    return TimeZone._(name, times, typeOf, types, rule);
  }

  /// The offset at `utc` (seconds since the epoch).
  ZoneOffset offsetAt(int utc) {
    if (_times.isEmpty || utc < _times.first) {
      final rule = _rule;
      if (_times.isEmpty && rule != null) return rule.offsetAt(utc);
      // Before the first transition: the first standard time type.
      return _types.firstWhere((t) => !t.dst, orElse: () => _types.first);
    }
    if (utc >= _times.last) {
      final rule = _rule;
      if (rule != null) return rule.offsetAt(utc);
      return _types[_typeOf.last];
    }
    var lo = 0, hi = _times.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_times[mid] <= utc) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return _types[_typeOf[lo]];
  }

  /// The wall-clock time in this zone at the UTC instant `at` (a UTC DateTime whose fields are
  /// the local fields).
  DateTime wallTime(DateTime at) {
    final utc = at.toUtc();
    final offset = offsetAt(utc.millisecondsSinceEpoch ~/ 1000);
    return utc.add(Duration(seconds: offset.seconds));
  }
}

class _Counts {
  const _Counts(
    this.isUt,
    this.isStd,
    this.leap,
    this.time,
    this.type,
    this.char,
  );
  final int isUt, isStd, leap, time, type, char;

  int blockSize(int timeSize) =>
      time * timeSize +
      time +
      type * 6 +
      char +
      leap * (timeSize + 4) +
      isStd +
      isUt;
}

class _Reader {
  _Reader(this.bytes) : data = ByteData.sublistView(bytes);
  final Uint8List bytes;
  final ByteData data;

  String ascii(int n) => asciiAt(0, n);
  String asciiAt(int at, int n) =>
      String.fromCharCodes(bytes.sublist(at, at + n));
  int int32(int at) => data.getInt32(at);
  int int64(int at) => data.getInt64(at);

  _Counts? counts(int at) {
    if (bytes.length < at + 24) return null;
    final c = [for (var k = 0; k < 6; k++) data.getUint32(at + k * 4)];
    // Sanity limits: a hostile file must not make us allocate gigabytes.
    if (c.any((n) => n > 1 << 20)) return null;
    return _Counts(c[0], c[1], c[2], c[3], c[4], c[5]);
  }
}

/// The system time zone database.
class ZoneDatabase {
  ZoneDatabase({String? directory, Map<String, String>? environment})
    : _env = environment ?? Platform.environment,
      directory =
          directory ??
          (environment ?? Platform.environment)['TZDIR'] ??
          '/usr/share/zoneinfo';

  final String directory;
  final Map<String, String> _env;
  final Map<String, TimeZone?> _cache = {};

  static final _validName = RegExp(r'^[A-Za-z0-9_+\-]+(/[A-Za-z0-9_+\-]+)*$');

  /// The zone `name`; null if it does not exist or is not a valid name.
  TimeZone? zone(String name) {
    if (!_validName.hasMatch(name) || name.split('/').contains('..')) {
      return null;
    }
    return _cache.putIfAbsent(name, () {
      try {
        final file = File('$directory/$name');
        if (!file.existsSync()) return null;
        return TimeZone.parse(name, file.readAsBytesSync());
      } on FileSystemException {
        return null;
      }
    });
  }

  /// The name of the local zone: `$TZ`, the target of `/etc/localtime`, `/etc/timezone`.
  String? localName({String etc = '/etc'}) {
    final tz = _env['TZ'];
    if (tz != null && tz.isNotEmpty) {
      final name = tz.startsWith(':') ? tz.substring(1) : tz;
      if (zone(name) != null) return name;
    }
    try {
      final link = Link('$etc/localtime');
      if (link.existsSync()) {
        final target = link.targetSync();
        final i = target.indexOf('zoneinfo/');
        if (i >= 0) return target.substring(i + 'zoneinfo/'.length);
      }
      final file = File('$etc/timezone');
      if (file.existsSync()) {
        final name = file.readAsStringSync().trim();
        if (zone(name) != null) return name;
      }
    } on FileSystemException {
      // No local zone: the caller falls back to UTC.
    }
    return null;
  }
}
