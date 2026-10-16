// The toolbar (kit `Apps/Clock/Toolbar`): 52 pt, unified with the window (Ossido draws only the
// window buttons, over the 96 pt `Controls` slot), the section control (`Segmented Text`
// piece, silica_ui's AmalfiSegmentedControl with its lens) centred between two spacers and the
// round "+" (`Add` piece) at the right.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'style.dart';

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
    this.onAdd,
  });

  final Section section;
  final ValueChanged<Section> onSection;

  /// The "+" action, given the point under the button where a menu opens; null: no button
  /// (stopwatch: nothing to add).
  final ValueChanged<Offset>? onAdd;

  @override
  Widget build(BuildContext context) {
    final add = onAdd;
    return WindowDragArea(
      child: AmalfiToolbar(
        padding: const EdgeInsets.only(
          left: ClockMetrics.toolbarLeading,
          right: ClockMetrics.toolbarTrailing,
        ),
        surface: AmalfiToolbarSurface.none,
        children: [
          // Ossido draws the window buttons here.
          const SizedBox(width: ClockMetrics.controlsPiece),
          const AmalfiSpacerPiece(),
          AmalfiToolbarPiece(
            child: SectionControl(section: section, onChanged: onSection),
          ),
          const AmalfiSpacerPiece(),
          if (add != null)
            AmalfiToolbarPiece.add(
              child: Builder(
                builder: (context) => AmalfiToolbarButton(
                  key: const ValueKey('add'),
                  icon: const AmalfiGlyph(AmalfiGlyphs.plus),
                  semanticLabel: AppLocalizations.of(context).add,
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
            )
          else
            // The stopwatch has nothing to add: the slot stays so that the section control
            // does not move.
            const SizedBox(width: ClockMetrics.addPiece),
        ],
      ),
    );
  }
}

/// The segmented control of the four sections (kit `Segments/Control/One 4 Text/Large`):
/// silica_ui's, with the glass lens while pressed.
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
    child: AmalfiSegmentedControl(
      size: AmalfiControlSize.large,
      segments: [
        for (final n in sectionNames(AppLocalizations.of(context)))
          AmalfiSegment.text(n),
      ],
      selected: {section.index},
      onChanged: (s) {
        if (s.isNotEmpty) onChanged(Section.values[s.first]);
      },
    ),
  );
}
