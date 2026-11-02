import Toybox.Lang;
import Toybox.Test;

(:test)
function slimDropsUnusedFieldsAndMergesWarmups(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    Test.assertEqual(w["programName"], "GZCLP");
    Test.assertEqual(w["startTime"], Fixtures.START);
    var squat = w["entries"][0];
    Test.assertEqual(squat["sets"].size(), 3);
    Test.assertEqual(squat["sets"][0]["setId"], "squatw");
    Test.assertEqual(squat["sets"][0]["isWarmup"], true);
    Test.assert(!squat.hasKey("imageUrl"));
    Test.assert(!squat["sets"][0].hasKey("originalWeight"));
    Test.assert(SlimWorkout.slim(null) == null);
    return true;
}

(:test)
function cursorSkipsCompletedAndSkipped(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatw"]));
    var c = SlimWorkout.cursor(w, []);
    Test.assertEqual(c[0], 0);
    Test.assertEqual(c[1], 1);
    c = SlimWorkout.cursor(w, ["squata", "squatb"]);
    Test.assertEqual(c[0], 1);
    Test.assertEqual(c[1], 0);
    var done = SlimWorkout.slim(Fixtures.workoutRaw(["squatw", "squata", "squatb", "bencha", "benchb"]));
    Test.assert(SlimWorkout.cursor(done, []) == null);
    return true;
}

(:test)
function applyPendingMarksQueuedSets(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    var queue = [
        {"t" => "set", "st" => Fixtures.START, "entryId" => "squat_barbell", "setId" => "squatw", "completed" => {"reps" => 5, "weight" => "40kg"}},
        {"t" => "set", "st" => 1l, "entryId" => "squat_barbell", "setId" => "squata", "completed" => {"reps" => 5}}
    ];
    SlimWorkout.applyPending(w, queue);
    Test.assert(SlimWorkout.findSet(w, "squatw")["completed"] != null);
    Test.assert(SlimWorkout.findSet(w, "squata")["completed"] == null);
    return true;
}

(:test)
function countsAndUnit(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatw"]));
    var counts = SlimWorkout.counts(w["entries"][0]);
    Test.assertEqual(counts[0], 1);
    Test.assertEqual(counts[1], 3);
    Test.assertEqual(SlimWorkout.unit(w), "kg");
    return true;
}

(:test)
function activityNameFitsFifteenChars(logger as Test.Logger) as Boolean {
    Test.assertEqual(SlimWorkout.activityName({"programName" => "GZCLP", "dayName" => "A1"}), "GZCLP A1");
    // Too long together: the day alone, which says what was trained, instead of a name cut mid-word.
    Test.assertEqual(SlimWorkout.activityName({"programName" => "Stan Workouts", "dayName" => "Push Day"}), "Push Day");
    Test.assertEqual(SlimWorkout.activityName({"programName" => "The Bridge 3.0 Hypertrophy", "dayName" => "Week 1 Day 2"}), "Week 1 Day 2");
    // A long day is cut at a word.
    Test.assertEqual(SlimWorkout.activityName({"programName" => "P", "dayName" => "Week 12 Day 3 Lower Body"}), "Week 12 Day 3");
    Test.assertEqual(SlimWorkout.activityName({"programName" => "Stan Workouts", "dayName" => null}), "Stan Workouts");
    Test.assertEqual(SlimWorkout.activityName({"programName" => null, "dayName" => "Upper"}), "Upper");
    Test.assertEqual(SlimWorkout.activityName({"programName" => null, "dayName" => "Supercalifragilistic"}), "Supercalifragil");
    Test.assertEqual(SlimWorkout.activityName({"programName" => null, "dayName" => null}), "Lift Log");
    return true;
}

(:test)
function slimKeepsEquipment(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    Test.assertEqual(w["entries"][0]["equipment"], "barbell");
    return true;
}

(:test)
function slimSkipsMalformedEntriesAndSets(logger as Test.Logger) as Boolean {
    var raw = Fixtures.workoutRaw([]);
    raw["entries"].add("not an entry");
    raw["entries"].add({"entryId" => "x", "name" => "X", "sets" => "nope", "warmupSets" => [5, null]});
    raw["entries"][0]["sets"].add(7);
    var w = SlimWorkout.slim(raw);
    Test.assertEqual(w["entries"].size(), 3);
    Test.assertEqual(w["entries"][0]["sets"].size(), 3);
    Test.assertEqual(w["entries"][2]["sets"].size(), 0);
    Test.assert(SlimWorkout.slim({"entries" => "x"}) == null);
    return true;
}

(:test)
function slimKeepsExerciseId(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    Test.assertEqual(w["entries"][0]["exerciseId"], "squat_barbell");
    return true;
}

(:test)
function cursorStaysOnFocusedExerciseUntilItIsDone(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["bencha"]));
    var c = SlimWorkout.cursorAt(w, [], "bench_barbell");
    Test.assertEqual(c[0], 1);
    Test.assertEqual(c[1], 1);
    // Skipped sets of the focused exercise don't hold it.
    c = SlimWorkout.cursorAt(w, ["benchb"], "bench_barbell");
    Test.assertEqual(c[0], 0);
    Test.assertEqual(c[1], 0);
    // No focus, or a focus no longer in the workout: program order.
    Test.assertEqual(SlimWorkout.cursorAt(w, [], null)[0], 0);
    Test.assertEqual(SlimWorkout.cursorAt(w, [], "gone")[0], 0);
    var done = SlimWorkout.slim(Fixtures.workoutRaw(["bencha", "benchb"]));
    Test.assertEqual(SlimWorkout.cursorAt(done, [], "bench_barbell")[0], 0);
    return true;
}
