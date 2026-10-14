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
          final left = center - controlWidth / 2;
          // The "+" ends 8 pt from the right edge (CL-01: centre at x 998 of 1024).
          const plusRight = 8.0;
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
                    builder: (context) => RoundButton(
                      key: const ValueKey('add'),
                      symbol: 'plus',
                      onPressed: () {
                        final box = context.findRenderObject();
                        if (box is! RenderBox) return;
                        add(
                          box.localToGlobal(
                            Offset(box.size.width, box.size.height + 4),
                          ),
                        );
                      },
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

/// The segmented control: a 378 × 36 capsule with a 28 pt pill that slides in ~300 ms to the
/// chosen section; the content changes on release, in one frame.
class SectionControl extends StatefulWidget {
  const SectionControl({
    super.key,
    required this.section,
    required this.onChanged,
  });

  final Section section;
  final ValueChanged<Section> onChanged;

  @override
  State<SectionControl> createState() => _SectionControlState();
}

class _SectionControlState extends State<SectionControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: ClockMetrics.pillSlide,
  );
  late double _from = _left(widget.section.index);
  late double _to = _from;
  int? _hover;

  static double _left(int index) {
    var x = 0.0;
    for (var i = 0; i < index; i++) {
      x += ClockMetrics.segmentWidths[i];
    }
    return x;
  }

  double get _pill =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_slide.value);

  @override
  void didUpdateWidget(SectionControl old) {
    super.didUpdateWidget(old);
    if (old.section != widget.section) {
      _from = _pill;
      _to = _left(widget.section.index);
      _slide.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = sectionNames(AppLocalizations.of(context));
    final active = WindowActive.of(context);
    const h = ClockMetrics.controlHeight;
    const inset = (h - ClockMetrics.pillHeight) / 2;
    // The rim (1 + 0.5 pt per side) leaves 375 pt for the 378 pt of measured segments.
    final k = (ClockMetrics.controlWidth - 3) / ClockMetrics.controlWidth;
    return Container(
      key: const ValueKey('section control'),
      width: ClockMetrics.controlWidth,
      height: h,
      // The rim: a dark outer line, then a light top and a darker bottom.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: ClockColors.rimOuter),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h / 2 - 1),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ClockColors.rimTop, ClockColors.rimBottom],
          ),
        ),
        padding: const EdgeInsets.all(0.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ClockColors.track,
            borderRadius: BorderRadius.circular(h / 2 - 1.5),
          ),
          child: AnimatedBuilder(
            animation: _slide,
            builder: (context, _) {
              final index = widget.section.index;
              return Stack(
                children: [
                  if (_hover != null && _hover != index)
                    Positioned(
                      left: _left(_hover!) * k + inset,
                      top: inset - 1,
                      width:
                          ClockMetrics.segmentWidths[_hover!] * k - 2 * inset,
                      height: ClockMetrics.pillHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: ClockColors.hover,
                          borderRadius: BorderRadius.circular(
                            ClockMetrics.pillHeight / 2,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    key: const ValueKey('pill'),
                    left: _pill * k + inset,
                    top: inset - 1,
                    width: ClockMetrics.segmentWidths[index] * k - 2 * inset,
                    height: ClockMetrics.pillHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          ClockMetrics.pillHeight / 2,
                        ),
                        gradient: active
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  ClockColors.pillTop,
                                  ClockColors.pillBottom,
                                ],
                              )
                            : null,
                        color: active ? null : ClockColors.pillInactive,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < names.length; i++)
                        MouseRegion(
                          onEnter: (_) => setState(() => _hover = i),
                          onExit: (_) => setState(() {
                            if (_hover == i) _hover = null;
                          }),
                          child: GestureDetector(
                            key: ValueKey('section ${Section.values[i].name}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(Section.values[i]),
                            child: SizedBox(
                              width: ClockMetrics.segmentWidths[i] * k,
                              height: h - 3,
                              child: Center(
                                child: Text(
                                  names[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: clockText(
                                    13,
                                    weight: FontWeight.w600,
                                    color: active
                                        ? ClockColors.text
                                        : ClockColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
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
