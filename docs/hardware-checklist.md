# M1 hardware checklist

- [x] Simulator: FIT session has sport training (10) / strength_training (20), one lap per set, developer fields reps, weight, set, warmup, exercise, program, day, total_sets, total_volume.
- [x] Simulator: startTime parses as Long (1792337509000) and finish succeeds against liftosaur.com.
- [x] Simulator: start, set logging and finish against liftosaur.com with a real API key; phone app updates.
- [x] Simulator: app memory 29.5–43.2 kB of 763.6 kB during a real workout.
- [ ] Watch: requests with Authorization and X-Liftosaur-* headers succeed through Garmin Connect Mobile on iOS.
- [ ] Watch: the largest workout response that loads without "Workout too large" (number of exercises × sets: ___).
- [ ] Watch: a full workout logs with the phone locked in a pocket.
- [ ] Watch: the queue drains after Bluetooth is turned off and on.
- [ ] Watch: the Liftosaur phone app updates live during the workout.
- [ ] Watch: holding Up opens the menu without adding a rep; holding Start switches the field without logging.
- [ ] Watch: rest-end vibration is felt with the screen off.
- [ ] Garmin Connect: the activity shows as Strength Training with heart rate, calories, time and one lap per set.

Found and fixed during simulator runs: bodiless 404 halted sync; activity name over 15 characters crashed createSession; unit-test storage leaked into app runs; arrow/×/… glyphs missing from the watch font.

## Modern UI and store build

- [x] Simulator: every screen at fr170 (390 px), fr255s (218 px, MIP), fenix7 (MIP), fenix843mm (416 px), fr965 (454 px) with `scripts/preview.sh`.
- [x] Simulator: app memory 38.5–53.2 kB of 763.6 kB with the new UI.
- [x] Store config (`store.jungle`): the built package for fr170 does not contain the developer's key; the developer build does.
- [x] `scripts/package.sh` builds all 55 watches (67 part numbers).
- [ ] Beta App: the "Liftosaur API key" setting shows in Garmin Connect, and a pasted key reaches the watch without a restart.
- [ ] Watch: the rest ring, boxes and check pill read well outdoors and in the gym.

## Workout features

- [x] Simulator: browse, Input, Timer, overview and menu screens at fr170 and fr255s with `scripts/preview.sh`; glance shows in the simulator.
- [x] Simulator: memory 59.6 kB of 507.7 kB on fr255s during a workout.
- [x] `scripts/package.sh` builds all 55 watches with the glance.
- [ ] Watch: swipes move between sets and exercises; taps on boxes and pills hit the right target.
- [ ] Watch: an undone set shows as not done in the Liftosaur phone app; an edited set shows the new values.
- [ ] Watch: an RPE set and a set with a prompted variable log without "missing_set_input".
- [ ] Watch: a one-sided timed set logs both sides; the Liftosaur app shows the times.
- [ ] Watch: an added set appears in the Liftosaur app.
- [ ] Watch: choosing another day on the Start screen starts that day.
- [ ] Watch: with "Record Garmin activity" off, no activity reaches Garmin Connect.
