import Toybox.Lang;
import Toybox.Test;

(:test)
function queueHeadRunGroupsSetsOfOneWorkout(logger as Test.Logger) as Boolean {
    var a = Queue.set(1l, "e", "aaaaaa", {"reps" => 5});
    var b = Queue.set(1l, "e", "bbbbbb", {"reps" => 5});
    var other = Queue.set(2l, "e", "cccccc", {"reps" => 5});
    var fin = Queue.finish(1l, 9l, null);
    Test.assertEqual(Queue.headRunLength([]), 0);
    Test.assertEqual(Queue.headRunLength([a, b, fin]), 2);
    Test.assertEqual(Queue.headRunLength([a, other]), 1);
    Test.assertEqual(Queue.headRunLength([fin, a]), 1);
    Test.assertEqual(Queue.dropFirst([a, b, fin], 2).size(), 1);
    Test.assert(!fin.hasKey("intervals"));
    return true;
}

(:test)
function queueCap(logger as Test.Logger) as Boolean {
    var q = [];
    for (var i = 0; i < Config.QUEUE_CAP - 1; i++) {
        q.add(Queue.set(1l, "e", "s", {"reps" => 1}));
    }
    Test.assert(!Queue.isFull(q));
    q.add(Queue.set(1l, "e", "s", {"reps" => 1}));
    Test.assert(Queue.isFull(q));
    return true;
}

(:test)
function requestsForRunPicksEndpoint(logger as Test.Logger) as Boolean {
    var a = Queue.set(1l, "squat", "aaaaaa", {"reps" => 5, "weight" => "100kg"});
    var b = Queue.set(1l, "squat", "bbbbbb", {"reps" => 4, "weight" => "100kg"});
    var one = Requests.forRun([a]);
    Test.assertEqual(one["method"], :post);
    Test.assertEqual(one["path"], "/workout/set");
    Test.assertEqual(one["body"]["setId"], "aaaaaa");
    Test.assertEqual(one["body"]["completed"]["weight"], "100kg");
    var two = Requests.forRun([a, b]);
    Test.assertEqual(two["path"], "/workout/sets");
    Test.assertEqual(two["body"]["sets"].size(), 2);
    var fin = Requests.forRun([Queue.finish(1l, 9l, [[1l, 5l], [7l, 9l]])]);
    Test.assertEqual(fin["path"], "/workout/finish");
    Test.assertEqual(fin["body"]["startTime"], 1l);
    Test.assertEqual(fin["body"]["endTime"], 9l);
    Test.assertEqual(fin["body"]["intervals"].size(), 2);
    var plain = Requests.forRun([Queue.finish(1l, 9l, null)]);
    Test.assert(!plain["body"].hasKey("intervals"));
    return true;
}

(:test)
function requestsHeadersOnlyWritesCarryDeviceAndClient(logger as Test.Logger) as Boolean {
    var get = Requests.headers("lftsk_x", "dev1", :get);
    Test.assertEqual(get["Authorization"], "Bearer lftsk_x");
    Test.assert(!get.hasKey("X-Liftosaur-Device-Id"));
    var post = Requests.headers("lftsk_x", "dev1", :post);
    Test.assertEqual(post["X-Liftosaur-Device-Id"], "dev1");
    Test.assertEqual(post["X-Liftosaur-Client"], Config.CLIENT);
    Test.assertEqual(Requests.start(5l)["body"]["startTime"], 5l);
    Test.assertEqual(Requests.current()["method"], :get);
    Test.assertEqual(Requests.next()["path"], "/workout/next");
    return true;
}

(:test)
function requestsNextDayUsesWholeNumbers(logger as Test.Logger) as Boolean {
    Test.assertEqual(Requests.nextDay(1.0, "2")["path"], "/workout/next?week=1&dayInWeek=2");
    return true;
}

(:test)
function storeCapsNotSynced(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var a = [];
    for (var i = 0; i < Config.QUEUE_CAP + 3; i++) {
        a.add({"t" => "set", "n" => i});
    }
    Store.addNotSynced(a);
    var kept = Store.notSynced();
    Test.assertEqual(kept.size(), Config.QUEUE_CAP);
    // The newest are kept.
    Test.assertEqual(kept[kept.size() - 1]["n"], Config.QUEUE_CAP + 2);
    Store.clearAll();
    return true;
}

(:test)
function storeRefusesValueOverTheLimitWithoutCrashing(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var raw = Fixtures.workoutRaw([]);
    var sets = [];
    for (var i = 0; i <= Config.MAX_WORKOUT_SETS; i++) {
        sets.add(Fixtures.set("s" + i, i, false, 5, "100kg", 90, []));
    }
    raw["entries"][0]["sets"] = sets;
    Test.assert(!Store.setWorkout(SlimWorkout.slim(raw)));
    Test.assert(Store.workout() == null);
    Test.assert(Store.setWorkout(SlimWorkout.slim(Fixtures.workoutRaw([]))));
    Store.clearAll();
    return true;
}

(:test)
function storeWorkoutReadsAreCachedUntilWritten(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var w = SlimWorkout.slim(Fixtures.workoutRaw([]));
    Store.setWorkout(w);
    Test.assert(Store.workout() == Store.workout());
    Store.setWorkout(null);
    Test.assert(Store.workout() == null);
    return true;
}
