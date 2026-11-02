# AGENTS.md

Guide for AI coding agents (and people) working on Lift Log for Liftosaur, an unofficial Garmin Connect IQ watch app in Monkey C. It runs Liftosaur workouts through the Liftosaur Workout API and records a Garmin Strength Training activity. Read `CONTRIBUTING.md` for the human workflow; this file holds the rules and traps that matter when changing code.

## Commands

| Task | Command | Done when |
| --- | --- | --- |
| Unit tests (fr170 simulator) | `scripts/test.sh` | last line starts with `PASSED` |
| One test | `scripts/test.sh <testFunctionName>` | `PASSED (passed=1, ...)` |
| Build every watch in `manifest.xml` | `scripts/package.sh` | `BUILD SUCCESSFUL`, writes `bin/LiftosaurGarmin.iq` |
| Dev build with the built-in key | `scripts/build.sh` | `bin/LiftosaurGarmin.prg` |
| One screen with fake data | `scripts/preview.sh <mode> [device]` | the simulator shows it; log in `bin/preview/run.log` |
| Release (maintainer) | `scripts/release.sh <version>` | tag `v<version>` and a GitHub release with the `.iq` |

Preview modes: `rest`, `over`, `norest`, `hold`, `done`, `start`, `waiting`, `error`, `nokey`, `browse`, `prompt`, `edit`, `rpe`, `timed`, `timedwork`, `menu`, `overview`, `bg`.

Builds and tests need the Connect IQ SDK (found by `scripts/sdk.sh`), Java 17, `developer_key.der` in the repo root and `resources-secret/secrets.xml` (copy `secrets.example.xml`); the last two are gitignored. `monkey.jungle` is the dev build (fr170, built-in key); `store.jungle` is the store build (every watch, `resources-store` with an empty key). Type checking is off (`-l 0`).

`scripts/test.sh` hangs if another app runs in the simulator; it kills `monkeydo` first, and if it still hangs, quit the simulator. The simulator also wedges after many runs: a preview or test stays on the blue triangle and never loads. Kill `monkeydo`, `MonkeyDoDeux` and `ConnectIQ.app`, start it again and wait about 20 s before the next run. A crash in the simulator prints `Error: Unhandled Exception` with a stack to `bin/preview/run.log` (previews) or the test output; always read it after a preview.

## Definition of done

1. Tests were written first and seen failing, for every bug fix and every piece of new logic.
2. `scripts/test.sh` passes with no `ERROR` or `FAIL`.
3. `scripts/package.sh` builds every device. A change that compiles on fr170 can fail on another watch.
4. UI changes: previewed on `fr255s` (small round), `fr965` (large round), `venu3` (touch, no Up/Down) and `venusq2` (rectangular), with no exception in `bin/preview/run.log`.
5. Buttons and touch alone both reach every action. The README controls table matches.
6. No API key, developer key or `.prg` in the diff.

## Architecture

```
LiftosaurApp ── getInitialView builds ──> Controller ──> Ui (switches views)
                                            │   └──> Recording (Garmin activity: laps, HR, save)
                                            └──> Sync ──> Api ──> makeWebRequest via the phone
Store (Application.Storage): workout, queue, rest, skipped, focus, rec, halt, notSynced, glance
```

- **Controller** (`source/Controller.mc`) owns the flow: boot, start, log, save, undo, add set, finish, discard, phone-finish. It changes `Store` first (optimistic), queues the write, then calls `Sync.drain()`.
- **Sync** (`source/Sync.mc`) sends the queue in order: consecutive set writes for one workout go as one batch (`Queue.headRunLength`). It retries with backoff, polls `GET /workout/current` every 15 s during a workout, adopts the server's workout (`SlimWorkout.applyPending` re-applies unsent writes on top), and reports `onWorkoutGone`, `onHalt`, `onSetsSent`.
- **Pure modules** hold every rule and are where tests go: `Look` (what screens show), `Nav` (moving between sets), `FitExercise` (Liftosaur exercise → FIT exercise category and name), `Prompt` (input fields), `TimedSet`, `Weight`, `Rest`, `Queue`, `Requests` (request bodies), `ErrorPolicy` (status → action), `SlimWorkout` (shrinks the API payload, cursor), `DayPick`, `ApiKey`, `GlanceText`.
- **Views** in `source/ui/` read `Store`, call pure modules and draw. `Theme.drawRows` lays out a stack of rows sized from the watch's fonts (`Theme.TIERS`, largest that fits); never use fixed pixel sizes.
- **Cursor** (the set to do next): `Store.cursor()`, which is `SlimWorkout.cursorAt` with the focus (the `entryId` of the exercise last logged). Don't call `SlimWorkout.cursor` from app code; it ignores the focus.
- **Background sync** (`source/BgSync.mc`, `source/BgService.mc`): when the app closes with sets queued, `BgSchedule` registers a one-shot temporal event 5 minutes on. `BgService` then sends the queue with `BgSync`, retries every 5 minutes while offline, and on any other failure leaves the queue for the app and asks to open it (`Background.requestApplicationWake`). Opening the app cancels the event, so the app and the background never send at once.
- **Glance and complication**: `Store.setGlance` stores the next or ongoing day for the glance (`GlanceView`, `(:glance)`) and publishes it as complication 0 (`Face.publish`, `resources/complications.xml`) for watch faces.
- **Ticker** (`source/Ticker.mc`) is the one timer the screens share. Sync owns the only other timer.

## Testing rules

Tests are Run No Evil functions in `test/`, one file per area, run by `scripts/test.sh`. Robust tests are the main defense of this app: the watch can't be debugged in the field, so every behavior that can be expressed without drawing must have a test.

- Write the failing test first, run it, see the failure you expect, then fix. A test that never failed proves nothing.
- Name a test after the behavior: `syncPollSendsSetsLoggedWhileItWaited`, not `testSync3`.
- Every global `(:test)` function is run as a test. Put helpers in a `(:test) module` (see `ControllerUtil`, `SyncUtil`, `TestUtil`).
- Start each test from a clean state: `Store.clearAll()` (or a helper that calls it). Tests share storage with each other and with the simulator app.
- Use the fakes in `test/Fakes.mc`: `FakeApi` records requests and answers them in order with `respond(status, data)`; `FakeUi`, `FakeRec` and `FakeListener` record calls as strings. Add a method to a fake when production code calls a new one, or the test crashes with "Symbol not found".
- Use `test/Fixtures.mc` for API payloads; copy the real shape from the Liftosaur API, not a guess.
- Cover the edges, not just the happy path: ends of lists, empty queues, null fields, offline (`respond(-104, null)`), server errors (`401`, `409`, `400 missing_set_input`), a workout replaced or finished on the phone, writes queued while a request is in flight.
- Time: `System.getTimer()` is ms since boot, `Time.now()` is Unix seconds. Make times relative to a value read in the test (`t0 + 1000`), never absolute literals. Expose a step function with an explicit `now` (like `Sync.step(now)`) instead of waiting on a timer.
- `Test.assertEqual(x, null)` errors; use `Test.assert(x == null)`.
- Logic hidden in a view can't be tested. Move it into a pure module and test it there.

## Monkey C and Connect IQ traps

These caused real bugs here.

- **32-bit Numbers.** `Number` is 32-bit. Unix seconds near 1.8e9 overflow when added: write `a + (b - a) / 2`, not `(a + b) / 2`. Millisecond timestamps must be `Long` (`1738274512000l`, `.toLong() * 1000l`).
- **Timer limit.** A watch allows only a few timers at once; going over throws "Too Many Timers Error". Never create `Timer.Timer` in a view or dialog. Use `Ticker.watch(self)` in `onShow`, `Ticker.unwatch(self)` in `onHide` (the view gets `tick()` every 250 ms; throttle inside), and `Ticker.later(callback)` for a one-shot.
- **Input dispatch.** `BehaviorDelegate` runs the behavior (`onSelect`, `onBack`, `onNextPage`, `onPreviousPage`) first and drops the raw `onTap`/`onSwipe` if the behavior returns `true`. A tap is `onSelect`, swipe up/down are page behaviors, swipe right is `onBack`. Screens with tap targets handle buttons in `onKey`/`onKeyPressed`/`onKeyReleased` and return `false` from the behaviors (see `ActiveSetDelegate`, `PromptDelegate`).
- **Touch-only watches** (Venu, vivoactive) have Start, Back and Menu keys only. Every action needs a touch path: tap targets recorded while drawing (`_hits` as `[x, y, w, h, action]`), `onHold` for the menu, menu items for Back-only actions.
- **View stack.** `switchToView` replaces only the top view. A view left under a menu can be shown again later with no workout in `Store`; views must handle `Store.workout() == null` (see `ActiveSetView.tick`).
- **Confirmation** pops itself after `onResponse` returns, so a view switch made inside it is popped too. Run the action with `Ticker.later`.
- **Glance.** Code the glance uses needs `(:glance)`; keep it tiny, since glances get very little memory.
- **Background process.** It loads only `(:background)` code and has 64 KB. Mark anything it calls (`Store`, `Queue`, `Requests`, `Api`, `ApiKey`, `Config`, ...) and scope resources it reads with `scope="background"` (the `ApiKey` string). A temporal event repeating by `Duration` can't be registered within 5 minutes of the last one (the call throws); register a `Moment` instead. `Notifications.showNotification` from the background crashed the 9.2 simulator, so the app doesn't use it. Test it with `PREVIEW_URL=http://127.0.0.1:<port>/api/v1 scripts/preview.sh bg <device>` against a local fake server, with "Use Device HTTPS Requirements" off; the event fires about 5 minutes after the preview closes the app.
- **Memory.** Small watches have little heap. `SlimWorkout.slim` keeps only the fields the app uses; don't keep the raw payload.
- **Fonts.** Fonts differ per watch and lack glyphs (no check mark, heart or minus). Draw those shapes (`Theme.checkPill`, `Theme.heart`, `Theme.stepButton`).

## Liftosaur Workout API facts

Source: `lambda/utils/apiv1Workout.ts` in https://github.com/astashov/liftosaur. Check it before relying on a field.

- `GET /workout/current`, `GET /workout/next?week=&dayInWeek=`, `POST /workout/start` (`week`, `dayInWeek`), `POST /workout/set` (one), `POST /workout/sets` (a batch, see `Requests.forRun`), `POST /workout/finish`, `DELETE /workout/current` (`startTime`).
- `POST /workout/set` with `completed: null` un-completes a set; with values on a completed set it edits it. `append: true` with `entryId` and a new 6-lowercase-letter `setId` appends a set.
- `completed` takes `reps`, `repsLeft`, `weight`, `rpe`, `setTimer`, `setTimerLeft`, `userVars`. A set that asks for AMRAP reps, weight, RPE or prompted variables fails with `400 missing_set_input` without them.
- A set's `plates` are the plates to load for that set, not the plates the gym has. Weight steps are 2.5 kg / 5 lb.
- A set's `timer` is already resolved (set, superset, workout or warmup default).
- The server starts the phone's rest timer when it processes the set write, not when the watch logged it. `Controller.onSetsSent` moves a running watch rest to the server's time.
- Not exposed by the API (so the watch can't follow them): the exercise selected on the phone (`currentEntryIndex`) and the phone's rest timer (`timer`, `timerSince`). Deleting a set and personal records have no API either.
- Every request sends `Authorization: Bearer <key>`. Writes (anything but GET) also send `X-Liftosaur-Client` (`Config.CLIENT`, bump with the store version) and `X-Liftosaur-Device-Id`.

## Garmin exercises

Garmin Connect builds its exercise list and muscle map from FIT `set` and `exercise_title` messages. A Connect IQ app can't write those: `ActivityRecording` only adds laps and developer fields (session, lap, record). So each lap carries developer fields `fit_category`, `fit_exercise` and `exercise_id`, for a companion tool to turn into exercise sets. The mapping table is `resources/jsonData/fit_exercises.json`, built by `tools/fit-exercises/` (see its README). It is about 19 KB in memory: `Controller.fitCode` loads it once per workout and keeps only that workout's codes.

## Ids that must never change

Changing these breaks installed apps or recorded activities:

- The app id in `manifest.xml` (`a6d4e0df...`): the Connect IQ Store identifies the app by it. Every package must also be signed with the same `developer_key.der`.
- FIT developer field ids in `source/Recording.mc` and `resources/fitcontributions.xml`: Garmin Connect and tools read past activities by id. Add new fields with new ids.
- Complication id 0 in `resources/complications.xml`: watch faces subscribe to it.
- Store keys (`Store.KEYS`): an update must read what the previous version left on the watch.

## Workflow and releases

`main` is protected: work on a branch, open a pull request, squash-merge (linear history, no force pushes). A release is a PR that bumps `Config.CLIENT` and adds `## What's new (<version>)` to `store/listing.md`; after merging, `scripts/release.sh <version>` builds from a clean checkout, tags and creates the GitHub release with the `.iq`. The store form answers are in `store/listing.md`. When `store/PRIVACY.md` changes, update the public copy linked there (a GitHub gist) too.

## Conventions

- Match the surrounding code: small functions, comments only where the reason isn't obvious, plain names.
- Commits: plain imperative subject ("Fix Too Many Timers crash on confirming a dialog") and a body that says why.
- New screen state that a preview can't show: add a mode to `preview/Preview.mc` and `scripts/preview.sh`.
- Design docs for larger features go in `docs/superpowers/specs/`.
- Secrets: the dev key lives only in `resources-secret/secrets.xml` (gitignored). Store builds use `resources-store` with an empty key; never put a key anywhere else.
