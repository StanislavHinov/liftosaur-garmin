# Liftosaur Garmin watch app — design

> **Superseded.** This is the original design, kept for its reasoning. The app has changed since (touch-only and rectangular watches, the app name, the shared Ticker, the Sync clock). Current behavior: README.md and AGENTS.md.


## Goal

A standalone Connect IQ watch app for the Garmin Forerunner 170 (`fr170`) runs Liftosaur workouts set by set. It talks to the Liftosaur Workout API directly. The Liftosaur server runs all program logic. The watch shows the current set, logs sets with physical buttons, and records a native Garmin Strength Training activity that syncs to Garmin Connect.

Success means:

- A full workout can be done from the watch with the phone locked in a pocket.
- Sets land in Liftosaur with progressions, 1RMs and the next-day pointer updated by the server.
- The Liftosaur phone app updates live during the workout, through the server push.
- The activity appears in Garmin Connect as Strength Training with heart rate, calories and time.

## Context and constraints

- The Liftosaur maintainer suggested a standalone app on the Workout API instead of a change to the Liftosaur repo. The API is documented in the "Running a Workout" section of `docs/content/api.md` in `astashov/liftosaur`, and at <https://www.liftosaur.com/docs>.
- The API needs Liftosaur Premium and an API key (`lftsk_...`). The user has Premium.
- The watch reaches the internet with `Communications.makeWebRequest`. Garmin Connect Mobile on the paired iPhone relays the requests. No custom phone app exists.
- The `fr170` watch app memory limit is 768 KB. Every API write returns the whole workout, and the watch parses it.
- Connect IQ cannot write native FIT set messages. Garmin Connect shows one lap per set. Custom FIT fields render in Garmin Connect only for a Connect IQ Store or Beta App install. A sideloaded build still writes them into the FIT file.
- A sideloaded app cannot have its settings edited in Garmin Connect Mobile. The API key is built into the sideloaded `.prg`.

## Scope

Version 1 supports every set type the API supports: normal, warmup, AMRAP, ask-weight, RPE, prompted variables, timed sets, and unilateral sets.

A workout starts from the watch, or the watch takes over a workout started on the phone.

Out of scope for version 1: adding sets, removing or reordering sets, editing a set after it was logged, choosing another program day than the next one, and resending "not synced" sets.

## Architecture

The repo is `liftosaur-garmin`. It holds one Monkey C app.

- `LiftosaurApp.mc` is the entry point. It loads stored state on start. On first start it creates the device id, a random string saved in `Application.Storage`.
- `Api.mc` wraps `Communications.makeWebRequest`. It adds three headers to every request: `Authorization: Bearer <apiKey>`, `X-Liftosaur-Device-Id: <device id>` and `X-Liftosaur-Client: liftosaur-garmin/<version>`. It has one method per endpoint and returns the parsed body or an error code.
- `WorkoutStore.mc` holds the slim workout copy and the write queue. It saves both with `Application.Storage`.
- `Sync.mc` drains the queue in order and replaces the slim copy with each response. While a workout is active and the screen is on, it polls `GET /workout/current` every 15 s.
- `Recording.mc` owns the `ActivityRecording` session and the `FitContributor` fields.
- `Haptics.mc` gives one buzz when rest reaches zero. Logging a set does not buzz.
- Views: `StartView`, `WaitingView`, `ActiveSetView`, `PromptView`, `RestView`, `TimedSetView`, `ProgressListView`, the workout menu, and a banner drawn by every view.

### Slim workout copy

Right after parsing a response, the watch keeps only these fields: `programName`, `dayName`, `startTime`, and per entry `entryId`, `name`, `hasUpdateScript`, `promptedVars`, `warmupSets` and `sets`. Per set it keeps `setId`, `index`, `isWarmup`, `reps`, `minReps`, `isAmrap`, `weight`, `plates`, `rpe`, `logRpe`, `askWeight`, `isUnilateral`, `timer`, `setTimer` and `completed`. It drops `imageUrl`, `description`, `notes` and every other field.

### API key

Each user enters their key in the Garmin Connect phone app: Connect IQ Store, Liftosaur, Settings, "Liftosaur API key". It is the `apiKey` property (`resources/properties.xml`, `resources/settings.xml`). Spaces and line breaks around a pasted key are dropped. When the key changes, the app uses it at once, clears a halt and boots again. Without a key the watch shows "Add your API key".

A developer build can carry a built-in key, used only while the setting is empty: `resources-secret/secrets.xml` (gitignored), included by `monkey.jungle`. The store build (`store.jungle`) uses `resources-store/strings.xml`, whose key is empty, so a published package never contains a key.

## Workout flow

### Start

1. On open the app calls `GET /workout/current`.
2. If a workout is live, the watch takes it over and starts recording.
3. If no workout is live, the app calls `GET /workout/next` and shows `StartView`, for example "GZCLP · A1 · 5 exercises". Start sends `POST /workout/start` with `startTime` from the watch clock, then starts recording.
4. A `409 workout_already_active` reply means the phone started another workout. The watch fetches `current` and takes it over.
5. Offline at start: the watch cannot start a workout without `GET /workout/next`. It shows "Connect phone to start".

### Logging a set

1. The user logs the set on the watch.
2. If the set needs input, the watch shows the Prompt screen first. The fields come from the set: `isAmrap` needs reps (and left reps when `isUnilateral`), `askWeight` needs weight, `logRpe` needs RPE, and `promptedVars` needs one value per variable. Timed sets send the held seconds that the watch measured.
3. The watch adds a `set` entry to the queue at once. The screen never waits for the network.
4. `Sync.mc` sends the entry and adopts the response.
5. When the entry has `hasUpdateScript: true`, the next set shows "Updating…" until the response arrives. Offline, it shows the old targets with a "may change" mark.

Values follow the API shapes. Numbers stay numbers. Weights and percentages are strings such as `"100kg"`. Prompted variables keep the shape the API sent.

### Rest

The rest timer runs on the watch from the set's `timer`. Skipping rest is local. The API has no rest endpoint.

### Changes made on the phone

The poll every 15 s picks up sets logged or edited on the phone. The watch adopts the response, as the API docs ask.

### Finish

- "Save & finish" on the watch: the watch adds a `finish` entry with `startTime`, `endTime` and the pause `intervals`, then saves the Garmin activity at once. The finish is sent after all queued sets. Offline, it stays queued with the real times. The Waiting screen shows "1 workout to sync" until it is sent.
- Finish on the phone: the next poll returns `workout: null`. The watch saves the Garmin activity. Queued sets for that workout fail with `no_active_workout` and move to the "not synced" list.
- "Discard Liftosaur workout" on the watch: two confirmations, then a `discard` entry that sends `DELETE /workout/current` with `startTime`.
- "Discard Garmin activity" on the watch: two confirmations. It discards the Garmin activity only.

## Write queue

- Entry types: `set {entryId, setId, completed}`, `finish {startTime, endTime, intervals}`, and `discard {startTime}`. Every entry carries the `startTime` of its workout.
- The queue drains in order. Consecutive `set` entries go together in one `POST /workout/sets`. A single `set` goes to `POST /workout/set`.
- Every API write is safe to repeat. After a lost reply the watch sends the same entry again.
- Retry delays are 5, 15, 30 and 60 s. After that the watch retries every 60 s while `System.getDeviceSettings().phoneConnected` is true. Every app start also drains the queue.
- The cap is 200 entries. At the cap the watch stops logging and shows "Connect phone to sync". No entry is dropped silently.

## Errors

- Network error or timeout: keep the queue and retry. The banner shows "Offline · N queued".
- `401`: a blocking screen says "API key invalid — rebuild with a new key". Sync stops.
- `403`: a blocking screen says "Liftosaur Premium required". Sync stops.
- `404 set_not_found`: fetch `current`. If the set is still missing, drop the entry and add it to the "not synced" list.
- `404 no_active_workout`: move the queued sets of that workout to the "not synced" list. The Garmin laps keep the data.
- `409 workout_already_active` on start: take over `current`.
- `400 missing_set_input` or `invalid_set_input`: this is a watch bug. Show the error, keep the entry, and stop the queue so later sets do not apply to a wrong state.
- `422 program_error`: show the server message and stop sync.
- `5xx`: retry with the delays above.
- Response too large or out of memory (`-402` and related codes): show "Workout too large for watch" and log the response size.

The "not synced" list shows on the Waiting screen as "N sets not synced". In version 1 it is information only.

## Screens and buttons

The theme is a black background with white text. Green marks the current target and completed sets. Amber marks the rest timer ring. Red marks failed sets. Grey marks inactive items. The edge of the round 390x390 screen stays free for the timer ring.

Button mapping on the Forerunner:

- Start is `onSelect`. Back is `onBack`. A long press on Up is `onMenu`.
- A long press on Start is detected with `onKeyPressed` and `onKeyReleased` timing.
- A long press on Back belongs to the system. The app does not use it.

### Start screen

Shows the next workout name, day and exercise count. Start begins the workout. Back exits the app.

### Waiting

Shows "No workout", the queue state, "1 workout to sync" and "N sets not synced" when they apply. Start fetches `current` and `next` again. A long press on Up opens a menu with "Exit".

### Active set

```text
         BARBELL ROW
       Set 2 of 4 · AMRAP
      5+ reps  x  60 kg
    target 5 · RPE 8 · 20/5
         ● ● ○ ○
```

- Start logs the set. Then the watch shows Prompt when the set needs input, or the next set with the rest line.
- Up and Down change the selected value. Reps change by 1. Weight changes by 2.5 kg or 5 lb. (The API's `plates` are what to load for the set, not the plates the gym has, so they cannot give the step.)
- A long press on Start moves the selection from reps to left reps (unilateral sets only), then weight, then back to reps. The selection returns to reps after each logged set.
- Back asks "Skip set?". Yes moves to the next set. The skipped set stays not completed. Skipping writes nothing.
- A long press on Up opens the workout menu.
- A swipe left opens the progress list.
- A changed value shows in white with the target struck through next to it.

### Prompt

The watch shows one field at a time: reps, left reps, weight, RPE, then each prompted variable.

- Up and Down change the value. Start confirms and shows the next field. Back shows the previous field.
- Confirming the last field queues the set.
- RPE moves in steps of 0.5 from 6 to 10. A variable moves by 1, or by the weight step when its value is a weight.

### Rest

There is no separate rest screen. After a logged set the watch shows the next set at once, with the rest timer as a small line above the exercise name, as in the Liftosaur Apple Watch app.

- The line shows "Rest 1:23" in amber while time remains. It is computed from the logged time plus `timer`, so it stays correct after an app restart.
- At zero the watch buzzes once. The line then counts up in green as overtime, for example "Rest +0:12".
- The rest ends when the next set is logged, which starts a new rest.
- While the rest line shows, the grey status banner moves to the bottom of the screen.

### Timed set

- Get ready shows a large white 10 s countdown. Start skips the rest of it.
- Work counts up in green, with the `setTimer` target next to it. The time turns amber past the target. Start ends the hold.
- Unilateral timed sets run left first, then right. The watch sends `setTimerLeft` and `setTimer` together in one write.

### Progress list

Shows every exercise with done and total sets. The current exercise is green. Finished exercises carry a check mark. Touch scrolls the list. A swipe right or Back returns to Active set. The list is read only.

### Workout menu

- "Resume" closes the menu.
- "Pause" or "Unpause" pauses the Garmin recording and adds an interval boundary for `finish`.
- "Save & finish" asks for confirmation, then runs the finish flow.
- "Discard Liftosaur workout" asks for confirmation twice.
- "Discard Garmin activity" asks for confirmation twice.

### Banners

A grey line at the top of every screen shows "Offline · N queued" while the queue cannot drain.

### Touch

Touch works for swipes between Active set and the progress list, for scrolling the list, and for menu items. Every other touch event returns `true` from the delegate, so it is ignored.

## Garmin recording

- The workout start or takeover starts the session: `ActivityRecording.createSession({:name => "<program> <day>" cut to 15 characters, :sport => Activity.SPORT_TRAINING, :subSport => Activity.SUB_SPORT_STRENGTH_TRAINING})`, then `start()`. The watch sensors record heart rate, calories and elapsed time.
- Every logged set calls `addLap()`. Rest time falls into the next lap.
- Lap fields with `FitContributor`: reps, left reps, weight, RPE, set number, warmup flag, and the exercise name as a string of up to 24 bytes. That is 7 of the 16 fields and about 45 of the 256 bytes per lap message.
- Session fields: program name and day name (32 bytes each), total sets and total volume.
- Pause calls `stop()`. Unpause calls `start()`. Save calls `stop()` and then `save()`. Discard calls `stop()` and then `discard()`. Garmin Connect uploads a saved activity at the next watch sync.
- While a session records, the app handles Back itself, so the user cannot leave the app by accident.
- If the app crashes, that Garmin recording is lost. The Liftosaur data is safe in the queue and on the server. On the next start the app begins a new recording and shows "Recording restarted".

## Watch storage

`Application.Storage` keys:

- `deviceId`: the stable install id.
- `workout`: the slim workout copy.
- `queue`: the write queue.
- `rec`: whether a session records, its start time, pause intervals and the lap count.
- `rest`: the time the last set was logged and its rest duration.
- `notSynced`: the "not synced" list.

On start the app loads every key and shows the screen for the stored state.

## Testing

- Connect IQ unit tests (`(:test)` functions, run with `monkeyc --unit-test` in the simulator):
  - request building: the three headers and the body for each endpoint;
  - set id format and uniqueness;
  - trimming a sample response to the slim copy;
  - queue order (sets before finish), batching, adopting the response and the cap;
  - the action for each error code;
  - rest countdown maths;
  - the field order of the Prompt screen for each set flag combination.
- End to end in the Connect IQ simulator. The simulator sends real HTTPS requests from the Mac, so a full workout runs against liftosaur.com with the user's key. These runs write real workouts to the account. Each run uses a test program and ends with `DELETE /workout/current`, and the user confirms before each run that writes.
- Hardware checklist in milestone 1:
  - the custom headers pass through Garmin Connect Mobile on iOS;
  - the largest workout response that fits in watch memory;
  - a full workout from the watch with the phone locked;
  - the queue drains after Bluetooth is turned off and on;
  - the phone app updates live through the server push;
  - the activity appears in Garmin Connect as Strength Training.

## Build and sideload

1. Install the Connect IQ SDK Manager. Download the current SDK and the `fr170` device profile.
2. Generate a developer key with `openssl genrsa -out developer_key.pem 4096`. Convert it with `openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt`. Keep both files out of git.
3. Create an API key in Liftosaur: Settings, API Keys, Create API Key. Put it in `resources-secret/secrets.xml` as the `apiKey` property value.
4. Build with `monkeyc -d fr170 -f monkey.jungle -o bin/LiftosaurGarmin.prg -y developer_key.der`, or run "Monkey C: Build for Device" in the VS Code extension and pick `fr170`.
5. Connect the watch with USB. On macOS the watch uses MTP, so Finder does not show it. Copy `LiftosaurGarmin.prg` into `GARMIN/APPS/` with OpenMTP or Garmin Express.
6. Unplug the watch. The app appears in the activity and app list.

Troubleshooting:

- The app does not appear: the `.prg` was built for another device. Rebuild with `-d fr170`, and check that `manifest.xml` lists `fr170` and a minimum API level the device supports.
- The app shows an error icon or closes at start: read `GARMIN/APPS/LOGS/CIQ_LOG.YML` on the watch. "Out of memory" means the app passed the 768 KB limit.
- Every request fails: check that Garmin Connect Mobile runs on the iPhone and is connected to the watch.
- "API key invalid": create a new key, update `secrets.xml`, rebuild and copy again.
- Custom fields do not show in Garmin Connect: expected for a sideloaded build. Upload the app as a private Beta App to see them.

## Milestones

1. API client, start or take over a workout, normal and warmup sets, rest timer, recording, queue, finish, and the hardware checklist.
2. AMRAP, ask-weight, RPE, prompted variables and the Prompt screen.
3. Timed sets and unilateral sides.
4. Progress list, polling for phone edits, "Discard Liftosaur workout", and the Beta App settings field.

## Risks

- The whole-workout response may not fit in watch memory for long workouts. Milestone 1 measures the limit. The fallback is a request to the maintainer for a smaller response option.
- Custom request headers through Garmin Connect Mobile on iOS are not yet tested. Milestone 1 tests them first. Without them the API cannot be used.
- The API key sits inside the `.prg` file. Anyone with the file can use the key. Keep the file private, and delete the key in Liftosaur if the file leaks.
