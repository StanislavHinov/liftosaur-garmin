import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Runs a timed set: get ready, then the clock; one-sided sets run left, then right.
class TimedView extends WatchUi.View {
    var run;
    var sides = [];
    var _title;
    var _target;
    var _unilateral;
    var _active;
    var _pos;
    var _base;
    var _reps;
    var _weight;
    var _finished = false;

    function initialize(title, target, unilateral, active, pos, base, reps, weight) {
        View.initialize();
        _title = title;
        _target = target;
        _unilateral = unilateral;
        _active = active;
        _pos = pos;
        _base = base;
        _reps = reps;
        _weight = weight;
        run = TimedSet.begin(Controller.nowSec(), target);
    }

    function onShow() {
        Ticker.watch(self);
    }

    function onHide() {
        Ticker.unwatch(self);
    }

    function tick() {
        if (!_finished && TimedSet.isDone(run, Controller.nowSec())) {
            finishSide(_target);
        }
        WatchUi.requestUpdate();
    }

    // Start: skip get-ready, or log the time so far.
    function press() {
        var now = Controller.nowSec();
        if (TimedSet.phase(run, now) == :ready) {
            run = TimedSet.skipReady(run, now);
        } else {
            finishSide(TimedSet.elapsed(run, now));
        }
        WatchUi.requestUpdate();
    }

    function finishSide(seconds) {
        Haptics.buzz(400);
        sides.add(seconds);
        if (_unilateral && sides.size() == 1) {
            run = TimedSet.begin(Controller.nowSec(), _target);
            return;
        }
        _finished = true;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        _active.backToCurrent();
        getController().logCompleted(_pos[0], _pos[1], TimedSet.completed(_base, sides), _reps, _weight);
    }

    function onUpdate(dc) {
        Theme.clear(dc);
        var now = Controller.nowSec();
        var ready = TimedSet.phase(run, now) == :ready;
        if (ready) {
            Theme.ring(dc, TimedSet.readyLeft(run, now).toFloat() / TimedSet.READY, Theme.READY, Theme.READY_TRACK);
        } else {
            Theme.ring(dc, TimedSet.fraction(run, now), Theme.PURPLE, Theme.CARD);
        }
        var side = _unilateral ? (sides.size() == 0 ? "Left" : "Right") : null;
        var label = ready ? "Get ready" : (side == null ? "Hold" : side);
        if (ready && side != null) {
            label = "Get ready: " + side;
        }
        Theme.drawRows(dc, [
            [:small, _title, Theme.GREY],
            [:big, label, ready ? Theme.READY : Theme.TEXT],
            [:value, TimedSet.text(run, now), ready ? Theme.READY : Theme.PURPLE_LIGHT],
            [:small, "of " + Rest.clock(_target), Theme.GREY],
            [:pill, ready ? "GO" : "LOG", Theme.PURPLE]
        ]);
    }
}

class TimedDelegate extends WatchUi.BehaviorDelegate {
    var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() {
        _view.press();
        return true;
    }

    function onTap(evt) {
        _view.press();
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onPreviousPage() { return true; }
    function onNextPage() { return true; }
}
