// Tests measure with the real Inter (silica_ui's static weights), not with the test font:
// widths and truncations are those of the window.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final inter = FontLoader('packages/silica_ui/Inter')
    ..addFont(rootBundle.load('packages/silica_ui/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('packages/silica_ui/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('packages/silica_ui/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('packages/silica_ui/fonts/Inter-Bold.ttf'));
  await inter.load();
  await testMain();
}
