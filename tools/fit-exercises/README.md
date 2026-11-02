# Liftosaur → Garmin exercise table

Builds `resources/jsonData/fit_exercises.json`: each Liftosaur exercise id maps to the FIT exercise category and name that Garmin Connect uses for its exercise list and muscle map. A value is `category * 65536 + name`. `source/FitExercise.mc` reads it.

## Sources

- FIT profile: `src/profile.js` from https://github.com/garmin/fit-javascript-sdk (the `exerciseCategory` enum and one `<category>ExerciseName` enum per category).
- Liftosaur exercises: `src/models/exercise.ts` from https://github.com/astashov/liftosaur (`allExercisesList`).

## Rebuild

```bash
mkdir -p /tmp/fitsrc/fit-sdk /tmp/fitsrc/liftosaur-src /tmp/fitwork
curl -sL https://raw.githubusercontent.com/garmin/fit-javascript-sdk/main/src/profile.js -o /tmp/fitsrc/fit-sdk/profile.js
gh api repos/astashov/liftosaur/contents/src/models/exercise.ts -H "Accept: application/vnd.github.raw" > /tmp/fitsrc/liftosaur-src/exercise.ts
python3 -I tools/fit-exercises/extract.py /tmp/fitsrc /tmp/fitwork
python3 -I tools/fit-exercises/match.py /tmp/fitwork > /tmp/fitwork/default.txt
python3 -I tools/fit-exercises/build.py /tmp/fitwork
cp /tmp/fitwork/table.json resources/jsonData/fit_exercises.json
scripts/test.sh
```

`match.py` scores Garmin names against each exercise's name and default equipment; `default.txt` lists the best match for review. Automatic matches are only a start: `build.py` holds the hand-reviewed fixes (`OVR`, by exercise) and equipment variants (`EQOVR`, such as `benchPress_dumbbell`). An exercise mapped to `None` has no Garmin equivalent and records as unknown.

To correct a mapping, change `OVR` or `EQOVR`, rebuild, and add the case to `fitExerciseTableMatchesFitProfile` in `test/FitExerciseTest.mc` if it's a common lift. `build.py` fails if a Garmin name doesn't exist in the FIT profile.
