# Contributing to Lift Log for Liftosaur

Lift Log for Liftosaur is an unofficial Garmin Connect IQ watch app, written in Monkey C. It runs Liftosaur workouts through the Liftosaur Workout API (https://www.liftosaur.com/api/v1) and records a Garmin Strength Training activity. It is not affiliated with Liftosaur or Garmin.

One person maintains it in their spare time. Bug reports, tests, fixes and small features are welcome. This guide says how to make a change that can be merged.

## Before you start

- For a bug, open an issue with the bug report form first, or comment on an existing one.
- For a feature or a new watch, open an issue and wait for a reply before you write much code. Check the scope section below first.
- Typos, docs fixes and small test additions can go straight to a pull request.

## Toolchain

You need a Mac with Homebrew. The scripts expect macOS paths. On Linux or Windows the code builds, but you will need to adjust the scripts.

1. Install the Connect IQ SDK Manager from https://developer.garmin.com/connect-iq/sdk/. In SDK Manager, download the newest SDK and set it as current. Download these devices too: `fr170` (tests and the default build), `fr255s`, `fr965` and `venu3` (screenshots). `scripts/package.sh` builds every watch in `manifest.xml`, so download all of them before you run it.

   `scripts/sdk.sh` prints the SDK folder the other scripts use:

   ```bash
   scripts/sdk.sh
   ```

2. Install Java 17. The Connect IQ compiler needs it, and the scripts look for it in `/opt/homebrew/opt/openjdk@17`:

   ```bash
   brew install openjdk@17
   ```

3. Create a developer key in the repo root. It signs your builds. Never commit it; `.gitignore` excludes `*.der`, `*.pem` and `developer_key.*`.

   ```bash
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```

4. Create `resources-secret/secrets.xml`. `scripts/build.sh` and `scripts/test.sh` fail without it.

   ```bash
   mkdir -p resources-secret
   cp secrets.example.xml resources-secret/secrets.xml
   ```

   For tests and previews, the placeholder key is enough. To run the app against your own Liftosaur account, replace the placeholder with your API key (Liftosaur → Settings → API Keys, needs Premium).

5. Optional: VS Code with the "Monkey C" extension, for editing and "Monkey C: Build for Device".

Check the setup:

```bash
scripts/test.sh
```

The last line of the output should start with `PASSED`.

## Project layout

- `source/`: the app. Pure logic modules (`Look.mc`, `Nav.mc`, `Prompt.mc`, `TimedSet.mc`, `Weight.mc`, `Queue.mc`, `ErrorPolicy.mc` and others) hold the rules. `Controller.mc`, `Sync.mc` and `Api.mc` talk to the API. `source/ui/` holds the views.
- `test/`: unit tests, one file per area (`WeightTest.mc`, `NavTest.mc` and so on). `test/Fakes.mc` has fakes such as `FakeApi`. `test/Fixtures.mc` has sample API responses.
- `preview/Preview.mc`: fake data for `scripts/preview.sh`.
- `scripts/`: build, test, preview and package scripts.
- `docs/superpowers/specs/`: design docs. Read the relevant one before you change a feature.
- `manifest.xml`: the supported watches.
- `store/`: the Connect IQ Store listing, privacy policy and media.

## Workflow

1. Fork the repo and create a branch from `main`:

   ```bash
   git checkout -b fix-undo-crash
   ```

2. Keep each pull request to one change. A bug fix and a refactor go in separate pull requests. Small pull requests get reviewed sooner.
3. Write the test first (see below), then the code.
4. Run `scripts/test.sh` and `scripts/package.sh`. Both must pass.
5. For a UI change, take screenshots (see below).
6. Open a pull request and fill in the template.

### Commit messages

Match the existing history:

- The subject is a plain imperative sentence, with no prefix and no trailing period: "Fix Too Many Timers crash on confirming a dialog", "Step weight by 2.5 kg or 5 lb".
- The body says why the change was needed and what the user sees. It does not repeat the diff.

Example:

```
Step weight by 2.5 kg or 5 lb

The API's plates are what to load for one set, not the plates the gym
has, so a set loaded with 20 kg plates stepped by 40 kg.
```

## Tests

Tests are required for every code change.

- **Bug fixes** start with a test that fails because of the bug. Commit the test with the fix.
- **Features** start with failing tests for their logic. Write the tests, see them fail, then write the code.

Tests are Connect IQ Run No Evil tests: global functions marked `(:test)` that take a `Test.Logger` and return `true`. Helpers go inside a `(:test) module`, because the runner treats every global `(:test)` function as a test.

```monkeyc
(:test)
function weightStepIsSmallestIncrement(logger as Test.Logger) as Boolean {
    Test.assert(TestUtil.near(Weight.step("kg"), 2.5));
    return true;
}
```

Name a test after the behavior it checks. Use the fakes in `test/Fakes.mc` instead of the network, and add a fake there if you need a new one.

Run the tests in the simulator:

```bash
scripts/test.sh
```

The script stops any app running in the simulator, runs the tests on `fr170`, and wipes the test storage afterwards. It fails unless the output has a `PASSED` line.

Then build every watch in `manifest.xml`:

```bash
scripts/package.sh
```

This catches code that compiles on one watch and fails on another, such as a missing font or an API a watch lacks. It writes `bin/LiftosaurGarmin.iq`; do not commit it.

### Keep logic testable

Put rules and calculations in pure modules, like `source/Look.mc`, `Nav.mc`, `Prompt.mc`, `TimedSet.mc` and `Weight.mc`. A pure module takes plain values and returns plain values. It does not draw, read storage, start timers or make requests, so a test can call it directly.

Views in `source/ui/` stay thin: they read state, call the pure modules and draw. If a view grows an `if` that decides what the user can do, move that decision into a module and test it there.

Watches have little memory. Avoid large objects and long-lived arrays, and run the app on a small watch such as `fr255s` before you open the pull request. Read `GARMIN/APPS/LOGS/CIQ_LOG.YML` or the simulator log for "Out of memory".

## UI changes

Attach screenshots of the changed screen on three watches:

- `fr255s`: a small round watch with buttons
- `fr965`: a large round watch with buttons
- `venu3`: a touch watch with no Up and Down buttons
- `venusq2`: a rectangular touch watch

`scripts/preview.sh` opens one screen with fake data in the simulator. It needs no Liftosaur account or network:

```bash
scripts/preview.sh rest fr255s
scripts/preview.sh rest fr965
scripts/preview.sh rest venu3
scripts/preview.sh rest venusq2
```

Modes: `rest`, `over`, `norest`, `hold`, `done`, `start`, `waiting`, `error`, `nokey`, `browse`, `prompt`, `edit`, `rpe`, `timed`, `timedwork`, `menu`, `overview`. Take the screenshot of the simulator window with macOS: Cmd+Shift+4, then Space, then click the window. If your change adds a screen that no mode shows, add a mode to `preview/Preview.mc` and `scripts/preview.sh`.

Every control must work both ways:

- **Buttons**: on five-button watches, with no touch.
- **Touch**: on touch-only watches, with no Up and Down buttons.

Test both in the simulator. If you add or change a control, update the controls table in `README.md` ("Using the app").

Garmin runs a behavior handler (`onSelect`, `onNextPage`, `onBack`) before the raw key or tap event, and drops the raw event when the behavior returns `true`. Check the existing delegates in `source/ui/` before you add input handling.

## Secrets

Never commit:

- an API key. `resources-secret/` is gitignored. Keep your key there and nowhere else.
- a developer key (`developer_key.der`, `developer_key.pem`).
- a `.prg` built with your key. Anyone with the file can use the key inside it.

Before you push, check what you are about to send:

```bash
git status
git diff --cached
```

Remove keys from logs, screenshots and issue text too. Liftosaur API keys start with `lftsk_`. If you commit a key by mistake, delete it in Liftosaur (Settings → API Keys) and create a new one; removing it from git history is not enough.

## Scope

In scope:

- Bugs in the watch app.
- Features that the Liftosaur Workout API supports and that fit a watch screen. Parity with the Liftosaur Apple Watch app is a good guide.
- Support for more Garmin watches with Connect IQ API level 5 or higher.
- Memory, battery and layout fixes for specific watches.
- Tests, docs and build scripts.

Out of scope:

- Anything the Liftosaur Workout API cannot do. For example, deleting a set: the API has no call for it. Ask Liftosaur for the API change first (https://github.com/astashov/liftosaur/issues).
- Changes to Liftosaur itself: the web app, the phone apps, programs or Liftoscript. Report those to Liftosaur.
- Ports to other platforms, such as Wear OS, Apple Watch or other watch brands.
- Watches below Connect IQ API level 5.
- Analytics, tracking, or any server run by this project. See `store/PRIVACY.md`.

## Reporting bugs

Use the bug report form. Include:

- Watch model and firmware version (on the watch: Settings → System → About).
- App version (Garmin Connect → Connect IQ Store → installed apps, or the store page).
- Phone model and OS version, and whether Garmin Connect Mobile was running and connected.
- Whether you used buttons or touch.
- Steps to reproduce, what you expected, and what happened.
- If the app crashed or showed an error icon: `GARMIN/APPS/LOGS/CIQ_LOG.YML` from the watch. Connect the watch by USB; on macOS use OpenMTP (https://openmtp.ganeshrvel.com) or Garmin Express, because the watch uses MTP.

Remove your API key from anything you paste. It starts with `lftsk_`.

Problems with your program, Liftoscript, or the Liftosaur phone or web app belong in Liftosaur's tracker: https://github.com/astashov/liftosaur/issues

## Releases

Releases are maintainer-only. The maintainer raises the version (`Config.CLIENT` and a "What's new (<version>)" section in `store/listing.md`), runs `scripts/release.sh <version>`, which builds the signed store package from a clean checkout, tags `v<version>` and creates a GitHub release with the package, then uploads the same `.iq` to the Connect IQ Store. Do not change version numbers or store files (`store/`, `resources-store/`) in a pull request unless asked.

## Response times

This is a spare-time project with one maintainer. Expect a reply to issues and pull requests within a few weeks, sometimes longer. A pull request that follows this guide, with tests and screenshots, is the fastest to review. If nothing has happened after a month, a polite comment on the issue or pull request is fine.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Report security problems as described in [SECURITY.md](SECURITY.md), not in public issues.
