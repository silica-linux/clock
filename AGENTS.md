# AGENTS.md

Clock is a Silica app: the rules of `silica-desktop/AGENTS.md` apply (clean-room, assets, never
crash, everything is a command, measured parity, English everywhere). On top of them:

## Clean-room

- Observations of the reference system live in the private repository `silica-reference`
  (`clock.md`, request CL-01), never here. Here only the request code and the measured metrics
  are cited.
- Specification, comments and interface texts are written in our own words, in English, with
  the Italian translation in `lib/l10n/app_it.arb`. No texts copied from the reference.
- Measured numbers (sizes, colors, timings) can be used in code, with the request they come
  from.

## Work

- Before every commit: `dart format`, `flutter analyze --fatal-infos`, `flutter test`,
  `tool/check_assets.sh`. One task per commit.
- Localization: every user-visible string goes in `lib/l10n/app_en.arb` (source) and
  `app_it.arb`; `flutter gen-l10n` regenerates `lib/l10n/gen/` (committed).
- For visual work: screenshots inside Ossido (`ui.screenshot`), comparison with the reference,
  and the metric in `docs/parity.md` only if measured.
- `silica_ui` is used from a tag (`ref` in `pubspec.yaml`); a widget that other apps need too
  goes into `silica-ui`, not here.
- Never crash: a missing time zone database, an unreadable settings file or a missing
  notification server are normal cases.
- Issues and milestones: https://github.com/orgs/silica-os/projects/1.
