# Stopwatch

Sessions CL-01, CL-02. Window at its default 1024 × 768. Geometry:
[diagrams/stopwatch-layout.svg](diagrams/stopwatch-layout.svg).

## Digital view (default)

| Item | Value |
| --- | --- |
| Time | "00:00.00" (minutes, seconds, hundredths; the hundredths separator follows the locale) |
| Digits | **thin** weight, white; one "0" inks 51 × 74 (≈ 104 pt type) |
| Block | 390 × 86, centred horizontally, top at y 87 |
| Laps table | 320 wide, x 352–672 |
| Table headers | Lap / Lap time / Total, `#565656`, ≈ 10 pt |
| Rows | ≈ **31** tall, full width, 1 pt `#343434` lines between rows |
| Row text | ≈ 13 pt: lap name regular, times semibold, white |
| Fastest lap | green `#5bd061` (as read; see note) |
| Slowest lap | red **`#ff4245`** |

- The lap in progress is the top row and its times update live.
- Fastest and slowest colours only appear once there are enough laps to compare
  (*provisional*: the exact threshold was not tested).
- Note on green: the text green was read as `#5bd061` before conversion; the button green
  below, read the same way, converts to `#30d159`. Use the same converted green for both.

## Buttons

Two capsules **150 × 28**, at y 690, 20 apart, centred under the table (x 352 and 522).

| Button | Role | Rest | Hover | Pressed |
| --- | --- | --- | --- | --- |
| Start | right, while stopped | **`#30d159`** | no change | **`#4cd669`** |
| Stop | right, while running | **`#ff4245`** | no change | **`#ff5858`** |
| Lap / Reset | left | `#2f2f2f` | no change | **`#434343`** |
| Lap, disabled (at rest, never started) | left | `#262626`, label `#5c5c5c` | no change | no change |

- Labels are white (except the disabled one); the whole capsule changes colour, with no
  outline and no scaling.
- The pressed fill appears in the first frame after button down (≤ 13 ms) and disappears
  in the first frame after button up: **no fade** in either direction.
- The action runs on **button up**: Stop becomes Start, and Lap becomes Reset, in the frame
  after the release. Releasing outside the button cancels it.

## Lap rows

No hover, no pressed look, no selection and no context menu.

## Timing

| Event | Time from button down on Start |
| --- | --- |
| Start turns into Stop | +16 ms (one frame) |
| Digits start counting | +122 ms |
| Digit repaint | every ≈ 27 ms (every second display frame at 75 Hz) |

Lap adds its row immediately.

## Analog view

View menu › analog stopwatch.

- Dial **360** diameter with tick marks and numerals 5–60, a small minutes sub-dial, an
  orange main hand and a blue lap hand; the digital time sits under the centre.
- The laps table is hidden in this view.
- Tick lengths, sub-dial size and hand widths: *unmeasured*.
