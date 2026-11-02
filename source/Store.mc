import Toybox.Application;
import Toybox.Lang;

(:background)
module Store {
    const KEYS = ["queue", "workout", "skipped", "rest", "rec", "notSynced", "halt", "glance", "focus"];
    // The workout is read on every redraw; keep the last one read or written instead of deserializing it.
    // Treat it as read-only unless you call setWorkout after changing it.
    var _workout = null;
    var _workoutLoaded = false;

    function get(key, fallback) {
        var v = Application.Storage.getValue(key);
        return v == null ? fallback : v;
    }

    function put(key, v) {
        if (v == null) {
            Application.Storage.deleteValue(key);
        } else {
            Application.Storage.setValue(key, v);
        }
    }

    function queue() { return get("queue", []); }
    function setQueue(q) { put("queue", q); }
    function workout() {
        if (!_workoutLoaded) {
            _workout = get("workout", null);
            _workoutLoaded = true;
        }
        return _workout;
    }

    // False, and nothing written, for a workout too big for one storage value.
    function setWorkout(w) {
        if (w != null && SlimWorkout.setCount(w) > Config.MAX_WORKOUT_SETS) {
            return false;
        }
        put("workout", w);
        _workout = w;
        _workoutLoaded = true;
        return true;
    }
    // The entryId of the exercise last logged; see SlimWorkout.cursorAt.
    function focus() { return get("focus", null); }
    function setFocus(entryId) { put("focus", entryId); }
    // The set to do next.
    function cursor() { return SlimWorkout.cursorAt(workout(), skipped(), focus()); }
    function skipped() { return get("skipped", []); }
    function setSkipped(a) { put("skipped", a); }
    function rest() { return get("rest", null); }
    function setRest(r) { put("rest", r); }
    function rec() { return get("rec", null); }
    function setRec(r) { put("rec", r); }
    function halt() { return get("halt", null); }
    function setHalt(h) { put("halt", h); }
    function notSynced() { return get("notSynced", []); }
    function setNotSynced(a) { put("notSynced", a); }
    // What the glance shows: {"ongoing", "day"}, or null.
    function setGlance(ongoing, day) {
        var g = day == null ? null : {"ongoing" => ongoing, "day" => day};
        put("glance", g);
        Face.publish(g);
    }

    function addNotSynced(entries) {
        var list = notSynced();
        list.addAll(entries);
        // Kept across workouts, so capped; the newest are kept.
        if (list.size() > Config.QUEUE_CAP) {
            list = list.slice(list.size() - Config.QUEUE_CAP, null);
        }
        put("notSynced", list);
    }

    function deviceId() {
        var id = get("deviceId", null);
        if (id == null) {
            id = Ids.newDeviceId();
            put("deviceId", id);
        }
        return id;
    }

    function clearAll() {
        _workout = null;
        _workoutLoaded = false;
        for (var i = 0; i < KEYS.size(); i++) {
            put(KEYS[i], null);
        }
    }
}
