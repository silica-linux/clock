// The Stopwatch section (kit `Apps/Clock/Stopwatch`, `Stopwatch Idle`, CL-01): the time in
// Numeral 104 digits `mm:ss.cc` centred at the top, the laps table (320 pt wide, 32 pt rows,
// 1 pt separators, the current lap on top, fastest green and slowest red) and two capsules 96 pt
// apart at the bottom: Lap/Reset (`Lap Button`, disabled at rest) and Start/Stop (green / red).

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'model/stopwatch.dart';
import 'style.dart';
import 'widgets.dart';

class StopwatchView extends StatefulWidget {
  const StopwatchView({super.key, required this.controller});
  final ClockController controller;

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

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
    return Stack(
      children: [
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
          left: 0,
          right: 0,
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
