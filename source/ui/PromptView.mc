import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Asks values one field at a time: the set's extra values before logging, or the reps or weight
// tapped on the set screen. Up and Down or the − and + buttons change the value; Start or the pill goes on.
// done is called with the fields after the last one.
class PromptView extends WatchUi.View {
    var fields;
    var index = 0;
    var _title;
    var _done;
    var _lastLabel;
    // Tap targets drawn this frame: [x, y, w, h, action].
    var _hits = [];

    function initialize(title, f, done, lastLabel) {
        View.initialize();
        _title = title;
        fields = f;
        _done = done;
        _lastLabel = lastLabel;
    }

    function step(dir) {
        Prompt.adjust(fields[index], dir);
        WatchUi.requestUpdate();
    }

    function next() {
        if (index < fields.size() - 1) {
            index++;
            WatchUi.requestUpdate();
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        _done.invoke(fields);
    }

    function back() {
        if (index > 0) {
            index--;
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }

    function tap(xy) {
        for (var i = 0; i < _hits.size(); i++) {
            var h = _hits[i];
            if (xy[0] >= h[0] && xy[0] <= h[0] + h[2] && xy[1] >= h[1] && xy[1] <= h[1] + h[3]) {
                if (h[4] == :minus) {
                    step(-1);
                } else if (h[4] == :plus) {
                    step(1);
                } else {
                    next();
                }
                return;
            }
        }
    }

    function onUpdate(dc) {
        Theme.clear(dc);
        var f = fields[index];
        var last = index == fields.size() - 1;
        var r = Theme.drawRows(dc, [
            [:small, _title, Theme.GREY],
            [:big, f["label"], Theme.TEXT],
            [:value, Prompt.text(f), f["kind"] == :weight ? Theme.GREEN : Theme.ORANGE, true],
            [:small, fields.size() > 1 ? (index + 1) + " of " + fields.size() : "", Theme.GREY],
            [:pill, last ? _lastLabel : "NEXT", Theme.PURPLE]
        ]);
        var ys = r[0];
        var heights = r[1];
        var tier = r[2];
        var w = dc.getWidth();
        // − and + beside the value box, kept inside the round screen.
        var by = ys[2];
        var bh = heights[2];
        var bw = Theme.boxW(dc, Prompt.text(f), null, tier[1], tier[2]);
        var rad = bh * 2 / 5;
        var gap = rad / 2;
        var edge = (w - Theme.chord(dc, by + bh / 2)) / 2 + gap;
        var lx = (w - bw) / 2 - gap - rad;
        if (lx - rad < edge) {
            lx = edge + rad;
        }
        var rx = w - lx;
        var cy = by + bh / 2;
        Theme.stepButton(dc, lx, cy, rad, false);
        Theme.stepButton(dc, rx, cy, rad, true);
        var pillW = Theme.pillW(dc, last ? _lastLabel : "NEXT", tier[2]);
        _hits = [
            [lx - rad - gap, cy - rad - gap, (rad + gap) * 2, (rad + gap) * 2, :minus],
            [rx - rad - gap, cy - rad - gap, (rad + gap) * 2, (rad + gap) * 2, :plus],
            [(w - pillW) / 2 - gap, ys[4] - gap, pillW + gap * 2, heights[4] + gap * 2, :next]
        ];
    }
}

// Buttons go through onKey, so a tap (which the behavior maps to onSelect) reaches onTap.
class PromptDelegate extends WatchUi.BehaviorDelegate {
    var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER) {
            _view.next();
        } else if (key == WatchUi.KEY_UP) {
            _view.step(1);
        } else if (key == WatchUi.KEY_DOWN) {
            _view.step(-1);
        } else if (key == WatchUi.KEY_ESC) {
            _view.back();
        } else {
            return false;
        }
        return true;
    }

    function onSelect() { return false; }

    function onTap(evt) {
        _view.tap(evt.getCoordinates());
        return true;
    }

    // Swipes: up and down change the value, right goes back.
    function onPreviousPage() {
        _view.step(1);
        return true;
    }

    function onNextPage() {
        _view.step(-1);
        return true;
    }

    function onBack() {
        _view.back();
        return true;
    }
}

// Logs (or saves) the set with the values from the Input screen.
class PromptLog {
    var _active;
    var _pos;
    var _base;
    var _reps;
    var _weight;
    var _isEdit;

    function initialize(active, pos, base, reps, weight, isEdit) {
        _active = active;
        _pos = pos;
        _base = base;
        _reps = reps;
        _weight = weight;
        _isEdit = isEdit;
    }

    function run(fields) {
        _active.backToCurrent();
        var completed = Prompt.completed(_base, fields);
        if (_isEdit) {
            getController().saveCompleted(_pos[0], _pos[1], completed);
        } else {
            getController().logCompleted(_pos[0], _pos[1], completed, _reps, _weight);
        }
    }
}
