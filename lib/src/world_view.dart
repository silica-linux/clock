// The World section (CL-01): a map with the day/night line and a pin per city on top, a row
// of 222 pt tall cards in a grid (186 wide at 1024 pt, 15 pt margins and gaps) below, each with a 120 pt analog face (white by day,
// black by night), the city and its time, the day and offset, sunrise and sunset.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'controller.dart';
import 'style.dart';
import 'time/cities.dart';
import 'time/tzif.dart';
import 'widgets.dart';

/// `HH:MM`, or `h:MM AM` when the system does not use the 24-hour clock.
String formatTime(BuildContext context, int hour, int minute) {
  final mm = minute.toString().padLeft(2, '0');
  if (MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? true) {
    return '${hour.toString().padLeft(2, '0')}:$mm';
  }
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12:$mm ${hour < 12 ? 'AM' : 'PM'}';
}

class WorldView extends StatefulWidget {
  const WorldView({super.key, required this.controller});
  final ClockController controller;

  @override
  State<WorldView> createState() => _WorldViewState();
}

class _WorldViewState extends State<WorldView> {
  Timer? _tick;
  OverlayEntry? _menu;
  List<Float32List> _landRings = const [];

  @override
  void initState() {
    super.initState();
    loadLand().then((rings) {
      if (mounted) setState(() => _landRings = rings);
    });
    // The second hands move once a second.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _menu?.remove();
    super.dispose();
  }

  void _openMenu(City city, Offset at) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final l = AppLocalizations.of(context);
    _menu?.remove();
    _menu = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: MenuHost(
          anchor: at,
          opaque: true,
          entries: [
            MenuAction(
              l.removeClock,
              onSelected: () => widget.controller.removeCity(city.zone),
            ),
          ],
          onDismissed: () {
            _menu?.remove();
            _menu = null;
          },
        ),
      ),
    );
    overlay.insert(_menu!);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final cities = c.worldCities;
    final now = c.now();
    final localZone =
        c.zones.zone(c.zones.localName() ?? 'UTC') ?? TimeZone.utc;
    final pins = [
      for (final city in cities)
        (
          city,
          formatTime(
            context,
            c.timeIn(city.zone).hour,
            c.timeIn(city.zone).minute,
          ),
        ),
    ];
    // CLOCK-WORLD (#95, measured): the map has no fixed size, it takes the full width with
    // height 0.488 x width and never scrolls sideways; the map and the cards scroll together
    // in one vertical view under the toolbar. The cards sit in a grid of fixed 222 pt height
    // whose columns come from the window width, not from the number of cities (cardGrid): a
    // single city is one card of one slot (186 pt at 1024 pt), never the whole row.
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final grid = CardGrid.of(width);
        return SingleChildScrollView(
          key: const ValueKey('world scroll'),
          padding: const EdgeInsets.only(top: toolbarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width,
                height: width * ClockMetrics.worldMapRatio,
                child: CustomPaint(
                  key: const ValueKey('world map'),
                  painter: WorldMapPainter(
                    now: now,
                    land: _landRings,
                    pins: pins,
                  ),
                ),
              ),
              const SizedBox(height: ClockMetrics.worldMapGap),
              if (cities.isEmpty)
                SizedBox(
                  height: ClockMetrics.worldCardHeight,
                  width: width,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).worldEmpty,
                      style: clockText(15, color: ClockColors.secondary),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClockMetrics.cardsLeft,
                  ),
                  child: Wrap(
                    key: const ValueKey('world cards'),
                    spacing: CardGrid.gap,
                    runSpacing: CardGrid.gap,
                    children: [
                      for (final city in cities)
                        GestureDetector(
                          onSecondaryTapUp: (d) =>
                              _openMenu(city, d.globalPosition),
                          child: WorldCard(
                            key: ValueKey('card ${city.zone}'),
                            city: city,
                            zone: c.zones.zone(city.zone) ?? TimeZone.utc,
                            local: localZone,
                            now: now,
                            clock: c.now,
                            width: grid.cardWidth,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: ClockMetrics.worldMapGap),
            ],
          ),
        );
      },
    );
  }
}

/// A world clock card: 222 pt tall, `#323232`, radius 12, the face 20 pt from the top.
class WorldCard extends StatelessWidget {
  const WorldCard({
    super.key,
    required this.city,
    required this.zone,
    required this.local,
    required this.now,
    this.clock,
    this.width = 186,
  });

  final City city;
  final TimeZone zone;
  final TimeZone local;
  final DateTime now;
  final DateTime Function()? clock;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wall = zone.wallTime(now);
    final here = local.wallTime(now);
    final utcSeconds = now.toUtc().millisecondsSinceEpoch ~/ 1000;
    final offset =
        zone.offsetAt(utcSeconds).seconds - local.offsetAt(utcSeconds).seconds;
    final dayDiff = DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
    ).difference(DateTime.utc(here.year, here.month, here.day)).inDays;
    final day = dayDiff > 0
        ? l.dayTomorrow
        : dayDiff < 0
        ? l.dayYesterday
        : l.dayToday;
    final hours = offset / 3600;
    final offsetText =
        '${hours >= 0 ? '+' : '−'}'
        '${hours.abs() == hours.abs().roundToDouble() ? hours.abs().round() : hours.abs().toStringAsFixed(1).replaceAll('.', l.decimalSeparator)}';
    final sun = sunTimes(wall, city.latitude, city.longitude);
    final daylight = sun == null
        ? wall.hour >= 6 && wall.hour < 18
        : now.toUtc().isAfter(sun.$1) && now.toUtc().isBefore(sun.$2);
    String sunText(DateTime utc) {
      final w = zone.wallTime(utc);
      return formatTime(context, w.hour, w.minute);
    }

    return Container(
      width: width,
      height: ClockMetrics.worldCardHeight,
      decoration: BoxDecoration(
        color: ClockColors.card,
        borderRadius: BorderRadius.circular(ClockMetrics.cardRadius),
      ),
      child: Column(
        children: [
          const SizedBox(height: ClockMetrics.faceTop),
          SizedBox.square(
            dimension: ClockMetrics.face,
            child: AnalogFace(
              time: wall,
              day: daylight,
              now: now,
              clock: clock,
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              l.cityTime(
                city.name,
                formatTime(context, wall.hour, wall.minute),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: clockText(13, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.hoursOffset(day, offsetText),
            style: clockText(12, color: ClockColors.secondary),
          ),
          const SizedBox(height: 4),
          if (sun != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ClockSymbol(
                  'sunrise',
                  size: 12,
                  color: ClockColors.secondary,
                ),
                const SizedBox(width: 3),
                Text(
                  sunText(sun.$1),
                  style: clockText(11, color: ClockColors.secondary),
                ),
                const SizedBox(width: 10),
                const ClockSymbol(
                  'sunset',
                  size: 12,
                  color: ClockColors.secondary,
                ),
                const SizedBox(width: 3),
                Text(
                  sunText(sun.$2),
                  style: clockText(11, color: ClockColors.secondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// How the hands move (CLOCK-HANDS, silica-reference #95, measured): never in steps, all three
/// sweep continuously. macOS redraws the face about every 72 ms; the second hand advances
/// ~0.45 degrees per redraw (5.99 degrees per second), without a snap or an overshoot.
abstract final class HandMotion {
  static const Duration redraw = Duration(milliseconds: 72);

  /// The position within 12 hours, in seconds, of the wall time [t] [elapsed] later.
  static double position(DateTime t, Duration elapsed) =>
      ((t.hour % 12) * 3600 +
          t.minute * 60 +
          t.second +
          t.millisecond / 1000 +
          t.microsecond / 1e6 +
          elapsed.inMicroseconds / 1e6) %
      43200;
}

/// The analog face of a card: [ClockFacePainter] with all the hands sweeping continuously.
/// [time] is the wall time at the instant [now]; the face then follows [clock].
class AnalogFace extends StatefulWidget {
  const AnalogFace({
    super.key,
    required this.time,
    required this.day,
    this.now,
    this.clock,
  });
  final DateTime time;
  final bool day;
  final DateTime? now;
  final DateTime Function()? clock;

  @override
  State<AnalogFace> createState() => _AnalogFaceState();
}

class _AnalogFaceState extends State<AnalogFace> {
  Timer? _redraw;

  @override
  void initState() {
    super.initState();
    if (widget.clock != null) {
      _redraw = Timer.periodic(HandMotion.redraw, (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _redraw?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock = widget.clock;
    final now = widget.now;
    final elapsed = clock == null || now == null
        ? Duration.zero
        : clock().difference(now);
    return CustomPaint(
      painter: ClockFacePainter(
        seconds: HandMotion.position(widget.time, elapsed),
        day: widget.day,
      ),
    );
  }
}

/// The analog face: white with black numerals and hands by day, the opposite by night; the
/// second hand is thin and orange with an orange center dot.
class ClockFacePainter extends CustomPainter {
  ClockFacePainter({required this.seconds, required this.day});

  /// The position within 12 hours, in seconds.
  final double seconds;
  final bool day;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final face = day ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final ink = day ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    canvas.drawCircle(c, r, Paint()..color = face);
    for (var n = 1; n <= 12; n++) {
      final a = n * math.pi / 6 - math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: clockText(
            15 * r / 60,
            color: ink,
            weight: FontWeight.w600,
          ).copyWith(height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = c + Offset(math.cos(a), math.sin(a)) * (r * 0.78);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
    void hand(double fraction, double length, double width, Color color) {
      final a = fraction * 2 * math.pi - math.pi / 2;
      canvas.drawLine(
        c,
        c + Offset(math.cos(a), math.sin(a)) * length,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final secondHand = seconds % 60;
    final minuteHand = seconds / 60 % 60;
    final hourHand = seconds / 3600 % 12;
    hand(hourHand / 12, r * 0.5, 4 * r / 60, ink);
    hand(minuteHand / 60, r * 0.75, 4 * r / 60, ink);
    canvas.drawCircle(c, 3.5 * r / 60, Paint()..color = ink);
    hand(secondHand / 60, r * 0.86, 1.2 * r / 60, ClockColors.orange);
    canvas.drawCircle(c, 2.2 * r / 60, Paint()..color = ClockColors.orange);
  }

  @override
  bool shouldRepaint(ClockFacePainter old) =>
      old.seconds != seconds || old.day != day;
}

/// The land of the map (Natural Earth 1:110m, public domain): rings of longitude/latitude
/// pairs, loaded once from the asset.
Future<List<Float32List>>? _land;
Future<List<Float32List>> loadLand() => _land ??= () async {
  try {
    final json = jsonDecode(
      await rootBundle.loadString('assets/map/land.json'),
    );
    final scale = (json['scale'] as num?)?.toDouble() ?? 1;
    return [
      for (final ring in json['rings'] as List)
        Float32List.fromList([
          for (final v in ring as List) (v as num) / scale,
        ]),
    ];
  } on Object {
    // No map data: oceans and lines only.
    return <Float32List>[];
  }
}();

/// The map: an equirectangular world, black oceans and dark gray land, the time-zone lines,
/// the day/night line and a pin (orange dot, bold name, time) per city.
class WorldMapPainter extends CustomPainter {
  WorldMapPainter({
    required this.now,
    required this.pins,
    this.land = const [],
  });
  final DateTime now;
  final List<(City, String)> pins;
  final List<Float32List> land;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000000),
    );
    Offset point(double lat, double lon) =>
        Offset((lon + 180) / 360 * size.width, (90 - lat) / 180 * size.height);
    final ground = Paint()..color = const Color(0xFF3A3A3C);
    for (final ring in land) {
      final path = Path();
      for (var k = 0; k + 1 < ring.length; k += 2) {
        final p = point(ring[k + 1], ring[k]);
        k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), ground);
    }
    final zones = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    for (var lon = -172.5; lon <= 180; lon += 15) {
      final x = (lon + 180) / 360 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), zones);
    }
    // The subsolar point and the day/night line.
    final utc = now.toUtc();
    final n = utc.difference(DateTime.utc(utc.year)).inMinutes / 1440;
    final gamma = 2 * math.pi / 365 * n;
    final decl =
        0.006918 -
        0.399912 * math.cos(gamma) +
        0.070257 * math.sin(gamma) -
        0.006758 * math.cos(2 * gamma);
    final hours = utc.hour + utc.minute / 60 + utc.second / 3600;
    final subLon = -(hours - 12) * 15;
    final night = Path();
    final line = Path();
    final tanD = math.tan(decl);
    for (var i = 0; i <= 360; i++) {
      final lon = -180.0 + i;
      final lat =
          math.atan(
            -math.cos((lon - subLon) * math.pi / 180) /
                (tanD == 0 ? 1e-9 : tanD),
          ) *
          180 /
          math.pi;
      final p = point(lat, lon);
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
        night.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
        night.lineTo(p.dx, p.dy);
      }
    }
    // The night is on the side of the pole the sun leans away from.
    final nightTop = decl < 0;
    night
      ..lineTo(size.width, nightTop ? 0 : size.height)
      ..lineTo(0, nightTop ? 0 : size.height)
      ..close();
    canvas.drawPath(night, Paint()..color = const Color(0x66000000));
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (final (city, time) in pins) {
      final p = point(city.latitude, city.longitude);
      canvas.drawCircle(p, 4, Paint()..color = ClockColors.orange);
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${city.name}\n',
              style: clockText(12, weight: FontWeight.w600),
            ),
            TextSpan(text: time, style: clockText(11)),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Near the right edge the label goes on the left of the pin.
      final right = p.dx + 8 + tp.width <= size.width;
      tp.paint(canvas, p + Offset(right ? 8 : -8 - tp.width, -8));
    }
  }

  @override
  bool shouldRepaint(WorldMapPainter old) => true;
}

/// The sheet that adds a city: a 620 × 680 sheet with a round ×, a 604 × 36 search field with
/// the orange focus ring and plain 24 pt rows.
class AddCitySheet extends StatefulWidget {
  const AddCitySheet({
    super.key,
    required this.cities,
    required this.onPick,
    required this.onClose,
  });

  final List<City> cities;
  final ValueChanged<City> onPick;
  final VoidCallback onClose;

  @override
  State<AddCitySheet> createState() => _AddCitySheetState();
}

class _AddCitySheetState extends State<AddCitySheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final results = searchCities(widget.cities, _query.text);
    return Sheet(
      size: const Size(620, 680),
      onDismiss: widget.onClose,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RoundButton(
                  key: const ValueKey('close sheet'),
                  symbol: 'xmark',
                  size: 28,
                  onPressed: widget.onClose,
                ),
                Expanded(
                  child: Text(
                    l.addCity,
                    textAlign: TextAlign.center,
                    style: clockText(15, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
            const SizedBox(height: 10),
            ClockTextField(
              key: const ValueKey('city search'),
              controller: _query,
              placeholder: l.searchCities,
              width: 604,
              height: 36,
              autofocus: true,
              leading: const ClockSymbol(
                'search',
                size: 14,
                color: ClockColors.secondary,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (results.isNotEmpty) widget.onPick(results.first);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        l.noResults,
                        style: clockText(13, color: ClockColors.secondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemExtent: 24,
                      itemBuilder: (context, i) => _CityRow(
                        city: results[i],
                        onTap: () => widget.onPick(results[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatefulWidget {
  const _CityRow({required this.city, required this.onTap});
  final City city;
  final VoidCallback onTap;

  @override
  State<_CityRow> createState() => _CityRowState();
}

class _CityRowState extends State<_CityRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      key: ValueKey('city ${widget.city.zone}'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _hover ? ClockColors.orange : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          widget.city.country.isEmpty
              ? widget.city.name
              : '${widget.city.name}, ${widget.city.country}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: clockText(13),
        ),
      ),
    ),
  );
}
