// Controls of the app that the kit draws with an app colour and silica_ui does not offer
// with one (the capsule buttons, the round play/pause buttons, the switch) and the sheet
// over the window. Everything else (fields, pop-ups, the checkbox, the toolbar) is
// silica_ui's.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'style.dart';

/// The pressed fill of a capsule (CL-02): green, red and gray as measured; other colours
/// (orange) lighten the same way (*provisional*, not measured).
Color pressedFill(Color color) {
  if (color == clockPalette.start) return const Color(0xFF4CD669);
  if (color == clockPalette.stop) return const Color(0xFFFF5858);
  if (color == clockPalette.lapButton) return const Color(0xFF434343);
  return Color.lerp(color, const Color(0xFFFFFFFF), 0.1)!;
}

/// A capsule push button of the kit with an app fill (`Buttons/Push/Primary` with a colour
/// override: Start, Stop, Pause, Save; `Buttons/Push/Secondary` with `App/Clock/Lap Button`:
/// Lap, Cancel): [AmalfiPushButton] cannot take a colour (silica-ui gap, reported).
///
/// 28 tall, [width] wide at least (72 or 68, grows with a long label, on the 4 pt grid),
/// Body Emphasis label. Pressed, the whole capsule takes the pressed fill at once and the
/// action fires on release (CL-02). Disabled: the whole button at 35 %.
class ClockButton extends StatelessWidget {
  const ClockButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fill,
    this.width = ClockMetrics.buttonNarrow,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The fill (`App/Clock/Start`, `Stop`, `Accent`); null: the secondary look (`Lap Button`
  /// with a border and the control shadow).
  final Color? fill;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final secondary = fill == null;
    final base = fill ?? clockPalette.lapButton;
    final content = secondary ? colors.textPrimary : colors.textOnAccent;
    const height = ClockMetrics.buttonHeight;
    return AmalfiInteraction(
      onActivate: onPressed,
      activators: AmalfiInteraction.buttonActivates,
      builder: (context, state) {
        final color = state.pressed ? pressedFill(base) : base;
        final shape = AmalfiSmoothBorder(
          radius: height / 2,
          side: secondary
              ? BorderSide(
                  color: colors.lineBorder,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : BorderSide.none,
        );
        return Opacity(
          opacity: state.enabled ? 1 : AmalfiStates.disabledOpacity,
          child: Semantics(
            button: true,
            enabled: state.enabled,
            label: label,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: width),
                  child: DecoratedBox(
                    decoration: AmalfiShapeDecoration(
                      color: color,
                      shape: shape,
                      shadows: secondary ? amalfiControlShadows(colors) : null,
                    ),
                    child: Stack(
                      children: [
                        if (state.hovered && !state.pressed)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: colors.stateHoverOverlay,
                                shape: shape,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: height,
                          child: Center(
                            widthFactor: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                style: AmalfiType.bodyEmphasis(color: content),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.focused)
                  Positioned.fill(child: AmalfiFocusHalo(radius: height / 2)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A glyph of silica-icons with a drawn fallback (the play and pause shapes) while the icons
/// are not installed.
class ClockGlyph extends StatelessWidget {
  const ClockGlyph(this.name, {super.key, required this.size, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => AmalfiSymbol(
    name,
    size: size,
    color: color,
    fallback: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _FallbackGlyph(
          name,
          color ?? IconTheme.of(context).color ?? const Color(0xFFFFFFFF),
        ),
      ),
    ),
  );
}

class _FallbackGlyph extends CustomPainter {
  _FallbackGlyph(this.name, this.color);
  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width, h = size.height;
    switch (name) {
      case 'play':
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.28, h * 0.18)
            ..lineTo(w * 0.8, h * 0.5)
            ..lineTo(w * 0.28, h * 0.82)
            ..close(),
          paint,
        );
      case 'pause':
        canvas
          ..drawRRect(
            RRect.fromLTRBR(
              w * 0.26,
              h * 0.2,
              w * 0.44,
              h * 0.8,
              Radius.circular(w * 0.04),
            ),
            paint,
          )
          ..drawRRect(
            RRect.fromLTRBR(
              w * 0.56,
              h * 0.2,
              w * 0.74,
              h * 0.8,
              Radius.circular(w * 0.04),
            ),
            paint,
          );
    }
  }

  @override
  bool shouldRepaint(_FallbackGlyph old) =>
      old.name != name || old.color != color;
}

/// A round icon button of the kit (`Buttons/Icon/Round`) with an app fill: the play and
/// pause of the timer list. [size] 28 (Regular) or 32 (Large); the glyph is 16, dark on the
/// colour.
class ClockRoundButton extends StatelessWidget {
  const ClockRoundButton({
    super.key,
    required this.symbol,
    required this.semanticLabel,
    required this.fill,
    required this.onPressed,
    this.size = 28,
  });

  final String symbol;
  final String semanticLabel;
  final Color fill;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return AmalfiInteraction(
      onActivate: onPressed,
      activators: AmalfiInteraction.buttonActivates,
      builder: (context, state) {
        final shape = AmalfiSmoothBorder(radius: size / 2);
        return Opacity(
          opacity: state.enabled ? 1 : AmalfiStates.disabledOpacity,
          child: Semantics(
            button: true,
            enabled: state.enabled,
            label: semanticLabel,
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: AmalfiShapeDecoration(
                        color: state.pressed ? pressedFill(fill) : fill,
                        shape: shape,
                      ),
                    ),
                  ),
                  if (state.hovered && !state.pressed)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: colors.stateHoverOverlay,
                          shape: shape,
                        ),
                      ),
                    ),
                  Center(
                    child: ClockGlyph(
                      symbol,
                      size: AmalfiControlSize.regular.iconSize,
                      color: colors.surfaceSunken,
                    ),
                  ),
                  if (state.focused)
                    Positioned.fill(child: AmalfiFocusHalo(radius: size / 2)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The alarm switch: the kit's `Toggles/Switch/Regular` (40 × 24 track, 20 pt thumb 2 pt
/// inside it) with `App/Clock/Switch On` as the on colour. The thumb slides in 180 ms
/// (CL-09); `silica_ui`'s switch cannot take an app colour (reported).
class ClockSwitch extends StatelessWidget {
  const ClockSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  static const Size size = Size(40, 24);
  static const double thumb = 20;
  static const double inset = 2;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return AmalfiInteraction(
      onActivate: () => onChanged(!value),
      builder: (context, state) => Semantics(
        toggled: value,
        label: semanticLabel,
        child: SizedBox.fromSize(
          size: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: AmalfiShapeDecoration(
                    color: value ? clockPalette.switchOn : colors.surfaceSunken,
                    shape: AmalfiSmoothBorder(
                      radius: size.height / 2,
                      side: value
                          ? BorderSide.none
                          : BorderSide(
                              color: colors.lineBorder,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                left: value ? size.width - inset - thumb : inset,
                top: inset,
                width: thumb,
                height: thumb,
                child: DecoratedBox(
                  decoration: AmalfiShapeDecoration(
                    color: colors.textOnAccent,
                    shape: AmalfiSmoothBorder(radius: thumb / 2),
                    shadows: amalfiControlShadows(colors),
                  ),
                ),
              ),
              if (state.focused)
                Positioned.fill(
                  child: AmalfiFocusHalo(radius: size.height / 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet centred over the window (kit `Alarm Editor`): the window behind dimmed with
/// `Surface/Sunken` at 60 %, the sheet `App/Clock/Sheet` with a 1 pt border, radius 20 and a
/// 0 / 12 / 32 shadow.
class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    required this.size,
    required this.child,
    required this.onDismiss,
  });

  final Size size;
  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('scrim'),
            onTap: onDismiss,
            child: ColoredBox(
              color: colors.surfaceSunken.withValues(alpha: 0.6),
            ),
          ),
        ),
        Center(
          child: SizedBox.fromSize(
            size: size,
            child: DecoratedBox(
              decoration: AmalfiShapeDecoration(
                color: clockPalette.sheet,
                shape: AmalfiSmoothBorder(
                  radius: AmalfiRadii.sheetAlert,
                  side: BorderSide(
                    color: colors.lineBorder,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
