import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;

class Sync {
    var _api;
    var _listener;
    var _busy = false;
    var _inFlight = 0;
    // When the run in flight was sent, in seconds; the server stamps its writes between this and the reply.
    var _sentSec = 0;
    var _retryIdx = 0;
    var _offline = false;
    // One timer for retries and polling; a watch allows only a few timers at once.
    var _timer = null;
    var _retryAt = null;
    var _polling = false;
    var _polledAt = 0;

    function initialize(api, listener) {
        _api = api;
        _listener = listener;
    }

    // How many queue entries are on their way now; they must stay at the head until the reply.
    function inFlight() {
        return _busy ? _inFlight : 0;
    }

    function isOffline() {
        return _offline;
    }

    function drain() {
        if (_busy || Store.halt() != null) {
            return;
        }
        var q = Store.queue();
        var n = Queue.headRunLength(q);
        if (n == 0) {
            _retryIdx = 0;
            _offline = false;
            return;
        }
        _busy = true;
        _inFlight = n;
        _sentSec = Time.now().value();
        _api.request(Requests.forRun(q.slice(0, n)), method(:onResponse));
    }

    function onResponse(status, data) {
        _busy = false;
        var q = Store.queue();
        var run = q.slice(0, _inFlight);
        var action = ErrorPolicy.decide(status, data);
        if (action.equals("ok")) {
            Store.setQueue(Queue.dropFirst(q, _inFlight));
            _retryIdx = 0;
            _offline = false;
            if (run[0]["t"].equals("finish")) {
                _listener.onFinishSynced();
            } else if (run[0]["t"].equals("set")) {
                _listener.onSetsSent(run, _sentSec, Time.now().value());
                adopt(data);
            }
            drain();
        } else if (action.equals("retry")) {
            scheduleRetry();
        } else if (action.equals("noWorkout")) {
            dropWorkout(run[0]["st"]);
            drain();
        } else if (action.equals("refetch")) {
            _busy = true;
            _api.request(Requests.current(), method(:onRefetch));
        } else {
            halt(action, data);
        }
    }

    // Every 15 s during a workout: notices a workout finished, discarded or replaced on the phone.
    function startPolling() {
        _polling = true;
        _polledAt = System.getTimer();
        runClock();
    }

    function stopPolling() {
        _polling = false;
    }

    function runClock() {
        if (_timer == null) {
            _timer = new Timer.Timer();
            _timer.start(method(:onClock), 1000, true);
        }
    }

    function onClock() {
        step(System.getTimer());
    }

    // now in ms (System.getTimer): sends a due retry, polls every 15 s, and stops the clock when idle.
    function step(now) {
        if (_polling) {
            _listener.onClock();
        }
        if (_retryAt != null && now >= _retryAt) {
            _retryAt = null;
            onRetryTimer();
        }
        if (_polling && now - _polledAt >= 15000) {
            _polledAt = now;
            poll();
        }
        if (!_polling && _retryAt == null && _timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function poll() {
        if (_busy || Store.halt() != null || Store.workout() == null) {
            return;
        }
        if (Store.queue().size() > 0) {
            drain();
            return;
        }
        _busy = true;
        _inFlight = 0;
        _api.request(Requests.current(), method(:onPoll));
    }

    function onPoll(status, data) {
        _busy = false;
        if (ErrorPolicy.decide(status, data).equals("ok")) {
            var local = Store.workout();
            var raw = data instanceof Dictionary && data["data"] instanceof Dictionary ? data["data"]["workout"] : null;
            if (local != null && raw != null && raw["startTime"] != local["startTime"]) {
                _listener.onWorkoutGone();
            } else {
                adopt(data);
            }
        }
        // Sets logged while the poll was out could not be sent then.
        drain();
    }

    function onRefetch(status, data) {
        _busy = false;
        var action = ErrorPolicy.decide(status, data);
        if (action.equals("retry") || action.equals("refetch")) {
            scheduleRetry();
            return;
        }
        if (!action.equals("ok")) {
            halt(action, data);
            return;
        }
        var local = Store.workout();
        var raw = data instanceof Dictionary && data["data"] instanceof Dictionary ? data["data"]["workout"] : null;
        if (local != null && (raw == null || raw["startTime"] != local["startTime"])) {
            // Set writes apply to whatever workout is live, so a rejected set means the phone moved on.
            dropWorkout(local["startTime"]);
            drain();
            return;
        }
        adopt(data);
        var w = Store.workout();
        var kept = [];
        var lost = [];
        var q = Store.queue();
        for (var i = 0; i < q.size(); i++) {
            var e = q[i];
            var missing = e["t"].equals("set")
                && (w == null || e["st"] != w["startTime"] || SlimWorkout.findSet(w, e["setId"]) == null);
            if (missing) {
                lost.add(e);
            } else {
                kept.add(e);
            }
        }
        if (lost.size() == 0) {
            halt("haltBug", {"error" => {"message" => "Set rejected but still in workout"}});
            return;
        }
        Store.setQueue(kept);
        Store.addNotSynced(lost);
        drain();
    }

    function adopt(data) {
        var local = Store.workout();
        if (local == null || !(data instanceof Dictionary) || !(data["data"] instanceof Dictionary)) {
            return;
        }
        var raw = data["data"]["workout"];
        if (raw == null) {
            _listener.onWorkoutGone();
            return;
        }
        if (raw["startTime"] != local["startTime"]) {
            return;
        }
        var w = SlimWorkout.slim(raw);
        SlimWorkout.applyPending(w, Store.queue());
        Store.setWorkout(w);
        _listener.onWorkoutUpdated();
    }

    function dropWorkout(st) {
        var kept = [];
        var lost = [];
        var q = Store.queue();
        for (var i = 0; i < q.size(); i++) {
            var e = q[i];
            if (e["st"] != st) {
                kept.add(e);
            } else if (e["t"].equals("set")) {
                lost.add(e);
            }
        }
        Store.setQueue(kept);
        Store.addNotSynced(lost);
        var local = Store.workout();
        if (local != null && local["startTime"] == st) {
            _listener.onWorkoutGone();
        }
    }

    function halt(reason, data) {
        var message = ErrorPolicy.message(data);
        Store.setHalt({"reason" => reason, "message" => message});
        _listener.onHalt(reason, message);
    }

    function scheduleRetry() {
        _offline = true;
        var delays = Config.RETRY_DELAYS;
        var seconds = _retryIdx < delays.size() ? delays[_retryIdx] : 60;
        _retryIdx++;
        startTimer(seconds);
    }

    function startTimer(seconds) {
        _retryAt = System.getTimer() + seconds * 1000;
        runClock();
    }

    function onRetryTimer() {
        if (!System.getDeviceSettings().phoneConnected) {
            startTimer(60);
            return;
        }
        drain();
    }
}
