import Toybox.Lang;
import Toybox.Test;

(:test)
class FakeApi {
    var requests;
    var callbacks;
    var key = "lftsk_test";

    function initialize() {
        requests = [];
        callbacks = [];
    }

    function setKey(apiKey) {
        key = apiKey;
    }

    function hasKey() {
        return key != null;
    }

    function request(desc, callback) {
        requests.add(desc);
        callbacks.add(callback);
    }

    function pending() {
        return callbacks.size();
    }

    function last() {
        return requests[requests.size() - 1];
    }

    function respond(status, data) {
        var cb = callbacks[0];
        callbacks = callbacks.slice(1, null);
        cb.invoke(status, data);
    }
}

(:test)
class FakeListener {
    var calls;

    function initialize() {
        calls = [];
    }
    function onWorkoutUpdated() { calls.add("updated"); }
    function onWorkoutGone() { calls.add("gone"); }
    function onFinishSynced() { calls.add("finishSynced"); }
    function onClock() {}
    function onSetsSent(run, sentSec, ackSec) {
        Test.assert(ackSec >= sentSec);
        calls.add("sent:" + run[0]["setId"]);
    }
    function onHalt(reason, message) { calls.add("halt:" + reason); }
}
(:test)
class FakeRec {
    var active = false;
    var started = 0;
    var laps = 0;
    var saved = 0;
    var discarded = 0;
    var paused = false;

    function initialize() {}
    function start(name, unit) { active = true; started++; }
    var lastFit = null;
    var lastExerciseId = null;
    var lastUnit = null;
    var lastTotals = null;
    function lap(label, setNumber, isWarmup, reps, weight, unit, fit, exerciseId) {
        laps++;
        lastUnit = unit;
        lastFit = fit;
        lastExerciseId = exerciseId;
    }
    function pause() { paused = true; }
    function resume() { paused = false; }
    function save(program, day, totals) { active = false; saved++; lastTotals = totals; }
    function discard() { active = false; discarded++; }
    function isActive() { return active; }
}

(:test)
class FakeUi {
    var shown;

    function initialize() {
        shown = [];
    }
    function showLoading() { shown.add("loading"); }
    function showWaiting(message) { shown.add("waiting"); }
    function showStart() { shown.add("start"); }
    function showActive() { shown.add("active"); }
    function showBlocked(reason, message) { shown.add("blocked:" + reason); }
    function showEnded(saved) { shown.add(saved ? "ended" : "ended:nosave"); }
    function slideActive(dir) { shown.add(dir > 0 ? "active:next" : "active:back"); }
    function refresh() {}
    function lastShown() { return shown[shown.size() - 1]; }
}
