import Toybox.Lang;
import Toybox.Test;

(:test)
function fitExerciseLooksUpVariantThenBase(logger as Test.Logger) as Boolean {
    var table = {"squat" => 28 * 65536 + 6, "squat_dumbbell" => 28 * 65536 + 31};
    Test.assertEqual(FitExercise.lookup(table, "squat_dumbbell"), 28 * 65536 + 31);
    // No entry for the barbell variant: the exercise's own mapping.
    Test.assertEqual(FitExercise.lookup(table, "squat_barbell"), 28 * 65536 + 6);
    Test.assertEqual(FitExercise.lookup(table, "squat"), 28 * 65536 + 6);
    // Custom exercises have random ids.
    Test.assert(FitExercise.lookup(table, "k3j9dq_barbell") == null);
    Test.assert(FitExercise.lookup(table, null) == null);
    return true;
}

(:test)
function fitExerciseSplitsCodeAndMarksUnknown(logger as Test.Logger) as Boolean {
    var parts = FitExercise.split(28 * 65536 + 6);
    Test.assertEqual(parts[0], 28);
    Test.assertEqual(parts[1], 6);
    // FIT's "unknown" exercise category.
    parts = FitExercise.split(null);
    Test.assertEqual(parts[0], 65534);
    Test.assertEqual(parts[1], 0);
    return true;
}

(:test)
function fitExerciseCodesForKeepsOnlyTheWorkout(logger as Test.Logger) as Boolean {
    var table = {"squat" => 1835014, "benchPress" => 1};
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    var codes = FitExercise.codesFor(table, w);
    Test.assertEqual(codes.size(), 2);
    Test.assertEqual(codes["squat_barbell"], 1835014);
    Test.assertEqual(codes["benchPress_barbell"], 1);
    return true;
}

// The shipped table: spot checks against the FIT profile, so a regenerated table can't silently shift.
(:test)
function fitExerciseTableMatchesFitProfile(logger as Test.Logger) as Boolean {
    var table = FitExercise.load();
    Test.assert(table.size() >= 250);
    var expect = [
        ["squat_barbell", 28, 6],              // barbellBackSquat
        ["benchPress_barbell", 0, 1],          // barbellBenchPress
        ["benchPress_dumbbell", 0, 6],         // dumbbellBenchPress
        ["deadlift_barbell", 8, 0],            // barbellDeadlift
        ["romanianDeadlift_barbell", 8, 23],   // romanianDeadlift
        ["overheadPress_barbell", 24, 14],     // overheadBarbellPress
        ["latPulldown_cable", 21, 13],         // latPulldown
        ["tricepsPushdown_cable", 30, 39],     // tricepsPressdown
        ["pullUp_bodyweight", 21, 38],         // pullUp
        ["hipThrust_barbell", 10, 0],          // barbellHipThrustOnFloor
        ["standingCalfRaise_leverageMachine", 1, 18],  // standingCalfRaise
        ["standingCalfRaise_dumbbell", 1, 20], // standingDumbbellCalfRaise
        ["reverseWristCurl_dumbbell", 7, 17]   // dumbbellReverseWristCurl
    ];
    for (var i = 0; i < expect.size(); i++) {
        var parts = FitExercise.split(FitExercise.lookup(table, expect[i][0]));
        Test.assertEqual(parts[0], expect[i][1]);
        Test.assertEqual(parts[1], expect[i][2]);
    }
    Test.assert(FitExercise.lookup(table, "deadHang_bodyweight") == null);
    return true;
}
