# Alerts: timer end and alarm firing

Session CL-02 (the timer end was also recorded in CL-01 with the same intervals).
Timelines: [diagrams/alert-timeline.svg](diagrams/alert-timeline.svg).

Both alerts are an ordinary **notification banner** at the top right of the screen; the
app shows no window, sheet or full-screen alert and does not come to the front.

## Banner

| Item | Value |
| --- | --- |
| Size | 344 × 58 |
| Position | top right of the screen, top edge at y 46 |
| Content | app icon, app name in bold, then the timer name or the alarm label as the body |
| On hover | a × at the top left and an options button with a chevron |
| Timer actions | show details, restart, **stop**, close |
| Alarm actions | show details, **stop**, **snooze**, close |
| Lifetime | stays until acted on |

The options menu itself was not opened (*unmeasured*); its actions are known from the
accessibility tree.

## Sound

- Repeated bursts, each 1.4–1.9 s above threshold and made of decaying taps, one burst
  every 2.6–2.9 s, **until stopped**.
- Peak ≈ −9.4 dBFS at system volume 88 % (same for timer and alarm).
- Only the level envelope was measured; the sound itself is ours to design.

## Timer end

Times from the frame where the window resets.

| Event | Time |
| --- | --- |
| Last digit change (00:00) | −922 ms |
| Window back to the picker, preset to **the timer's own duration**, one frame | **0** |
| Label field and sound pop-up of the picker filled in | +26 / +120 ms |
| Banner starts sliding in | **+147 ms** |
| Sound starts | ≈ **+290 ms** |
| Banner settled | ≈ **+630 ms** |

After stopping from the banner: the banner slides out in ≈ 160 ms and the sound ends
within 80 ms. The finished timer is added to Recent.

## Alarm firing

Times from the minute change of the system clock.

| Event | Time |
| --- | --- |
| Clock reaches the alarm minute | 0 |
| Card switch turns **off** and the card dims, one frame, no animation | +13 ms |
| Banner starts sliding in | +227 ms |
| Sound starts | **+389 ms** |
| Banner settled | ≈ +707 ms |

- **Snooze**: banner out in ≈ 190 ms, sound stops within ≈ 60 ms, the card switch turns
  back **on** (the card shows nothing else about the snooze). The alarm fires again
  exactly one snooze length later (60.0 s with a 1 min setting): switch off, banner
  +187 ms after it, sound +352 ms after it, same banner as before.
- **Stop**: banner out in ≈ 150 ms, sound stops, the switch stays **off**.
- Repeating alarms (repeat days set): *unmeasured*; expected to stay on after firing
  (*provisional*).
