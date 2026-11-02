import Toybox.Lang;
import Toybox.Test;

(:test)
function addSetCopiesLastSetTargets(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatb"]));
    var s = SlimWorkout.addSet(w, 0, "abcdef");
    var sets = w["entries"][0]["sets"];
    Test.assertEqual(sets.size(), 4);
    Test.assertEqual(sets[3]["setId"], "abcdef");
    Test.assertEqual(sets[3]["weight"], "100kg");
    Test.assert(sets[3]["completed"] == null);
    Test.assert(sets[2]["completed"] != null);
    Test.assertEqual(s["setId"], "abcdef");
    return true;
}

(:test)
function newSetIdIsSixLowercaseLetters(logger as Test.Logger) as Boolean {
    var id = Ids.newSetId();
    Test.assertEqual(id.length(), 6);
    var chars = id.toCharArray();
    for (var i = 0; i < chars.size(); i++) {
        Test.assert(chars[i] >= 'a' && chars[i] <= 'z');
    }
    return true;
}

(:test)
function appendRequestHasNoCompletion(logger as Test.Logger) as Boolean {
    var e = Queue.append(Fixtures.START, "squat_barbell", "abcdef");
    var body = Requests.forRun([e])["body"];
    Test.assertEqual(body["append"], true);
    Test.assertEqual(body["entryId"], "squat_barbell");
    Test.assert(!body.hasKey("completed"));
    var both = Requests.forRun([e, Queue.set(Fixtures.START, "squat_barbell", "abcdef", {"reps" => 5})])["body"]["sets"];
    Test.assertEqual(both[0]["append"], true);
    Test.assertEqual(both[1]["completed"]["reps"], 5);
    return true;
}

(:test)
function pendingAppendSurvivesServerCopy(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    var q = [Queue.append(Fixtures.START, "bench_barbell", "abcdef"), Queue.set(Fixtures.START, "bench_barbell", "abcdef", {"reps" => 5})];
    SlimWorkout.applyPending(w, q);
    var s = SlimWorkout.findSet(w, "abcdef");
    Test.assert(s != null);
    Test.assertEqual(s["completed"]["reps"], 5);
    Test.assertEqual(w["entries"][1]["sets"].size(), 3);
    return true;
}

(:test)
function discardRequestDeletesCurrent(logger as Test.Logger) as Boolean {
    var d = Requests.forRun([Queue.discard(Fixtures.START)]);
    Test.assertEqual(d["method"], :delete);
    Test.assertEqual(d["path"], "/workout/current");
    Test.assertEqual(d["body"]["startTime"], Fixtures.START);
    Test.assertEqual(Queue.headRunLength([Queue.discard(Fixtures.START), Queue.set(Fixtures.START, "e", "s", null)]), 1);
    var h = Requests.headers("k", "dev", :delete);
    Test.assertEqual(h["X-Liftosaur-Device-Id"], "dev");
    return true;
}

(:test)
function controllerAddsAndDiscards(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var rec = new FakeRec();
    var ui = new FakeUi();
    var c = ControllerUtil.startedController(api, rec, ui);
    Test.assert(c.addSet(1));
    var w = Store.workout();
    Test.assertEqual(w["entries"][1]["sets"].size(), 3);
    var q = Store.queue();
    Test.assertEqual(q[0]["append"], true);
    Test.assertEqual(q[0]["setId"], w["entries"][1]["sets"][2]["setId"]);
    c.logSet(5, 40.0);
    c.discardWorkout();
    // The added set is on its way, so it stays until its reply; the logged set, still waiting, is dropped.
    q = Store.queue();
    Test.assertEqual(q.size(), 2);
    Test.assertEqual(q[0]["append"], true);
    Test.assertEqual(q[1]["t"], "discard");
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    q = Store.queue();
    Test.assertEqual(q.size(), 1);
    Test.assertEqual(q[0]["t"], "discard");
    Test.assertEqual(rec.discarded, 1);
    Test.assert(Store.workout() == null);
    Test.assertEqual(ui.lastShown(), "waiting");
    return true;
}

(:test)
function navFirstOpenSetOfExercise(logger as Test.Logger) as Boolean {
    var w = SlimWorkout.slim(Fixtures.workoutRaw(["squatw", "squata"]));
    var p = Nav.firstOpen(w, 0);
    Test.assertEqual(p[1], 2);
    var all = SlimWorkout.slim(Fixtures.workoutRaw(["bencha", "benchb"]));
    Test.assertEqual(Nav.firstOpen(all, 1)[1], 1);
    return true;
}
