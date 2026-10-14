# World clock

Session CL-01. Measured on two test cities, one in daylight and one at night.

## Map

- The upper part of the section is a world map 1024 × 500 pt (full window width): black
  oceans, dark gray land, thin vertical time-zone lines, and the day/night boundary drawn as
  a thin light curve.
- Each city is a pin: an orange dot **`#ff9230`**, its name in bold white and its local time
  under the name.

## Cards

Card grid: [diagrams/cards.svg](diagrams/cards.svg).

| Item | Value |
| --- | --- |
| Card | **186 × 222**, corner radius ≈ 12, fill `#323232` |
| Row | horizontal, first card at x 15, pitch **202** (16 gap) |
| Analog face | **120** diameter, centred horizontally, 20 below the card top |

- **Day and night faces.** A city in daytime has a white face with black numerals and
  hands; a city at night has a black face with white numerals and hands.
- Numerals 1–12 bold, ≈ 15 pt type ("12" inks 15 × 11). Hour and minute hands are thick;
  the second hand is thin and orange, with an orange dot at the centre.
- Under the face: "City, time" in white semibold ≈ 13 pt (`cityTime`), then the day and hour
  offset in gray (`hoursOffset`, e.g. "Today, +3 h"), then sunrise and sunset times with
  small icons, in gray.
- Sunrise / sunset icon shapes and the precise text positions: *unmeasured*.

## Adding and removing

- "+" opens a sheet of **620 × 680**: a round × close button at the top left, a search
  field 604 × 36 with an orange focus ring, and the matches as plain rows ≈ 24 pt tall
  showing "City, Country".
- Choosing a row adds a card at the end of the row and a pin on the map.
- A card's context menu has a single action: remove the clock (`removeClock`).
