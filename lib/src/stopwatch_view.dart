// The Stopwatch section (kit `Apps/Clock/Stopwatch`, `Stopwatch Idle`, CL-01): the time in
// Numeral 104 digits `mm:ss.cc` centred at the top, the laps table (320 pt wide, 32 pt rows,
// 1 pt separators, the current lap on top, fastest green and slowest red) and two capsules 96 pt
// apart at the bottom: Lap/Reset (`Lap Button`, disabled at rest) and Start/Stop (green / red).

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'model/stopwatch.dart';
import 'style.dart';
import 'widgets.dart';

class StopwatchView extends StatefulWidget {
  const StopwatchView({
    super.key,
    required this.controller,
    this.analog = false,
  });
  final ClockController controller;

  /// The analog face (kit `Stopwatch Analog`): a dial left of the laps table.
  final bool analog;

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

/// The stopwatch with the analog face.
class AnalogStopwatchView extends StopwatchView {
  const AnalogStopwatchView({super.key, required super.controller})
    : super(analog: true);
}

const double _dial = 360;
const double _dialGap = 60;

/// The dial's top in the section (kit: 192 in the window, under the 52 pt toolbar).
const double _dialTop = 192 - AmalfiToolbarMetrics.toolbarHeight;

class _StopwatchViewState extends State<StopwatchView>
    with SingleTickerProviderStateMixin {
  // The digits follow every frame while the stopwatch runs; at rest the ticker stops, so the
  // app asks for no frames (#202).
  late final Ticker _ticker = createTicker((_) {
    if (widget.controller.stopwatch.running) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(StopwatchView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  void _sync() {
    final running = widget.controller.stopwatch.running;
    if (running && !_ticker.isActive) _ticker.start();
    if (!running && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final c = widget.controller;
    final sw = c.stopwatch;
    final active = WindowActiveScope.of(context);
    final laps = sw.laps;
    final totals = sw.lapTotals;
    final extremes = sw.extremes;
    String time(Duration d) => formatStopwatch(d, decimal: l.decimalSeparator);
    final width = MediaQuery.sizeOf(context).width;
    // The dial and the table are centred together (142 pt from the left at 1024 pt).
    final groupLeft = math.max(
      0.0,
      (width - (_dial + _dialGap + ClockMetrics.lapsWidth)) / 2,
    );
    return Stack(
      children: [
        if (widget.analog)
          Positioned(
            left: groupLeft,
            top: _dialTop,
            width: _dial,
            height: _dial,
            child: _AnalogDial(
              key: const ValueKey('analog dial'),
              stopwatch: sw,
              time: time(sw.elapsed),
              ink: colors.textPrimary,
              secondary: colors.textTertiary,
              face: ClockDial.face,
              hole: ClockDial.hole,
            ),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            top: ClockMetrics.stopwatchDigitsCenter - 104 / 2,
            height: 104,
            child: Center(
              child: Text(
                time(sw.elapsed),
                key: const ValueKey('stopwatch digits'),
                style: numeral(104, color: colors.textPrimary, tabular: true),
              ),
            ),
          ),
        Positioned(
          top: ClockMetrics.lapsTop,
          bottom:
              ClockMetrics.stopwatchButtonsBottom +
              ClockMetrics.buttonHeight +
              24,
          left: widget.analog ? groupLeft + _dial + _dialGap : 0,
          right: widget.analog ? null : 0,
          width: widget.analog ? ClockMetrics.lapsWidth : null,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: ClockMetrics.lapsWidth,
              // The header is there at rest too; its line and the rows once started.
              child: Column(
                children: [
                  _LapHeader(
                    cells: [
                      l.lapsHeaderLap,
                      l.lapsHeaderSplit,
                      l.lapsHeaderTotal,
                    ],
                    line: sw.used,
                  ),
                  if (sw.used)
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _LapRow(
                            key: const ValueKey('current lap'),
                            cells: [
                              l.lapNumber(laps.length + 1),
                              time(sw.currentLap),
                              time(sw.elapsed),
                            ],
                          ),
                          for (var i = laps.length - 1; i >= 0; i--)
                            _LapRow(
                              key: ValueKey('lap $i'),
                              cells: [
                                l.lapNumber(i + 1),
                                time(laps[i]),
                                time(totals[i]),
                              ],
                              color: extremes == null
                                  ? null
                                  : i == extremes.$1
                                  ? clockPalette.start
                                  : i == extremes.$2
                                  ? clockPalette.stop
                                  : null,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: ClockMetrics.stopwatchButtonsBottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: ClockMetrics.buttonsGap,
            children: [
              ClockButton(
                key: const ValueKey('lap reset'),
                label: sw.running || !sw.used ? l.lap : l.reset,
                onPressed: sw.used ? c.stopwatchLapReset : null,
              ),
              ClockButton(
                key: const ValueKey('start stop'),
                label: sw.running ? l.stop : l.start,
                // Measured (CL-02): the start button goes gray in an inactive window.
                fill: !active
                    ? colors.textTertiary
                    : sw.running
                    ? clockPalette.stop
                    : clockPalette.start,
                onPressed: c.stopwatchStartStop,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The columns of the laps table: the lap name at the left (112 pt), the lap time and the total
/// right-aligned (100 and 96 pt, 12 apart).
Widget _cells(List<Widget> cells) => Row(
  children: [
    SizedBox(width: 112, child: cells[0]),
    SizedBox(width: 100, child: cells[1]),
    const SizedBox(width: 12),
    SizedBox(width: 96, child: cells[2]),
  ],
);

/// The header of the laps table (Label, tertiary, 14 pt) with its 1 pt line 6 pt below.
class _LapHeader extends StatelessWidget {
  const _LapHeader({required this.cells, required this.line});
  final List<String> cells;
  final bool line;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final style = AmalfiType.label(color: colors.textTertiary);
    return SizedBox(
      height: ClockMetrics.lapsHeader,
      child: Column(
        children: [
          _cells([
            for (var i = 0; i < cells.length; i++)
              Text(
                cells[i],
                maxLines: 1,
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                style: style,
              ),
          ]),
          const SizedBox(height: 6),
          if (line)
            SizedBox(
              height: 1,
              child: ColoredBox(
                color: colors.lineSeparator,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

/// A row of the laps table: the lap name in Body, the times in Body Emphasis (tabular), a 1 pt
/// line below; 32 pt in all.
class _LapRow extends StatelessWidget {
  const _LapRow({super.key, required this.cells, this.color});

  final List<String> cells;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final ink = color ?? colors.textPrimary;
    // Only the lap times take the colour (kit: the name stays primary).
    return SizedBox(
      height: ClockMetrics.lapsRow,
      child: Column(
        children: [
          const SizedBox(height: 7),
          _cells([
            Text(
              cells[0],
              maxLines: 1,
              style: AmalfiType.body(color: colors.textPrimary),
            ),
            Text(
              cells[1],
              maxLines: 1,
              textAlign: TextAlign.right,
              style: AmalfiType.bodyEmphasis(
                color: ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            Text(
              cells[2],
              maxLines: 1,
              textAlign: TextAlign.right,
              style: AmalfiType.bodyEmphasis(
                color: colors.textPrimary,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ]),
          const Spacer(),
          SizedBox(
            height: 1,
            child: ColoredBox(
              color: colors.lineSeparator,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The analog face (kit `Stopwatch Analog / Dark`, 360 pt): 60 ticks (every fifth long) and the
/// numerals 5…60 outside the centre, the digital time below the middle, a 96 pt minutes
/// sub-dial (30 minutes) at the top, the orange second hand (3 × 196, 27 pt tail), the blue
/// hand of the current lap (2 × 170) and the orange centre cap.
class _AnalogDial extends StatelessWidget {
  const _AnalogDial({
    super.key,
    required this.stopwatch,
    required this.time,
    required this.ink,
    required this.secondary,
    required this.face,
    required this.hole,
  });

  final StopwatchModel stopwatch;
  final String time;
  final Color ink;
  final Color secondary;
  final Color face;
  final Color hole;

  @override
  Widget build(BuildContext context) {
    const c = _dial / 2;
    Widget numeral(String text, double radius, double angle, TextStyle style) {
      final a = angle * math.pi / 180;
      return Positioned(
        left: c + radius * math.sin(a) - 16,
        top: c - radius * math.cos(a) - 11,
        width: 32,
        height: 22,
        child: Center(child: Text(text, maxLines: 1, style: style)),
      );
    }

    final subTop = 304.0 - 192 - 48; // 64 from the dial's top (kit 256 − 192)
    final subCentre = Offset(c, subTop + 48);
    final label = AmalfiType.bodyEmphasis(color: ink).copyWith(height: 1);
    final subLabel = AmalfiType.label(color: secondary).copyWith(height: 1);
    return ExcludeSemantics(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DialPainter(
                elapsed: stopwatch.elapsed,
                lap: stopwatch.currentLap,
                ink: ink,
                secondary: secondary,
                face: face,
                hole: hole,
                subCentre: subCentre,
              ),
            ),
          ),
          for (var i = 1; i <= 12; i++)
            numeral('${i * 5}', 134, i * 30.0, label),
          for (final (text, angle) in [
            ('30', 0.0),
            ('10', 120.0),
            ('20', 240.0),
          ])
            Positioned(
              left: subCentre.dx + 26.5 * math.sin(angle * math.pi / 180) - 12,
              top: subCentre.dy - 26.5 * math.cos(angle * math.pi / 180) - 7,
              width: 24,
              height: 14,
              child: Center(child: Text(text, style: subLabel)),
            ),
          Positioned(
            left: c - 100,
            top: 416 - 192,
            width: 200,
            height: 40,
            child: Center(
              child: Text(
                time,
                key: const ValueKey('analog time'),
                maxLines: 1,
                style: numeral40(ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle numeral40(Color ink) => AmalfiType.numeral40(
  color: ink,
).copyWith(height: 1, fontFeatures: const [FontFeature.tabularFigures()]);

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.elapsed,
    required this.lap,
    required this.ink,
    required this.secondary,
    required this.face,
    required this.hole,
    required this.subCentre,
  });

  final Duration elapsed;
  final Duration lap;
  final Color ink;
  final Color secondary;
  final Color face;
  final Color hole;
  final Offset subCentre;

  static const Color orange = Color(0xFFFF9230);
  static const Color blue = Color(0xFF3D95FF);

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    canvas.drawCircle(centre, 180, Paint()..color = face);
    canvas.drawCircle(
      centre,
      179.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x1FFFFFFF),
    );
    _ticks(canvas, centre, 60, 172, 14, 6.5, 2, 1);
    // The sub-dial: 30 minutes, a tick per minute, every fifth long.
    canvas.drawCircle(subCentre, 48, Paint()..color = const Color(0xFF1B1C1F));
    _ticks(canvas, subCentre, 30, 45, 6, 3, 1.5, 1, longEvery: 5);

    final micros = elapsed.inMicroseconds;
    final seconds = (micros % 60000000) / 60000000;
    final minutes = (micros % 1800000000) / 1800000000;
    final lapSeconds = (lap.inMicroseconds % 60000000) / 60000000;
    _hand(canvas, subCentre, minutes, 40, 6, 2, orange);
    _hand(canvas, centre, lapSeconds, 150, 20, 2, blue);
    _hand(canvas, centre, seconds, 168, 27, 3, orange);
    canvas.drawCircle(subCentre, 4, Paint()..color = orange);
    canvas.drawCircle(centre, 8, Paint()..color = orange);
    canvas.drawCircle(centre, 3, Paint()..color = hole);
  }

  void _ticks(
    Canvas canvas,
    Offset centre,
    int count,
    double outer,
    double longLength,
    double shortLength,
    double longWidth,
    double shortWidth, {
    int longEvery = 5,
  }) {
    final long = Paint()
      ..color = ink
      ..strokeWidth = longWidth
      ..strokeCap = StrokeCap.butt;
    final short = Paint()
      ..color = secondary
      ..strokeWidth = shortWidth
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < count; i++) {
      final isLong = i % longEvery == 0;
      final a = i / count * 2 * math.pi;
      final dir = Offset(math.sin(a), -math.cos(a));
      final length = isLong ? longLength : shortLength;
      canvas.drawLine(
        centre + dir * outer,
        centre + dir * (outer - length),
        isLong ? long : short,
      );
    }
  }

  /// A hand at `turn` (0…1 of a full turn, 0 at the top): `front` ahead of the centre, `tail`
  /// behind it.
  void _hand(
    Canvas canvas,
    Offset centre,
    double turn,
    double front,
    double tail,
    double width,
    Color colour,
  ) {
    final a = turn * 2 * math.pi;
    final dir = Offset(math.sin(a), -math.cos(a));
    canvas.drawLine(
      centre - dir * tail,
      centre + dir * front,
      Paint()
        ..color = colour
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.elapsed != elapsed ||
      old.lap != lap ||
      old.ink != ink ||
      old.secondary != secondary ||
      old.face != face ||
      old.hole != hole;
}
