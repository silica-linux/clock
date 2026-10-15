// The toolbar (CL-01): 52 pt, unified with the window (Ossido draws only the window buttons),
// with the 378 × 36 segmented control of the four sections and the round "+" on the right.
// The control is centered on the window, or on the area right of the timer list once that
// list exists; when it does not fit (the minimum width) it becomes a pop-up button.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'style.dart';
import 'widgets.dart';

/// The x where the window buttons end (traffic lights at +18, +41, +64, 16 pt each).
const double windowButtonsEnd = 80;

/// The section names, in the order of the control.
List<String> sectionNames(AppLocalizations l) => [
  l.sectionWorld,
  l.sectionAlarms,
  l.sectionStopwatch,
  l.sectionTimers,
];

class ClockToolbar extends StatelessWidget {
  const ClockToolbar({
    super.key,
    required this.section,
    required this.onSection,
    required this.centerOffset,
    this.onAdd,
  });

  final Section section;
  final ValueChanged<Section> onSection;

  /// Where the control is centered, from the left edge of the window.
  final double Function(double width) centerOffset;

  /// The "+" action; null: no button (stopwatch).
  final ValueChanged<Offset>? onAdd;

  @override
  Widget build(BuildContext context) => WindowDragArea(
    child: SizedBox(
      height: toolbarHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final controlWidth = ClockMetrics.controlWidth;
          final center = centerOffset(width);
          final left = center - controlWidth / 2 + ClockMetrics.controlShift;
          // The "+" ends 7 pt from the right edge (CL-01: centre at x 998 of 1024).
          const plusRight = 7.0;
          final plusLeft = width - plusRight - ClockMetrics.plusButton;
          final fits =
              left >= windowButtonsEnd + 8 &&
              left + controlWidth <= plusLeft - 8;
          final add = onAdd;
          return Stack(
            children: [
              if (fits)
                Positioned(
                  left: left,
                  top: (toolbarHeight - ClockMetrics.controlHeight) / 2,
                  child: SectionControl(section: section, onChanged: onSection),
                )
              else
                Positioned(
                  right:
                      plusRight +
                      (add == null ? 0 : ClockMetrics.plusButton + 10),
                  top: (toolbarHeight - 28) / 2,
                  child: SectionPopup(section: section, onChanged: onSection),
                ),
              if (add != null)
                Positioned(
                  right: plusRight,
                  top: (toolbarHeight - ClockMetrics.plusButton) / 2,
                  child: Builder(
                    builder: (context) => ToolbarCapsule(
                      key: const ValueKey('add'),
                      children: [
                        ToolbarSegment(
                          width: ClockMetrics.plusButton,
                          // Acts on press, like a button with a menu (CL-02).
                          onPress: () {
                            final box = context.findRenderObject();
                            if (box is! RenderBox) return;
                            add(
                              box.localToGlobal(
                                Offset(box.size.width, box.size.height + 4),
                              ),
                            );
                          },
                          icon: (color) =>
                              ClockSymbol('plus', size: 18, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// The segmented control of the four sections: silica_ui's large segmented control (glass lens
/// while pressed), 4 × 92.5 pt segments for the measured 378 pt.
class SectionControl extends StatelessWidget {
  const SectionControl({
    super.key,
    required this.section,
    required this.onChanged,
  });

  final Section section;
  final ValueChanged<Section> onChanged;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const ValueKey('section control'),
    child: SegmentedControl(
      size: ControlSize.large,
      segments: [
        for (final n in sectionNames(AppLocalizations.of(context)))
          Segment(label: n),
      ],
      selected: {section.index},
      onChanged: (i) => onChanged(Section.values[i]),
      segmentWidth: 92.5,
    ),
  );
}

/// The control at the minimum width: a pop-up button with the current section and ⌃⌄.
class SectionPopup extends StatefulWidget {
  const SectionPopup({
    super.key,
    required this.section,
    required this.onChanged,
  });
  final Section section;
  final ValueChanged<Section> onChanged;

  @override
  State<SectionPopup> createState() => _SectionPopupState();
}

class _SectionPopupState extends State<SectionPopup> {
  OverlayEntry? _menu;

  void _open() {
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context);
    if (box is! RenderBox || overlay == null) return;
    final names = sectionNames(AppLocalizations.of(context));
    final at = box.localToGlobal(Offset(0, box.size.height + 4));
    _menu = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: MenuHost(
          anchor: at,
          opaque: true,
          entries: [
            for (final s in Section.values)
              MenuAction(
                names[s.index],
                checked: s == widget.section,
                shortcut: '⌘${s.index + 1}',
                onSelected: () => widget.onChanged(s),
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
    final names = sectionNames(AppLocalizations.of(context));
    return GestureDetector(
      key: const ValueKey('section popup'),
      onTapDown: (_) => _open(),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ClockColors.track,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ClockColors.rimOuter),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              names[widget.section.index],
              style: clockText(13, weight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const ClockSymbol(
              'chevron-up-down',
              size: 12,
              color: ClockColors.text,
            ),
          ],
        ),
      ),
    );
  }
}
