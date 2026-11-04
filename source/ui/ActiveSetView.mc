import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ActiveSetView extends WatchUi.View {
    var _setId = null;
    var _reps = 0;
    var _weight = null;
    var _unit = "kg";
    var _step = 2.5;
    var _field = :reps;
    // The second last handled; the shared ticker calls four times a second.
    var _tickSec = null;
    // The browsed set as [entry, set]; null follows the cursor.
    var _pos = null;
    var _loadedDone = false;
    // Tap targets drawn this frame: [x, y, w, h, action].
    var _hits = [];

    function initialize() {
        View.initialize();
    }

    function onShow() {
        Ticker.watch(self);
    }

    function onHide() {
        Ticker.unwatch(self);
    }

    function position() {
        var w = Store.workout();
        if (w == null) {
            return null;
        }
        if (_pos != null && (_pos[0] >= w["entries"].size() || _pos[1] >= w["entries"][_pos[0]]["sets"].size())) {
            _pos = null;
        }
        return _pos != null ? _pos : Store.cursor();
    }

    function isBrowsing() {
        if (_pos == null) {
            return false;
        }
        var cur = Store.cursor();
        return cur == null || cur[0] != _pos[0] || cur[1] != _pos[1];
    }

    function current() {
        var w = Store.workout();
        var pos = position();
        if (pos == null) {
            return null;
        }
        var entry = w["entries"][pos[0]];
        var set = entry["sets"][pos[1]];
        var done = set["completed"];
        // A logged set shows what was logged; a set that is not done shows its target.
        if (!set["setId"].equals(_setId) || _loadedDone != (done != null)) {
            _setId = set["setId"];
            _loadedDone = done != null;
            var reps = done != null && done["reps"] != null ? done["reps"] : set["reps"];
            _reps = reps == null ? 0 : reps;
            var target = Weight.parse(set["weight"]);
            var p = done != null && done["weight"] != null ? Weight.parse(done["weight"]) : target;
            _weight = p == null ? null : p[0];
            _unit = p == null ? "kg" : p[1];
            _step = Weight.step(_unit);
            _field = :reps;
        }
        return [entry, set, pos];
    }

    function browse(dir) {
        var w = Store.workout();
        var pos = position();
        if (w == null || pos == null && dir > 0) {
            return;
        }
        var next = pos == null ? lastSet(w) : Nav.step(w, pos, dir);
        if (next != null) {
            slideTo(next, dir > 0 ? WatchUi.SLIDE_LEFT : WatchUi.SLIDE_RIGHT);
        }
    }

    // The set slides in as a new screen, in the direction of travel.
    function slideTo(pos, transition) {
        var v = new ActiveSetView();
        v._pos = pos;
        WatchUi.switchToView(v, new ActiveSetDelegate(v), transition);
    }

    function slideToward(pos) {
        var cmp = Nav.compare(pos, position());
        slideTo(pos, cmp < 0 ? WatchUi.SLIDE_RIGHT : WatchUi.SLIDE_LEFT);
    }

    function jump(dir) {
        var w = Store.workout();
        var pos = position();
        if (w == null) {
            return;
        }
        var next = pos == null ? (dir < 0 ? lastSet(w) : null) : Nav.jumpEntry(w, pos, dir);
        if (next != null) {
            slideTo(next, dir > 0 ? WatchUi.SLIDE_UP : WatchUi.SLIDE_DOWN);
        }
    }

    // Hold Down: the next exercise, wrapping around, for watches without touch.
    function cycle() {
        var w = Store.workout();
        var next = w == null ? null : Nav.cycleEntry(w, position());
        if (next != null) {
            slideTo(next, WatchUi.SLIDE_UP);
        }
    }

    // From "All sets done", going back starts at the last set.
    function lastSet(w) {
        var entries = w["entries"];
        for (var i = entries.size() - 1; i >= 0; i--) {
            if (entries[i]["sets"].size() > 0) {
                return [i, entries[i]["sets"].size() - 1];
            }
        }
        return null;
    }

    function showEntry(ei) {
        var w = Store.workout();
        var p = w == null ? null : Nav.firstOpen(w, ei);
        if (p != null) {
            slideToward(p);
        }
    }

    function addSet() {
        var pos = position();
        var w = Store.workout();
        var ei = pos != null ? pos[0] : (w == null ? -1 : w["entries"].size() - 1);
        if (ei >= 0) {
            getController().addSet(ei);
        }
    }

    function backToCurrent() {
        _pos = null;
        WatchUi.requestUpdate();
    }

    // Back while browsing: the current set slides in from where it is.
    function returnToCurrent() {
        var cur = Store.cursor();
        var cmp = Nav.compare(cur, position());
        var v = new ActiveSetView();
        WatchUi.switchToView(v, new ActiveSetDelegate(v), cmp < 0 ? WatchUi.SLIDE_RIGHT : WatchUi.SLIDE_LEFT);
    }

    function viewedDone() {
        var c = current();
        return c != null && c[1]["completed"] != null;
    }

    function undo() {
        var c = current();
        if (c == null || c[1]["completed"] == null) {
            return;
        }
        Menus.confirm("Undo set?", new UndoAction(self, c[2]).method(:run));
    }

    function tap(xy) {
        for (var i = _hits.size() - 1; i >= 0; i--) {
            var h = _hits[i];
            if (xy[0] >= h[0] && xy[0] <= h[0] + h[2] && xy[1] >= h[1] && xy[1] <= h[1] + h[3]) {
                var action = h[4];
                if (action == :reps || action == :weight) {
                    editField(action);
                } else if (action == :log) {
                    logSet();
                } else if (action == :undo) {
                    undo();
                } else if (action == :rest) {
                    Menus.restMenu();
                } else if (action == :title) {
                    Menus.overview(self);
                }
                return true;
            }
        }
        return true;
    }

    // A tapped box opens a value screen with − and +, for watches without Up and Down.
    function editField(kind) {
        var c = current();
        if (c == null || kind == :weight && _weight == null) {
            return;
        }
        _field = kind;
        var f = kind == :reps
            ? Prompt.field("reps", "Reps", _reps, 1, 0, null, :reps, null)
            : Prompt.field("weight", "Weight (" + _unit + ")", _weight, _step, 0, null, :weight, _unit);
        var view = new PromptView(c[0]["name"], [f], method(:setValue), "DONE");
        WatchUi.pushView(view, new PromptDelegate(view), WatchUi.SLIDE_UP);
    }

    function setValue(fields) {
        var f = fields[0];
        if (f["key"].equals("reps")) {
            _reps = f["value"];
        } else {
            _weight = f["value"];
        }
        WatchUi.requestUpdate();
    }

    function adjust(dir) {
        var c = current();
        if (c == null) {
            return;
        }
        if (_field == :reps) {
            _reps = _reps + dir < 0 ? 0 : _reps + dir;
        } else if (_weight != null) {
            var next = _weight + dir * _step;
            _weight = next < 0 ? 0.0 : next;
        }
        WatchUi.requestUpdate();
    }

    function toggleField() {
        if (_weight != null) {
            _field = _field == :reps ? :weight : :reps;
            WatchUi.requestUpdate();
        }
    }

    function hasQueuedSet(entry) {
        var q = Store.queue();
        for (var i = 0; i < q.size(); i++) {
            if (q[i]["t"].equals("set") && entry["entryId"].equals(q[i]["entryId"])) {
                return true;
            }
        }
        return false;
    }
    function tick() {
        var sec = Controller.nowSec();
        if (sec == _tickSec) {
            return;
        }
        _tickSec = sec;
        // Left under a menu when the workout ended on the phone, then shown again.
        if (Store.workout() == null) {
            Ticker.unwatch(self);
            getController().boot();
            return;
        }
        getController().checkRestOver(sec);
        var rest = Store.rest();
        // The total time on "All sets done" ticks too.
        if (rest != null || Store.cursor() == null) {
            WatchUi.requestUpdate();
        }
    }

    function logSet() {
        var c = current();
        if (c == null) {
            Menus.confirm("Save & finish?", new MenuActions().method(:finish));
            return;
        }
        var pos = c[2];
        if (c[1]["setTimer"] != null && c[1]["completed"] == null) {
            var base = getController().completedFor(c[1], _reps, _weight);
            var timed = new TimedView(c[0]["name"], c[1]["setTimer"], c[1]["isUnilateral"] == true, self, pos, base, _reps, _weight);
            WatchUi.pushView(timed, new TimedDelegate(timed), WatchUi.SLIDE_LEFT);
            return;
        }
        var fields = Prompt.fields(c[0], c[1], SlimWorkout.unit(Store.workout()));
        if (fields.size() > 0) {
            var base = getController().completedFor(c[1], _reps, _weight);
            var log = new PromptLog(self, pos, base, _reps, _weight, c[1]["completed"] != null);
            var view = new PromptView(c[0]["name"], fields, log.method(:run), "LOG");
            WatchUi.pushView(view, new PromptDelegate(view), WatchUi.SLIDE_LEFT);
            return;
        }
        _pos = null;
        if (c[1]["completed"] != null) {
            getController().saveSet(pos[0], pos[1], _reps, _weight);
        } else {
            getController().logSetAt(pos[0], pos[1], _reps, _weight);
        }
    }

    function onUpdate(dc) {
        _hits = [];
        Theme.clear(dc);
        if (Store.workout() == null) {
            return;
        }
        var h = dc.getHeight();
        var inset = (h * 0.08).toNumber();
        var bottom = Theme.bannerText() != null ? (h * 0.83).toNumber() : h - inset;
        var c = current();
        if (c == null) {
            drawDone(dc, inset, bottom);
        } else {
            var rest = Store.rest();
            var now = Controller.nowSec();
            if (rest != null) {
                Theme.restRing(dc, Look.restFraction(rest, now), Look.restOver(rest, now));
            }
            drawSet(dc, inset, bottom, c, rest, now);
        }
        Theme.bannerAt(dc, 0.89);
    }

    // Tries the font tiers from largest to smallest and draws the first stack that fits the screen.
    function drawSet(dc, top, bottom, c, rest, now) {
        var tiers = Theme.TIERS;
        for (var t = 0; t < tiers.size(); t++) {
            var plan = planSet(dc, tiers[t], c, rest != null, top, bottom);
            if (plan["fits"] || t == tiers.size() - 1) {
                drawPlan(dc, tiers[t], plan, c, rest, now);
                return;
            }
        }
    }

    function planSet(dc, tier, c, hasRest, top, bottom) {
        var big = tier[0];
        var num = tier[1];
        var small = tier[2];
        var entry = c[0];
        var set = c[1];
        var w = dc.getWidth();
        var heights = [];
        if (hasRest) {
            heights.add(Graphics.getFontAscent(big));
        }
        var name = entry["name"];
        var title = name;
        var titleH = Graphics.getFontAscent(big);
        if (dc.getTextWidthInPixels(name, big) > w * 0.78) {
            title = dc.fitTextToArea(name, big, w * 0.78, Graphics.getFontHeight(big) * 2 + 4, true);
            if (title.find("\n") != null) {
                titleH += Graphics.getFontHeight(big);
            }
        }
        heights.add(titleH);
        heights.add(Graphics.getFontAscent(small));
        var plan = {"title" => title, "boxRow" => heights.size(), "info" => null};
        heights.add(Theme.boxH(num, small));
        var info = Look.infoLine(entry, set);
        var infoRow = -1;
        if (info[0].length() + info[1].length() > 0) {
            plan["info"] = info;
            infoRow = heights.size();
            heights.add(Graphics.getFontAscent(small));
        }
        heights.add(Theme.pillH(small));
        heights.add(Graphics.getFontAscent(small));
        var gap = Theme.capH(small) * 3 / 4;
        var ys = Layout.stack(heights, gap, top, bottom);
        var fits = Layout.total(heights, gap) <= bottom - top;
        if (fits) {
            var by = ys[plan["boxRow"]];
            var bh = heights[plan["boxRow"]];
            var room = Theme.chord(dc, by);
            var lower = Theme.chord(dc, by + bh);
            fits = boxRowWidth(dc, set, num, small) <= (room < lower ? room : lower) - gap * 2;
        }
        if (fits && infoRow >= 0) {
            var iy = ys[infoRow];
            var a = Theme.chord(dc, iy);
            var b = Theme.chord(dc, iy + heights[infoRow]);
            fits = dc.getTextWidthInPixels(info[0] + info[1], small) <= (a < b ? a : b) - gap;
        }
        plan["heights"] = heights;
        plan["ys"] = ys;
        plan["fits"] = fits;
        return plan;
    }

    function repsText(set) {
        // The target reads like the phone ("6-9"), until the reps are changed or the set is logged.
        if (set["completed"] == null && set["reps"] != null && _reps == set["reps"]) {
            return Look.repsTarget(set);
        }
        return _reps.toString() + (set["isAmrap"] == true ? "+" : "");
    }

    function timesGap(dc, small) {
        return dc.getTextWidthInPixels("×", small) + Theme.capH(small);
    }

    function boxRowWidth(dc, set, num, small) {
        var repsW = Theme.boxW(dc, repsText(set), null, num, small);
        if (_weight == null) {
            return repsW;
        }
        return repsW + timesGap(dc, small) + Theme.boxW(dc, Weight.formatNumber(_weight), _unit, num, small);
    }

    function drawPlan(dc, tier, plan, c, rest, now) {
        var big = tier[0];
        var num = tier[1];
        var small = tier[2];
        var entry = c[0];
        var set = c[1];
        var w = dc.getWidth();
        var ys = plan["ys"];
        var heights = plan["heights"];
        var row = 0;
        if (rest != null) {
            Theme.textAt(dc, ys[row], big, Look.restText(rest, now), Look.restOver(rest, now) ? Theme.GREEN : Theme.PURPLE_LIGHT);
            _hits.add([0, ys[row], w, heights[row], :rest]);
            row++;
        }
        drawHeartRate(dc, ys[ys.size() - 1], small);
        Theme.textAt(dc, ys[row], big, plan["title"], Theme.TEXT);
        _hits.add([0, ys[row], w, heights[row], :title]);
        row++;

        var done = set["completed"] != null;
        var label = "Set " + (c[2][1] + 1) + "/" + entry["sets"].size() + (done ? " · Done" : "");
        if (entry["hasUpdateScript"] == true && hasQueuedSet(entry)) {
            label += getController().sync().isOffline() ? " · may change" : " · Updating...";
        }
        var r = Theme.capH(small) * 2 / 5;
        var space = Theme.capH(small) / 2;
        var labelW = dc.getTextWidthInPixels(label, small);
        var x = (w - labelW - space - Theme.dotsWidth(dc, entry["sets"].size(), r)) / 2;
        dc.setColor(done ? Theme.GREEN : Theme.GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, ys[row], small, label, Graphics.TEXT_JUSTIFY_LEFT);
        Theme.dots(dc, x + labelW + space, ys[row] + Graphics.getFontAscent(small) - Theme.capH(small) / 2, entry["sets"], c[2][1], r);
        row++;

        var by = ys[row];
        var bh = heights[row];
        var reps = repsText(set);
        var targetReps = set["reps"] == null ? 0 : set["reps"];
        var repsColor = _reps == targetReps ? Theme.ORANGE : Theme.TEXT;
        var repsW = Theme.boxW(dc, reps, null, num, small);
        if (_weight == null) {
            Theme.box(dc, (w - repsW) / 2, by, repsW, bh, reps, null, repsColor, true, num, small);
            _hits.add([(w - repsW) / 2, by, repsW, bh, :reps]);
        } else {
            var weightText = Weight.formatNumber(_weight);
            var weightW = Theme.boxW(dc, weightText, _unit, num, small);
            var mid = timesGap(dc, small);
            var left = (w - repsW - mid - weightW) / 2;
            var target = Weight.parse(set["weight"]);
            var weightColor = target != null && _weight == target[0] ? Theme.GREEN : Theme.TEXT;
            Theme.box(dc, left, by, repsW, bh, reps, null, repsColor, _field == :reps, num, small);
            dc.setColor(Theme.GREY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left + repsW + mid / 2, by + bh / 2, small, "×", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            Theme.box(dc, left + repsW + mid, by, weightW, bh, weightText, _unit, weightColor, _field == :weight, num, small);
            _hits.add([left, by, repsW, bh, :reps]);
            _hits.add([left + repsW + mid, by, weightW, bh, :weight]);
        }
        row++;

        var info = plan["info"];
        if (info != null) {
            Theme.twoTone(dc, ys[row] + Graphics.getFontHeight(small) / 2, small, info[0], Theme.GREY, info[1], Theme.TEXT);
            row++;
        }
        var py = ys[row] + heights[row] / 2;
        var ph = heights[row];
        var checkW = (ph * 2.4).toNumber();
        if (!done) {
            Theme.checkPill(dc, w / 2, py, ph);
            _hits.add([(w - checkW) / 2, py - ph / 2, checkW, ph, :log]);
            return;
        }
        // A logged set: save the edited values, or undo.
        var undoW = Theme.pillW(dc, "UNDO", small);
        var gapX = ph / 3;
        var x0 = (w - checkW - gapX - undoW) / 2;
        Theme.checkPill(dc, x0 + checkW / 2, py, ph);
        Theme.pillAt(dc, x0 + checkW + gapX + undoW / 2, py, "UNDO", Theme.PILL_GREY, small);
        _hits.add([x0, py - ph / 2, checkW, ph, :log]);
        _hits.add([x0 + checkW + gapX, py - ph / 2, undoW, ph, :undo]);
    }

    // "♥ 132", and the time after it when that setting is on: "♥ 132   14:05".
    function drawHeartRate(dc, y, font) {
        var info = Activity.getActivityInfo();
        var text = Look.heartRate(info == null ? null : info.currentHeartRate);
        var clock = null;
        if (Prefs.showClock()) {
            var t = System.getClockTime();
            clock = Look.timeOfDay(t.hour, t.min, System.getDeviceSettings().is24Hour);
        }
        var s = Theme.capH(font) / 2;
        var textW = dc.getTextWidthInPixels(text, font);
        var gap = s * 3;
        var clockW = clock == null ? 0 : gap + dc.getTextWidthInPixels(clock, font);
        var x = (dc.getWidth() - textW - s * 3 - clockW) / 2;
        var cy = y + Graphics.getFontAscent(font) - Theme.capH(font) / 2;
        Theme.heart(dc, x + s, cy, s);
        dc.setColor(Theme.GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + s * 3, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
        if (clock != null) {
            dc.setColor(Theme.TEXT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + s * 3 + textW + gap, y, font, clock, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    function drawDone(dc, top, bottom) {
        var s = Look.summary(Store.workout(), Controller.nowMs());
        var w = dc.getWidth();
        var tiers = Theme.TIERS;
        for (var t = 0; t < tiers.size(); t++) {
            var big = tiers[t][0];
            var small = tiers[t][2];
            var pillH = Theme.pillH(small);
            var heights = [Graphics.getFontAscent(big), Graphics.getFontAscent(small), pillH, pillH, Graphics.getFontAscent(small)];
            var gap = Theme.capH(small);
            if (Layout.total(heights, gap) > bottom - top && t < tiers.size() - 1) {
                continue;
            }
            var ys = Layout.stack(heights, gap, top, bottom);
            Theme.textAt(dc, ys[0], big, "All sets done", Theme.GREEN);
            Theme.textAt(dc, ys[1], small, "Total time " + s["time"], Theme.GREY);
            var a = s["sets"] + " sets · ";
            var cardW = dc.getTextWidthInPixels(a + s["volume"], small) + pillH;
            Theme.card(dc, (w - cardW) / 2, ys[2], cardW, pillH);
            Theme.twoTone(dc, ys[2] + pillH / 2, small, a, Theme.ORANGE, s["volume"], Theme.GREEN);
            Theme.pill(dc, ys[3] + pillH / 2, "FINISH", Theme.PURPLE, small);
            _hits.add([0, ys[3], w, pillH, :log]);
            Theme.textAt(dc, ys[4], small, Theme.menuHint(), Theme.GREY);
            return;
        }
    }
}

class UndoAction {
    var _view;
    var _pos;

    function initialize(view, pos) {
        _view = view;
        _pos = pos;
    }

    function run() {
        _view.backToCurrent();
        getController().undoSet(_pos[0], _pos[1]);
    }
}

class ActiveSetDelegate extends WatchUi.BehaviorDelegate {
    var _view;
    var _enterAt = null;
    var _upAt = null;
    var _downAt = null;
    var _menuOpened = false;
    var _menuAt = null;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKeyPressed(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER) {
            _enterAt = System.getTimer();
            return true;
        }
        if (key == WatchUi.KEY_UP) {
            _upAt = System.getTimer();
            _menuOpened = false;
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _downAt = System.getTimer();
            return true;
        }
        return false;
    }

    function onKeyReleased(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER && _enterAt != null) {
            var held = System.getTimer() - _enterAt;
            _enterAt = null;
            if (held >= Config.HOLD_MS) {
                _view.toggleField();
            } else {
                _view.logSet();
            }
            return true;
        }
        if (key == WatchUi.KEY_UP && _upAt != null) {
            var heldUp = System.getTimer() - _upAt;
            _upAt = null;
            if (!_menuOpened && heldUp < Config.HOLD_MS) {
                _view.adjust(1);
            }
            return true;
        }
        if (key == WatchUi.KEY_DOWN && _downAt != null) {
            var heldDown = System.getTimer() - _downAt;
            _downAt = null;
            if (heldDown >= Config.HOLD_MS) {
                _view.cycle();
            } else {
                _view.adjust(-1);
            }
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            backPressed();
            return true;
        }
        return false;
    }

    function onKey(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN || key == WatchUi.KEY_ESC) {
            return true;
        }
        if (key == WatchUi.KEY_MENU) {
            return onMenu();
        }
        return false;
    }

    function onMenu() {
        // A screen hold can arrive as both onHold and the menu behavior; open the menu once.
        var now = System.getTimer();
        if (_menuAt != null && now - _menuAt < 1000) {
            return true;
        }
        _menuAt = now;
        _menuOpened = true;
        Menus.workoutMenu(_view);
        return true;
    }

    // Holding the screen opens the menu on watches without an Up button.
    function onHold(evt) {
        return onMenu();
    }

    // The Back button, handled as a key so that swipe right (which the device maps to onBack) reaches onSwipe.
    function backPressed() {
        if (_view.isBrowsing()) {
            _view.returnToCurrent();
            return;
        }
        Menus.confirm("Skip set?", new MenuActions().method(:skip));
    }

    // Garmin runs the behavior first and passes the raw tap or swipe on only when it returns false:
    // tap is onSelect, swipe up/down is nextPage/previousPage, swipe right is onBack.
    // The buttons are handled in onKeyPressed/onKeyReleased, so these return false.
    function onBack() { return false; }
    function onSelect() { return false; }
    function onNextPage() { return false; }
    function onPreviousPage() { return false; }
    function onTap(evt) {
        return _view.tap(evt.getCoordinates());
    }

    // Left and right move between sets, up and down between exercises.
    function onSwipe(evt) {
        var d = evt.getDirection();
        if (d == WatchUi.SWIPE_LEFT) {
            _view.browse(1);
        } else if (d == WatchUi.SWIPE_RIGHT) {
            _view.browse(-1);
        } else if (d == WatchUi.SWIPE_UP) {
            _view.jump(1);
        } else if (d == WatchUi.SWIPE_DOWN) {
            _view.jump(-1);
        }
        return true;
    }
}
