// Colors, sizes and type of the Clock app, measured in CL-01 (silica-reference `clock.md`).
// The app is always dark: the measured light and dark captures are pixel-identical.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

abstract final class ClockColors {
  static const Color background = Color(0xFF1E1E1E);
  static const Color text = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF8E8E93);
  static const Color dimmed = Color(0xFF6A6A6A);

  /// The gray texts of an alarm card, and all of them when the alarm is off (CL-09).
  static const Color alarmMinor = Color(0xFFA2A2A2);

  /// The pop-up button at the minimum width: track and outer rim.
  static const Color track = Color(0xFF3D3D3D);
  static const Color rimOuter = Color(0xFF0B0B0B);

  /// Hover highlight of a segment and of the round buttons: *provisional* (CL-01 notes a hover
  /// state but did not capture its color).
  static const Color hover = Color(0x14FFFFFF);

  /// Cards (world clocks, alarms) and the timer list.
  static const Color card = Color(0xFF323232);
  static const Color timerCard = Color(0xFF48484A);
  static const Color sheet = Color(0xFF272727);
  static const Color line = Color(0xFF343434);
  static const Color lapHeader = Color(0xFF565656);

  /// Accents (sRGB).
  static const Color orange = Color(0xFFFF9230);
  static const Color green = Color(0xFF30D159);
  static const Color red = Color(0xFFFF4245);
  static const Color switchOn = Color(0xFFF49C40);
  static const Color switchKnobOn = Color(0xFFFEF0E3);
  static const Color switchOff = Color(0xFF454545);
  static const Color switchKnobOff = Color(0xFFE3E3E3);
  static const Color ringTrack = Color(0xFF3B3B3D);

  /// Capsule buttons: neutral, disabled.
  static const Color button = Color(0xFF2F2F2F);
  static const Color buttonDisabled = Color(0xFF262626);
  static const Color emptySymbol = Color(0xFF9A9A9A);
  static const Color emptyText = Color(0xFFDDDDDD);
  static const Color pickerDigits = Color(0xFFDDDDDD);
  static const Color pickerUnits = Color(0xFF989898);
}

abstract final class ClockMetrics {
  static const Size window = Size(1024, 768);
  static const Size minWindow = Size(690, 640);

  static const double controlHeight = 36;

  /// The control sits 3 pt right of the center of its area, with or without the timer list
  /// (CL-01, CL-06: ink 327–702 and 487–862 at 1024 pt).
  static const double controlShift = 3;
  static const List<double> segmentWidths = [95, 94, 95, 94];
  static double get controlWidth => segmentWidths.fold(0, (a, b) => a + b);
  static const double plusButton = 36;

  /// The world map keeps this size (AX "Mappa del mondo", CL-01); the gap below it is
  /// provisional (CLOCK-WORLD).
  static const Size worldMap = Size(1024, 500);
  static const double worldMapGap = 15;

  static const Size worldCard = Size(186, 222);
  static const Size alarmCard = Size(186, 181);
  static const double cardPitch = 202;
  static const double cardsLeft = 15;
  static const double cardRadius = 12;
  static const double face = 120;
  static const double faceTop = 20;

  static const double stopwatchTop = 87;
  static const double lapsWidth = 320;
  static const double lapRow = 31;
  static const Size capsuleButton = Size(150, 28);
  static const double capsuleGap = 20;

  /// Distance of the capsule buttons from the bottom of a 768 pt window (top at +690).
  static const double buttonsBottom = 768 - 690 - 28;

  static const double timerSidebar = 320;
  static const Size timerCardSize = Size(300, 92);
  static const double ring = 360;
  static const double ringStroke = 6;
}

/// Text in Inter (silica_ui), white by default.
TextStyle clockText(
  double size, {
  Color color = ClockColors.text,
  FontWeight? weight,
}) => TextStyle(
  fontFamily: uiFontFamily,
  package: 'silica_ui',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.2,
);

/// Thin digits (Inter variable at weight 200), tabular so the time does not dance.
TextStyle thinDigits(
  double size, {
  Color color = ClockColors.text,
  double weight = 200,
}) => TextStyle(
  fontFamily: 'InterVariable',
  fontSize: size,
  color: color,
  height: 1,
  fontVariations: [FontVariation('wght', weight)],
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Semibold tabular figures (lap times, card times).
TextStyle tabular(
  double size, {
  Color color = ClockColors.text,
  FontWeight weight = FontWeight.w600,
}) => clockText(
  size,
  color: color,
  weight: weight,
).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
