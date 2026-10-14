# Clock · specification

What Clock does and how it behaves. Where a value comes from a measurement of the reference
there is the request code (`CL-xx`); values still waiting for one are marked *provisional* in
the code.

The interface texts are localized (`lib/l10n`): English is the source language, Italian the
first translation. The wording is our own.

## Window

- 1024 × 768 by default (CL-01), at least 690 × 640 (CL-13, `SilicaWindow.setSizeLimits`). The toolbar is unified with the window: the section control
  centered, a "+" at the right (inset 8).
- **Section control**: 378 × 36, four segments (World, Alarms, Stopwatch, Timers); the
  pill slides to the chosen segment in 300 ms (ease-out cubic). With the timer list on screen
  the control centers on the content to the right of the list; when it does not fit (at the
  minimum width with the timer list) it becomes a pop-up button with the same four entries.
- The "+" acts on mouse down (CL-02) and is hovered with `#515152`: in World it opens
  Add a City, in Alarms the new-alarm editor, in Timers the menu of presets (1, 2, 3, 4, 5, 10,
  15, 20, 30, 45, 60, 120 minutes). It is hidden in Stopwatch.
- The window has an inactive state (dimmed toolbar) following the Silica window lifecycle.

## Commands and shortcuts

| Command | Shortcut |
| --- | --- |
| World, Alarms, Stopwatch, Timers | ⌘1, ⌘2, ⌘3, ⌘4 |

The chosen section is remembered across launches.

## World

- A world map with land from Natural Earth (public domain), the night side shaded by the
  terminator of the current time, a pin per city.
- One card per city (186 × 222, pitch 202) along the bottom: analog face, name, offset from
  the local time and day ("Today, +1 h"). Its context menu has Remove Clock.
- **Add a City**: a sheet with a search field; cities come from the system time-zone tables
  (`zone1970.tab`, `zone.tab`, `iso3166.tab`), names starting with the query first.
- Time zones are read from the system TZif files, including the POSIX rule of their footer;
  names outside the database are refused.

## Alarms

- Cards of 186 × 181: time, label, repeat summary ("Repeat: Every day", "Weekdays", "Weekends", the
  days), switch. An empty list shows "No Alarms".
- **Editor** (sheet): time, repeat (one toggle per weekday), label, sound, snooze (on by
  default) and the snooze length, a pop-up of 1–15 minutes (default 9). Cancel and Save; an
  existing alarm also has Delete.
- **Ringing** (CL-02): a one-off alarm turns its switch off at once; the notification
  ("Clock", the label or "Alarm") appears after 227 ms with Stop and Snooze; the sound
  (freedesktop theme `alarm-clock-elapsed`) starts after 389 ms and repeats until stopped or
  for five minutes. Stop leaves the switch off. Snooze stops the sound, turns the switch back
  on and rings again after the snooze length.
- Alarms, snoozes and timer ends are armed with precise timers; a 250 ms check catches the
  rest (a suspended machine, a changed clock).

## Stopwatch

- Digits `mm:ss,cc` (the decimal separator of the locale); past an hour `h:mm:ss,cc`.
- Two capsules (150 × 28, 20 apart): Lap/Reset on the left, Start/Stop on the right (green to
  start, red to stop). The lap table always shows its header; the fastest lap in green, the
  slowest in red.

## Timers

- **Picker**: hours, minutes and seconds (default 15 minutes), label, sound, Start.
- **Running**: a ring of 360 × 360 that empties as time passes, the time left, the end time,
  Pause/Resume and Cancel.
- **List** (on the left, once a timer runs or there are recents): running timers, then recent
  ones (newest first, no duplicates) to start again with one click.
- **End** (CL-02): the timer leaves the list and the view goes back to the picker; the
  notification ("Clock", the label or "Timer done") appears after 147 ms with Stop and
  Restart; the sound starts after 290 ms. Restart runs the same timer again.

## Buttons (CL-02)

- Capsules have no hover; pressed, they take the pressed fill in the first frame (green
  `#4cd669`, red `#ff5858`, gray `#434343`) and act on release.

## Settings

`$XDG_CONFIG_HOME/clock/settings.json`: cities, alarms, recent timers, the chosen section. A
broken file starts empty.

## System

- Notifications through `org.freedesktop.Notifications` (silica-daemon) over the embedder's
  `silica/dbus` channel; actions come back as `ActionInvoked` signals. Without a session bus
  the app keeps working without banners.
- Sound through `canberra-gtk-play`, falling back to `paplay` with the theme file.
