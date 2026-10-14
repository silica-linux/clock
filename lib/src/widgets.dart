// Controls shared by the sections: capsule buttons, the switch, a sheet over the window and the
// system symbols of silica-icons.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'style.dart';

/// Whether the window is the active one (from `flutter/lifecycle`), for the inactive colors.
class WindowActive extends InheritedWidget {
  const WindowActive({super.key, required this.active, required super.child});
  final bool active;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WindowActive>()?.active ??
      true;

  @override
  bool updateShouldNotify(WindowActive old) => old.active != active;
}

/// A symbol of silica-icons (`$SILICA_ICONS_DIR/symbols/regular/<name>.svg`) in `color`; empty
/// if the icons are not installed.
class ClockSymbol extends StatelessWidget {
  const ClockSymbol(
    this.name, {
    super.key,
    required this.size,
    required this.color,
  });
  final String name;
  final double size;
  final Color color;

  static String? directory = Platform.environment['SILICA_ICONS_DIR'];

  @override
  Widget build(BuildContext context) {
    final dir = directory;
    final file = dir == null ? null : File('$dir/symbols/regular/$name.svg');
    if (file == null || !file.existsSync()) {
      return SizedBox(width: size, height: size);
    }
    return SvgPicture.file(
      file,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// A 150 × 28 capsule button (CL-01): filled, white label, pressed slightly darker.
class CapsuleButton extends StatefulWidget {
  const CapsuleButton({
    super.key,
    required this.label,
    required this.color,
    this.onPressed,
    this.width = 150,
    this.height = 28,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  @override
  State<CapsuleButton> createState() => _CapsuleButtonState();
}

class _CapsuleButtonState extends State<CapsuleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fill = !enabled
        ? ClockColors.buttonDisabled
        : _pressed
        ? Color.lerp(widget.color, const Color(0xFF000000), 0.15)!
        : widget.color;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(widget.height / 2),
        ),
        child: Text(
          widget.label,
          style: clockText(
            13,
            weight: FontWeight.w600,
            color: enabled ? ClockColors.text : ClockColors.dimmed,
          ),
        ),
      ),
    );
  }
}

/// A round button with a symbol (the "+" of the toolbar, the timer list play and pause).
class RoundButton extends StatefulWidget {
  const RoundButton({
    super.key,
    required this.symbol,
    required this.onPressed,
    this.size = 36,
    this.fill = ClockColors.track,
    this.color = ClockColors.text,
  });

  final String symbol;
  final VoidCallback? onPressed;
  final double size;
  final Color fill;
  final Color color;

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _hover
              ? Color.alphaBlend(ClockColors.hover, widget.fill)
              : widget.fill,
          shape: BoxShape.circle,
        ),
        child: ClockSymbol(
          widget.symbol,
          size: widget.size * 0.5,
          color: widget.color,
        ),
      ),
    ),
  );
}

/// The alarm switch: orange track and white knob when on, gray when off (CL-01).
class ClockSwitch extends StatelessWidget {
  const ClockSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  static const Size size = Size(48, 28);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(2),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? ClockColors.switchOn : ClockColors.switchOff,
        borderRadius: BorderRadius.circular(size.height / 2),
      ),
      child: Container(
        width: size.height - 4,
        height: size.height - 4,
        decoration: BoxDecoration(
          color: value ? ClockColors.text : ClockColors.switchKnobOff,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

/// A sheet centered over the window, with the window behind dimmed.
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
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: onDismiss,
          child: const ColoredBox(color: Color(0x66000000)),
        ),
      ),
      Center(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: ClockColors.sheet,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3D3D3D)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    ],
  );
}

/// A one-line text field with the orange focus ring of the sheets.
class ClockTextField extends StatefulWidget {
  const ClockTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.width = 224,
    this.height = 26,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
    this.leading,
  });

  final TextEditingController controller;
  final String placeholder;
  final double width;
  final double height;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? leading;

  @override
  State<ClockTextField> createState() => _ClockTextFieldState();
}

class _ClockTextFieldState extends State<ClockTextField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _focus.requestFocus,
    child: Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(widget.height / 2.6),
        border: Border.all(
          color: _focus.hasFocus ? ClockColors.orange : const Color(0xFF3D3D3D),
          width: _focus.hasFocus ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          ?widget.leading,
          if (widget.leading != null) const SizedBox(width: 6),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (widget.controller.text.isEmpty)
                  Text(
                    widget.placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: clockText(13, color: ClockColors.dimmed),
                  ),
                EditableText(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  style: clockText(13),
                  cursorColor: ClockColors.orange,
                  backgroundCursorColor: ClockColors.text,
                  selectionColor: const Color(0x66FF9230),
                  maxLines: 1,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
