// Alerts outside the window: a freedesktop notification (org.freedesktop.Notifications, served
// by silica-daemon) over the embedder's `silica/dbus` channel, and a ringing sound from the
// freedesktop sound theme (`alarm-clock-elapsed`) repeated until stopped. Without a session bus
// or a player the app keeps working: the alert is simply quieter.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _dbus = MethodChannel('silica/dbus', JSONMethodCodec());

const String _destination = 'org.freedesktop.Notifications';
const String _path = '/org/freedesktop/Notifications';

/// A notification the app can show and replace.
class Notifier {
  Notifier({Future<Object?> Function(String, Object?)? invoke})
    : _invoke = invoke ?? _dbus.invokeMethod<Object?>;

  final Future<Object?> Function(String method, Object? args) _invoke;
  final Map<int, void Function(String action)> _handlers = {};
  int? _subscription;
  bool _listening = false;

  /// Shows a notification with actions (`[key, label, …]`); `onAction` gets the key, or
  /// `closed` when it goes away. Returns its id, or null without a notification server.
  Future<int?> show({
    required String app,
    required String summary,
    required String body,
    List<String> actions = const [],
    String icon = 'alarm-clock',
    bool persistent = true,
    void Function(String action)? onAction,
  }) async {
    try {
      await _listen();
      final reply = await _invoke('call', {
        'bus': 'session',
        'destination': _destination,
        'path': _path,
        'interface': _destination,
        'method': 'Notify',
        'signature': 'susssasa{sv}i',
        'args': [
          app,
          0,
          icon,
          summary,
          body,
          actions,
          {'urgency': 2, 'category': 'alarm', 'resident': persistent},
          persistent ? 0 : -1,
        ],
      });
      final id = reply is List && reply.isNotEmpty && reply.first is int
          ? reply.first as int
          : null;
      if (id != null && onAction != null) _handlers[id] = onAction;
      return id;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Closes a notification.
  Future<void> close(int id) async {
    _handlers.remove(id);
    try {
      await _invoke('call', {
        'bus': 'session',
        'destination': _destination,
        'path': _path,
        'interface': _destination,
        'method': 'CloseNotification',
        'signature': 'u',
        'args': [id],
      });
    } on PlatformException {
      // Already gone.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  Future<void> _listen() async {
    if (_listening) return;
    _listening = true;
    _dbus.setMethodCallHandler((call) async {
      if (call.method != 'signal') return null;
      final a = call.arguments;
      if (a is! Map || a['id'] != _subscription) return null;
      final args = a['args'];
      if (args is! List || args.isEmpty || args.first is! int) return null;
      final id = args.first as int;
      final handler = _handlers[id];
      if (handler == null) return null;
      if (a['member'] == 'ActionInvoked' && args.length > 1) {
        handler('${args[1]}');
      } else if (a['member'] == 'NotificationClosed') {
        _handlers.remove(id);
        handler('closed');
      }
      return null;
    });
    try {
      final id = await _invoke('subscribe', {
        'bus': 'session',
        'interface': _destination,
        'path': _path,
      });
      if (id is int) _subscription = id;
    } on PlatformException {
      // No signals: actions only through the window.
    } on MissingPluginException {
      // Outside Silica.
    }
  }
}

/// The ringing sound: the theme sound every [interval] until [stop].
class Ringer {
  Ringer({this.interval = const Duration(milliseconds: 2400)});

  final Duration interval;
  Timer? _timer;
  int _rings = 0;

  bool get ringing => _timer != null;

  void start({Duration limit = const Duration(minutes: 5)}) {
    if (_timer != null) return;
    _rings = 0;
    final max = limit.inMilliseconds ~/ interval.inMilliseconds;
    _play();
    _timer = Timer.periodic(interval, (_) {
      if (++_rings >= max) {
        stop();
        return;
      }
      _play();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static void _play() {
    // canberra plays the theme sound by name; paplay plays the file of the freedesktop theme.
    Process.run('canberra-gtk-play', ['-i', 'alarm-clock-elapsed']).then((
      result,
    ) {
      if (result.exitCode == 0) return;
      _fallback();
    }, onError: (_) => _fallback());
  }

  static void _fallback() {
    const file = '/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga';
    if (!File(file).existsSync()) return;
    Process.run('paplay', [file]).then((_) {}, onError: (_) {});
  }
}
