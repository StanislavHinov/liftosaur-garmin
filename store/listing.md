# Connect IQ Store listing

Paste these into the form at https://apps.garmin.com/developer when you upload `bin/LiftosaurGarmin.iq`.

## App type

Device App (watch app). Category: Health & Fitness.

## Name

Lift Log for Liftosaur

An unofficial name, chosen without the Liftosaur author's permission to use "Liftosaur" alone. It matches `AppName` in `resources/strings.xml`.

## Short description

Log your Liftosaur workouts from your watch.

## Description

Run your Liftosaur program from your wrist. The watch shows the current exercise, set, reps (or the rep range, such as 6-9) and weight, and logs each set to your Liftosaur account with one press of Start. The phone app updates as you train.

- Start the next workout from your program, pick another day, or continue the one open on your phone.
- Works with buttons or by touch alone: tap the reps or weight to change it, hold the screen for the menu. Weight changes by 2.5 kg or 5 lb.
- Every set type: RPE, one-sided reps, asked weights, program variables, and timed sets with a get-ready countdown.
- Swipe between sets and exercises, or hold Down for the next exercise; do exercises in any order. The workout overview shows each exercise's progress and next set.
- Undo or edit a logged set; add a set.
- Rest timer with a countdown ring that stays in step with the phone, also for sets checked on the phone, one buzz when rest is over, and -15 s / +15 s / skip.
- Heart rate and the time of day on screen (the time can be turned off), and plates to load for barbell exercises.
- Records a Garmin Strength Training activity with heart rate, calories and one lap per set (can be turned off).
- Works offline: sets are kept on the watch and sent when your phone is back, even after you close the app.
- In Garmin Connect, the activity's laps show each set's exercise, reps and weight, and the summary shows the program, day, sets and volume.
- A watch-face complication shows your next workout day.

Requirements:
- Liftosaur Premium and a Liftosaur API key (Liftosaur: Settings, API Keys).
- After installing, open the Garmin Connect app: Connect IQ Store, Lift Log for Liftosaur, Settings, and paste the key.
- Garmin Connect must be running on your phone during the workout.

Unofficial: not affiliated with Liftosaur or Garmin.

## What's new (1.1.0)

- The time of day next to the heart rate. Turn it off in the workout menu ("Hide time") or in the app's settings in Garmin Connect.
- Rep ranges show as on the phone, such as 6-9, instead of only the top number.
- Checking a set on the phone now starts its rest timer on the watch too.

## What's new (1.0.0)

- First release.

## Form answers

| Field | Answer |
| --- | --- |
| Hero Image | `store/hero-1440x720.jpg` |
| Category / Subcategory | Health & Fitness, then the closest strength or training subcategory |
| Does your app collect user data? | Yes: it sends workout data and the API key to liftosaur.com. Privacy policy link: https://gist.github.com/StanislavHinov/d233db81acf2119dad94be9b90d937b5 (a secret gist of `store/PRIVACY.md`; update it when the policy changes) |
| ANT+ profiles | No |
| Regional limits | No |
| Cover Image | `store/icon-500.png` |
| Icons for App Store on Device | No |
| Screen Images | `store/screenshots/start.png`, `norest.png`, `edit.png`, `overview.png`, `rest.png`, `rpe.png`, `timedwork.png`, `done.png` |
| Preview Video | Upload the release video (kept outside git, see `release-<version>/`) to YouTube (Unlisted), paste the link |
| Email Address | A contact address you don't mind being public |
| Source Code URL | https://github.com/StanislavHinov/liftosaur-garmin |
| Review Notification | Yes |
| App Migration | No |
| Monetization | No |
| iOS Companion App URL | https://apps.apple.com/us/app/liftosaur-scriptable-workouts/id1661880849 |
| Android Companion App URL | https://play.google.com/store/apps/details?id=com.liftosaur.www.twa |
| Product URL | Empty |

## Permissions the app asks for, and why

- Background: sends sets that are still waiting after the app is closed.
- Communications: talks to the Liftosaur API through the phone.
- ComplicationPublisher: shows the next workout day on watch faces.
- Fit, FitContributor: records the strength activity and the set fields.
- Sensor: heart rate during the workout.

## Privacy

The app sends the API key and workout data only to liftosaur.com. It keeps the current workout and unsent sets on the watch until they are sent, in the background if the app was closed.
