# Measured parity

Only measured metrics (screenshots of Clock inside Ossido, headless, against the reference
shots of the same section and window size), never estimates. Every row cites the request the
reference comes from.

| Area | Metric | Value | Request | Measured on |
| --- | --- | --- | --- | --- |
| Toolbar | section control: size, center | 378 × 36, centered at x 512 (672 with the timer list) | CL-01 | 2026-10-14 |
| Stopwatch | digits ink box | 316–707 × 88–173 against 316–706 × 87–172 | CL-01 | 2026-10-14 |
| Timers | picker digits ink box (x) | 319–704 against 318–704 | CL-01 | 2026-10-14 |
| World | map band, cards top, card pitch | map y 52–531, cards at y 546 flush with the bottom, pitch 202: as the reference | CL-01 | 2026-10-14 |
| World | Reykjavík pin | on the reference position | CL-01 | 2026-10-14 |
| Alarms | ringing: switch, notification, sound | at once, 227 ms, 389 ms (widget test with fake time) | CL-02 | 2026-10-14 |
| Timers | end: picker, notification, sound | at once, 147 ms, 290 ms (widget test with fake time) | CL-02 | 2026-10-14 |
| Alarms | Snooze of 1 minute | rings again after 60.0 s | CL-02 | 2026-10-14 |

Conditions: 1024 × 768 window, Ossido without a window (`--headless`, 2560 × 1440), the cities
Atlantic/Reykjavik and Pacific/Auckland, comparison on the same window coordinates.

Known differences:

- Inside Ossido the window shows about 761 pt of content instead of 768, so the bottom
  capsules sit 6 pt higher than in the widget tests (y 690); it looks like the session or the
  embedder, not the app.
- The analog view of the stopwatch (from the global menu) is missing.
- Country and city names are in English only; the sound list has only the default sound.
- The minimum and maximum window size are not enforced by the embedder yet.
