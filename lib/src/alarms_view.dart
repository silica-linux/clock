// The Alarms section (kit `Apps/Clock/Alarms`, `Alarms Empty`, `Alarm Editor`): an empty state
// (alarm symbol and a Title 2 line, centred), the alarms as 184 × 180 cards on the world-clock
// grid with a switch (orange on, the whole card dims when off), and the 512 × 392 editor sheet
// over the window.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'model/alarms.dart';
import 'style.dart';
import 'widgets.dart';
import 'world_view.dart' show formatTime;

/// The repeat summary: never, every day, weekdays, weekends or the short day names.
String repeatText(AppLocalizations l, Set<int> days) {
  if (days.isEmpty) return l.repeatNever;
  if (days.length == 7) return l.repeatEveryDay;
  if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
    return l.repeatWeekdays;
  }
  if (days.length == 2 && days.contains(6) && days.contains(7)) {
    return l.repeatWeekends;
  }
  final names = l.weekdaysShort.split(',');
  return [
    for (var d = 1; d <= 7; d++)
      if (days.contains(d) && d - 1 < names.length) names[d - 1],
  ].join(', ');
}

class AlarmsView extends StatelessWidget {
  const AlarmsView({super.key, required this.controller, required this.onEdit});
  final ClockController controller;

  /// A card was tapped: open the editor for that alarm.
  final ValueChanged<Alarm> onEdit;

  void _openMenu(BuildContext context, Alarm alarm, Offset at) {
    final l = AppLocalizations.of(context);
    showAmalfiMenu(
      context: context,
      position: at,
      entries: [
        AmalfiMenuAction(
          l.toggleAlarm,
          onSelected: () => controller.toggleAlarm(alarm),
        ),
        AmalfiMenuAction(
          l.deleteAlarm,
          destructive: true,
          onSelected: () => controller.deleteAlarm(alarm.id),
        ),
      ],
    ).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final alarms = controller.alarms;
    if (alarms.isEmpty) {
      // The kit's block (32 pt symbol, 16 pt, Title 2) starts 300 pt below the toolbar.
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClockGlyph('alarm', size: 32, color: colors.textTertiary),
              const SizedBox(height: 16),
              Text(
                l.noAlarms,
                style: AmalfiType.title2(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.all(ClockMetrics.cardsMargin),
        // The grid starts at the left margin; a row with fewer cards than columns is not centred.
        child: Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: CardGrid.gap,
            runSpacing: CardGrid.gap,
            children: [
              for (final alarm in alarms)
                GestureDetector(
                  onTap: () => onEdit(alarm),
                  onSecondaryTapUp: (d) =>
                      _openMenu(context, alarm, d.globalPosition),
                  child: AlarmCard(
                    key: ValueKey('alarm ${alarm.id}'),
                    alarm: alarm,
                    width: CardGrid.of(box.maxWidth).cardWidth,
                    onToggle: () => controller.toggleAlarm(alarm),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An alarm card (kit `Alarm Card On|Off`): the time, the label, the repeat and the sound one
/// under the other, the switch at the bottom right; an alarm that is off turns all its texts
/// tertiary.
class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    this.width = 184,
  });
  final double width;
  final Alarm alarm;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final on = alarm.enabled;
    Widget line(double top, double height, String text, TextStyle style) =>
        Positioned(
          left: 16,
          right: 16,
          top: top,
          height: height,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
    return SizedBox(
      width: width,
      height: ClockMetrics.alarmCardHeight,
      child: DecoratedBox(
        decoration: AmalfiShapeDecoration(
          color: clockPalette.card,
          shape: AmalfiSmoothBorder(radius: ClockMetrics.cardRadius),
        ),
        child: Stack(
          children: [
            line(
              16,
              40,
              formatTime(context, alarm.hour, alarm.minute),
              numeral(40, color: on ? colors.textPrimary : colors.textTertiary),
            ),
            line(
              72,
              18,
              alarm.label.isEmpty ? l.alarmDefaultLabel : alarm.label,
              AmalfiType.body(
                color: on ? colors.textPrimary : colors.textTertiary,
              ),
            ),
            line(
              96,
              16,
              repeatText(l, alarm.repeat),
              AmalfiType.callout(
                color: on ? colors.textSecondary : colors.textTertiary,
              ),
            ),
            line(
              116,
              16,
              l.defaultSound,
              AmalfiType.callout(color: colors.textTertiary),
            ),
            Positioned(
              left: width - 16 - ClockSwitch.size.width,
              top: 136,
              child: ClockSwitch(
                key: ValueKey('switch ${alarm.id}'),
                value: on,
                semanticLabel: alarm.label.isEmpty
                    ? l.alarmDefaultLabel
                    : alarm.label,
                onChanged: (_) => onToggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The editor sheet (kit `Alarm Editor`, 512 × 392): the time with hour and minute fields (the
/// focused one filled with the accent, arrows and digits change it), seven round day toggles,
/// the label, the sound, snooze and its length, Cancel and Save. Every control sits at the
/// kit's frame.
class AlarmEditor extends StatefulWidget {
  const AlarmEditor({
    super.key,
    required this.alarm,
    required this.isNew,
    required this.onCancel,
    required this.onSave,
    required this.onDelete,
  });

  final Alarm alarm;
  final bool isNew;
  final VoidCallback onCancel;
  final ValueChanged<Alarm> onSave;
  final VoidCallback onDelete;

  static const Size size = Size(512, 392);

  @override
  State<AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<AlarmEditor> {
  late int _hour = widget.alarm.hour;
  late int _minute = widget.alarm.minute;
  late final Set<int> _repeat = {...widget.alarm.repeat};
  late bool _snooze = widget.alarm.snooze;
  late int _snoozeMinutes = widget.alarm.snoozeMinutes;
  late final TextEditingController _label = TextEditingController(
    text: widget.alarm.label,
  );

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _save() => widget.onSave(
    widget.alarm.copyWith(
      hour: _hour,
      minute: _minute,
      repeat: _repeat,
      label: _label.text.trim(),
      snooze: _snooze,
      snoozeMinutes: _snoozeMinutes,
      enabled: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final letters = l.weekdayLetters.characters.toList();
    Widget caption(double top, String text) => Positioned(
      left: 24,
      top: top,
      width: 96,
      height: 16,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AmalfiType.callout(color: colors.textSecondary),
      ),
    );
    return Sheet(
      size: AlarmEditor.size,
      onDismiss: widget.onCancel,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 20,
            right: 24,
            height: 22,
            child: Text(
              widget.isNew ? l.newAlarm : l.editAlarm,
              style: AmalfiType.title3(color: colors.textPrimary),
            ),
          ),
          Positioned(
            left: 168,
            top: 64,
            child: TimeField(
              hour: _hour,
              minute: _minute,
              onChanged: (h, m) => setState(() {
                _hour = h;
                _minute = m;
              }),
            ),
          ),
          caption(152, l.repeat),
          for (var d = 1; d <= 7; d++)
            Positioned(
              left: 132 + (d - 1) * 40.0,
              top: 144,
              child: _DayToggle(
                key: ValueKey('day $d'),
                letter: d - 1 < letters.length ? letters[d - 1] : '',
                on: _repeat.contains(d),
                onTap: () => setState(
                  () =>
                      _repeat.contains(d) ? _repeat.remove(d) : _repeat.add(d),
                ),
              ),
            ),
          caption(196, l.label),
          Positioned(
            left: 132,
            top: 192,
            child: AmalfiTextField(
              key: const ValueKey('alarm label'),
              controller: _label,
              placeholder: l.alarmDefaultLabel,
              width: 224,
              onSubmitted: (_) => _save(),
            ),
          ),
          caption(236, l.sound),
          Positioned(
            left: 132,
            top: 232,
            child: AmalfiPopUpButton<int>(
              key: const ValueKey('alarm sound'),
              // The only sound the app has (the freedesktop alarm sound): listed, so the
              // control does what it says; more sounds are tracked in silica-os/clock.
              items: [AmalfiPopUpItem(value: 0, label: l.defaultSound)],
              value: 0,
              onChanged: (_) {},
              width: 224,
              semanticLabel: l.sound,
            ),
          ),
          Positioned(
            left: 132,
            top: 272,
            child: AmalfiCheckbox(
              key: const ValueKey('snooze'),
              value: _snooze,
              label: l.snooze,
              onChanged: (v) => setState(() => _snooze = v),
            ),
          ),
          caption(308, l.snoozeLength),
          Positioned(
            left: 132,
            top: 304,
            child: AmalfiPopUpButton<int>(
              key: const ValueKey('snooze length'),
              items: [
                for (var m = 1; m <= 15; m++)
                  AmalfiPopUpItem(value: m, label: l.minutes(m)),
              ],
              value: _snoozeMinutes,
              onChanged: _snooze
                  ? (m) => setState(() => _snoozeMinutes = m)
                  : null,
              width: 108,
              semanticLabel: l.snoozeLength,
            ),
          ),
          if (!widget.isNew)
            Positioned(
              left: 24,
              top: 348,
              child: AmalfiPushButton(
                key: const ValueKey('delete alarm'),
                label: l.delete,
                variant: AmalfiPushButtonVariant.destructive,
                onPressed: widget.onDelete,
              ),
            ),
          Positioned(
            left: 352,
            top: 348,
            child: ClockButton(
              key: const ValueKey('cancel'),
              label: l.cancel,
              width: ClockMetrics.buttonWide,
              onPressed: widget.onCancel,
            ),
          ),
          Positioned(
            left: 432,
            top: 348,
            child: ClockButton(
              key: const ValueKey('save'),
              label: l.save,
              fill: clockPalette.accent,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

/// A round day toggle (kit `Day 1…7`): 32 pt, the accent with an `On Accent` letter when on,
/// `Surface/Sunken` with a secondary letter when off.
class _DayToggle extends StatelessWidget {
  const _DayToggle({
    super.key,
    required this.letter,
    required this.on,
    required this.onTap,
  });
  final String letter;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return AmalfiInteraction(
      onActivate: onTap,
      builder: (context, state) => Semantics(
        button: true,
        selected: on,
        label: letter,
        child: SizedBox.square(
          dimension: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: AmalfiShapeDecoration(
                    color: on ? clockPalette.accent : colors.surfaceSunken,
                    shape: AmalfiSmoothBorder(radius: 16),
                  ),
                ),
              ),
              if (state.hovered && !state.pressed)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colors.stateHoverOverlay,
                      shape: AmalfiSmoothBorder(radius: 16),
                    ),
                  ),
                ),
              Center(
                child: Text(
                  letter,
                  style: AmalfiType.label(
                    color: on ? colors.textOnAccent : colors.textSecondary,
                  ),
                ),
              ),
              if (state.focused)
                Positioned.fill(child: AmalfiFocusHalo(radius: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A time field with an hour and a minute part (kit `Hour field`, `Minute field`: 80 × 64,
/// radius 12, Display digits): click a part to focus it (accent fill), then type digits or
/// use the arrow keys; Tab moves to the other part.
class TimeField extends StatefulWidget {
  const TimeField({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  final FocusNode _focus = FocusNode();
  int _part = 0;
  String _typed = '';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _typed = ''));
    // The editor opens with the hour selected (kit `Hour field`), ready for the keyboard; an
    // `autofocus` would lose against the window's own focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _set(int value) {
    if (_part == 0) {
      widget.onChanged(value % 24, widget.minute);
    } else {
      widget.onChanged(widget.hour, value % 60);
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final current = _part == 0 ? widget.hour : widget.minute;
    final limit = _part == 0 ? 24 : 60;
    if (key == LogicalKeyboardKey.arrowUp) {
      _set((current + 1) % limit);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _set((current - 1 + limit) % limit);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.tab) {
      setState(() {
        _part = 1 - _part;
        _typed = '';
      });
    } else if (event.character case final c? when RegExp('[0-9]').hasMatch(c)) {
      _typed = (_typed + c).length > 2 ? c : _typed + c;
      final v = int.parse(_typed);
      _set(v < limit ? v : int.parse(c));
      if (_typed.length == 2 && _part == 0) {
        setState(() {
          _part = 1;
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
    final colors = AmalfiTheme.of(context).colors;
    Widget part(int index, int value) {
      final focused = _focus.hasFocus && _part == index;
      return GestureDetector(
        key: ValueKey(index == 0 ? 'hour part' : 'minute part'),
        onTap: () {
          _focus.requestFocus();
          setState(() {
            _part = index;
            _typed = '';
          });
        },
        child: SizedBox(
          width: 80,
          height: 64,
          child: DecoratedBox(
            decoration: AmalfiShapeDecoration(
              color: focused ? clockPalette.accent : colors.surfaceSunken,
              shape: AmalfiSmoothBorder(radius: 12),
            ),
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: AmalfiType.display(
                  color: focused ? colors.textOnAccent : colors.textPrimary,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
        ),
      );
    }

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _key,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          part(0, widget.hour),
          SizedBox(
            width: 20,
            child: Center(
              child: Text(
                ':',
                style: AmalfiType.display(color: colors.textPrimary),
              ),
            ),
          ),
          part(1, widget.minute),
        ],
      ),
    );
  }
}
