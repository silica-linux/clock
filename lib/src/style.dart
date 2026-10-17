// Metrics and colors of the Clock app on the Amalfi design system (silica-design kit page
// `App · Clock`, masters `Apps/Clock/*`). Every colour is a token: the app palette
// `App/Clock/*` (dark only: the app looks the same in both system appearances) and the shared
// ones (`Text/*`, `Line/*`, `Surface/*`). Timings and curves stay the measured ones (CL-01).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

/// The palette of the app (`App/Clock/*`, dark).
const AmalfiClockColors clockPalette = AmalfiClockColors.dark;

/// The shared dark tokens: the app is always dark.
final AmalfiColors darkColors = AmalfiColors.dark;

/// The faces of the world cards: white by day, `Surface/Sunken` by night; the numerals and
/// hands take the opposite one (kit `City Card Day` and `City Card Night`).
abstract final class ClockFace {
  static const Color dayFace = Color(0xFFFFFFFF);
  static Color get nightFace => darkColors.surfaceSunken;
  // Dark ink on the white day face (the app's tokens are the dark ones: the face is not).
  static Color get dayInk => AmalfiColors.light.textPrimary;
  static const Color nightInk = Color(0xFFFFFFFF);
}

/// The map, drawn in the app (the kit shows an image): black oceans and gray land.
/// The analog stopwatch dial (kit `Stopwatch Analog / Dark`; the app is dark only).
abstract final class ClockDial {
  static const Color face = Color(0xFF272727);

  /// The window surface seen through the centre cap.
  static const Color hole = Color(0xFF1E1E1E);
}

abstract final class ClockMap {
  static const Color ocean = Color(0xFF000000);
  static const Color land = Color(0xFF2C2C2E);
  static const Color zoneLine = Color(0x14FFFFFF);
  static const Color night = Color(0x66000000);
  static const Color boundary = Color(0xB3FFFFFF);
}

abstract final class ClockMetrics {
  /// The kit window (1024 × 800 with the 52 pt toolbar); the smallest size shows every
  /// section (CL-13).
  static const Size window = Size(1024, 800);
  static const Size minWindow = Size(690, 640);

  /// The toolbar's round "+" is a piece of 44 pt (4 + 32 + 8), kept as an empty slot in the
  /// stopwatch so that the section control does not move between sections.
  static const double addPiece = 44;

  /// The window controls are drawn by Ossido over the toolbar: a 96 pt slot (kit piece
  /// `Controls`).
  static const double controlsPiece = AmalfiToolbarPieceMetrics.controlsWidth;

  /// The trailing padding of the toolbar after the `Add` piece (which ends with 8): the kit
  /// has the button end 16 pt from the window's edge (components.md).
  static const double toolbarTrailing = 8;

  /// The window-button slot starts 4 pt inside the bar (kit piece `Controls` at x 4).
  static const double toolbarLeading = 4;

  /// The world map: full width, 480 pt at 1024 pt, the map centred on the equator (the
  /// pins of the kit sit at `240 - latitude * width / 360`). The gap below it is 16.
  static const double worldMapRatio = 480 / 1024;
  static const double mapGap = 16;

  /// Under the world cards (kit World: cards end at 768 in the 800 pt window).
  static const double worldBottomMargin = 32;

  static const double worldCardHeight = 220;
  static const double worldCardMinWidth = 160;
  static const double alarmCardHeight = 180;
  static const double cardGap = 16;
  static const double cardsMargin = 20;
  static const double cardRadius = 12;
  static const double face = 120;
  static const double faceTop = 20;

  /// Pins: an 8 pt dot, the name and the time 8 pt from its centre.
  static const double pinRadius = 4;

  /// The digits of the big numerals are positioned by the centre of their figures, measured
  /// on the kit's PNG (Sketch's fixed 40 pt line box makes the frames of the masters
  /// meaningless for the large sizes): the stopwatch's 104 centre is at 121 in the window.
  static const double stopwatchDigitsCenter =
      121 - AmalfiToolbarMetrics.toolbarHeight;
  static const double lapsTop = 296 - AmalfiToolbarMetrics.toolbarHeight;
  static const double lapsWidth = 320;
  static const double lapsRow = 32;
  static const double lapsHeader = 21;

  /// Capsule buttons are 28 tall; 72 wide for Cancel/Pause, 68 for Lap/Start/Stop, 96 apart.
  static const double buttonHeight = 28;
  static const double buttonWide = 72;
  static const double buttonNarrow = 68;
  static const double buttonsGap = 96;

  /// The stopwatch buttons end 68 pt above the bottom of a 800 pt window.
  static const double stopwatchButtonsBottom = 800 - 704 - 28;

  static const double timerSidebar = AmalfiWindowMetrics.listWidth;
  static const Size timerCardSize = Size(300, 92);
  static const double ring = 360;
  static const double ringStroke = 6;
}

/// The card grid of the world clocks and the alarms (CLOCK-WORLD, #95, measured): the side
/// margins and gaps of the kit (20 and 16), as many columns as fit with each card at least
/// ~160 pt wide, the cards sharing the row (184 pt at 1024 pt). The columns follow the window
/// width, never the number of cards.
class CardGrid {
  const CardGrid(this.columns, this.cardWidth);

  static const double gap = ClockMetrics.cardGap;

  factory CardGrid.of(double width) {
    const margin = ClockMetrics.cardsMargin;
    final usable = width - 2 * margin;
    var n = 1;
    while ((usable - n * gap) / (n + 1) >= ClockMetrics.worldCardMinWidth) {
      n++;
    }
    return CardGrid(n, (usable - (n - 1) * gap) / n);
  }

  final int columns;
  final double cardWidth;
}

/// The big numerals (Numeral 40/64/72/104, Inter regular): the box is the font size tall so
/// that the figures sit at its centre, and the digits are tabular where they change.
TextStyle numeral(double size, {Color? color, bool tabular = false}) =>
    switch (size) {
      40 => AmalfiType.numeral40(color: color),
      64 => AmalfiType.numeral64(color: color),
      72 => AmalfiType.numeral72(color: color),
      104 => AmalfiType.numeral104(color: color),
      _ => throw ArgumentError('no Numeral $size token'),
    }.copyWith(
      height: 1,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
