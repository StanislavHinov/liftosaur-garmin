import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
module ControllerUtil {
    function startedController(api, rec, ui) {
        Store.clearAll();
        var c = new Controller(api, rec, ui);
        c.boot();
        api.respond(200, {"data" => {"workout" => null}});
        api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
        c.startWorkout();
        api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
        return c;
    }
}

(:test)
function controllerBootShowsStartWithNextWorkout(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var ui = new FakeUi();
    var c = new Controller(api, new FakeRec(), ui);
    c.boot();
    Test.assertEqual(api.last()["path"], "/workout/current");
    api.respond(200, {"data" => {"workout" => null}});
    Test.assertEqual(api.last()["path"], "/workout/next");
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    Test.assertEqual(ui.lastShown(), "start");
    Test.assertEqual(c.preview()["dayName"], "A1");
    return true;
}

(:test)
function controllerBootTakesOverLiveWorkout(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var rec = new FakeRec();
    var ui = new FakeUi();
    var c = new Controller(api, rec, ui);
    c.boot();
    api.respond(200, Fixtures.response(Fixtures.workoutRaw(["squatw"])));
    Test.assertEqual(rec.started, 1);
    Test.assertEqual(ui.lastShown(), "active");
    Test.assertEqual(Store.rec()["intervals"][0][0], Fixtures.START);
    return true;
}

(:test)
function controllerStartSendsLongStartTime(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var ui = new FakeUi();
    ControllerUtil.startedController(api, rec, ui);
    var startReq = api.requests[2];
    Test.assertEqual(startReq["path"], "/workout/start");
    Test.assert(startReq["body"]["startTime"] instanceof Long);
    Test.assertEqual(rec.started, 1);
    Test.assertEqual(ui.lastShown(), "active");
    return true;
}

(:test)
function controllerStartConflictAdoptsCurrent(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var ui = new FakeUi();
    var c = new Controller(api, new FakeRec(), ui);
    c.boot();
    api.respond(200, {"data" => {"workout" => null}});
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    c.startWorkout();
    api.respond(409, {"error" => {"code" => "workout_already_active", "message" => "x"}});
    Test.assertEqual(api.last()["path"], "/workout/current");
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    Test.assertEqual(ui.lastShown(), "active");
    return true;
}

(:test)
function controllerLogSetQueuesLapsAndRests(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var ui = new FakeUi();
    var c = ControllerUtil.startedController(api, rec, ui);
    Test.assert(c.logSet(6, 42.5));
    var q = Store.queue();
    Test.assertEqual(q.size(), 1);
    Test.assertEqual(q[0]["setId"], "squatw");
    Test.assertEqual(q[0]["completed"]["reps"], 6);
    Test.assertEqual(q[0]["completed"]["weight"], "42.5kg");
    Test.assert(SlimWorkout.findSet(Store.workout(), "squatw")["completed"] != null);
    Test.assertEqual(rec.laps, 1);
    Test.assertEqual(Store.rest()["dur"], 90);
    Test.assertEqual(ui.lastShown(), "active:next");
    Test.assertEqual(api.last()["path"], "/workout/set");
    return true;
}

(:test)
function controllerSkipMovesCursor(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.skipSet();
    var cur = SlimWorkout.cursor(Store.workout(), Store.skipped());
    Test.assertEqual(cur[1], 1);
    Test.assertEqual(Store.queue().size(), 0);
    return true;
}

(:test)
function controllerBootResumesStoredWorkout(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.logSet(5, 40.0);
    var requestsBefore = api.requests.size();
    var rec2 = new FakeRec();
    var ui2 = new FakeUi();
    var c2 = new Controller(new FakeApi(), rec2, ui2);
    c2.boot();
    Test.assertEqual(rec2.started, 1);
    Test.assertEqual(rec2.laps, 0);
    Test.assertEqual(ui2.lastShown(), "active");
    Test.assert(Store.rest() != null);
    Test.assertEqual(Store.queue().size(), 1);
    Test.assertEqual(SlimWorkout.cursor(Store.workout(), Store.skipped())[1], 1);
    Test.assert(requestsBefore > 0);
    return true;
}

(:test)
function controllerFinishQueuesAndSaves(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var ui = new FakeUi();
    var c = ControllerUtil.startedController(api, rec, ui);
    c.finish();
    var q = Store.queue();
    Test.assertEqual(q[q.size() - 1]["t"], "finish");
    Test.assert(!q[q.size() - 1].hasKey("intervals"));
    Test.assertEqual(rec.saved, 1);
    Test.assert(Store.workout() == null);
    Test.assertEqual(ui.lastShown(), "waiting");
    return true;
}

(:test)
function controllerPauseAddsIntervals(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var c = ControllerUtil.startedController(api, rec, new FakeUi());
    c.togglePause();
    Test.assert(c.isPaused());
    Test.assert(rec.paused);
    c.togglePause();
    Test.assert(!c.isPaused());
    c.finish();
    var q = Store.queue();
    Test.assertEqual(q[q.size() - 1]["intervals"].size(), 2);
    return true;
}

(:test)
function controllerWorkoutGoneSavesAndWaits(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var ui = new FakeUi();
    var c = ControllerUtil.startedController(api, rec, ui);
    c.onWorkoutGone();
    Test.assertEqual(rec.saved, 1);
    Test.assert(Store.workout() == null);
    Test.assertEqual(ui.lastShown(), "ended");
    return true;
}

(:test)
function controllerWithoutKeyAsksForItThenBoots(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    api.key = null;
    var ui = new FakeUi();
    var c = new Controller(api, new FakeRec(), ui);
    c.boot();
    Test.assertEqual(ui.lastShown(), "blocked:noKey");
    Test.assertEqual(api.requests.size(), 0);
    Store.setHalt({"reason" => "badKey", "message" => null});
    c.useKey("lftsk_new");
    Test.assert(Store.halt() == null);
    Test.assertEqual(api.last()["path"], "/workout/current");
    return true;
}

(:test)
function controllerLogsAnySetAndUnskipsIt(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var c = ControllerUtil.startedController(api, rec, new FakeUi());
    Test.assert(c.logSetAt(1, 0, 5, 60.0));
    var q = Store.queue();
    Test.assertEqual(q[0]["setId"], "bencha");
    Test.assertEqual(q[0]["completed"]["weight"], "60kg");
    Test.assert(SlimWorkout.findSet(Store.workout(), "bencha")["completed"] != null);
    Test.assertEqual(rec.laps, 1);
    // Skip takes the next set of the exercise just logged.
    c.skipSet();
    Test.assertEqual(Store.skipped()[0], "benchb");
    Test.assert(c.logSetAt(1, 1, 5, 60.0));
    Test.assertEqual(Store.skipped().size(), 0);
    return true;
}

(:test)
function controllerSaveSetEditsWithoutLapOrRest(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var c = ControllerUtil.startedController(api, rec, new FakeUi());
    c.logSet(5, 40.0);
    var restAt = Store.rest()["at"];
    Test.assert(c.saveSet(0, 0, 6, 42.5));
    var q = Store.queue();
    var last = q[q.size() - 1];
    Test.assertEqual(last["setId"], "squatw");
    Test.assertEqual(last["completed"]["reps"], 6);
    Test.assertEqual(last["completed"]["weight"], "42.5kg");
    Test.assertEqual(SlimWorkout.findSet(Store.workout(), "squatw")["completed"]["reps"], 6);
    Test.assertEqual(rec.laps, 1);
    Test.assertEqual(Store.rest()["at"], restAt);
    return true;
}

(:test)
function controllerUndoQueuesNullCompletion(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.logSet(5, 40.0);
    Test.assert(c.undoSet(0, 0));
    var q = Store.queue();
    var last = q[q.size() - 1];
    Test.assertEqual(last["setId"], "squatw");
    Test.assert(last.hasKey("completed") && last["completed"] == null);
    Test.assert(SlimWorkout.findSet(Store.workout(), "squatw")["completed"] == null);
    var cur = SlimWorkout.cursor(Store.workout(), Store.skipped());
    Test.assertEqual(cur[1], 0);
    var body = Requests.forRun([last])["body"];
    Test.assert(body.hasKey("completed") && body["completed"] == null);
    return true;
}

(:test)
function controllerAdjustsAndSkipsRest(logger as Test.Logger) as Boolean {
    var c = ControllerUtil.startedController(new FakeApi(), new FakeRec(), new FakeUi());
    c.logSet(5, 40.0);
    Test.assertEqual(Store.rest()["dur"], 90);
    c.adjustRest(15);
    Test.assertEqual(Store.rest()["dur"], 105);
    c.adjustRest(-15);
    Test.assertEqual(Store.rest()["dur"], 90);
    c.skipRest();
    Test.assert(Store.rest() == null);
    c.adjustRest(15);
    Test.assert(Store.rest() == null);
    return true;
}

(:test)
function controllerLogsAndSavesFullCompletion(logger as Test.Logger) as Boolean {
    var rec = new FakeRec();
    var c = ControllerUtil.startedController(new FakeApi(), rec, new FakeUi());
    Test.assert(c.logCompleted(1, 1, {"reps" => 5, "weight" => "60kg", "rpe" => 8.5}, 5, 60.0));
    var q = Store.queue();
    Test.assertEqual(q[0]["setId"], "benchb");
    Test.assert(TestUtil.near(q[0]["completed"]["rpe"], 8.5));
    Test.assertEqual(rec.laps, 1);
    Test.assert(c.saveCompleted(1, 1, {"reps" => 5, "weight" => "60kg", "rpe" => 9}));
    q = Store.queue();
    Test.assertEqual(q[q.size() - 1]["completed"]["rpe"], 9);
    Test.assertEqual(rec.laps, 1);
    return true;
}

(:test)
function controllerEditKeepsLoggedSetTimer(logger as Test.Logger) as Boolean {
    var c = ControllerUtil.startedController(new FakeApi(), new FakeRec(), new FakeUi());
    var set = {"weight" => "60kg", "completed" => {"reps" => 1, "setTimer" => 45, "setTimerLeft" => 40}};
    var body = c.completedFor(set, 2, 60.0);
    Test.assertEqual(body["reps"], 2);
    Test.assertEqual(body["setTimer"], 45);
    Test.assertEqual(body["setTimerLeft"], 40);
    Test.assert(!c.completedFor({"weight" => "60kg", "completed" => null}, 2, 60.0).hasKey("setTimer"));
    return true;
}

(:test)
function controllerWorkoutGoneWithoutRecordingSaysSo(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var ui = new FakeUi();
    var c = ControllerUtil.startedController(api, rec, ui);
    c.discardGarmin();
    c.onWorkoutGone();
    Test.assertEqual(rec.saved, 0);
    Test.assertEqual(ui.lastShown(), "ended:nosave");
    return true;
}

(:test)
function controllerLogSlidesToNextSetAndUndoSlidesBack(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var ui = new FakeUi();
    var c = ControllerUtil.startedController(api, new FakeRec(), ui);
    c.logSet(5, 40.0);
    Test.assertEqual(ui.lastShown(), "active:next");
    c.undoSet(0, 0);
    Test.assertEqual(ui.lastShown(), "active:back");
    return true;
}

(:test)
function controllerRestFollowsServerTimeWhenSetSyncs(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.logSet(5, 40.0);
    var at = Store.rest()["at"];
    var run = Store.queue();
    // The phone's rest starts when the server gets the set: between sending (at + 20) and the reply (at + 24).
    c.onSetsSent(run, at + 20, at + 24);
    Test.assertEqual(Store.rest()["at"], at + 22);
    return true;
}

(:test)
function controllerRestStaysWhenOverOrNotItsSet(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.logSet(5, 40.0);
    var at = Store.rest()["at"];
    var run = Store.queue();
    // Rest already over on the watch: moving it would buzz a second time.
    c.onSetsSent(run, at + 200, at + 202);
    Test.assertEqual(Store.rest()["at"], at);
    // Another set's write, or an undo, does not start this rest.
    c.onSetsSent([Queue.set(Fixtures.START, "bench_barbell", "bencha", {"reps" => 5})], at + 10, at + 12);
    Test.assertEqual(Store.rest()["at"], at);
    c.onSetsSent([Queue.set(Fixtures.START, "squat_barbell", "squatw", null)], at + 10, at + 12);
    Test.assertEqual(Store.rest()["at"], at);
    return true;
}

(:test)
function controllerBootSurvivesBodyThatIsNotTheApi(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var ui = new FakeUi();
    var c = new Controller(api, new FakeRec(), ui);
    c.boot();
    api.respond(200, "<html>");
    Test.assertEqual(ui.lastShown(), "waiting");
    c.boot();
    api.respond(200, {"data" => {"workout" => null}});
    api.respond(200, {"data" => {"workout" => {"entries" => 5}}});
    Test.assertEqual(ui.lastShown(), "waiting");
    return true;
}

(:test)
function controllerResendKeepsTheQueueCap(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    var q = [];
    for (var i = 0; i < Config.QUEUE_CAP - 1; i++) {
        q.add(Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => i}));
    }
    Store.setQueue(q);
    var lost = [];
    for (var i = 0; i < 5; i++) {
        lost.add(Queue.set(Fixtures.START, "bench_barbell", "bencha", {"reps" => i}));
    }
    Store.setNotSynced(lost);
    Test.assertEqual(c.resendNotSynced(), 1);
    Test.assertEqual(Store.queue().size(), Config.QUEUE_CAP);
    Test.assertEqual(Store.notSynced().size(), 4);
    return true;
}

(:test)
function controllerFinishSavesRecordingStartedBeforeSettingChanged(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var c = ControllerUtil.startedController(api, rec, new FakeUi());
    // "Record Garmin activity" turned off mid-workout: the running activity is still saved.
    c.setRecording(false);
    c.finish();
    Test.assertEqual(rec.saved, 1);
    return true;
}

(:test)
function controllerDiscardSurvivesSetsInFlight(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.logSet(5, 40.0);
    Test.assertEqual(api.last()["path"], "/workout/set");
    c.discardWorkout();
    // The set's reply comes after the discard was queued; the discard must still be sent.
    api.respond(200, Fixtures.response(Fixtures.workoutRaw(["squatw"])));
    var q = Store.queue();
    Test.assertEqual(q.size(), 1);
    Test.assertEqual(q[0]["t"], "discard");
    Test.assertEqual(api.last()["method"], :delete);
    return true;
}

(:test)
function controllerSkipStuckChangeUnblocksSync(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var ui = new FakeUi();
    var c = ControllerUtil.startedController(api, new FakeRec(), ui);
    c.logSet(5, 40.0);
    api.respond(400, {"error" => {"code" => "invalid_request", "message" => "bad set"}});
    Test.assert(Store.halt() != null);
    // RETRY would send the same change again; skipping moves it to "not synced".
    c.skipStuckChange();
    Test.assert(Store.halt() == null);
    Test.assertEqual(Store.queue().size(), 0);
    Test.assertEqual(Store.notSynced().size(), 1);
    return true;
}

(:test)
function controllerLapCarriesGarminExercise(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var c = ControllerUtil.startedController(api, rec, new FakeUi());
    c.logSet(5, 40.0);
    Test.assertEqual(rec.lastExerciseId, "squat_barbell");
    Test.assertEqual(rec.lastFit, 28 * 65536 + 6);
    return true;
}

(:test)
function controllerTakeOverOfHugeWorkoutStopsCleanly(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var ui = new FakeUi();
    var c = new Controller(api, new FakeRec(), ui);
    c.boot();
    var raw = Fixtures.workoutRaw([]);
    var sets = [];
    for (var i = 0; i < 400; i++) {
        sets.add(Fixtures.set("s" + i, i, false, 5, "100kg", 90, []));
    }
    raw["entries"][0]["sets"] = sets;
    api.respond(200, Fixtures.response(raw));
    Test.assertEqual(ui.lastShown(), "blocked:tooLarge");
    return true;
}

(:test)
function controllerBuzzesWhenRestEndsOnAnyScreen(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.logSet(5, 40.0);
    var rest = Store.rest();
    Haptics.restBuzzedAt = null;
    Test.assert(!c.checkRestOver(rest["at"] + 10));
    Test.assert(c.checkRestOver(rest["at"] + rest["dur"]));
    // Once per rest.
    Test.assert(!c.checkRestOver(rest["at"] + rest["dur"] + 5));
    return true;
}

(:test)
function controllerSavesTotalsFromFinalSets(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var c = ControllerUtil.startedController(api, rec, new FakeUi());
    c.logSet(5, 40.0);
    Test.assertEqual(rec.lastUnit, "kg");
    // A mistake undone and logged again counts once, with the final values.
    c.undoSet(0, 0);
    c.logSet(8, 40.0);
    c.finish();
    Test.assertEqual(rec.lastTotals["sets"], 1);
    Test.assert(TestUtil.near(rec.lastTotals["volumeNum"], 320.0));
    return true;
}

(:test)
function controllerStaysOnTheExerciseLoggedOutOfOrder(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    c.logSetAt(1, 0, 5, 60.0);
    var cur = Store.cursor();
    Test.assertEqual(cur[0], 1);
    Test.assertEqual(cur[1], 1);
    // The plain "log" goes to the focused exercise too.
    c.logSet(5, 60.0);
    Test.assertEqual(Store.workout()["entries"][1]["sets"][1]["completed"]["reps"], 5);
    // Bench is done: back to program order.
    cur = Store.cursor();
    Test.assertEqual(cur[0], 0);
    Test.assertEqual(cur[1], 0);
    return true;
}

(:test)
function controllerNewWorkoutForgetsTheFocusedExercise(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var c = new Controller(api, new FakeRec(), new FakeUi());
    c.boot();
    api.respond(200, {"data" => {"workout" => null}});
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    // Left over from the last workout.
    Store.setFocus("bench_barbell");
    c.startWorkout();
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    Test.assert(Store.focus() == null);
    Test.assertEqual(Store.cursor()[0], 0);
    Store.setFocus("bench_barbell");
    Store.clearAll();
    Test.assert(Store.focus() == null);
    return true;
}
