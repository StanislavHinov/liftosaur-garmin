import Toybox.Lang;
import Toybox.Time;

class Controller {
    var _api;
    var _rec;
    var _ui;
    var _sync;
    var _preview = null;
    var _booted = false;
    var _notice = null;
    var _record = true;
    // A day chosen on the Start screen as [week, dayInWeek], the one being tried, and what to try next.
    var _picked = null;
    var _trying = null;
    var _tries = [];
    // FIT exercise codes for the current workout's exercises, by Liftosaur exercise id.
    var _fitCodes = null;

    function initialize(api, rec, ui) {
        _api = api;
        _rec = rec;
        _ui = ui;
        _sync = new Sync(api, self);
    }

    static function nowMs() {
        return Time.now().value().toLong() * 1000l;
    }

    static function nowSec() {
        return Time.now().value();
    }

    function sync() { return _sync; }

    // Off for people who get their Garmin activity from another tool, such as liftosaur2garmin.
    function setRecording(on) {
        _record = on;
    }
    function preview() { return _preview; }
    function notice() { return _notice; }

    function bootOnce() {
        if (!_booted) {
            _booted = true;
            boot();
        }
    }

    function useKey(apiKey) {
        _api.setKey(apiKey);
        Store.setHalt(null);
        boot();
    }

    function boot() {
        if (!_api.hasKey()) {
            _ui.showBlocked("noKey", null);
            return;
        }
        var h = Store.halt();
        if (h != null) {
            _ui.showBlocked(h["reason"], h["message"]);
            return;
        }
        var w = Store.workout();
        if (w != null) {
            var rec = Store.rec();
            if (rec != null && rec["garmin"] == true && !_rec.isActive()) {
                _rec.start(SlimWorkout.activityName(w), SlimWorkout.unit(w));
                _notice = "Recording restarted";
            }
            showWorkout();
            _sync.drain();
            _sync.startPolling();
            return;
        }
        _sync.drain();
        _ui.showLoading();
        _api.request(Requests.current(), method(:onBootCurrent));
    }

    // A change the server rejects stops the sync, and RETRY sends it again. This moves it to the
    // not-synced list (resendable from the Waiting menu) so the rest can go.
    function skipStuckChange() {
        var q = Store.queue();
        var n = Queue.headRunLength(q);
        if (n > 0) {
            Store.addNotSynced(q.slice(0, n));
            Store.setQueue(Queue.dropFirst(q, n));
        }
        clearHalt();
    }

    function clearHalt() {
        Store.setHalt(null);
        boot();
    }

    function onBootCurrent(status, data) {
        var action = ErrorPolicy.decide(status, data);
        var raw = action.equals("ok") ? ErrorPolicy.workout(data) : null;
        if (raw == :bad) {
            handleStartError("retry", data);
        } else if (action.equals("ok")) {
            if (raw != null) {
                takeOver(raw);
            } else {
                _api.request(Requests.next(), method(:onBootNext));
            }
        } else {
            handleStartError(action, data);
        }
    }

    function onBootNext(status, data) {
        var action = ErrorPolicy.decide(status, data);
        var raw = action.equals("ok") ? ErrorPolicy.workout(data) : null;
        if (raw == :bad) {
            handleStartError("retry", data);
        } else if (action.equals("ok")) {
            _preview = SlimWorkout.slim(raw);
            _picked = null;
            if (_preview == null) {
                Store.setGlance(false, null);
                _ui.showWaiting("No program in Liftosaur");
            } else {
                Store.setGlance(false, _preview["dayName"]);
                _ui.showStart();
            }
        } else {
            handleStartError(action, data);
        }
    }

    function startWorkout() {
        var r = _picked == null ? Requests.start(nowMs()) : Requests.startDay(nowMs(), _picked[0], _picked[1]);
        _api.request(r, method(:onStarted));
    }

    // Up and Down on the Start screen: preview the previous or next program day.
    function pickDay(dir) {
        if (_preview == null || _preview["dayData"] == null) {
            return;
        }
        var base = _picked == null ? _preview["dayData"] : {"week" => _picked[0], "dayInWeek" => _picked[1]};
        var day = DayPick.step(base, dir);
        if (day == null) {
            return;
        }
        _tries = dir > 0 ? DayPick.fallbacks(day) : [];
        tryDay(day);
    }

    function tryDay(day) {
        _trying = day;
        _api.request(Requests.nextDay(day[0], day[1]), method(:onPickedDay));
    }

    function onPickedDay(status, data) {
        var action = ErrorPolicy.decide(status, data);
        var raw = action.equals("ok") ? ErrorPolicy.workout(data) : null;
        if (raw != null && raw != :bad) {
            _preview = SlimWorkout.slim(raw);
            _picked = _trying;
            _ui.showStart();
        } else if (_tries.size() > 0) {
            var next = _tries[0];
            _tries = _tries.slice(1, null);
            tryDay(next);
        }
    }

    function onStarted(status, data) {
        var action = ErrorPolicy.decide(status, data);
        var raw = action.equals("ok") ? ErrorPolicy.workout(data) : null;
        if (action.equals("ok") && (raw == :bad || raw == null)) {
            // Started, but the body didn't carry the workout: ask for it.
            _api.request(Requests.current(), method(:onBootCurrent));
        } else if (action.equals("ok")) {
            takeOver(raw);
        } else if (action.equals("adoptCurrent") || action.equals("refetch")) {
            _api.request(Requests.current(), method(:onBootCurrent));
        } else {
            handleStartError(action, data);
        }
    }

    function handleStartError(action, data) {
        if (action.equals("retry")) {
            _ui.showWaiting("Connect phone to start");
        } else {
            var message = ErrorPolicy.message(data);
            Store.setHalt({"reason" => action, "message" => message});
            _ui.showBlocked(action, message);
        }
    }

    function takeOver(raw) {
        var w = SlimWorkout.slim(raw);
        SlimWorkout.applyPending(w, Store.queue());
        if (!Store.setWorkout(w)) {
            handleStartError("tooLarge", null);
            return;
        }
        Store.setSkipped([]);
        Store.setFocus(null);
        Store.setRest(null);
        Store.setRec({"garmin" => _record, "intervals" => [[w["startTime"], null]]});
        if (_record) {
            _rec.start(SlimWorkout.activityName(w), SlimWorkout.unit(w));
        }
        Store.setGlance(true, w["dayName"]);
        _picked = null;
        _sync.startPolling();
        showWorkout();
    }

    function showWorkout() {
        _ui.showActive();
    }

    function logSet(reps, weight) {
        var cur = Store.cursor();
        if (cur == null) {
            return false;
        }
        return logSetAt(cur[0], cur[1], reps, weight);
    }

    // Logs the set at any position, also out of order or after a skip.
    function logSetAt(ei, si, reps, weight) {
        var w = Store.workout();
        if (w == null) {
            return false;
        }
        return logCompleted(ei, si, completedFor(w["entries"][ei]["sets"][si], reps, weight), reps, weight);
    }

    // completed is the full API body (with left reps, RPE or variables); reps and weight go to the Garmin lap.
    function logCompleted(ei, si, completed, reps, weight) {
        var w = Store.workout();
        if (w == null) {
            return false;
        }
        var entry = w["entries"][ei];
        var set = entry["sets"][si];
        if (!queueWrite(w, entry, set, completed)) {
            return false;
        }
        var skipped = Store.skipped();
        if (skipped.indexOf(set["setId"]) >= 0) {
            skipped.remove(set["setId"]);
            Store.setSkipped(skipped);
        }
        Store.setFocus(entry["entryId"]);
        if (_rec.isActive()) {
            var id = entry["exerciseId"];
            var target = Weight.parse(set["weight"]);
            var unit = weight != null && target != null ? target[1] : null;
            var warm = set["isWarmup"] == true;
            _rec.lap(Look.lapLabel(entry["name"], warm), si + 1, warm, reps, weight, unit, fitCode(w, id), id);
        }
        startRest(set);
        _notice = null;
        _sync.drain();
        _ui.slideActive(1);
        return true;
    }

    // New values for a set that is already logged; the API replaces them without a second completion.
    function saveSet(ei, si, reps, weight) {
        var w = Store.workout();
        if (w == null) {
            return false;
        }
        return saveCompleted(ei, si, completedFor(w["entries"][ei]["sets"][si], reps, weight));
    }

    function saveCompleted(ei, si, completed) {
        var w = Store.workout();
        if (w == null) {
            return false;
        }
        var entry = w["entries"][ei];
        if (!queueWrite(w, entry, entry["sets"][si], completed)) {
            return false;
        }
        _sync.drain();
        _ui.refresh();
        return true;
    }

    // completed: null un-completes the set in Liftosaur.
    function undoSet(ei, si) {
        var w = Store.workout();
        if (w == null) {
            return false;
        }
        var entry = w["entries"][ei];
        if (!queueWrite(w, entry, entry["sets"][si], null)) {
            return false;
        }
        _sync.drain();
        _ui.slideActive(-1);
        return true;
    }

    function addSet(ei) {
        var w = Store.workout();
        if (w == null) {
            return false;
        }
        var q = Store.queue();
        if (Queue.isFull(q)) {
            _notice = "Connect phone to sync";
            _ui.refresh();
            return false;
        }
        var set = SlimWorkout.addSet(w, ei, Ids.newSetId());
        if (set == null) {
            return false;
        }
        q.add(Queue.append(w["startTime"], w["entries"][ei]["entryId"], set["setId"]));
        Store.setQueue(q);
        Store.setWorkout(w);
        _sync.drain();
        _ui.refresh();
        return true;
    }

    // Throws away the Liftosaur workout and the Garmin activity; its unsent sets no longer matter.
    function discardWorkout() {
        var w = Store.workout();
        if (w == null) {
            return;
        }
        var st = w["startTime"];
        var q = Store.queue();
        var kept = [];
        var sending = _sync.inFlight();
        for (var i = 0; i < q.size(); i++) {
            // Entries already sent stay: Sync drops them by count when their reply comes.
            if (i < sending || q[i]["st"] != st) {
                kept.add(q[i]);
            }
        }
        kept.add(Queue.discard(st));
        Store.setQueue(kept);
        _rec.discard();
        clearLocal();
        _ui.showWaiting(null);
        _sync.drain();
    }

    function adjustRest(delta) {
        var rest = Look.adjustRest(Store.rest(), delta, nowSec());
        if (rest != null) {
            Store.setRest(rest);
            _ui.refresh();
        }
    }

    function skipRest() {
        Store.setRest(null);
        _ui.refresh();
    }

    // Resolved once per workout; an exercise added on the phone later loads the table again.
    function fitCode(w, exerciseId) {
        if (exerciseId == null) {
            return null;
        }
        if (_fitCodes == null || !_fitCodes.hasKey(exerciseId)) {
            _fitCodes = FitExercise.codesFor(FitExercise.load(), w);
        }
        return _fitCodes[exerciseId];
    }

    function completedFor(set, reps, weight) {
        var completed = {"reps" => reps};
        var target = Weight.parse(set["weight"]);
        if (weight != null && target != null) {
            completed["weight"] = Weight.format(weight, target[1]);
        }
        // Editing a logged timed set keeps the time it recorded.
        var done = set["completed"];
        if (done != null) {
            var keep = ["setTimer", "setTimerLeft"];
            for (var i = 0; i < keep.size(); i++) {
                if (done[keep[i]] != null) {
                    completed[keep[i]] = done[keep[i]];
                }
            }
        }
        return completed;
    }

    function queueWrite(w, entry, set, completed) {
        var q = Store.queue();
        if (Queue.isFull(q)) {
            _notice = "Connect phone to sync";
            _ui.refresh();
            return false;
        }
        q.add(Queue.set(w["startTime"], entry["entryId"], set["setId"], completed));
        Store.setQueue(q);
        SlimWorkout.markCompleted(w, set["setId"], completed);
        Store.setWorkout(w);
        return true;
    }

    function skipSet() {
        var w = Store.workout();
        var skipped = Store.skipped();
        var cur = Store.cursor();
        if (cur == null) {
            return;
        }
        skipped.add(w["entries"][cur[0]]["sets"][cur[1]]["setId"]);
        Store.setSkipped(skipped);
        _ui.showActive();
    }

    function isPaused() {
        var rec = Store.rec();
        if (rec == null) {
            return false;
        }
        var intervals = rec["intervals"];
        return intervals[intervals.size() - 1][1] != null;
    }

    function togglePause() {
        var rec = Store.rec();
        if (rec == null) {
            return;
        }
        var intervals = rec["intervals"];
        if (isPaused()) {
            intervals.add([nowMs(), null]);
            _rec.resume();
        } else {
            intervals[intervals.size() - 1][1] = nowMs();
            _rec.pause();
        }
        rec["intervals"] = intervals;
        Store.setRec(rec);
        _ui.refresh();
    }

    function finish() {
        var w = Store.workout();
        if (w == null) {
            return;
        }
        var endMs = nowMs();
        var rec = Store.rec();
        var intervals = rec == null ? [[w["startTime"], null]] : rec["intervals"];
        if (intervals[intervals.size() - 1][1] == null) {
            intervals[intervals.size() - 1][1] = endMs;
        }
        var q = Store.queue();
        q.add(Queue.finish(w["startTime"], endMs, intervals.size() > 1 ? intervals : null));
        Store.setQueue(q);
        // The setting may have changed since the start; save the activity that is running.
        if (_rec.isActive()) {
            _rec.save(w["programName"], w["dayName"], Look.summary(w, nowMs()));
        }
        clearLocal();
        _ui.showWaiting(null);
        _sync.drain();
    }

    function discardGarmin() {
        _rec.discard();
        var rec = Store.rec();
        if (rec != null) {
            rec["garmin"] = false;
            Store.setRec(rec);
        }
        _ui.refresh();
    }

    // Puts the sets that were dropped back in the queue; any that fail again return to the list.
    function resendNotSynced() {
        var lost = Store.notSynced();
        if (lost.size() == 0) {
            return 0;
        }
        var q = Store.queue();
        var room = Config.QUEUE_CAP - q.size();
        var n = lost.size() < room ? lost.size() : (room > 0 ? room : 0);
        q.addAll(lost.slice(0, n));
        Store.setQueue(q);
        Store.setNotSynced(lost.slice(n, null));
        _sync.drain();
        _ui.refresh();
        return n;
    }

    function clearLocal() {
        _fitCodes = null;
        _sync.stopPolling();
        Store.setGlance(false, null);
        Store.setWorkout(null);
        Store.setSkipped(null);
        Store.setFocus(null);
        Store.setRest(null);
        Store.setRec(null);
    }

    // Buzzes once when the rest ends, whatever screen is up. Called by the set screen and the sync clock.
    function checkRestOver(nowSec) {
        var rest = Store.rest();
        if (rest == null || Rest.remaining(rest, nowSec) > 0 || Haptics.restBuzzedAt == rest["at"]) {
            return false;
        }
        Haptics.restBuzzedAt = rest["at"];
        Haptics.buzz(400);
        return true;
    }

    function onClock() {
        checkRestOver(nowSec());
    }

    // The rest after a set, when it has one and a set is left to do.
    function startRest(set) {
        var timer = set["timer"];
        var hasNext = Store.cursor() != null;
        Store.setRest(timer != null && timer > 0 && hasNext ? {"at" => nowSec(), "dur" => timer, "setId" => set["setId"]} : null);
    }

    // before is the workout as the watch had it. A set logged on the phone starts its rest here too,
    // and the watch follows that exercise, as after a set logged on the watch.
    function onWorkoutUpdated(before) {
        var w = Store.workout();
        var done = before == null || w == null ? null : SlimWorkout.lastNewlyDone(before, w);
        if (done != null) {
            Store.setFocus(done[0]["entryId"]);
            startRest(done[1]);
        }
        _ui.refresh();
    }

    function onWorkoutGone() {
        var w = Store.workout();
        var saved = _rec.isActive() && w != null;
        if (saved) {
            _rec.save(w["programName"], w["dayName"], Look.summary(w, nowMs()));
        }
        clearLocal();
        Haptics.buzz(600);
        _ui.showEnded(saved);
    }

    // The phone's rest starts when the server gets the set, which can be well after the tap when the phone
    // was out of reach. A rest still running moves to the server's time, the midpoint of send and reply.
    function onSetsSent(run, sentSec, ackSec) {
        var rest = Store.rest();
        if (rest == null || rest["setId"] == null || Rest.remaining(rest, ackSec) == 0) {
            return;
        }
        for (var i = 0; i < run.size(); i++) {
            var e = run[i];
            if (rest["setId"].equals(e["setId"]) && e["append"] != true && e["completed"] != null) {
                // Adding two timestamps would pass the 32-bit Number limit.
                var at = sentSec + (ackSec - sentSec) / 2;
                if (at > rest["at"]) {
                    rest["at"] = at;
                    Store.setRest(rest);
                    _ui.refresh();
                }
                return;
            }
        }
    }

    function onFinishSynced() {
        _ui.refresh();
    }

    function onHalt(reason, message) {
        _ui.showBlocked(reason, message);
    }
}
