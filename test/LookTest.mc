import Toybox.Lang;
import Toybox.Test;

(:test)
function lookRestTextAndFraction(logger as Test.Logger) as Boolean {
    var rest = {"at" => 1000, "dur" => 90};
    Test.assert(Look.restText(null, 1000) == null);
    Test.assertEqual(Look.restText(rest, 1048), "0:42 / 1:30");
    Test.assertEqual(Look.restText(rest, 1090), "+0:00 / 1:30");
    Test.assertEqual(Look.restText(rest, 1102), "+0:12 / 1:30");
    Test.assert(TestUtil.near(Look.restFraction(rest, 1000), 1.0));
    Test.assert(TestUtil.near(Look.restFraction(rest, 1045), 0.5));
    Test.assert(TestUtil.near(Look.restFraction(rest, 1200), 0.0));
    Test.assert(TestUtil.near(Look.restFraction(null, 1000), 0.0));
    Test.assertEqual(Look.restOver(rest, 1089), false);
    Test.assertEqual(Look.restOver(rest, 1090), true);
    Test.assertEqual(Look.restOver(null, 1090), false);
    return true;
}

(:test)
function lookPlatesOnlyForBarbell(logger as Test.Logger) as Boolean {
    var plates = {"plates" => [{"weight" => "20kg", "num" => 2}]};
    Test.assertEqual(Look.showPlates({"equipment" => "barbell"}, plates), true);
    Test.assertEqual(Look.showPlates({"equipment" => "dumbbell"}, plates), false);
    Test.assertEqual(Look.showPlates({"equipment" => null}, plates), false);
    Test.assertEqual(Look.showPlates({"equipment" => "barbell"}, {"plates" => []}), false);
    Test.assertEqual(Look.showPlates({"equipment" => "barbell"}, {"plates" => null}), false);
    return true;
}

(:test)
function lookInfoLine(logger as Test.Logger) as Boolean {
    var barbell = {"equipment" => "barbell"};
    var warm = {"isWarmup" => true, "isAmrap" => false, "plates" => [{"weight" => "20kg", "num" => 2}]};
    var line = Look.infoLine(barbell, warm);
    Test.assertEqual(line[0], "Warmup · Plates: ");
    Test.assertEqual(line[1], "2x20");
    var amrap = {"isWarmup" => false, "isAmrap" => true, "plates" => null};
    line = Look.infoLine({"equipment" => "dumbbell"}, amrap);
    Test.assertEqual(line[0], "AMRAP");
    Test.assertEqual(line[1], "");
    line = Look.infoLine({"equipment" => "dumbbell"}, {"isWarmup" => false, "isAmrap" => false, "plates" => null});
    Test.assertEqual(line[0], "");
    Test.assertEqual(line[1], "");
    return true;
}

(:test)
function lookSummaryCountsCompletedSets(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatw", "squata"]));
    var s = Look.summary(w, Fixtures.START + 3723000l);
    Test.assertEqual(s["sets"], 2);
    Test.assertEqual(s["volume"], "700 kg");
    Test.assertEqual(s["time"], "1:02:03");
    var none = Look.summary(SlimWorkout.slim(Fixtures.workoutRaw([])), Fixtures.START - 5000l);
    Test.assertEqual(none["sets"], 0);
    Test.assertEqual(none["volume"], "0 kg");
    Test.assertEqual(none["time"], "0:00:00");
    return true;
}

(:test)
function lookAdjustsRestAndEndsItNow(logger as Test.Logger) as Boolean {
    var rest = {"at" => 1000, "dur" => 90};
    Test.assertEqual(Look.adjustRest(rest, 15, 1010)["dur"], 105);
    Test.assertEqual(Look.adjustRest(rest, -15, 1010)["dur"], 75);
    // 10 s left; -15 s would end in the past, so the rest ends now.
    Test.assertEqual(Look.adjustRest(rest, -15, 1080)["dur"], 80);
    Test.assertEqual(Look.adjustRest(rest, 15, 1010)["at"], 1000);
    Test.assert(Look.adjustRest(null, 15, 1010) == null);
    return true;
}

(:test)
function lookHeartRateText(logger as Test.Logger) as Boolean {
    Test.assertEqual(Look.heartRate(142), "142");
    Test.assertEqual(Look.heartRate(null), "--");
    Test.assertEqual(Look.heartRate(0), "--");
    return true;
}

(:test)
function lookInfoLineShowsHoldTime(logger as Test.Logger) as Boolean {
    var line = Look.infoLine({"equipment" => null}, {"isWarmup" => false, "isAmrap" => false, "plates" => null, "setTimer" => 60});
    Test.assertEqual(line[0], "Hold 1:00");
    return true;
}

(:test)
function tickerRunsLaterOnceAndTicksTheScreen(logger as Test.Logger) as Boolean {
    var probe = new TickProbe();
    Ticker.watch(probe);
    Ticker.later(probe.method(:later));
    Ticker.tick();
    Ticker.tick();
    Test.assertEqual(probe.laters, 1);
    Test.assertEqual(probe.ticks, 2);
    Ticker.unwatch(probe);
    Ticker.tick();
    Test.assertEqual(probe.ticks, 2);
    return true;
}

(:test)
class TickProbe {
    var ticks = 0;
    var laters = 0;
    function initialize() {}
    function tick() { ticks++; }
    function later() { laters++; }
}

(:test)
function lookInfoLineShowsRpe(logger as Test.Logger) as Boolean {
    var set = {"isWarmup" => false, "isAmrap" => true, "plates" => null, "rpe" => 8, "completed" => null};
    Test.assertEqual(Look.infoLine({"equipment" => "dumbbell"}, set)[0], "AMRAP · RPE 8");
    // A logged set shows the RPE that was logged.
    set["completed"] = {"reps" => 5, "rpe" => 8.5};
    Test.assertEqual(Look.infoLine({"equipment" => "dumbbell"}, set)[0], "AMRAP · RPE 8.5");
    var barbell = {"isWarmup" => false, "isAmrap" => false, "rpe" => 7, "completed" => null,
        "plates" => [{"weight" => "20kg", "num" => 2}]};
    var line = Look.infoLine({"equipment" => "barbell"}, barbell);
    Test.assertEqual(line[0], "RPE 7 · Plates: ");
    Test.assertEqual(line[1], "2x20");
    return true;
}

(:test)
function lookAdjustRestKeepsItsSet(logger as Test.Logger) as Boolean {
    var rest = Look.adjustRest({"at" => 100, "dur" => 90, "setId" => "squatw"}, 15, 120);
    Test.assertEqual(rest["dur"], 105);
    Test.assertEqual(rest["setId"], "squatw");
    return true;
}

(:test)
function lookSummaryCountsMixedUnitsInWorkoutUnit(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatw"]));
    // squatw: 5 x 40kg = 200 kg. A set logged in lb counts in kg.
    SlimWorkout.markCompleted(w, "squata", {"reps" => 2, "weight" => "100lb"});
    var s = Look.summary(w, Fixtures.START);
    Test.assertEqual(s["sets"], 2);
    Test.assert(TestUtil.near(s["volumeNum"], 200.0 + 2 * 45.359237));
    Test.assertEqual(s["volume"], "290.72 kg");
    return true;
}

(:test)
function lookLapTexts(logger as Test.Logger) as Boolean {
    Test.assertEqual(Look.lapLabel("Squat", true), "Squat (warm-up)");
    Test.assertEqual(Look.lapLabel("Squat", false), "Squat");
    Test.assertEqual(Look.weightText(102.5, "kg"), "102.5 kg");
    Test.assertEqual(Look.weightText(null, null), "Bodyweight");
    return true;
}

(:test)
function lookOverviewLineShowsProgressAndNextSet(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatw", "bencha", "benchb"]));
    Test.assertEqual(Look.overviewLine(w["entries"][0], true), "Now · 1/3 · 5×100kg");
    Test.assertEqual(Look.overviewLine(w["entries"][0], false), "1/3 · 5×100kg");
    Test.assertEqual(Look.overviewLine(w["entries"][1], false), "Done · 2/2");
    var bw = SlimWorkout.slim(Fixtures.workoutRaw([]));
    bw["entries"][1]["sets"][0]["weight"] = null;
    Test.assertEqual(Look.overviewLine(bw["entries"][1], false), "0/2 · 5 reps");
    bw["entries"][1]["sets"][0]["setTimer"] = 60;
    Test.assertEqual(Look.overviewLine(bw["entries"][1], false), "0/2 · 1:00");
    return true;
}
