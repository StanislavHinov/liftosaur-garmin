import Toybox.Lang;
import Toybox.Test;

(:test)
function controllerSkipsGarminRecordingWhenOff(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var rec = new FakeRec();
    var c = new Controller(api, rec, new FakeUi());
    c.setRecording(false);
    c.boot();
    api.respond(200, {"data" => {"workout" => null}});
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    c.startWorkout();
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    c.logSet(5, 40.0);
    c.finish();
    Test.assertEqual(rec.started, 0);
    Test.assertEqual(rec.laps, 0);
    Test.assertEqual(rec.saved, 0);
    Test.assertEqual(Store.queue()[Store.queue().size() - 1]["t"], "finish");
    return true;
}

(:test)
function dayPickSteps(logger as Test.Logger) as Boolean {
    var p = DayPick.step({"week" => 1, "dayInWeek" => 2}, 1);
    Test.assertEqual(p[0], 1);
    Test.assertEqual(p[1], 3);
    p = DayPick.step({"week" => 1, "dayInWeek" => 2}, -1);
    Test.assertEqual(p[1], 1);
    Test.assert(DayPick.step({"week" => 1, "dayInWeek" => 1}, -1) == null);
    p = DayPick.step({"week" => 3, "dayInWeek" => 1}, -1);
    Test.assertEqual(p[0], 2);
    Test.assertEqual(p[1], 1);
    // When a day after the last one does not exist, try the next week, then the first week.
    var f = DayPick.fallbacks([2, 5]);
    Test.assertEqual(f[0][0], 3);
    Test.assertEqual(f[0][1], 1);
    Test.assertEqual(f[1][0], 1);
    Test.assertEqual(f[1][1], 1);
    return true;
}

(:test)
function requestsForAChosenDay(logger as Test.Logger) as Boolean {
    Test.assertEqual(Requests.nextDay(2, 1)["path"], "/workout/next?week=2&dayInWeek=1");
    var s = Requests.startDay(1000l, 2, 1)["body"];
    Test.assertEqual(s["week"], 2);
    Test.assertEqual(s["dayInWeek"], 1);
    Test.assertEqual(s["startTime"], 1000l);
    Test.assert(!Requests.start(1000l)["body"].hasKey("week"));
    return true;
}

(:test)
function controllerPicksDayAndWrapsAround(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var api = new FakeApi();
    var ui = new FakeUi();
    var c = new Controller(api, new FakeRec(), ui);
    c.boot();
    api.respond(200, {"data" => {"workout" => null}});
    api.respond(200, Fixtures.response(Fixtures.workoutRaw([])));
    c.pickDay(1);
    Test.assertEqual(api.last()["path"], "/workout/next?week=1&dayInWeek=2");
    api.respond(404, {"error" => {"code" => "not_found", "message" => "No such day"}});
    Test.assertEqual(api.last()["path"], "/workout/next?week=2&dayInWeek=1");
    api.respond(404, {"error" => {"code" => "not_found", "message" => "No such day"}});
    Test.assertEqual(api.last()["path"], "/workout/next?week=1&dayInWeek=1");
    var raw = Fixtures.workoutRaw([]);
    raw["dayName"] = "B1";
    api.respond(200, Fixtures.response(raw));
    Test.assertEqual(c.preview()["dayName"], "B1");
    Test.assertEqual(ui.lastShown(), "start");
    c.startWorkout();
    Test.assertEqual(api.last()["body"]["week"], 1);
    Test.assertEqual(api.last()["body"]["dayInWeek"], 1);
    return true;
}

(:test)
function glanceTextForStoredState(logger as Test.Logger) as Boolean {
    Test.assertEqual(GlanceText.text({"ongoing" => false, "day" => "Upper A"}), "Up next: Upper A");
    Test.assertEqual(GlanceText.text({"ongoing" => true, "day" => "Upper A"}), "Ongoing: Upper A");
    Test.assertEqual(GlanceText.text(null), "Tap to open");
    return true;
}

(:test)
function controllerWritesGlanceState(logger as Test.Logger) as Boolean {
    var c = ControllerUtil.startedController(new FakeApi(), new FakeRec(), new FakeUi());
    Test.assertEqual(Store.get("glance", null)["ongoing"], true);
    Test.assertEqual(Store.get("glance", null)["day"], "A1");
    c.finish();
    Test.assert(Store.get("glance", null) == null);
    return true;
}

(:test)
function controllerResendsNotSyncedSets(logger as Test.Logger) as Boolean {
    var api = new FakeApi();
    var c = ControllerUtil.startedController(api, new FakeRec(), new FakeUi());
    Store.addNotSynced([Queue.set(Fixtures.START, "squat_barbell", "squatw", {"reps" => 5})]);
    Test.assertEqual(c.resendNotSynced(), 1);
    Test.assertEqual(Store.notSynced().size(), 0);
    Test.assertEqual(Store.queue()[0]["setId"], "squatw");
    return true;
}
