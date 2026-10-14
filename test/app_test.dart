import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_clock/src/app.dart';
import 'package:silica_clock/src/controller.dart';
import 'package:silica_clock/src/model/settings.dart';
import 'package:silica_clock/src/system/notifier.dart';
import 'package:silica_clock/src/time/cities.dart';
import 'package:silica_clock/src/time/tzif.dart';

const rome = City(
  zone: 'Europe/Rome',
  name: 'Rome',
  country: 'Italy',
  latitude: 41.9,
  longitude: 12.48,
);
const tokyo = City(
  zone: 'Asia/Tokyo',
  name: 'Tokyo',
  country: 'Japan',
  latitude: 35.65,
  longitude: 139.74,
);

/// A ringer that only counts (no processes in tests).
class FakeRinger extends Ringer {
  int rings = 0;
  bool _on = false;
  @override
  bool get ringing => _on;
  @override
  void start({Duration limit = const Duration(minutes: 5)}) {
    rings++;
    _on = true;
  }

  @override
  void stop() => _on = false;
}

void main() {
  late List<MethodCall> dbus;

  setUp(() {
    dbus = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('silica/dbus', JSONMethodCodec()),
          (call) async {
            dbus.add(call);
            return call.method == 'subscribe' ? 1 : [7];
          },
        );
  });

  Future<ClockController> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(1024, 768),
    FakeRinger? ringer,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ClockController(
      settings: Settings(null),
      zones: ZoneDatabase(),
      cities: const [rome, tokyo],
      ringer: ringer ?? FakeRinger(),
    );
    await tester.pumpWidget(ClockApp(controller: controller, locale: locale));
    return controller;
  }

  /// Unmounts the app and stops its timers before the test ends.
  Future<void> done(WidgetTester tester, ClockController c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('segmented control: 378 × 36, centered, the pill slides', (
    tester,
  ) async {
    final c = await pump(tester);
    final control = tester.getRect(
      find.byKey(const ValueKey('section control')),
    );
    expect(control.size, const Size(378, 36));
    expect(control.center.dx, closeTo(512, 0.5));
    expect(control.center.dy, closeTo(26, 0.5));
    await tester.tap(find.text('Stopwatch'));
    // The content changes at once, the pill reaches its place in ~300 ms.
    await tester.pump();
    expect(c.section, Section.stopwatch);
    final start = tester.getRect(find.byKey(const ValueKey('pill'))).left;
    await tester.pump(const Duration(milliseconds: 150));
    final mid = tester.getRect(find.byKey(const ValueKey('pill'))).left;
    await tester.pump(const Duration(milliseconds: 200));
    final end = tester.getRect(find.byKey(const ValueKey('pill'))).left;
    expect(mid, greaterThan(start));
    expect(end, greaterThan(mid));
    expect(end, closeTo(control.left + 1 + 95 + 94 + 4, 1.5));
    await done(tester, c);
  });

  testWidgets('stopwatch: digits, start and laps, Italian comma', (
    tester,
  ) async {
    final c = await pump(tester, locale: const Locale('it'));
    c.select(Section.stopwatch);
    await tester.pump();
    expect(find.text('00:00,00'), findsOneWidget);
    expect(find.text('Cronometro'), findsOneWidget);
    final buttons = [
      tester.getRect(find.byKey(const ValueKey('lap reset'))),
      tester.getRect(find.byKey(const ValueKey('start stop'))),
    ];
    expect(buttons[0].size, const Size(150, 28));
    expect(buttons[1].left - buttons[0].right, 20);
    expect(buttons[1].top, 690);
    await tester.tap(find.text('Avvia'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Ferma'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lap reset')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('lap 0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start stop')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lap reset')));
    await tester.pump();
    expect(find.text('00:00,00'), findsOneWidget);
    await done(tester, c);
  });

  testWidgets('alarms: empty state, editor, card and switch', (tester) async {
    final c = await pump(tester);
    c.select(Section.alarms);
    await tester.pump();
    expect(find.text('No Alarms'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add')));
    await tester.pump();
    expect(find.text('New Alarm'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day 6')));
    await tester.tap(find.byKey(const ValueKey('day 7')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save')));
    await tester.pump();
    expect(c.alarms, hasLength(1));
    expect(c.alarms.single.repeat, {6, 7});
    final card = tester.getSize(
      find.byKey(ValueKey('alarm ${c.alarms.single.id}')),
    );
    expect(card, const Size(186, 181));
    expect(find.text('Repeat: Weekends'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('switch ${c.alarms.single.id}')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.alarms.single.enabled, isFalse);
    await done(tester, c);
  });

  testWidgets(
    'timers: picker, running ring, list, control centered on the rest',
    (tester) async {
      final ringer = FakeRinger();
      final c = await pump(tester, ringer: ringer);
      c.select(Section.timers);
      await tester.pump();
      expect(find.text('15'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('timer start')));
      await tester.pump();
      expect(c.timers, hasLength(1));
      expect(
        tester.getSize(find.byKey(const ValueKey('timer ring'))),
        const Size(360, 360),
      );
      final control = tester.getRect(
        find.byKey(const ValueKey('section control')),
      );
      expect(control.center.dx, closeTo(320 + (1024 - 320) / 2, 0.5));
      await tester.tap(find.byKey(const ValueKey('timer cancel')));
      await tester.pump();
      expect(c.timers, isEmpty);
      // A timer that ends rings and notifies.
      c.startTimer(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      c.check();
      await tester.pump();
      expect(ringer.rings, 1);
      expect(dbus.where((m) => m.method == 'call'), isNotEmpty);
      await done(tester, c);
    },
  );

  testWidgets(
    'at the minimum width with the timer list the control becomes a pop-up',
    (tester) async {
      final c = await pump(tester, size: const Size(690, 640));
      expect(find.byKey(const ValueKey('section control')), findsOneWidget);
      c.startTimer(const Duration(minutes: 5));
      await tester.pump();
      expect(find.byKey(const ValueKey('section control')), findsNothing);
      expect(find.byKey(const ValueKey('section popup')), findsOneWidget);
      await done(tester, c);
    },
  );

  testWidgets('world: add a city from the sheet; the card is 186 × 222', (
    tester,
  ) async {
    final c = await pump(tester);
    expect(c.section, Section.world);
    await tester.tap(find.byKey(const ValueKey('add')));
    await tester.pump();
    expect(find.text('Add a City'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'tok');
    await tester.pump();
    expect(find.text('Rome, Italy'), findsNothing);
    await tester.tap(find.text('Tokyo, Japan'));
    await tester.pump();
    expect(c.settings.cities, ['Asia/Tokyo']);
    expect(
      tester.getSize(find.byKey(const ValueKey('card Asia/Tokyo'))),
      const Size(186, 222),
    );
    await done(tester, c);
  });
}
