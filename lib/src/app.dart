// The window of the Clock app: the toolbar over the section, the language from the system
// (English source, Italian translation), the active/inactive state from Ossido
// (`flutter/lifecycle`) and the shortcuts ⌘1–⌘4.

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'alarms_view.dart';
import 'controller.dart';
import 'model/timers.dart';
import 'stopwatch_view.dart';
import 'style.dart';
import 'timers_view.dart';
import 'toolbar.dart';
import 'widgets.dart';
import 'world_view.dart';

/// The system languages resolved against ours, English when none matches.
Locale resolveLocale(List<Locale> preferred) =>
    basicLocaleListResolution(preferred, AppLocalizations.supportedLocales);

class ClockApp extends StatefulWidget {
  const ClockApp({super.key, required this.controller, this.locale});
  final ClockController controller;

  /// A fixed language (tests); null follows the system.
  final Locale? locale;

  @override
  State<ClockApp> createState() => _ClockAppState();
}

class _ClockAppState extends State<ClockApp> with WidgetsBindingObserver {
  late Locale _locale =
      widget.locale ?? resolveLocale(PlatformDispatcher.instance.locales);
  bool _active = _isActive(WidgetsBinding.instance.lifecycleState);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: (state) => setState(() => _active = _isActive(state)),
  );

  static bool _isActive(AppLifecycleState? s) =>
      s == null || s == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle;
    widget.controller.start();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (widget.locale != null || locales == null) return;
    setState(() => _locale = resolveLocale(locales));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    super.dispose();
  }

  /// The app is always dark, whatever the system appearance is (CL-01: the measured light and
  /// dark captures are identical): the toolbar controls, menus and alerts of silica_ui and
  /// the window buttons, bar and shadow Ossido draws take the dark look.
  @override
  Widget build(BuildContext context) => SilicaAppearanceScope(
    appearance: SilicaAppearance.dark,
    child: Localizations(
      locale: _locale,
      delegates: const [
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      child: WindowActive(
        active: _active,
        child: DefaultTextEditingShortcuts(
          child: ColoredBox(
            color: ClockColors.background,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) =>
                      ClockWindow(controller: widget.controller),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ClockWindow extends StatefulWidget {
  const ClockWindow({super.key, required this.controller});
  final ClockController controller;

  @override
  State<ClockWindow> createState() => _ClockWindowState();
}

class _ClockWindowState extends State<ClockWindow> {
  final GlobalKey<AlarmsViewState> _alarms = GlobalKey();
  bool _addingCity = false;
  OverlayEntry? _menu;

  ClockController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    c.removeListener(_changed);
    _menu?.remove();
    super.dispose();
  }

  void _add(Offset at) {
    switch (c.section) {
      case Section.world:
        setState(() => _addingCity = true);
      case Section.alarms:
        _alarms.currentState?.addAlarm();
      case Section.timers:
        _presets(at);
      case Section.stopwatch:
        break;
    }
  }

  void _presets(Offset at) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final l = AppLocalizations.of(context);
    String name(int minutes) =>
        minutes >= 60 ? l.hours(minutes ~/ 60) : l.minutes(minutes);
    _menu?.remove();
    _menu = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: MenuHost(
          // The menu opens below the "+" and ends at its right edge.
          anchor: at - const Offset(180, 0),
          opaque: true,
          entries: [
            MenuAction(
              l.presets,
              submenu: [
                for (final m in timerPresetMinutes)
                  MenuAction(
                    name(m),
                    onSelected: () => c.startTimer(Duration(minutes: m)),
                  ),
              ],
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
    c.strings = AppLocalizations.of(context);
    final section = switch (c.section) {
      Section.world => WorldView(controller: c),
      Section.alarms => AlarmsView(key: _alarms, controller: c),
      Section.stopwatch => StopwatchView(controller: c),
      Section.timers => TimersView(controller: c),
    };
    // The ⌘ shortcuts (⌘1–⌘4 for the sections) are the menu bar's: SilicaMenuBar binds them.
    return SilicaMenuBar(
      menus: menus(AppLocalizations.of(context)),
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(child: section),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ClockToolbar(
                section: c.section,
                onSection: c.select,
                centerOffset: (width) => c.hasTimerList
                    ? ClockMetrics.timerSidebar +
                          (width - ClockMetrics.timerSidebar) / 2
                    : width / 2,
                onAdd: c.section == Section.stopwatch ? null : _add,
              ),
            ),
            if (_addingCity)
              Positioned.fill(
                child: AddCitySheet(
                  cities: c.cities,
                  onPick: (city) {
                    c.addCity(city);
                    setState(() => _addingCity = false);
                  },
                  onClose: () => setState(() => _addingCity = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The menus in Silica's menu bar (silica-desktop#175): the app menu, File with the recent
  /// timers and Close, Edit (every item disabled, as measured: the app has nothing to edit),
  /// View with the four sections and the stopwatch style, Window and Help.
  List<PlatformMenuItem> menus(AppLocalizations l) {
    final recents = c.settings.recents;
    final names = [
      l.viewWorld,
      l.sectionAlarms,
      l.sectionStopwatch,
      l.sectionTimers,
    ];
    return [
      SilicaMenus.app(l.appTitle),
      SilicaMenu(
        label: l.menuFile,
        menus: [
          PlatformMenuItemGroup(
            members: [
              SilicaMenu(
                label: l.startRecentTimer,
                menus: [
                  if (recents.isEmpty)
                    SilicaMenuItem(label: l.noRecentTimers, enabled: false)
                  else
                    for (final r in recents)
                      SilicaMenuItem(
                        label: r.label.isEmpty
                            ? formatCountdown(r.duration)
                            : '${formatCountdown(r.duration)} · ${r.label}',
                        onSelected: () {
                          c.select(Section.timers);
                          c.startTimer(r.duration, label: r.label);
                        },
                      ),
                ],
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              const SilicaMenuItem.system(SilicaMenuItemRole.close),
              // One window: there is nothing more to close; the item stays, as measured.
              SilicaMenuItem(label: l.closeAll, enabled: false),
            ],
          ),
        ],
      ),
      SilicaMenus.edit(l.menuEdit),
      SilicaMenu(
        label: l.menuView,
        menus: [
          PlatformMenuItemGroup(
            members: [
              for (final s in Section.values)
                SilicaMenuItem(
                  label: names[s.index],
                  checked: s == c.section,
                  shortcut: SingleActivator(
                    LogicalKeyboardKey(
                      LogicalKeyboardKey.digit1.keyId + s.index,
                    ),
                    meta: true,
                  ),
                  onSelected: () => c.select(s),
                ),
            ],
          ),
          // The stopwatch is digital only for now: both styles are listed, as measured, but
          // the analog one does not exist yet.
          PlatformMenuItemGroup(
            members: [
              SilicaMenuItem(
                label: l.stopwatchDigital,
                checked: true,
                enabled: false,
              ),
              SilicaMenuItem(label: l.stopwatchAnalog, enabled: false),
            ],
          ),
        ],
      ),
      SilicaMenus.window(l.menuWindow),
      SilicaMenus.help(l.menuHelp),
    ];
  }
}
