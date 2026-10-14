// The Timers section (CL-01). At rest: a picker with three parts (hours, minutes, seconds) as
// light thin digits with small gray units above, a label, the sound and Cancel / Start.
// Running: a 320 pt list on the left (the timers as 300 × 92 cards with a round pause button
// and its progress ring, then the recent timers with a green play button), and in the main
// area a 360 pt ring, stroke 6, orange on `#3b3b3d`, shrinking from the top, with the end
// time, the remaining time, the label and Cancel / Pause.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'model/timers.dart';
import 'style.dart';
import 'widgets.dart';
import 'world_view.dart' show formatTime;

/// The thin digits of the picker and of the ring: 73 pt tall (CL-01, 387 pt block).
const double timerDigitSize = 73 / 0.755;

class TimersView extends StatefulWidget {
  const TimersView({super.key, required this.controller});
  final ClockController controller;

  @override
  State<TimersView> createState() => _TimersViewState();
}

class _TimersViewState extends State<TimersView>
    with SingleTickerProviderStateMixin {
  // The display repaints while a timer runs (the digits twice a second is enough, the ring
  // moves smoothly).
  late final Ticker _ticker = createTicker((_) {
    if (widget.controller.timers.any((t) => t.timer.running)) setState(() {});
  });
  Duration _picked = const Duration(minutes: 15);
  final TextEditingController _label = TextEditingController();
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _label.dispose();
    super.dispose();
  }

  void _start() {
    widget.controller.startTimer(_picked, label: _label.text.trim());
    setState(() => _picking = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final current = c.currentTimer;
    final list = c.hasTimerList;
    return Row(
      children: [
        if (list)
          SizedBox(
            width: ClockMetrics.timerSidebar,
            child: _TimerList(
              controller: c,
              onSelect: (i) => setState(() {
                c.selectedTimer = i;
                _picking = false;
              }),
            ),
          ),
        Expanded(
          child: current == null || _picking
              ? _Picker(
                  duration: _picked,
                  label: _label,
                  onChanged: (d) => setState(() => _picked = d),
                  onStart: _start,
                  onCancel: current == null
                      ? null
                      : () => setState(() => _picking = false),
                )
              : _Running(key: ValueKey(current), controller: c, timer: current),
        ),
      ],
    );
  }
}

/// The picker: `hh:mm:ss` in light thin digits; click a part, then type or use the arrows
/// (the scroll wheel changes the part under the pointer).
class _Picker extends StatefulWidget {
  const _Picker({
    required this.duration,
    required this.label,
    required this.onChanged,
    required this.onStart,
    this.onCancel,
  });

  final Duration duration;
  final TextEditingController label;
  final ValueChanged<Duration> onChanged;
  final VoidCallback onStart;
  final VoidCallback? onCancel;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final FocusNode _focus = FocusNode();
  int _part = 1;
  String _typed = '';

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<int> get _parts => [
    widget.duration.inHours.clamp(0, 99),
    widget.duration.inMinutes % 60,
    widget.duration.inSeconds % 60,
  ];

  void _set(int part, int value) {
    final p = [..._parts];
    p[part] = value.clamp(0, part == 0 ? 99 : 59);
    widget.onChanged(Duration(hours: p[0], minutes: p[1], seconds: p[2]));
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final value = _parts[_part];
    if (key == LogicalKeyboardKey.arrowUp) {
      _set(_part, value + 1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _set(_part, value - 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() => _part = (_part + 2) % 3);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.tab) {
      setState(() => _part = (_part + 1) % 3);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (widget.duration > Duration.zero) widget.onStart();
    } else if (event.character case final ch?
        when RegExp('[0-9]').hasMatch(ch)) {
      _typed = (_typed + ch).length > 2 ? ch : _typed + ch;
      _set(_part, int.parse(_typed));
      if (_typed.length == 2 && _part < 2) {
        setState(() {
          _part++;
          _typed = '';
        });
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final units = [l.unitHours, l.unitMinutes, l.unitSeconds];
    final parts = _parts;
    Widget part(int i) => Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          _set(i, parts[i] + (e.scrollDelta.dy < 0 ? 1 : -1));
        }
      },
      child: GestureDetector(
        key: ValueKey('picker part $i'),
        onTap: () {
          _focus.requestFocus();
          setState(() {
            _part = i;
            _typed = '';
          });
        },
        child: Column(
          children: [
            Text(
              units[i],
              style: clockText(13, color: ClockColors.pickerUnits),
            ),
            const SizedBox(height: 4),
            Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: _focus.hasFocus && _part == i
                    ? const Color(0x33FF9230)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                parts[i].toString().padLeft(2, '0'),
                style: thinDigits(
                  timerDigitSize,
                  color: ClockColors.pickerDigits,
                ).copyWith(letterSpacing: -2.2),
              ),
            ),
          ],
        ),
      ),
    );
    final colon = Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        ':',
        style: thinDigits(
          timerDigitSize,
          color: ClockColors.pickerDigits,
        ).copyWith(letterSpacing: -2.2),
      ),
    );
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _key,
      onFocusChange: (_) => setState(() {}),
      child: Column(
        children: [
          const Spacer(flex: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [part(0), colon, part(1), colon, part(2)],
          ),
          const SizedBox(height: 28),
          ClockTextField(
            key: const ValueKey('timer label'),
            controller: widget.label,
            placeholder: l.timerLabel,
            width: 200,
          ),
          const SizedBox(height: 10),
          Container(
            width: 200,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ClockColors.button,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(l.defaultSound, style: clockText(13)),
          ),
          const Spacer(flex: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CapsuleButton(
                key: const ValueKey('timer cancel'),
                label: l.cancel,
                color: ClockColors.button,
                onPressed: widget.onCancel,
              ),
              const SizedBox(width: ClockMetrics.capsuleGap),
              CapsuleButton(
                key: const ValueKey('timer start'),
                label: l.start,
                color: WindowActive.of(context)
                    ? ClockColors.green
                    : ClockColors.dimmed,
                onPressed: widget.duration > Duration.zero
                    ? widget.onStart
                    : null,
              ),
            ],
          ),
          const SizedBox(height: ClockMetrics.buttonsBottom),
        ],
      ),
    );
  }
}

/// A running or paused timer in the main area.
class _Running extends StatelessWidget {
  const _Running({super.key, required this.controller, required this.timer});
  final ClockController controller;
  final RunningTimer timer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = timer.timer;
    final now = controller.now();
    final end = now.add(t.remaining);
    return Column(
      children: [
        const Spacer(),
        SizedBox.square(
          dimension: ClockMetrics.ring,
          child: CustomPaint(
            key: const ValueKey('timer ring'),
            painter: RingPainter(fraction: t.fraction),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClockSymbol(
                        'bell-fill',
                        size: 13,
                        color: t.running
                            ? ClockColors.secondary
                            : ClockColors.dimmed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.endsAt(formatTime(context, end.hour, end.minute)),
                        style: clockText(
                          15,
                          color: t.running
                              ? ClockColors.secondary
                              : ClockColors.dimmed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCountdown(t.remaining),
                    key: const ValueKey('remaining'),
                    style: thinDigits(
                      t.remaining.inHours > 0
                          ? timerDigitSize * 0.72
                          : timerDigitSize,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.label.isEmpty ? l.timerLabel : t.label,
                    style: clockText(15, color: ClockColors.secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CapsuleButton(
              key: const ValueKey('timer cancel'),
              label: l.cancel,
              color: ClockColors.button,
              onPressed: () => controller.cancelTimer(timer),
            ),
            const SizedBox(width: ClockMetrics.capsuleGap),
            CapsuleButton(
              key: const ValueKey('timer pause'),
              label: t.running ? l.pause : l.resume,
              color: t.running ? ClockColors.orange : ClockColors.green,
              onPressed: () => controller.pauseResume(timer),
            ),
          ],
        ),
        const SizedBox(height: ClockMetrics.buttonsBottom),
      ],
    );
  }
}

/// The ring: the track, and the time left as an arc from the top, shrinking clockwise.
class RingPainter extends CustomPainter {
  RingPainter({
    required this.fraction,
    this.stroke = ClockMetrics.ringStroke,
    this.color = ClockColors.orange,
  });

  final double fraction;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawOval(
      rect,
      Paint()
        ..color = ClockColors.ringTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    // What is left runs from the top clockwise; the spent part opens at the top.
    canvas.drawArc(
      rect,
      -math.pi / 2 + (2 * math.pi - sweep),
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// The list on the left: running timers as cards, then the recent ones.
class _TimerList extends StatelessWidget {
  const _TimerList({required this.controller, required this.onSelect});
  final ClockController controller;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 60, 10, 20),
      children: [
        for (var i = 0; i < c.timers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              key: ValueKey('timer card $i'),
              onTap: () => onSelect(i),
              child: Container(
                width: ClockMetrics.timerCardSize.width,
                height: ClockMetrics.timerCardSize.height,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: ClockColors.timerCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCountdown(c.timers[i].timer.remaining),
                            style: thinDigits(36),
                          ),
                          Text(
                            c.timers[i].timer.label.isEmpty
                                ? _durationText(l, c.timers[i].timer.duration)
                                : c.timers[i].timer.label,
                            style: clockText(13, color: ClockColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox.square(
                      dimension: 40,
                      child: CustomPaint(
                        painter: RingPainter(
                          fraction: c.timers[i].timer.fraction,
                          stroke: 3,
                        ),
                        child: Center(
                          child: RoundButton(
                            key: ValueKey('timer card pause $i'),
                            symbol: c.timers[i].timer.running
                                ? 'pause'
                                : 'play',
                            size: 30,
                            fill: const Color(0x00000000),
                            color: ClockColors.orange,
                            onPressed: () => c.pauseResume(c.timers[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (c.settings.recents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Text(
              l.recents,
              style: clockText(13, weight: FontWeight.w600),
            ),
          ),
          for (final r in c.settings.recents)
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ClockColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatCountdown(r.duration),
                          style: thinDigits(28, color: ClockColors.secondary),
                        ),
                        Text(
                          r.label.isEmpty
                              ? _durationText(l, r.duration)
                              : r.label,
                          style: clockText(12, color: ClockColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  RoundButton(
                    key: ValueKey('recent ${r.duration.inSeconds} ${r.label}'),
                    symbol: 'play',
                    size: 30,
                    fill: const Color(0x3330D159),
                    color: ClockColors.green,
                    onPressed: () => c.startTimer(r.duration, label: r.label),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// "15 min", "1 hour", "1 hour 30 min".
String _durationText(AppLocalizations l, Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return l.minutes(m == 0 ? 1 : m);
  return m == 0 ? l.hours(h) : '${l.hours(h)} ${l.minutes(m)}';
}
