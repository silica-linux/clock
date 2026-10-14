# Window

Sessions CL-01, CL-02.

## Appearance

- Always dark. Captures with the system in light and in dark appearance are identical pixel
  for pixel.
- Window background **`#1e1e1e`**.
- The app is a port of a phone/tablet app; its controls follow that family's look (capsule
  buttons, wheels, switches) rather than the desktop control set.

## Size

| Item | Value |
| --- | --- |
| Default and restored size | **1024 × 768** |
| Minimum | **690 × 640** |
| Maximum | the screen; full screen is allowed (green button active) |
| Toolbar | 52 pt |
| Window buttons | hit areas 16 × 16 at x 18, 41, 64, y 18 |

## Section switcher

The four sections (World, Alarms, Stopwatch, Timers) are a segmented control placed in the
toolbar. ⌘1–⌘4 select them in that order.

| Part | Value |
| --- | --- |
| Track | **378 × 36**, full capsule, fill `#3d3d3d` |
| Track rim | top `#727274`, bottom `#626262`, outer edge `#0b0b0b` (a glass edge) |
| Segments | 95, 94, 95, 94 pt wide (hit areas 36 tall) |
| Selected pill | ≈ **28 pt** tall, inset 4 pt, `#525252`–`#555555` |
| Labels | white, semibold, ≈ 13 pt |

- Placement: the control is centred on the window when nothing else is in the toolbar's
  way. Once the timer list (a 320 pt column on the left, see [timer.md](timer.md)) exists,
  the control is centred on the area to its right, and it stays there in every section.
- At the minimum window width the control is replaced by a pop-up button showing the
  current section with an up/down chevron, at the top right.
- Hovering a segment highlights it (colour *unmeasured*).
- Right end of the toolbar: a round 36 pt "+" button. It adds a city, an alarm or a timer
  depending on the section; there is none in the stopwatch section.
  - "+" fill on hover goes from `#3d3d3e` to `#515152`.
  - The "+" button acts on **button down** (its sheet is already open while the button is
    still held).

### Switching timing

Times from button down on a segment, three switches recorded:

| Event | Time |
| --- | --- |
| Pill starts moving | +25 to +52 ms |
| Pill settled | ≈ 300–350 ms, decelerating |
| Content replaced | +92 to +132 ms (≈ 30–60 ms after button up), in **one frame**, no crossfade |

## Inactive window

- Window buttons gray `#444444`.
- Selected segment `#464646` (from `#525252`); segment labels turn gray.
- The green Start button turns gray (`#6a6a6a` measured along the label row).

## Menus

| Menu | Content |
| --- | --- |
| App menu | standard items |
| File | recent timers › (starts one), Close ⌘W, Close All ⌥⌘W |
| Edit | standard items |
| View | World ⌘1, Alarms ⌘2, Stopwatch ⌘3, Timers ⌘4 · digital stopwatch (default, checked) / analog stopwatch |
| Window, Help | standard items |
