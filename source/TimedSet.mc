import Toybox.Lang;

// A timed set run: a get-ready countdown, then a clock toward the target. Times are in seconds.
module TimedSet {
    const READY = 5;

    function begin(nowSec, target) {
        return {"at" => nowSec, "target" => target};
    }

    // Start during get-ready starts the clock at once.
    function skipReady(run, nowSec) {
        return {"at" => nowSec - READY, "target" => run["target"]};
    }

    function phase(run, nowSec) {
        return nowSec - run["at"] < READY ? :ready : :work;
    }

    function readyLeft(run, nowSec) {
        var left = READY - (nowSec - run["at"]);
        return left > 0 ? left : 0;
    }

    function elapsed(run, nowSec) {
        var e = nowSec - run["at"] - READY;
        return e > 0 ? e : 0;
    }

    function fraction(run, nowSec) {
        if (run["target"] <= 0) {
            return 1.0;
        }
        var f = elapsed(run, nowSec).toFloat() / run["target"];
        return f > 1.0 ? 1.0 : f;
    }

    function isDone(run, nowSec) {
        return phase(run, nowSec) == :work && elapsed(run, nowSec) >= run["target"];
    }

    function text(run, nowSec) {
        if (phase(run, nowSec) == :ready) {
            return readyLeft(run, nowSec).toString();
        }
        return Rest.clock(elapsed(run, nowSec));
    }

    // sides holds the seconds per side: [both] or [left, right].
    function completed(base, sides) {
        var c = {};
        var keys = base.keys();
        for (var i = 0; i < keys.size(); i++) {
            c[keys[i]] = base[keys[i]];
        }
        if (sides.size() == 2) {
            c["setTimerLeft"] = sides[0];
            c["setTimer"] = sides[1];
        } else {
            c["setTimer"] = sides[0];
        }
        return c;
    }
}
