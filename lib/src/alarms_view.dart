// The Alarms section (CL-01): an empty state (alarm symbol and a bold line, centered), the
// alarms as 186 × 181 cards on the world-clock grid with a switch (orange on, gray off: the
// whole card dims), and the 514 × 391 editor sheet.

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

class AlarmsView extends StatefulWidget {
  const AlarmsView({super.key, required this.controller});
  final ClockController controller;

  @override
  State<AlarmsView> createState() => AlarmsViewState();
}

class AlarmsViewState extends State<AlarmsView> {
  Alarm? _editing;
  OverlayEntry? _menu;

  /// Opens the editor for a new alarm at the current time.
  void addAlarm() {
    final now = widget.controller.now();
    setState(
      () => _editing = Alarm(
        id: widget.controller.settings.nextAlarmId(),
        hour: now.hour,
        minute: now.minute,
      ),
    );
  }

  void _openMenu(Alarm alarm, Offset at) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final l = AppLocalizations.of(context);
    _menu?.remove();
    _menu = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: MenuHost(
          anchor: at,
          opaque: true,
          entries: [
            MenuAction(
              l.toggleAlarm,
              onSelected: () => widget.controller.toggleAlarm(alarm),
            ),
            MenuAction(
              l.deleteAlarm,
              onSelected: () => widget.controller.deleteAlarm(alarm.id),
            ),
          ],
          onDismissed: () {
            _menu?.remove();
            _menu = null;
          },
        ),
      ),
    );
    overlay.insert(_menu!);
  }

  @override
  void dispose() {
    _menu?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final alarms = widget.controller.alarms;
    final editing = _editing;
    return Stack(
      children: [
        if (alarms.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ClockSymbol(
                  'alarm',
                  size: 44,
                  color: ClockColors.emptySymbol,
                ),
                const SizedBox(height: 10),
                Text(
                  l.noAlarms,
                  style: clockText(
                    22,
                    weight: FontWeight.w600,
                    color: ClockColors.emptyText,
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ClockMetrics.cardsLeft,
                toolbarHeight + 15,
                ClockMetrics.cardsLeft,
                20,
              ),
              child: Wrap(
                spacing: CardGrid.gap,
                runSpacing: CardGrid.gap,
                children: [
                  for (final alarm in alarms)
                    GestureDetector(
                      onTap: () => setState(() => _editing = alarm),
                      onSecondaryTapUp: (d) =>
                          _openMenu(alarm, d.globalPosition),
                      child: AlarmCard(
                        key: ValueKey('alarm ${alarm.id}'),
                        alarm: alarm,
                        width: CardGrid.of(box.maxWidth).cardWidth,
                        onToggle: () => widget.controller.toggleAlarm(alarm),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (editing != null)
          Positioned.fill(
            child: AlarmEditor(
              key: ValueKey('editor ${editing.id}'),
              alarm: editing,
              isNew: !alarms.any((a) => a.id == editing.id),
              onCancel: () => setState(() => _editing = null),
              onSave: (a) {
                widget.controller.saveAlarm(a);
                setState(() => _editing = null);
              },
              onDelete: () {
                widget.controller.deleteAlarm(editing.id);
                setState(() => _editing = null);
              },
            ),
          ),
      ],
    );
  }
}

/// An alarm card (CL-09): the time, the label, the repeat and the sound one under the other,
/// the switch below them; an alarm that is off turns all its texts gray.
class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    this.width = 186,
  });
  final double width;
  final Alarm alarm;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = alarm.enabled;
    final ink = on ? ClockColors.text : ClockColors.alarmMinor;
    const minor = ClockColors.alarmMinor;
    Widget line(double top, String text, TextStyle style) => Positioned(
      left: 24,
      right: 12,
      top: top,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
    return Container(
      width: width,
      height: ClockMetrics.alarmCard.height,
      decoration: BoxDecoration(
        color: ClockColors.card,
        borderRadius: BorderRadius.circular(ClockMetrics.cardRadius),
      ),
      child: Stack(
        children: [
          // Proportional figures: the time of a card does not change while it is shown.
          line(
            33,
            formatTime(context, alarm.hour, alarm.minute),
            thinDigits(
              40,
              color: ink,
              weight: 300,
            ).copyWith(fontFeatures: const []),
          ),
          line(
            72,
            alarm.label.isEmpty ? l.alarmDefaultLabel : alarm.label,
            clockText(13, weight: FontWeight.w500, color: ink),
          ),
          line(
            90,
            l.repeatSummary(repeatText(l, alarm.repeat)),
            clockText(12, color: minor),
          ),
          line(
            107,
            l.soundSummary(l.defaultSound),
            clockText(12, color: minor),
          ),
          Positioned(
            left: 31,
            top: 130,
            child: ClockSwitch(
              key: ValueKey('switch ${alarm.id}'),
              value: on,
              onChanged: (_) => onToggle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The editor sheet (514 × 391, `#272727`): the time with hour and minute parts (the focused
/// part filled orange, arrows and digits change it), seven round day toggles, the label, the
/// sound, snooze and its length, Cancel and Save.
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

  Widget _row(String title, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: clockText(13, color: ClockColors.secondary),
          ),
        ),
        const SizedBox(width: 12),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final letters = l.weekdayLetters.characters.toList();
    return Sheet(
      size: const Size(514, 391),
      onDismiss: widget.onCancel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isNew ? l.newAlarm : l.editAlarm,
              textAlign: TextAlign.center,
              style: clockText(13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Center(
              child: TimeField(
                hour: _hour,
                minute: _minute,
                onChanged: (h, m) => setState(() {
                  _hour = h;
                  _minute = m;
                }),
              ),
            ),
            const SizedBox(height: 14),
            _row(
              l.repeat,
              Row(
                children: [
                  for (var d = 1; d <= 7; d++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        key: ValueKey('day $d'),
                        onTap: () => setState(
                          () => _repeat.contains(d)
                              ? _repeat.remove(d)
                              : _repeat.add(d),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _repeat.contains(d)
                                ? ClockColors.orange
                                : ClockColors.button,
                          ),
                          child: Text(
                            d - 1 < letters.length ? letters[d - 1] : '',
                            style: clockText(13, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _row(
              l.label,
              ClockTextField(
                key: const ValueKey('alarm label'),
                controller: _label,
                placeholder: l.alarmDefaultLabel,
                onSubmitted: (_) => _save(),
              ),
            ),
            _row(
              l.sound,
              Container(
                width: 224,
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: ClockColors.button,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(l.defaultSound, style: clockText(13)),
              ),
            ),
            _row(
              l.snooze,
              GestureDetector(
                key: const ValueKey('snooze'),
                onTap: () => setState(() => _snooze = !_snooze),
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _snooze ? ClockColors.orange : ClockColors.button,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _snooze
                      ? Text('✓', style: clockText(11, weight: FontWeight.w600))
                      : null,
                ),
              ),
            ),
            _row(
              l.snoozeLength,
              SnoozeLengthButton(
                minutes: _snoozeMinutes,
                enabled: _snooze,
                onChanged: (m) => setState(() => _snoozeMinutes = m),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (!widget.isNew)
                  CapsuleButton(
                    key: const ValueKey('delete alarm'),
                    label: l.delete,
                    color: ClockColors.button,
                    width: 71,
                    height: 26,
                    onPressed: widget.onDelete,
                  ),
                const Spacer(),
                CapsuleButton(
                  key: const ValueKey('cancel'),
                  label: l.cancel,
                  color: ClockColors.button,
                  width: 71,
                  height: 26,
                  onPressed: widget.onCancel,
                ),
                const SizedBox(width: 10),
                CapsuleButton(
                  key: const ValueKey('save'),
                  label: l.save,
                  color: ClockColors.orange,
                  width: 71,
                  height: 26,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A time field with an hour and a minute part: click a part to focus it (orange), then type
/// digits or use the arrow keys; Tab moves to the other part.
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
    Widget part(int index, int value) => GestureDetector(
      key: ValueKey(index == 0 ? 'hour part' : 'minute part'),
      onTap: () {
        _focus.requestFocus();
        setState(() {
          _part = index;
          _typed = '';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _focus.hasFocus && _part == index
              ? const Color(0xFFC87524)
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(value.toString().padLeft(2, '0'), style: thinDigits(40)),
      ),
    );
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _key,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          part(0, widget.hour),
          Text(':', style: thinDigits(40)),
          part(1, widget.minute),
        ],
      ),
    );
  }
}

/// The snooze length: a pop-up button with 1 to 15 minutes, the current one checked.
class SnoozeLengthButton extends StatefulWidget {
  const SnoozeLengthButton({
    super.key,
    required this.minutes,
    required this.enabled,
    required this.onChanged,
  });

  final int minutes;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  State<SnoozeLengthButton> createState() => _SnoozeLengthButtonState();
}

class _SnoozeLengthButtonState extends State<SnoozeLengthButton> {
  OverlayEntry? _menu;

  void _open() {
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context);
    if (box is! RenderBox || overlay == null) return;
    final l = AppLocalizations.of(context);
    final at = box.localToGlobal(Offset(0, box.size.height + 4));
    _menu = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: MenuHost(
          anchor: at,
          opaque: true,
          entries: [
            for (var m = 1; m <= 15; m++)
              MenuAction(
                l.minutes(m),
                checked: m == widget.minutes,
                onSelected: () => widget.onChanged(m),
              ),
          ],
          onDismissed: _close,
        ),
      ),
    );
    overlay.insert(_menu!);
  }

  void _close() {
    _menu?.remove();
    _menu = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = widget.enabled ? ClockColors.text : ClockColors.dimmed;
    return GestureDetector(
      key: const ValueKey('snooze length'),
      onTap: widget.enabled ? _open : null,
      child: Container(
        width: 120,
        height: 24,
        padding: const EdgeInsets.only(left: 8, right: 6),
        decoration: BoxDecoration(
          color: ClockColors.button,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.minutes(widget.minutes),
                style: clockText(13, color: color),
              ),
            ),
            Text('⌄', style: clockText(12, color: color)),
          ],
        ),
      ),
    );
  }
}
