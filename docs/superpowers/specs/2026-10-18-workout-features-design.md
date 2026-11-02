# Workout features: browse and undo, heart rate, set input, timed sets, overview, settings — design

## Goal

Close the gap with the Liftosaur Apple Watch app and the original M2–M4 milestones, in six phases. Each phase ships on its own, with unit tests written first for its logic.

Dropped, because the Liftosaur Workout API cannot do them: deleting a set (there is no endpoint), and personal records in the finish summary (no PR data comes back).

API facts this design relies on (`lambda/utils/apiv1Workout.ts`):

- `POST /workout/set` with `completed: null` un-completes a completed set. With values on a completed set, it replaces them without toggling.
- `completed` accepts `reps`, `repsLeft`, `weight`, `rpe`, `setTimer`, `setTimerLeft` and `userVars` (name → number or string). The API answers `400 missing_set_input` when an AMRAP, ask-weight, RPE or prompted-variable set lacks its value.
- `setTimerLeft` is only for unilateral exercises, and a unilateral timed set needs both sides.
- A set write with `append: true`, `entryId` and a new 6-lowercase-letter `setId` appends a set to that exercise.
- `GET /workout/next?week=&dayInWeek=` previews a given day. `POST /workout/start` accepts `week` and `dayInWeek`.
- `DELETE /workout/current` with `startTime` discards the workout.

## Phase 1: browse, undo, edit, and log any set

### Moving between sets

The set screen shows a *viewed* set. By default it follows the cursor (the first set that is neither done nor skipped). Browsing pins it to another set until the user returns.

- Touch: swipe left goes to the next set and swipe right to the previous one, crossing exercise boundaries. Swipe up goes to the next exercise and swipe down to the previous one, landing on that exercise's first set that is not done (or its last set when all are done). Browsing stops at the first and last set.
- Buttons, for watches without touch: the hold-Up workout menu gets "Previous set" and "Next set".
- Back while browsing returns to the current set. Back on the current set still asks "Skip set?".
- Pure module `Nav`: `step(w, pos, dir)` and `jumpEntry(w, pos, dir)` return the new `[entry, set]` position or `null` at the ends.

### What a viewed set offers

- A set that is not done looks like today: target values, the boxes, and the check pill. Start (or a tap on the check pill) logs it, even when it is not the current set. Logging a skipped set removes it from the skipped list.
- A completed set shows "Set N/M · Done" in green, the logged values in the boxes, a check pill (save) and a grey `UNDO` pill side by side.
  - Up and Down change the values as usual. Start or the check pill saves the change: the watch queues a set write with the new values. No rest starts and no lap is added.
  - `UNDO` (tap, or "Undo set" in the workout menu) asks "Undo set?". Yes queues a set write with `completed: null`, marks the set not done locally, and returns to the current set.
- Taps on the reps or weight box select that field. Hit areas are recorded while drawing.
- The Garmin activity keeps the lap of an undone or edited set; Connect IQ cannot remove laps.

### Controller

- `logSetAt(ei, si, reps, weight)` does what `logSet` does for any position. `logSet(reps, weight)` calls it with the cursor.
- `saveSet(ei, si, reps, weight)` queues new values for a completed set, with no lap or rest.
- `undoSet(ei, si)` queues `completed: null` and updates the local copy.

## Phase 2: heart rate and rest controls

- The set screen draws a small heart (two circles and a triangle) and the current heart rate under the check pill, from `Activity.getActivityInfo().currentHeartRate`. It shows `--` without a reading.
- Rest controls: tapping the rest line, or "Rest" in the workout menu, opens a menu with "-15 s", "+15 s" and "Skip rest". `Look.adjustRest(rest, delta, nowSec)` returns the new rest; a rest that would end in the past ends now. "Skip rest" clears the rest.

## Phase 3: input screen for special sets

- After Start on a set that needs input, the watch opens the Input screen instead of logging at once. `Prompt.fields(entry, set)` lists the fields in order: `repsLeft` (unilateral, not timed), `weight` (`askWeight`), `rpe` (`logRpe`), then one per prompted variable.
- Each field shows its name, a large value box, and "n of m". Up and Down change the value, Start goes to the next field, the last Start logs the set, Back goes to the previous field or closes the screen.
- Starting values and steps: left reps start at the reps value and step by 1; weight starts at the target or the last weight and steps by 2.5 kg or 5 lb; RPE starts at the target or 8, steps by 0.5 between 1 and 10; a numeric variable starts at its value and steps by 1 (0.5 when it has a fraction); a weight variable ("100kg") steps by 2.5 kg or 5 lb; a percent variable steps by 1.
- `Prompt.completed(...)` builds the `completed` body: `repsLeft`, `weight`, `rpe`, and `userVars`.
- `SlimWorkout.needsPhone` then returns false for these sets; only timed sets need Phase 4.

## Phase 4: timed sets

- Start on a timed set opens the Timer screen: a 5-second "Get ready" ring in yellow, then a clock "0:12 / 1:00" with a purple ring that fills toward the target.
- At the target the watch buzzes and logs the set with `setTimer` set to the target. Start during the clock logs the elapsed time early. Back cancels.
- A unilateral timed set runs Left, then Right, and logs `setTimerLeft` and `setTimer`.
- `TimedSet` (pure): the phase, elapsed and remaining for a given start time and now, and the `completed` body.

## Phase 5: overview, add set, discard

- Workout overview: a `Menu2` with one item per exercise, "done/total" as its sub-label. Picking one views that exercise's first set that is not done. Opened from the workout menu, or by tapping the exercise name.
- Add set (workout menu): appends a copy of the viewed exercise's last set. Locally it gets a new 6-letter id and no completion; the queue sends `append: true`.
- Discard Liftosaur workout (workout menu): two confirmations, then a queued `discard` entry (`DELETE /workout/current` with `startTime`). The Garmin activity is discarded too, and the watch returns to Waiting.

## Phase 6: settings, glance, choose the day, resend

- Setting "Record Garmin activity" (boolean, default on). Off: no recording, laps or save. For people who use liftosaur2garmin.
- Glance: "Lift Log" and "Up next: Upper A" or "Ongoing: Upper A", from storage the app writes. Opens the app.
- Start screen: Up and Down step to the next or previous day by asking `/workout/next` with `week` and `dayInWeek`. When a day does not exist, the next week's first day is tried, then the first week. Start starts the shown day.
- Waiting screen menu: "Resend N sets" moves the not-synced sets back to the queue. Sets that fail again return to the list.

## Testing

Each phase starts with failing unit tests for its pure module and controller changes, using the existing fakes. Phase 1 tests: `Nav` steps and jumps, including ends; `logSetAt` out of order and for a skipped set; `saveSet` queues values with no lap or rest; `undoSet` queues `completed: null`; the request body keeps `completed: null`. Every phase ends with all tests passing and `scripts/preview.sh` screenshots of its screens.
