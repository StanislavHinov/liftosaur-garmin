# Lift Log for Liftosaur

An unofficial Garmin watch app for Liftosaur. Not affiliated with Liftosaur or Garmin.

Runs Liftosaur workouts on the watch through the Liftosaur Workout API, and records a Garmin Strength Training activity. The look follows the Liftosaur Apple Watch app.

Supported: 68 Garmin watches with Connect IQ API level 5 or higher: the five-button watches (Forerunner 165/170/255/265/570/965/970, fēnix 7/8/9, epix 2, Enduro 3/4, Instinct 3 AMOLED, MARQ and others) and the touch watches (Venu 2/3/4, Venu Sq 2, Venu X1, vivoactive 5/6, D2 Air X10). See `manifest.xml`. Screens size themselves from each watch's fonts.

## Using the app

| | Buttons | Touch |
| --- | --- | --- |
| Log the set | Start | Tap the check pill |
| Change reps or weight | Up / Down; hold Start to switch field | Tap the box, then − / + and DONE |
| Open the menu | Hold Up | Hold the screen |
| Next / previous set | Menu → Next set / Previous set | Swipe left / right |
| Next exercise | Hold Down (wraps to the first) | Swipe up (swipe down: previous) |
| Pick any exercise | Menu → Workout overview | Tap the exercise name |
| Undo or edit a logged set | Browse to it; Start saves, Menu → Undo set | Tap UNDO, or the check pill to save |
| Back to the current set | Back | Menu → Current set |
| Skip a set | Back on the current set | Menu → Skip set |
| Rest: -15 s, +15 s, skip | Menu → Rest | Tap the rest time |
| Add a set | Menu → Add set | Menu → Add set |
| Finish | Start on "All sets done" | Tap FINISH |
| Pick another day | Up / Down on the Start screen | Swipe up / down on the Start screen |

Every control works by touch alone, so the app also runs on touch watches without Up and Down buttons (Venu 2/3/4, Venu Sq 2, Venu X1, vivoactive 5/6, D2 Air X10). The Input screen has − and + buttons too.

Exercises can be done in any order: after you log a set of an exercise, the watch stays on that exercise until its sets are done, then goes back to the program order. The workout overview lists each exercise with its sets done and next set ("Now · 1/3 · 5×100kg"), and opens on the current one.

Sets with RPE, left reps, an asked weight ("?") or program variables open an Input screen: Up / Down change the value, Start goes on. Timed sets open a 5-second get-ready ring, then a clock that logs at the target; Start logs early. One-sided timed sets run left, then right.

The menu also has Pause, Save & finish, Discard Garmin activity and Discard workout (the Liftosaur workout and the Garmin activity). The Waiting screen's menu has "Resend N sets" when sets failed to sync.

Settings in Garmin Connect: the Liftosaur API key, and "Record Garmin activity". Turn recording off when another tool, such as liftosaur2garmin, creates the Garmin activity, so you do not get two.

The glance shows the next or ongoing workout day. So does the app's complication, on watch faces that show Connect IQ complications.

Sets that couldn't be sent stay on the watch. If you close the app before they are sent, the watch tries again in the background every 5 minutes; if Liftosaur rejects one, it asks "Sets not synced. Open Lift Log?".

In Garmin Connect, the activity's Laps table shows each set's exercise, set number, reps and weight, and the summary shows the program, day, total sets and volume (for store installs; sideloaded apps don't show Connect IQ fields). Each lap also carries the Garmin exercise category and name for its Liftosaur exercise (`tools/fit-exercises/`). Garmin Connect does not show them as exercises yet: a Connect IQ app cannot write Garmin's exercise sets, so a companion tool is planned to add them.

Limits: an undone or edited set changes in Liftosaur, but its lap stays in the Garmin activity. Sets cannot be deleted from the watch; the Liftosaur API has no call for it.

## Setup

1. Install VS Code with the "Monkey C" extension, and the Connect IQ SDK Manager. In SDK Manager, download the newest SDK and the devices you want to test.
2. Install Java, which the Connect IQ compiler needs: `brew install openjdk@17`. The scripts find it in `/opt/homebrew/opt/openjdk@17`.
3. Create a developer key in the repo root:

   ```bash
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```

   Back up `developer_key.der` outside the repo. Every store update must be signed with the same key.

4. Optional, for your own builds: create a Liftosaur API key (Settings → API Keys, needs Premium), copy `secrets.example.xml` to `resources-secret/secrets.xml` and paste the key. The build fails without this file.

## The API key

Users enter their key in the Garmin Connect phone app: Connect IQ Store → Lift Log for Liftosaur → Settings → "Liftosaur API key". The watch uses it at once. Without a key the watch shows "Add your API key".

A developer build uses the key from `resources-secret/secrets.xml` only while the setting is empty. Anyone with that `.prg` file can use the key inside it, so keep it private. The store package never contains a key.

## Build and test

- `scripts/build.sh` builds `bin/LiftosaurGarmin.prg` for `fr170`, with your built-in key.
- `scripts/test.sh` builds with unit tests and runs them in the simulator.
- `scripts/preview.sh <mode> [device]` shows one screen with fake data, without a Liftosaur account or network. Modes: `rest`, `over`, `norest`, `hold`, `done`, `start`, `waiting`, `error`, `nokey`, `browse`, `prompt`, `edit`, `rpe`, `timed`, `timedwork`, `menu`, `overview`, `bg`. Example: `scripts/preview.sh rest fr255s`.
- `scripts/package.sh` builds `bin/LiftosaurGarmin.iq` for the Connect IQ Store: every watch, release mode, no key.
- In VS Code: Command Palette → "Monkey C: Build for Device" → `fr170`.

## Sideload to your watch

1. Run `scripts/build.sh` (change `-d fr170` in it for another watch).
2. Connect the watch with USB. macOS does not show it in Finder because the watch uses MTP. Install OpenMTP (https://openmtp.ganeshrvel.com) or use Garmin Express.
3. Copy `bin/LiftosaurGarmin.prg` into `GARMIN/APPS/` on the watch.
4. Unplug the watch. "Lift Log for Liftosaur" appears in the activity and app list.

A sideloaded app has no settings page in Garmin Connect, so it needs the built-in key.

## Publish to the Connect IQ Store

1. The app is listed as "Lift Log for Liftosaur", an unofficial name. Use "Liftosaur" alone only with permission from Liftosaur's author.
2. Run `scripts/package.sh`.
3. Sign in at https://apps.garmin.com/developer with a Garmin account and upload `bin/LiftosaurGarmin.iq`. To test first, mark it as a Beta App: only you can install it.
4. Add a description, screenshots (`scripts/preview.sh` makes them), and say that the app needs Liftosaur Premium and an API key.
5. Garmin reviews the app, usually within a few days. Users then install it from the Connect IQ Store and paste their key in its settings.

For an update: raise `Config.CLIENT`, add "What's new (<version>)" to `store/listing.md`, commit, run `scripts/release.sh <version>` (it tags the version and creates a GitHub release with the `.iq`), then upload that `.iq` with the same version in the store form. Every update must be signed with the same `developer_key.der`.

## Troubleshooting

- The app does not appear: it was built for another device. Rebuild for your watch, and check that `manifest.xml` lists it.
- The app shows an error icon or closes at start: read `GARMIN/APPS/LOGS/CIQ_LOG.YML` on the watch. "Out of memory" means the app passed the memory limit.
- Every request fails: check that Garmin Connect Mobile runs on the phone and is connected to the watch.
- "Sync stopped" after a set: Liftosaur rejected a change. RETRY sends it again; if it keeps failing, open the menu (hold the screen, or hold Up) and choose "Skip this change". It moves to the "not synced" list, which the Waiting screen's menu can resend.
- "API key invalid": create a new key in Liftosaur and paste it in the app settings in Garmin Connect (or in `resources-secret/secrets.xml` for a sideloaded build).
- Custom fields do not show in Garmin Connect: expected for a sideloaded app. A Beta App or store install shows them.
- Simulator shows a workout you did not start: unit tests and the app share storage in the simulator. `scripts/test.sh` wipes it after each run.
- `scripts/test.sh` hangs: another app is running in the simulator. The script stops it first; if it still hangs, quit the simulator.

## Contributing

Bug reports, tests and fixes are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request, and [SECURITY.md](SECURITY.md) to report a security problem. Coding agents start with [AGENTS.md](AGENTS.md). Everyone follows the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE). Liftosaur and Garmin are trademarks of their owners; this project is not affiliated with either.
