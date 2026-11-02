import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
module SyncUtil {
    function seedWorkout() {
        Store.clearAll();
        Store.setWorkout(SlimWorkout.slim(Fixtures.workoutRaw([])));
    }
}

(:test)
function storeKeepsLongStartTime(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    var st = Store.workout()["startTime"];
    Test.assert(st instanceof Long);
    Test.assertEqual(st, 1738274512000l);
    return true;
}

(:test)
function syncSendsSingleSetAndAdopts(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5, "weight" => "40kg"})]);
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.drain();
    Test.assertEqual(api.last()["path"], "/workout/set");
    api.respond(200, Fixtures.response(Fixtures.workoutRaw(["squatw"])));
    Test.assertEqual(Store.queue().size(), 0);
    Test.assert(SlimWorkout.findSet(Store.workout(), "squatw")["completed"] != null);
    Test.assert(listener.calls.indexOf("updated") >= 0);
    return true;
}

(:test)
function syncBatchesConsecutiveSets(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([
        Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5}),
        Queue.set(Fixtures.START, "squat_barbell", "squata", {"reps" => 5})
    ]);
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.drain();
    Test.assertEqual(api.last()["path"], "/workout/sets");
    Test.assertEqual(api.last()["body"]["sets"].size(), 2);
    return true;
}

(:test)
function syncAdoptKeepsPendingSets(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.drain();
    var q = Store.queue();
    q.add(Queue.set(Fixtures.START, "squat_barbell", "squata", {"reps" => 5}));
    Store.setQueue(q);
    api.respond(200, Fixtures.response(Fixtures.workoutRaw(["squatw"])));
    Test.assert(SlimWorkout.findSet(Store.workout(), "squata")["completed"] != null);
    Test.assertEqual(Store.queue().size(), 1);
    Test.assertEqual(api.pending(), 1);
    Test.assertEqual(api.last()["body"]["setId"], "squata");
    return true;
}

(:test)
function syncRetriesOnNetworkError(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.drain();
    api.respond(-104, null);
    Test.assertEqual(Store.queue().size(), 1);
    Test.assert(sync.isOffline());
    return true;
}

(:test)
function syncNoWorkoutMovesToNotSynced(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([
        Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5}),
        Queue.set(Fixtures.START, "squat_barbell", "squata", {"reps" => 5}),
        Queue.finish(Fixtures.START, Fixtures.START + 1000l, null)
    ]);
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.drain();
    api.respond(404, {"error" => {"code" => "no_active_workout", "message" => "x"}});
    Test.assertEqual(Store.queue().size(), 0);
    Test.assertEqual(Store.notSynced().size(), 2);
    Test.assert(listener.calls.indexOf("gone") >= 0);
    Test.assertEqual(api.pending(), 0);
    return true;
}

(:test)
function syncHaltsOnBadKey(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.drain();
    api.respond(401, null);
    Test.assertEqual(Store.halt()["reason"], "badKey");
    Test.assert(listener.calls.indexOf("halt:badKey") >= 0);
    sync.drain();
    Test.assertEqual(api.pending(), 0);
    return true;
}

(:test)
function syncFinishNotifiesListener(logger as Test.Logger) as Boolean {
    Store.clearAll();
    Store.setQueue([Queue.finish(Fixtures.START, Fixtures.START + 1000l, null)]);
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.drain();
    Test.assertEqual(api.last()["path"], "/workout/finish");
    api.respond(200, {"data" => {"workout" => {"id" => Fixtures.START}}});
    Test.assertEqual(Store.queue().size(), 0);
    Test.assert(listener.calls.indexOf("finishSynced") >= 0);
    return true;
}

(:test)
function syncRefetchDropsMissingSet(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "gone11", {"reps" => 5})]);
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.drain();
    api.respond(404, {"error" => {"code" => "set_not_found", "message" => "x"}});
    Test.assertEqual(api.last()["path"], "/workout/current");
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    Test.assertEqual(Store.queue().size(), 0);
    Test.assertEqual(Store.notSynced().size(), 1);
    return true;
}

(:test)
function syncRefetchFailureRetriesInsteadOfHalting(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.drain();
    api.respond(404, {"error" => {"code" => "set_not_found", "message" => "x"}});
    api.respond(404, null);
    Test.assert(Store.halt() == null);
    Test.assert(sync.isOffline());
    Test.assertEqual(Store.queue().size(), 1);
    return true;
}

(:test)
function syncRefetchOtherWorkoutDropsLocalWorkout(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.drain();
    api.respond(404, {"error" => {"code" => "set_not_found", "message" => "x"}});
    var other = Fixtures.workoutRaw([]);
    other["startTime"] = Fixtures.START + 60000l;
    api.respond(200, Fixtures.response(other));
    Test.assert(Store.halt() == null);
    Test.assertEqual(Store.queue().size(), 0);
    Test.assertEqual(Store.notSynced().size(), 1);
    Test.assert(listener.calls.indexOf("gone") >= 0);
    return true;
}

(:test)
function syncPollNoticesWorkoutFinishedOnPhone(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.poll();
    Test.assertEqual(api.last()["path"], "/workout/current");
    api.respond(200, {"data" => {"workout" => null}});
    Test.assert(listener.calls.indexOf("gone") >= 0);
    return true;
}

(:test)
function syncPollTreatsAnotherWorkoutAsEnded(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.poll();
    var raw = Fixtures.workoutRaw([]);
    raw["startTime"] = Fixtures.START + 99000l;
    api.respond(200, Fixtures.response(raw));
    Test.assert(listener.calls.indexOf("gone") >= 0);
    return true;
}

(:test)
function syncPollWaitsForQueueAndWorkout(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.poll();
    // Unsent sets go first; their response carries the workout anyway.
    Test.assertEqual(api.last()["path"], "/workout/set");
    Store.clearAll();
    var idle = new FakeApi();
    new Sync(idle, new FakeListener()).poll();
    Test.assertEqual(idle.requests.size(), 0);
    return true;
}

(:test)
function syncPollSendsSetsLoggedWhileItWaited(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.poll();
    // A set logged while the poll is out cannot be sent yet.
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    sync.drain();
    Test.assertEqual(api.requests.size(), 1);
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    Test.assertEqual(api.last()["path"], "/workout/set");
    return true;
}

(:test)
function syncRetryAndPollShareOneClock(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.drain();
    var t0 = System.getTimer();
    api.respond(-104, null);
    Test.assertEqual(api.requests.size(), 1);
    // The retry waits for its delay, then sends again.
    sync.step(t0 + 1000);
    Test.assertEqual(api.requests.size(), 1);
    sync.step(t0 + Config.RETRY_DELAYS[0] * 1000 + 1000);
    Test.assertEqual(api.requests.size(), 2);
    api.respond(200, Fixtures.response(Fixtures.workoutRaw(["squatw"])));
    // Polling asks for the workout every 15 s.
    sync.startPolling();
    sync.step(System.getTimer() + 16000);
    Test.assertEqual(api.last()["path"], "/workout/current");
    sync.stopPolling();
    return true;
}

(:test)
function syncPollFollowsExercisesReorderedOnPhone(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.poll();
    var raw = Fixtures.workoutRaw([]);
    // Bench moved first on the phone.
    raw["entries"] = [raw["entries"][1], raw["entries"][0]];
    api.respond(200, Fixtures.response(raw));
    Test.assert(listener.calls.indexOf("updated") >= 0);
    var w = Store.workout();
    Test.assertEqual(w["entries"][0]["name"], "Bench Press");
    var cur = SlimWorkout.cursor(w, []);
    Test.assertEqual(w["entries"][cur[0]]["sets"][cur[1]]["setId"], "bencha");
    return true;
}

(:test)
function syncReportsSentSetsWithTimes(logger as Test.Logger) as Boolean {
    SyncUtil.seedWorkout();
    Store.setQueue([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    var api = new FakeApi();
    var listener = new FakeListener();
    var sync = new Sync(api, listener);
    sync.drain();
    api.respond(200, Fixtures.response(Fixtures.workoutRaw(["squatw"])));
    Test.assert(listener.calls.indexOf("sent:squatw") >= 0);
    return true;
}
