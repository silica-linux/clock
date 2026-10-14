# Timers

Sessions CL-01, CL-02.

## Picker (no timer running)

- Three wheels for hours, minutes and seconds (hit areas 119 × 86 each), shown together as
  "00:15:00" in thin light gray `#dddddd` digits (block 387 × 73).
- Small gray unit labels above the wheels (`unitHours`, `unitMinutes`, `unitSeconds`),
  `#989898`.
- Below: a label field (placeholder `timerLabel`) and a sound pop-up (200 × 24, default
  sound).
- Buttons Cancel (disabled while idle) and Start.
- Clicking a wheel and typing digits sets that wheel.

## Presets

- The toolbar "+" menu has a Presets submenu: 1, 2, 3, 4, 5, 10, 15, 20, 30 and 45 minutes,
  1 hour and 2 hours.
- Choosing a preset **starts it immediately**.

## Running timer

- A **320 pt** list appears on the left of the window:
  - the active timer as a card 300 × 92, fill `#48484a`: remaining time in white, its
    duration ("1 min"), and a round orange pause button with a progress ring;
  - a Recent header and the recent timers below it (time in gray, round green start
    button).
- Main area: a ring **360** across, stroke **6**, orange **`#ff9230`** on a `#3b3b3d` track,
  emptying from the top. Inside it: a bell with the end time, the remaining time in white
  (digits 73 tall), the label and the sound pop-up.
- Buttons Cancel and **Pause** (orange).
- The display repaints twice a second: the digits change first, the ring about 215 ms
  later.

## Recent timers

- Finished timers are listed under Recent; each row can be deleted (trash action).
- File › recent timers lists them as well and starts the chosen one.

What happens when a timer reaches zero: [alerts.md](alerts.md).
