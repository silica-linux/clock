# Alarms

Sessions CL-01, CL-02.

## Empty state

- Centred in the window: an alarm-clock symbol (34 × 37, `#9a9a9a`) above the text
  `noAlarms` in bold, ≈ 22 pt type (230 × 25 ink), `#dddddd`.

## Alarm editor

A **514 × 391** sheet, fill `#272727`, centred on the window. While it is open the window
behind it is dimmed: window buttons gray, close disabled.

| Row | Control | Size |
| --- | --- | --- |
| Time | hour and minute fields, preset to the current time; the focused part has an orange fill (≈ `#c87524`); digits ≈ 29 pt cap height | — |
| Repeat | seven round day toggles, Monday first (`weekdayLetters`) | 32 × 32 each |
| Label | text field, placeholder `alarmDefaultLabel`; orange focus ring | 224 × 26 |
| Sound | pop-up, the default sound | 224 × 24 |
| Snooze | checkbox, on by default, orange when on | — |
| Snooze for | pop-up, 1–15 min, default **9 min** | 90 × 26 |
| Buttons | Cancel (gray) and **Save** (orange, default), bottom right | 71 × 26 each |

## Alarm list

Alarms are cards on the same grid as the world clocks ([diagrams/cards.svg](diagrams/cards.svg)).

| Item | Value |
| --- | --- |
| Card | **186 × 181**, pitch 202 |
| Content | time (light weight, ≈ 29 pt cap height), label, `repeatSummary`, `soundSummary` |
| Switch | hit area 68 × 30 |
| Switch on | track **`#fd9435`**, white knob |
| Switch off | track `#454545`, knob `#e3e3e3`; **all text on the card dims to gray** |

- Card actions: turn on / off (`toggleAlarm`) and delete (`deleteAlarm`).
- A non-repeating alarm turns itself off when it fires; snoozing turns it back on (see
  [alerts.md](alerts.md)).
