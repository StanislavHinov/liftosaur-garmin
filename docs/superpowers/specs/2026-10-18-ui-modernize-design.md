# Modern UI like the Liftosaur Apple Watch app — design

> **Superseded.** This is the original design, kept for its reasoning. The app has changed since (touch-only and rectangular watches, the app name, the shared Ticker, the Sync clock). Current behavior: README.md and AGENTS.md.


## Goal

Restyle every screen of the Forerunner 170 app to look like the Liftosaur Apple Watch app (`ios/LiftosaurWatch` in the Liftosaur repo): dark purple cards, a purple accent, orange reps and green weight. Workout logic, sync, buttons and menus do not change, except one new shortcut on the "All sets done" screen.

This replaces the "Screens and buttons" theme paragraph and the Active set sketch in `2026-10-18-liftosaur-garmin-design.md`. Button mapping there still holds.

## Palette

From `LiftosaurColor.swift`. The watch draws 16-bit color, so the shown colors are the nearest 16-bit values.

| Name | Hex | Use |
| --- | --- | --- |
| BG | `#000000` | background |
| CARD | `#252034` | cards, ring track |
| BOX | `#332D42` | value boxes |
| PILL_GREY | `#393248` | secondary pills |
| DOT_OFF | `#453D58` | sets not done |
| PURPLE | `#8356F6` | check and START pills, selected box border, rest ring |
| PURPLE_LIGHT | `#A48BFA` | rest time text |
| GREEN | `#2BDC9B` | weight, completed sets, rest over, values at target |
| ORANGE | `#FFB86B` | reps |
| YELLOW | `#FFD820` | "log on phone", "workout to sync" |
| RED | `#FF8066` | errors, "sets not synced" |
| TEXT | `#FFFFFF` | primary text |
| GREY | `#A4B0BC` | secondary text |

## Shared drawing helpers

`Theme.mc` keeps `clear`, `center`, `title` and the banner, and gains:

- `pill(dc, y, label, color)`: a rounded bar about 120 px wide and 36 px high on the 390 px screen (sizes scale with screen width), with a bold upper-case label. It is not a button. It shows what Start does.
- `box(dc, x, y, w, h, text, color, selected)`: a rounded `BOX` rectangle with a large number. A selected box has a 3 px `PURPLE` border.
- `card(dc, x, y, w, h)`: a rounded `CARD` rectangle.
- `dots(dc, x, y, sets)`: one 9 px dot per set: `GREEN` filled when completed, a white outline for the current set, `DOT_OFF` filled otherwise. The dot gap shrinks so the row never exceeds 40% of the screen width.
- `restRing(dc, fraction, over)`: a 7 px ring at the screen edge. The `CARD` track is drawn in full. The `PURPLE` arc starts at 12 o'clock and covers `fraction` of the circle clockwise. When `over` is true, the whole ring is `GREEN`.

## Display rules module

A new module `Look.mc` holds every display decision that can be tested without a screen:

- `restText(rest, nowSec)`: `null` without rest; `"0:42 / 1:30"` while resting; `"+0:12 / 1:30"` after the rest ends.
- `restFraction(rest, nowSec)`: remaining / duration, from 1.0 down to 0.0.
- `showPlates(entry, set)`: true when `entry["equipment"]` is `"barbell"` and `Weight.platesText(set["plates"])` is not empty.
- `infoLine(entry, set)`: the parts "Warmup", "AMRAP" and "Plates: …" joined with " · ", or an empty string.
- `summary(workout, startMs, nowMs)`: completed set count, total volume (reps × weight of completed sets, in the workout unit) and the elapsed time from the workout `startTime` to now as `H:MM:SS`, paused time included (the same span Liftosaur shows).

`SlimWorkout.slim` keeps `"equipment"` on each entry so `showPlates` can read it.

## Screens

### Active set

```text
        0:42 / 1:30            (rest line, light purple)
        Bench Press
     Set 2/5  ● ◯ ● ● ●
   [  3  ]  ×  [ 136.5 lb ]    (reps orange, weight green)
   Warmup · Plates: 45/2.5/1.25
            ( ✓ )              (purple check pill)
```

- The rest ring runs around the edge while resting, as `Theme.restRing`.
- Rest over: one buzz, as now. The ring turns solid green, and the rest line shows overtime in `GREEN`.
- No rest: no rest line, no ring. The rest of the layout moves up by about 5% of the screen height.
- The exercise name keeps the current rule: one line in `FONT_SMALL`, else two wrapped lines in `FONT_TINY`.
- The set row is "Set N/M" in `GREY`, followed by the dots.
- The reps box shows `ORANGE` digits, plus "+" for AMRAP. The weight box shows `GREEN` digits with a small unit. Either value turns white when it differs from the target. The selected field (reps or weight) has the purple border. Without a weight there is only the reps box, centered.
- The info line comes from `Look.infoLine`, in `GREY`. Plates are in white.
- The status suffix "· Updating..." or "· may change" stays at the end of the set row.
- A set that needs the phone replaces the boxes with "Log this set on phone" in `YELLOW` and "BACK to skip" in `GREY`. It shows no pill.
- The offline banner ("Offline · N queued" or a notice) always shows at 89% height, below the pill, so it never meets the exercise name.

### All sets done

- "All sets done" in `GREEN`, "Total time H:MM:SS" in `GREY`, then a card with "N sets · V kg" (count in `ORANGE`, volume in `GREEN`), then a `FINISH` pill and "Hold UP for menu" in `GREY`.
- New: Start opens the "Save & finish?" confirmation. Holding Up still opens the workout menu.

### Start

- The 70 px launcher icon at the top, or the offline banner in its place when it shows. Then "New Workout" in `GREY`.
- A card with the day name in bold, the program name in `GREY` and "N exercises" in white.
- A `START` pill.

### Waiting and loading

- The launcher icon (or the offline banner in its place), the message in bold ("No workout", "Loading..." and so on), and "Start one on your phone" in `GREY` when there is no workout.
- "N workout to sync" in `YELLOW` and "N sets not synced" in `RED`, as now.
- A `REFRESH` pill in `PILL_GREY`. Then "Phone connected" or "Phone not connected" in `GREY` near the bottom.

### Error (blocked)

- A red circle with "!" in it, the title in `RED`, the explanation in white, and a `RETRY` pill in `PILL_GREY`.

### Menus and confirmations

These stay as the system `Menu2` and `Confirmation`.

## Testing

- Unit tests for `Look`: rest text and fraction before, at and after the end; plates shown only for barbell with plates; the info line for warmup, AMRAP and plates combinations; summary counts and volume with completed, skipped and pending sets.
- A `SlimWorkout` test that `equipment` survives slimming.
- All existing tests pass.
- Simulator, fr170: a screenshot of each screen and state (resting, rest over, no rest, needs phone, all done, start, waiting, error). App memory stays under 100 kB during a workout.

## Sizing on every watch (after the simulator review)

Fixed pixel sizes did not match the device fonts: on the Forerunner 170 even `FONT_XTINY` is 30 px tall, and the × collided with the reps box. Sizes now come from the fonts the watch reports:

- `Theme.capH(font)` is 72% of the font ascent: the height of digits and capitals.
- Boxes are `capH(number font) + 2 × capH(small font)` high and as wide as their text plus padding (at least as wide as "88"). Pills are `2 × capH(small font) + 4` high.
- Each screen is a vertical stack of rows (`Layout.stack`), centered between 8–10% and 90–92% of the height.
- `Theme.TIERS` lists font sets from largest to smallest. A screen uses the first set whose stack fits the height and whose widest row fits the circle at that row's height (`Layout.chord`). The last set is used regardless.
- The set screen shows a small purple check pill (a drawn check mark; the font has none) instead of a START pill, which repeated on every set.
- The Start card drops the exercise chips: on smaller screens they were cut to a few letters.
- Supported: the 55 round watches with five buttons and API level 5 or higher (218–466 px, AMOLED and MIP). On MIP screens the card color falls to the nearest of 64 colors, a dark blue.
- `scripts/preview.sh <mode> [device]` shows any screen on any watch with fake data, no network and its own storage.

## Out of scope

- Custom fonts, exercise images and touch-specific controls.
- Changing what any button does, apart from Start on "All sets done".
