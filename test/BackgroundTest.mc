import Toybox.Communications;
import Toybox.Lang;
import Toybox.Test;

(:test)
module BgUtil {
    // Two sets of one workout, then a finish; the queue the closed app left behind.
    function queueSetsAndFinish() {
        Store.clearAll();
        Store.setQueue([
            Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5}),
            Queue.set(Fixtures.START, "squat_barbell", "squata", {"reps" => 5}),
            Queue.finish(Fixtures.START, Fixtures.START + 3600000l, null)
        ]);
    }

    function run(api) {
        var done = new BgDone();
        new BgSync(api, done.method(:onDone)).start();
        return done;
    }
}

(:test)
class BgDone {
    var result = null;
    var sets = -1;
    var finished = null;

    function initialize() {}

    function onDone(r, s, f) {
        result = r;
        sets = s;
        finished = f;
    }
}

(:test)
function bgSyncSendsTheQueueInOrderAndEmptiesIt(logger as Test.Logger) as Boolean {
    BgUtil.queueSetsAndFinish();
    var api = new FakeApi();
    var done = BgUtil.run(api);
    Test.assertEqual(api.last()["path"], "/workout/sets");
    api.respond(200, Fixtures.response(Fixtures.workoutRaw(["squatw", "squata"])));
    Test.assertEqual(Store.queue().size(), 1);
    Test.assertEqual(api.last()["path"], "/workout/finish");
    api.respond(200, Fixtures.response(null));
    Test.assertEqual(Store.queue().size(), 0);
    Test.assertEqual(done.result, "synced");
    Test.assertEqual(done.sets, 2);
    Test.assertEqual(done.finished, true);
    return true;
}

(:test)
function bgSyncLeavesTheQueueWhenOffline(logger as Test.Logger) as Boolean {
    BgUtil.queueSetsAndFinish();
    var api = new FakeApi();
    var done = BgUtil.run(api);
    api.respond(-104, null);
    Test.assertEqual(Store.queue().size(), 3);
    Test.assertEqual(done.result, "offline");
    // A server error is temporary too, and so is a 404 that isn't Liftosaur's (a proxy, no route).
    done = BgUtil.run(api);
    api.respond(503, null);
    Test.assertEqual(done.result, "offline");
    done = BgUtil.run(api);
    api.respond(404, null);
    Test.assertEqual(done.result, "offline");
    Test.assertEqual(Store.queue().size(), 3);
    return true;
}

(:test)
function bgSyncLeavesRejectedWritesToTheApp(logger as Test.Logger) as Boolean {
    BgUtil.queueSetsAndFinish();
    var api = new FakeApi();
    var done = BgUtil.run(api);
    api.respond(400, {"error" => {"code" => "missing_set_input", "message" => "RPE is required"}});
    Test.assertEqual(Store.queue().size(), 3);
    Test.assertEqual(done.result, "needsApp");
    Test.assert(Store.halt() == null);
    return true;
}

(:test)
function bgSyncCountsAReplyTooBigToReadAsDelivered(logger as Test.Logger) as Boolean {
    // Error replies are small; only the workout in a success reply outgrows a background process.
    BgUtil.queueSetsAndFinish();
    var api = new FakeApi();
    var done = BgUtil.run(api);
    api.respond(Communications.NETWORK_RESPONSE_OUT_OF_MEMORY, null);
    Test.assertEqual(Store.queue().size(), 1);
    api.respond(200, Fixtures.response(null));
    Test.assertEqual(done.result, "synced");
    return true;
}

(:test)
function bgSyncDoesNothingWhenHaltedOrEmpty(logger as Test.Logger) as Boolean {
    BgUtil.queueSetsAndFinish();
    Store.setHalt({"reason" => "badKey", "message" => null});
    var api = new FakeApi();
    var done = BgUtil.run(api);
    Test.assertEqual(api.requests.size(), 0);
    Test.assertEqual(done.result, "needsApp");
    Store.clearAll();
    done = BgUtil.run(api);
    Test.assertEqual(api.requests.size(), 0);
    Test.assertEqual(done.result, "idle");
    return true;
}

(:test)
function bgSyncKeepsSetsTheAppQueuedMeanwhile(logger as Test.Logger) as Boolean {
    BgUtil.queueSetsAndFinish();
    var api = new FakeApi();
    BgUtil.run(api);
    // The app opened and changed the queue while the reply was on its way.
    Store.setQueue([Queue.set(Fixtures.START, "bench_barbell", "bencha", {"reps" => 5})]);
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    Test.assertEqual(Store.queue().size(), 1);
    Test.assertEqual(Store.queue()[0]["setId"], "bencha");
    return true;
}

(:test)
function bgScheduleOnlyWithSomethingToSend(logger as Test.Logger) as Boolean {
    Store.clearAll();
    Test.assert(!BgSync.needed("lftsk_x"));
    BgUtil.queueSetsAndFinish();
    Test.assert(BgSync.needed("lftsk_x"));
    Test.assert(!BgSync.needed(null));
    Store.setHalt({"reason" => "badKey", "message" => null});
    Test.assert(!BgSync.needed("lftsk_x"));
    return true;
}

(:test)
function bgAsksToOpenTheAppOnlyWhenItIsNeeded(logger as Test.Logger) as Boolean {
    Test.assertEqual(BgSync.wakeMessage("needsApp"), "Sets not synced. Open Lift Log?");
    Test.assert(BgSync.wakeMessage("synced") == null);
    Test.assert(BgSync.wakeMessage("offline") == null);
    Test.assert(BgSync.wakeMessage("idle") == null);
    return true;
}

(:test)
function complicationTextFollowsTheGlance(logger as Test.Logger) as Boolean {
    Test.assertEqual(GlanceText.value({"ongoing" => false, "day" => "Day B"}), "Day B");
    Test.assertEqual(GlanceText.value({"ongoing" => true, "day" => "Day B"}), "Now: Day B");
    Test.assertEqual(GlanceText.value(null), "--");
    return true;
}
