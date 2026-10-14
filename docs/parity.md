# Measured parity

Only measured metrics (screenshots of Clock inside Ossido, headless, against the reference
shots of the same section and window size), never estimates. Every row cites the request the
reference comes from. Coordinates are window-relative, in points.

| Area | Metric | Value | Request | Measured on |
| --- | --- | --- | --- | --- |
| Toolbar | section control ink, no timer list | 327–702, as the reference | CL-01 · cl02, cl05 | 2026-10-14 |
| Toolbar | section control with the timer list | centered 3 pt right of the content area (reference 487–862) | CL-06 | 2026-10-14 |
| Stopwatch | digits ink box | 317–706 × 87–172 against 316–705 × 87–172 | CL-01 · cl02-stopwatch-dark | 2026-10-14 |
| Stopwatch | Start capsule | 522–671 × 690–717, as the reference | CL-01 · cl02-stopwatch-dark | 2026-10-14 |
| Timers | picker units row | 281–290, as the reference | CL-05 · cl05-timer-picker | 2026-10-14 |
| Timers | picker digits ink box | 317–706 × 321–393 against 317–705 × 321–394 | CL-05 · cl05-timer-picker | 2026-10-14 |
| Timers | label and sound pop-up | label text y 430 against 431; pop-up 412–611 × 453–475 against 412–611 × 453–476 | CL-05 · cl05-timer-picker | 2026-10-14 |
| Timers | capsules | 690–717, as the reference | CL-05 | 2026-10-14 |
| World | map band, cards | map y 52–531, cards from y 546, pitch 202: as the reference | CL-11 · cl11-world | 2026-10-14 |
| Alarms | card box | 15–200 × 67–247, as the reference | CL-09 · cl09-alarm-list | 2026-10-14 |
| Alarms | card time ink ("03:11") | 41–126 × 103–131 against 40–124 × 101–131 | CL-09 · cl09-alarm-list | 2026-10-14 |
| Alarms | label, repeat, sound rows | 142–150, 159–171, 176–185 against 142–152, 159–171, 176–186 | CL-09 · cl09-alarm-list | 2026-10-14 |
| Alarms | switch | 46–99 × 197–220, knob 32 × 20: as the reference | CL-09 · cl09-alarm-list | 2026-10-14 |
| Window | minimum size | a corner drag stops at 690 × 640 | CL-13 | 2026-10-14 |
| Alarms | ringing: switch, notification, sound | at once, 227 ms, 389 ms (widget test with fake time) | CL-02 | 2026-10-14 |
| Timers | end: picker, notification, sound | at once, 147 ms, 290 ms (widget test with fake time) | CL-02 | 2026-10-14 |
| Alarms | Snooze of 1 minute | rings again after 60.0 s (widget test) | CL-02 | 2026-10-14 |

Conditions: 1024 × 768 window, Ossido without a window (`--headless`, 2560 × 1440), the cities
Atlantic/Reykjavik and Pacific/Auckland, the alarm of the reference (03:11, "Prova CL"),
comparison on the same window coordinates. Captures are taken twice a second apart: the first
frame after a quiet period can still show the window opening at 98 % scale.

Known differences:

- The analog view of the stopwatch (from the global menu) is missing.
- Country and city names are in English only; the sound list has only the default sound.
- Our Italian unit labels and texts are our own wording ("s", "Predefinito").
