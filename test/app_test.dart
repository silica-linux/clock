import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_clock/src/app.dart';
import 'package:silica_clock/src/controller.dart';
import 'package:silica_clock/src/model/alarms.dart';
import 'package:silica_clock/src/model/settings.dart';
import 'package:silica_clock/src/style.dart';
import 'package:silica_clock/src/system/notifier.dart';
import 'package:silica_clock/src/world_view.dart';
import 'package:silica_clock/src/widgets.dart';
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
    bool fakeClock = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ClockController(
      settings: Settings(null),
      zones: ZoneDatabase(),
      cities: const [rome, tokyo],
      ringer: ringer ?? FakeRinger(),
      // The test clock: alarms and timers follow the fake time of `pump`.
      now: fakeClock ? () => tester.binding.clock.now().toLocal() : null,
      micros: fakeClock
          ? () => tester.binding.clock.now().microsecondsSinceEpoch
          : null,
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

  testWidgets('segmented control: 378 × 36, centered, the pill springs over', (
    tester,
  ) async {
    final c = await pump(tester);
    final control = tester.getRect(
      find.byKey(const ValueKey('section control')),
    );
    expect(control.size, const Size(378, 36));
    expect(control.center.dx, closeTo(512 + 3, 0.5));
    expect(control.center.dy, closeTo(26, 0.5));
    await tester.tap(find.text('Stopwatch'));
    // The content changes at once; the pill and the lens settle through their springs.
    await tester.pump();
    expect(c.section, Section.stopwatch);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('section control')), findsOneWidget);
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
    expect(card, const Size(186.8, 181));
    // CL-09: the switch (54 × 24) under the texts, 31 pt from the left of the card.
    final cardRect = tester.getRect(
      find.byKey(ValueKey('alarm ${c.alarms.single.id}')),
    );
    final switchRect = tester.getRect(
      find.byKey(ValueKey('switch ${c.alarms.single.id}')),
    );
    expect(switchRect.size, const Size(54, 24));
    expect(switchRect.topLeft - cardRect.topLeft, const Offset(31, 130));
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
      expect(control.center.dx, closeTo(320 + (1024 - 320) / 2 + 3, 0.5));
      await tester.tap(find.byKey(const ValueKey('timer cancel')));
      await tester.pump();
      expect(c.timers, isEmpty);
      // A timer that ends rings and notifies.
      c.startTimer(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      c.check();
      await tester.pump(const Duration(milliseconds: 300));
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

  testWidgets(
    'world: add a city from the sheet; a single card is one 186 × 222 slot',
    (tester) async {
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
        const Size(186.8, 222),
      );
      await done(tester, c);
    },
  );

  Iterable<MethodCall> notifies() => dbus.where(
    (m) => m.method == 'call' && (m.arguments as Map)['method'] == 'Notify',
  );

  Color fillOf(WidgetTester tester, Key key) {
    final box = tester.widget<Container>(
      find.descendant(of: find.byKey(key), matching: find.byType(Container)),
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  testWidgets('capsules take the pressed fill at once (CL-02)', (tester) async {
    expect(pressedFill(ClockColors.green), const Color(0xFF4CD669));
    expect(pressedFill(ClockColors.red), const Color(0xFFFF5858));
    expect(pressedFill(ClockColors.button), const Color(0xFF434343));
    final c = await pump(tester);
    c.select(Section.stopwatch);
    await tester.pump();
    const start = ValueKey('start stop');
    expect(fillOf(tester, start), ClockColors.green);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(start)),
    );
    await tester.pump();
    expect(fillOf(tester, start), const Color(0xFF4CD669));
    // The action fires on release.
    expect(c.stopwatch.running, isFalse);
    await gesture.up();
    await tester.pump();
    expect(c.stopwatch.running, isTrue);
    await done(tester, c);
  });

  testWidgets('the toolbar "+" acts on mouse down (CL-02)', (tester) async {
    final c = await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('add'))),
    );
    await tester.pump();
    expect(find.text('Add a City'), findsOneWidget);
    await gesture.up();
    await done(tester, c);
  });

  testWidgets('an alarm rings on time: switch, banner after 227 ms, sound '
      'after 389 ms; Snooze rings again after the snooze length', (
    tester,
  ) async {
    final ringer = FakeRinger();
    final c = await pump(tester, ringer: ringer, fakeClock: true);
    final now = tester.binding.clock.now().toLocal();
    final at = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    c.saveAlarm(
      Alarm(id: 1, hour: at.hour, minute: at.minute, snoozeMinutes: 1),
    );
    await tester.pump(at.difference(now));
    // One-off: the switch goes off as it rings.
    expect(c.alarms.single.enabled, isFalse);
    await tester.pump(const Duration(milliseconds: 226));
    expect(notifies(), isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    final notify = notifies().single.arguments as Map;
    expect((notify['args'] as List)[3], 'Clock');
    expect((notify['args'] as List)[4], 'Alarm');
    expect((notify['args'] as List)[5], ['stop', 'Stop', 'snooze', 'Snooze']);
    await tester.pump(const Duration(milliseconds: 161));
    expect(ringer.rings, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(ringer.rings, 1);

    // Snooze from the banner: the sound stops, the switch turns back on.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'silica/dbus',
      const JSONMethodCodec().encodeMethodCall(
        const MethodCall('signal', {
          'id': 1,
          'member': 'ActionInvoked',
          'args': [7, 'snooze'],
        }),
      ),
      (_) {},
    );
    await tester.pump();
    expect(ringer.ringing, isFalse);
    expect(c.alarms.single.enabled, isTrue);
    await tester.pump(
      const Duration(seconds: 60) - const Duration(milliseconds: 1),
    );
    expect(notifies(), hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(c.alarms.single.enabled, isFalse);
    await tester.pump(const Duration(milliseconds: 389));
    expect(notifies(), hasLength(2));
    expect(ringer.rings, 2);
    await done(tester, c);
  });

  testWidgets('a timer ends: back to the picker, banner after 147 ms, sound '
      'after 290 ms, Restart runs it again', (tester) async {
    final ringer = FakeRinger();
    final c = await pump(tester, ringer: ringer, fakeClock: true);
    c.select(Section.timers);
    c.startTimer(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    expect(c.timers, isEmpty);
    await tester.pump(const Duration(milliseconds: 146));
    expect(notifies(), isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect((notifies().single.arguments as Map)['args'][5], [
      'stop',
      'Stop',
      'repeat',
      'Restart',
    ]);
    await tester.pump(const Duration(milliseconds: 142));
    expect(ringer.rings, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(ringer.rings, 1);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'silica/dbus',
      const JSONMethodCodec().encodeMethodCall(
        const MethodCall('signal', {
          'id': 1,
          'member': 'ActionInvoked',
          'args': [7, 'repeat'],
        }),
      ),
      (_) {},
    );
    await tester.pump();
    expect(ringer.ringing, isFalse);
    expect(c.timers.single.timer.duration, const Duration(seconds: 5));
    expect(
      dbus.where(
        (m) => (m.arguments as Map?)?['method'] == 'CloseNotification',
      ),
      hasLength(1),
    );
    await done(tester, c);
  });

  testWidgets('the toolbar "+" is the silica_ui glass icon button (#2)', (
    tester,
  ) async {
    final c = await pump(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('add')),
        matching: find.byType(ToolbarSegment),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('add')), findsOneWidget);
    expect(
      tester.widget(find.byKey(const ValueKey('add'))),
      isA<ToolbarCapsule>(),
    );
    expect(find.byType(RoundButton), findsNothing);
    await done(tester, c);
  });

  test('the hands sweep continuously (#3, CLOCK-HANDS)', () {
    final t = DateTime(2026, 1, 1, 3, 20, 7, 0);
    final p0 = HandMotion.position(t, Duration.zero);
    expect(p0, 3 * 3600 + 20 * 60 + 7);
    // One redraw (72 ms) moves the second hand by ~0.43 degrees, no snap, no overshoot.
    final p1 = HandMotion.position(t, HandMotion.redraw);
    expect((p1 - p0) * 6, closeTo(0.432, 1e-9));
    expect(HandMotion.position(t, const Duration(seconds: 1)) - p0, 1);
    // Wraps at 12 hours.
    expect(
      HandMotion.position(
        DateTime(2026, 1, 1, 11, 59, 59),
        const Duration(seconds: 2),
      ),
      1,
    );
  });

  testWidgets(
    'the face redraws every 72 ms and the hands move between seconds',
    (tester) async {
      var t = DateTime(2026, 1, 1, 3, 20, 7);
      final start = t;
      final painters = <ClockFacePainter>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.square(
            dimension: 120,
            child: AnalogFace(
              time: start,
              day: true,
              now: start,
              clock: () => t,
            ),
          ),
        ),
      );
      CustomPaint paint() =>
          tester.widget<CustomPaint>(find.byKey(const ValueKey('hands')));
      painters.add(paint().painter! as ClockFacePainter);
      t = t.add(const Duration(milliseconds: 100));
      await tester.pump(HandMotion.redraw);
      painters.add(paint().painter! as ClockFacePainter);
      expect(painters[1].seconds - painters[0].seconds, closeTo(0.1, 1e-9));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a redraw of the hands repaints neither the dial nor the map (#202)',
    (tester) async {
      var t = DateTime(2026, 1, 1, 3, 20, 7);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.square(
            dimension: 120,
            child: AnalogFace(time: t, day: true, now: t, clock: () => t),
          ),
        ),
      );
      final hands = tester.renderObject(find.byKey(const ValueKey('hands')));
      final dial = tester.renderObject<RenderCustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is AnalogDialPainter,
        ),
      );
      // The dial sits in its own layer, the hands in the face's: neither is the card's.
      expect(dial.parent, isA<RenderRepaintBoundary>());
      RenderObject? boundary = hands.parent;
      while (boundary != null && !boundary.isRepaintBoundary) {
        boundary = boundary.parent;
      }
      final face = tester.renderObject(
        find
            .descendant(
              of: find.byType(AnalogFace),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      expect(boundary, same(face));
      t = t.add(HandMotion.redraw);
      await tester.pump(HandMotion.redraw);
      expect(dial.debugNeedsPaint, isFalse);
      expect(
        AnalogDialPainter(
          day: true,
        ).shouldRepaint(AnalogDialPainter(day: true)),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('the map repaints when its time step, pins or land change (#202)', () {
    final t = DateTime.utc(2026, 1, 1, 3, 20, 7, 500);
    expect(WorldMapPainter.step(t), DateTime.utc(2026, 1, 1, 3, 20));
    expect(
      WorldMapPainter.step(t.add(const Duration(seconds: 2))),
      WorldMapPainter.step(t),
    );
    // The view rebuilds at the next step: 2.5 s after 03:20:07.5, and a full step at a boundary.
    expect(
      WorldMapPainter.untilNextStep(t),
      const Duration(milliseconds: 2500),
    );
    expect(
      WorldMapPainter.untilNextStep(DateTime.utc(2026, 1, 1, 3, 20, 10)),
      WorldMapPainter.timeStep,
    );
    WorldMapPainter map(DateTime now, String time) =>
        WorldMapPainter(now: WorldMapPainter.step(now), pins: [(rome, time)]);
    final first = map(t, '04:20');
    expect(
      map(t.add(const Duration(seconds: 1)), '04:20').shouldRepaint(first),
      isFalse,
    );
    expect(
      map(t.add(const Duration(seconds: 10)), '04:20').shouldRepaint(first),
      isTrue,
    );
    expect(map(t, '04:21').shouldRepaint(first), isTrue);
    expect(
      WorldMapPainter(
        now: first.now,
        pins: first.pins,
        land: [Float32List(2)],
      ).shouldRepaint(first),
      isTrue,
    );
  });

  testWidgets('at rest the stopwatch and the timers ask for no frames (#202)', (
    tester,
  ) async {
    final c = await pump(tester);
    for (final section in [Section.stopwatch, Section.timers]) {
      c.select(section);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: '$section');
    }
    c.select(Section.stopwatch);
    await tester.pumpAndSettle();
    c.stopwatchStartStop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isTrue);
    c.stopwatchStartStop();
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await done(tester, c);
  });

  test('card grid: the columns and widths measured at each window width', () {
    // clock.md, CLOCK-WORLD: window width -> (cards per row, card width).
    const measured = {
      1400: (7, 182.9),
      1040: (5, 190.0),
      900: (5, 162.0),
      800: (4, 181.25),
      690: (3, 210.0),
    };
    measured.forEach((width, expected) {
      final grid = CardGrid.of(width.toDouble());
      expect(grid.columns, expected.$1, reason: '$width');
      expect(grid.cardWidth, closeTo(expected.$2, 0.1), reason: '$width');
    });
    expect(CardGrid.of(1024).cardWidth, closeTo(186.8, 0.01));
  });

  testWidgets(
    'world: the map takes the full width and the content scrolls (#4)',
    (tester) async {
      final c = await pump(tester);
      expect(c.section, Section.world);
      final map = find.byKey(const ValueKey('world map'));
      expect(tester.getSize(map), const Size(1024, 1024 * 0.488));
      await done(tester, c);

      final small = await pump(tester, size: const Size(700, 600));
      small.settings.cities = ['Asia/Tokyo', 'Europe/Rome'];
      small.notifyListeners();
      await tester.pump();
      expect(
        tester.getSize(find.byType(WorldCard).first),
        const Size(640 / 3, 222),
      );
      expect(tester.getSize(map), const Size(700, 700 * 0.488));
      final top = tester.getTopLeft(map);
      // Scrolling is vertical and moves the map and the cards together.
      final card = tester.getTopLeft(find.byType(WorldCard).first);
      await tester.drag(
        find.byKey(const ValueKey('world scroll')),
        const Offset(0, -30),
      );
      await tester.pump();
      expect(tester.getSize(map), const Size(700, 700 * 0.488));
      expect(tester.getTopLeft(map).dy, top.dy - 30);
      expect(tester.getTopLeft(find.byType(WorldCard).first).dy, card.dy - 30);
      expect(tester.getTopLeft(map).dx, 0);
      await done(tester, small);
    },
  );

  testWidgets(
    'always dark: the library resolves dark in a light system and Ossido is told',
    (tester) async {
      final window = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SilicaWindow.channel, (call) async {
            window.add(call);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SilicaWindow.channel, null),
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final c = await pump(tester);
      final context = tester.element(find.byType(ClockWindow));
      expect(MediaQuery.platformBrightnessOf(context), Brightness.dark);
      expect(SilicaAppearance.isDark(context), isTrue);
      expect(identical(ToolbarColors.of(context), ToolbarColors.dark), isTrue);
      expect(
        identical(SegmentedColors.of(context), SegmentedColors.dark),
        isTrue,
      );
      expect(
        window
            .where((call) => call.method == 'setAppearance')
            .map((call) => call.arguments),
        [
          {'appearance': 'dark'},
        ],
      );
      await done(tester, c);
    },
  );
}
