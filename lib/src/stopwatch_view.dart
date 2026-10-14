// The Stopwatch section (CL-01): thin white digits `mm:ss,cc` (74 pt digit height) centered
// with the top at +87, the laps table (320 pt wide, 31 pt rows, 1 pt `#343434` lines, the
// current lap on top, fastest green and slowest red) and two 150 × 28 capsules 20 pt apart at
// the bottom: Lap/Reset (`#2f2f2f`, disabled at rest) and Start/Stop (green / red).

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'model/stopwatch.dart';
import 'style.dart';
import 'widgets.dart';

/// The thin digits: 74 pt tall in a 390 pt block (CL-01). Inter's figures are ~0.755 em tall
/// and a little wider than the reference's, so the spacing is tightened.
const double stopwatchDigitSize = 74 / 0.755;
const double stopwatchDigitSpacing = -2.2;

/// The distance from the top of the text box to the top of the digits at that size.
const double _digitsInset = 11.5;

class StopwatchView extends StatefulWidget {
  const StopwatchView({super.key, required this.controller});
  final ClockController controller;

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

class _StopwatchViewState extends State<StopwatchView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) {
    if (widget.controller.stopwatch.running) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.controller;
    final sw = c.stopwatch;
    final active = WindowActive.of(context);
    final laps = sw.laps;
    final totals = sw.lapTotals;
    final extremes = sw.extremes;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: ClockMetrics.stopwatchTop - _digitsInset,
          child: Center(
            child: Text(
              formatStopwatch(sw.elapsed, decimal: l.decimalSeparator),
              key: const ValueKey('stopwatch digits'),
              style: thinDigits(
                stopwatchDigitSize,
              ).copyWith(letterSpacing: stopwatchDigitSpacing),
            ),
          ),
        ),
        Positioned(
          top: ClockMetrics.stopwatchTop + 120,
          bottom:
              ClockMetrics.buttonsBottom +
              ClockMetrics.capsuleButton.height +
              24,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: ClockMetrics.lapsWidth,
              // The header and its line are there at rest too; the rows once started.
              child: Column(
                children: [
                  _LapRow(
                    cells: [
                      l.lapsHeaderLap,
                      l.lapsHeaderSplit,
                      l.lapsHeaderTotal,
                    ],
                    header: true,
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
                              formatStopwatch(
                                sw.currentLap,
                                decimal: l.decimalSeparator,
                              ),
                              formatStopwatch(
                                sw.elapsed,
                                decimal: l.decimalSeparator,
                              ),
                            ],
                          ),
                          for (var i = laps.length - 1; i >= 0; i--)
                            _LapRow(
                              key: ValueKey('lap $i'),
                              cells: [
                                l.lapNumber(i + 1),
                                formatStopwatch(
                                  laps[i],
                                  decimal: l.decimalSeparator,
                                ),
                                formatStopwatch(
                                  totals[i],
                                  decimal: l.decimalSeparator,
                                ),
                              ],
                              color: extremes == null
                                  ? null
                                  : i == extremes.$1
                                  ? ClockColors.green
                                  : i == extremes.$2
                                  ? ClockColors.red
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
          bottom: ClockMetrics.buttonsBottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CapsuleButton(
                key: const ValueKey('lap reset'),
                label: sw.running || !sw.used ? l.lap : l.reset,
                color: ClockColors.button,
                onPressed: sw.used ? c.stopwatchLapReset : null,
              ),
              const SizedBox(width: ClockMetrics.capsuleGap),
              CapsuleButton(
                key: const ValueKey('start stop'),
                label: sw.running ? l.stop : l.start,
                color: !active
                    ? ClockColors.dimmed
                    : sw.running
                    ? ClockColors.red
                    : ClockColors.green,
                onPressed: c.stopwatchStartStop,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row of the laps table: lap name regular, times semibold, a 1 pt line below.
class _LapRow extends StatelessWidget {
  const _LapRow({
    super.key,
    required this.cells,
    this.header = false,
    this.color,
  });

  final List<String> cells;
  final bool header;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? ClockColors.text;
    return Container(
      height: header ? 22 : ClockMetrics.lapRow,
      decoration: header
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: ClockColors.line)),
            ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: Text(
                cells[i],
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                style: header
                    ? clockText(10, color: ClockColors.lapHeader)
                    : i == 0
                    ? clockText(13, color: ink)
                    : tabular(13, color: ink),
              ),
            ),
        ],
      ),
    );
  }
}
