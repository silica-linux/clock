// The sounds an alarm or a timer can ring with: the entries of the freedesktop sound theme
// that make sense as an alert, by theme name. The first one is the default.

/// The theme name of the default sound.
const String defaultSoundId = 'alarm-clock-elapsed';

/// The sounds offered by the Sound pop-ups, as freedesktop sound theme names.
const List<String> soundIds = [
  defaultSoundId,
  'bell',
  'complete',
  'message-new-instant',
  'phone-incoming-call',
  'window-attention',
];

/// [id] when it is one of [soundIds], else the default (a settings file edited by hand, or
/// written by a newer version).
String validSound(Object? id) =>
    id is String && soundIds.contains(id) ? id : defaultSoundId;
