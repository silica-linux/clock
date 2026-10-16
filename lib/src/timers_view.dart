// The Timers section (kit `Apps/Clock/Timer Picker`, `Timer Running`, CL-01). At rest: a
// picker with three parts (hours, minutes, seconds) as Numeral 72 digits with their units above,
// a label, the sound and Cancel / Start. Running: a 320 pt list on the left (the timers as
// 300 × 92 cards with a round pause button, then the recent timers with a green play button),
// and in the main area a 360 pt ring, stroke 6, orange on `Ring Track`, shrinking from the top,
// with the end time, the remaining time, the label, the sound and Cancel / Pause.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'model/timers.dart';
import 'style.dart';
import 'widgets.dart';
import 'world_view.dart' show formatTime;

/// `hh:mm:ss`, always with the hours: the kit's timer digits.
String timerDigits(Duration d) => formatCountdown(d, alwaysHours: true);

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
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(TimersView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  /// The ticker runs only while a timer does: at rest the app asks for no frames (#202).
  void _sync() {
    final running = widget.controller.timers.any((t) => t.timer.running);
    if (running && !_ticker.isActive) _ticker.start();
    if (!running && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
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
    final colors = AmalfiTheme.of(context).colors;
    // The list is 320 wide with a 1 pt separator on its edge; the main area is the rest of
    // the window, so the ring centres at 320 + (width - 320) / 2 (672 at 1024).
    return Stack(
      children: [
        Positioned.fill(
          left: list ? ClockMetrics.timerSidebar : 0,
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
        if (list) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: ClockMetrics.timerSidebar,
            child: ColoredBox(
              color: colors.surfaceSidebar,
              child: _TimerList(
                controller: c,
                onSelect: (i) => setState(() {
                  c.selectedTimer = i;
                  _picking = false;
                }),
              ),
            ),
          ),
          Positioned(
            left: ClockMetrics.timerSidebar,
            top: 0,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: colors.lineSeparator),
          ),
        ],
      ],
    );
  }
}

/// The picker: `hh:mm:ss` in Numeral 72 digits with their units above; click a part, then type
/// or use the arrows (the scroll wheel changes the part under the pointer).
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

  /// The kit's block: units at 124 (in the section), the digits' centre at 171, the label field
  /// at 288, the sound at 328 and the buttons at 412; it ends at 440 of the 748 pt section.
  static const double _unitsTop = 0;
  static const double _digitsTop = 11;
  static const double _fieldTop = 164;
  static const double _soundTop = 204;
  static const double _buttonsTop = 288;
  static const double _blockHeight = 316;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final units = [l.unitHours, l.unitMinutes, l.unitSeconds];
    final parts = _parts;
    final digits = numeral(72, color: colors.textPrimary, tabular: true);
    Widget part(int i) {
      final focused = _focus.hasFocus && _part == i;
      return Listener(
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
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _digitsTop),
                child: DecoratedBox(
                  decoration: AmalfiShapeDecoration(
                    color: focused
                        ? clockPalette.accent.withValues(alpha: 0.2)
                        : null,
                    shape: AmalfiSmoothBorder(radius: 8),
                  ),
                  child: Text(
                    parts[i].toString().padLeft(2, '0'),
                    style: digits,
                  ),
                ),
              ),
              Positioned(
                top: _unitsTop,
                left: 0,
                right: 0,
                height: 14,
                child: Text(
                  units[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AmalfiType.label(color: colors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final colon = Padding(
      padding: const EdgeInsets.only(top: _digitsTop),
      child: Text(':', style: digits),
    );
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _key,
      onFocusChange: (_) => setState(() {}),
      child: Column(
        children: [
          const Spacer(flex: 124),
          SizedBox(
            height: _blockHeight,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [part(0), colon, part(1), colon, part(2)],
                ),
                Positioned(
                  top: _fieldTop,
                  child: AmalfiTextField(
                    key: const ValueKey('timer label'),
                    controller: widget.label,
                    placeholder: l.timerLabel,
                    width: 200,
                  ),
                ),
                Positioned(
                  top: _soundTop,
                  child: AmalfiPopUpButton<int>(
                    key: const ValueKey('timer sound'),
                    // The only sound the app has: listed, so the control does what it
                    // says (more sounds: silica-os/clock issue).
                    items: [AmalfiPopUpItem(value: 0, label: l.defaultSound)],
                    value: 0,
                    onChanged: (_) {},
                    width: 200,
                    semanticLabel: l.sound,
                  ),
                ),
                Positioned(
                  top: _buttonsTop,
                  child: Row(
                    spacing: ClockMetrics.buttonsGap,
                    children: [
                      ClockButton(
                        key: const ValueKey('timer cancel'),
                        label: l.cancel,
                        width: ClockMetrics.buttonWide,
                        onPressed: widget.onCancel,
                      ),
                      ClockButton(
                        key: const ValueKey('timer start'),
                        label: l.start,
                        fill: WindowActiveScope.of(context)
                            ? clockPalette.start
                            : colors.textTertiary,
                        onPressed: widget.duration > Duration.zero
                            ? widget.onStart
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 308),
        ],
      ),
    );
  }
}

/// A running or paused timer in the main area (kit `Timer Running`): the ring, then the sound
/// and the buttons, as one 360 × 500 block that starts 96 pt below the toolbar.
class _Running extends StatelessWidget {
  const _Running({super.key, required this.controller, required this.timer});
  final ClockController controller;
  final RunningTimer timer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final t = timer.timer;
    final now = controller.now();
    final end = now.add(t.remaining);
    final minor = t.running ? colors.textSecondary : colors.textTertiary;
    const ring = ClockMetrics.ring;
    return Column(
      children: [
        const Spacer(flex: 96),
        SizedBox(
          width: ring,
          height: 500,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: ring,
                height: ring,
                child: CustomPaint(
                  key: const ValueKey('timer ring'),
                  painter: RingPainter(fraction: t.fraction),
                ),
              ),
              Positioned(
                left: ring / 2 - 8,
                top: 84,
                child: ClockGlyph('bell', size: 16, color: minor),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 108,
                height: 16,
                child: Text(
                  l.endsAt(formatTime(context, end.hour, end.minute)),
                  textAlign: TextAlign.center,
                  style: AmalfiType.callout(color: minor),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 165 - 64 / 2,
                height: 64,
                child: Center(
                  child: Text(
                    timerDigits(t.remaining),
                    key: const ValueKey('remaining'),
                    style: numeral(
                      64,
                      color: colors.textPrimary,
                      tabular: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 236,
                height: 16,
                child: Text(
                  t.label.isEmpty ? l.timerLabel : t.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmalfiType.callout(color: colors.textSecondary),
                ),
              ),
              Positioned(
                left: (ring - 200) / 2,
                top: 392,
                child: AmalfiPopUpButton<int>(
                  key: const ValueKey('timer running sound'),
                  items: [AmalfiPopUpItem(value: 0, label: l.defaultSound)],
                  value: 0,
                  onChanged: (_) {},
                  width: 200,
                  semanticLabel: l.sound,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 472,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: ClockMetrics.buttonsGap,
                  children: [
                    ClockButton(
                      key: const ValueKey('timer cancel'),
                      label: l.cancel,
                      width: ClockMetrics.buttonWide,
                      onPressed: () => controller.cancelTimer(timer),
                    ),
                    ClockButton(
                      key: const ValueKey('timer pause'),
                      label: t.running ? l.pause : l.resume,
                      width: ClockMetrics.buttonWide,
                      fill: t.running
                          ? clockPalette.accent
                          : clockPalette.start,
                      onPressed: () => controller.pauseResume(timer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 152),
      ],
    );
  }
}

/// The ring: the track, and the time left as an arc from the top, shrinking clockwise (kit
/// `Ring`: a 356 pt oval inside the 360 pt box, stroke 6, round cap).
class RingPainter extends CustomPainter {
  RingPainter({required this.fraction, this.stroke = ClockMetrics.ringStroke});

  final double fraction;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawOval(
      rect,
      Paint()
        ..color = clockPalette.ringTrack
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
        ..color = clockPalette.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.fraction != fraction || old.stroke != stroke;
}

/// The list on the left (kit `List region`): running timers as cards, then the recent ones.
class _TimerList extends StatelessWidget {
  const _TimerList({required this.controller, required this.onSelect});
  final ClockController controller;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final c = controller;
    final recents = c.settings.recents;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 16, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < c.timers.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == c.timers.length - 1 ? 0 : 8,
              ),
              child: GestureDetector(
                key: ValueKey('timer card $i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: SizedBox.fromSize(
                  size: ClockMetrics.timerCardSize,
                  child: DecoratedBox(
                    decoration: AmalfiShapeDecoration(
                      color: clockPalette.timerCard,
                      shape: AmalfiSmoothBorder(
                        radius: ClockMetrics.cardRadius,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 16,
                          top: 16,
                          right: 56,
                          height: 32,
                          child: Text(
                            timerDigits(c.timers[i].timer.remaining),
                            style: AmalfiType.title1(color: colors.textPrimary)
                                .copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 56,
                          right: 56,
                          height: 16,
                          child: Text(
                            c.timers[i].timer.label.isEmpty
                                ? _durationText(l, c.timers[i].timer.duration)
                                : c.timers[i].timer.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AmalfiType.callout(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          top: 28,
                          child: ClockRoundButton(
                            key: ValueKey('timer card pause $i'),
                            symbol: c.timers[i].timer.running
                                ? 'pause'
                                : 'play',
                            semanticLabel: c.timers[i].timer.running
                                ? l.pause
                                : l.resume,
                            size: 32,
                            fill: clockPalette.accent,
                            onPressed: () => c.pauseResume(c.timers[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (recents.isNotEmpty) ...[
            if (c.timers.isNotEmpty) const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                l.recents,
                style: AmalfiType.headline(color: colors.textTertiary),
              ),
            ),
            const SizedBox(height: 14),
            for (final r in recents)
              SizedBox(
                width: 288,
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 1,
                        child: ColoredBox(color: colors.lineSeparator),
                      ),
                      Positioned(
                        left: 0,
                        top: 8,
                        right: 36,
                        height: 22,
                        child: Text(
                          timerDigits(r.duration),
                          style: AmalfiType.title3(color: colors.textSecondary)
                              .copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 30,
                        right: 36,
                        height: 16,
                        child: Text(
                          r.label.isEmpty
                              ? _durationText(l, r.duration)
                              : r.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AmalfiType.callout(color: colors.textTertiary),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 8,
                        child: ClockRoundButton(
                          key: ValueKey(
                            'recent ${r.duration.inSeconds} ${r.label}',
                          ),
                          symbol: 'play',
                          semanticLabel: l.start,
                          fill: clockPalette.start,
                          onPressed: () =>
                              c.startTimer(r.duration, label: r.label),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// "15 min", "1 hour", "1 hour 30 min".
String _durationText(AppLocalizations l, Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return l.minutes(m == 0 ? 1 : m);
  return m == 0 ? l.hours(h) : '${l.hours(h)} ${l.minutes(m)}';
}
