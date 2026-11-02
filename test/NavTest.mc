import Toybox.Lang;
import Toybox.Test;

// Fixture positions: squat [squatw, squata, squatb] at entry 0, bench [bencha, benchb] at entry 1.
(:test)
function navStepsAcrossExercisesAndStopsAtEnds(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    var p = Nav.step(w, [0, 2], 1);
    Test.assertEqual(p[0], 1);
    Test.assertEqual(p[1], 0);
    p = Nav.step(w, [1, 0], -1);
    Test.assertEqual(p[0], 0);
    Test.assertEqual(p[1], 2);
    p = Nav.step(w, [0, 0], 1);
    Test.assertEqual(p[1], 1);
    Test.assert(Nav.step(w, [0, 0], -1) == null);
    Test.assert(Nav.step(w, [1, 1], 1) == null);
    return true;
}

(:test)
function navJumpsToFirstOpenSetOfExercise(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["bencha", "squatw"]));
    var p = Nav.jumpEntry(w, [0, 0], 1);
    Test.assertEqual(p[0], 1);
    Test.assertEqual(p[1], 1);
    p = Nav.jumpEntry(w, [1, 1], -1);
    Test.assertEqual(p[0], 0);
    Test.assertEqual(p[1], 1);
    Test.assert(Nav.jumpEntry(w, [1, 0], 1) == null);
    Test.assert(Nav.jumpEntry(w, [0, 1], -1) == null);
    var done = SlimWorkout.slim(Fixtures.workoutRaw(["bencha", "benchb"]));
    p = Nav.jumpEntry(done, [0, 0], 1);
    Test.assertEqual(p[1], 1);
    return true;
}

(:test)
function navComparesPositions(logger as Test.Logger) as Boolean {
    Test.assertEqual(Nav.compare([0, 2], [1, 0]), -1);
    Test.assertEqual(Nav.compare([1, 0], [0, 2]), 1);
    Test.assertEqual(Nav.compare([1, 1], [1, 1]), 0);
    Test.assertEqual(Nav.compare([1, 0], [1, 1]), -1);
    // null is "All sets done", after every set.
    Test.assertEqual(Nav.compare([1, 1], null), -1);
    Test.assertEqual(Nav.compare(null, [0, 0]), 1);
    return true;
}

(:test)
function navCycleEntryGoesToNextExerciseAndWraps(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatw"]));
    var p = Nav.cycleEntry(w, [0, 1]);
    Test.assertEqual(p[0], 1);
    Test.assertEqual(p[1], 0);
    p = Nav.cycleEntry(w, [1, 0]);
    Test.assertEqual(p[0], 0);
    Test.assertEqual(p[1], 1);
    // From "All sets done", the first exercise.
    p = Nav.cycleEntry(w, null);
    Test.assertEqual(p[0], 0);
    // One exercise: stays on it.
    var one = SlimWorkout.slim(Fixtures.workoutRaw([]));
    one["entries"].remove(one["entries"][1]);
    p = Nav.cycleEntry(one, [0, 2]);
    Test.assertEqual(p[0], 0);
    Test.assertEqual(p[1], 0);
    return true;
}
