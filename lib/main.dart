// Clock, the clock app of Silica: world clocks, alarms, stopwatch and timers.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'src/app.dart';
import 'src/controller.dart';
import 'src/model/settings.dart';
import 'src/style.dart';
import 'src/time/cities.dart';
import 'src/time/tzif.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The toolbar is unified with the window: Ossido draws only the window buttons.
  SilicaWindow.setFullSizeContent(toolbarHeight).ignore();
  // The smallest window that still shows every section (CL-13); no maximum.
  SilicaWindow.setSizeLimits(min: ClockMetrics.minWindow).ignore();
  final env = Platform.environment;
  final zones = ZoneDatabase();
  runApp(
    ClockApp(
      controller: ClockController(
        settings: Settings.forUser(env),
        zones: zones,
        cities: loadCities(directory: zones.directory),
      ),
    ),
  );
}
