import Toybox.Lang;

module SlimWorkout {
    const SET_KEYS = [
        "setId", "index", "isWarmup", "reps", "minReps", "isAmrap", "weight", "plates", "rpe",
        "logRpe", "askWeight", "isUnilateral", "timer", "setTimer", "completed"
    ];

    // The API's answer is not trusted: entries or sets of the wrong type are skipped.
    function slim(raw) {
        if (!(raw instanceof Dictionary) || !(raw["entries"] instanceof Array)) {
            return null;
        }
        var entries = [];
        var rawEntries = raw["entries"];
        for (var i = 0; i < rawEntries.size(); i++) {
            var e = rawEntries[i];
            if (!(e instanceof Dictionary)) {
                continue;
            }
            var sets = [];
            appendSets(sets, e["warmupSets"]);
            appendSets(sets, e["sets"]);
            entries.add({
                "entryId" => e["entryId"],
                "exerciseId" => e["exerciseId"],
                "name" => e["name"],
                "equipment" => e["equipment"],
                "hasUpdateScript" => e["hasUpdateScript"],
                "promptedVars" => e["promptedVars"],
                "sets" => sets
            });
        }
        return {
            "programName" => raw["programName"],
            "dayName" => raw["dayName"],
            "dayData" => raw["dayData"],
            "startTime" => raw["startTime"],
            "entries" => entries
        };
    }

    function appendSets(out, rawSets) {
        if (!(rawSets instanceof Array)) {
            return;
        }
        for (var j = 0; j < rawSets.size(); j++) {
            var s = rawSets[j];
            if (!(s instanceof Dictionary)) {
                continue;
            }
            var slimSet = {};
            for (var k = 0; k < SET_KEYS.size(); k++) {
                slimSet[SET_KEYS[k]] = s[SET_KEYS[k]];
            }
            out.add(slimSet);
        }
    }

    function cursor(w, skipped) {
        if (w == null) {
            return null;
        }
        var entries = w["entries"];
        for (var i = 0; i < entries.size(); i++) {
            var sets = entries[i]["sets"];
            for (var j = 0; j < sets.size(); j++) {
                if (sets[j]["completed"] == null && skipped.indexOf(sets[j]["setId"]) < 0) {
                    return [i, j];
                }
            }
        }
        return null;
    }

    // The next set of the exercise last logged (focus is its entryId), so exercises can be done in any order;
    // when that exercise has no open set left, the program order.
    function cursorAt(w, skipped, focus) {
        if (w != null && focus != null) {
            var entries = w["entries"];
            for (var i = 0; i < entries.size(); i++) {
                if (!focus.equals(entries[i]["entryId"])) {
                    continue;
                }
                var sets = entries[i]["sets"];
                for (var j = 0; j < sets.size(); j++) {
                    if (sets[j]["completed"] == null && skipped.indexOf(sets[j]["setId"]) < 0) {
                        return [i, j];
                    }
                }
            }
        }
        return cursor(w, skipped);
    }

    function findSet(w, setId) {
        var entries = w["entries"];
        for (var i = 0; i < entries.size(); i++) {
            var sets = entries[i]["sets"];
            for (var j = 0; j < sets.size(); j++) {
                if (setId.equals(sets[j]["setId"])) {
                    return sets[j];
                }
            }
        }
        return null;
    }

    // [entry, set] of the last set done in after but not in before: one logged elsewhere, such as the phone.
    function lastNewlyDone(before, after) {
        var found = null;
        var entries = after["entries"];
        for (var i = 0; i < entries.size(); i++) {
            var sets = entries[i]["sets"];
            for (var j = 0; j < sets.size(); j++) {
                if (sets[j]["completed"] == null) {
                    continue;
                }
                var old = findSet(before, sets[j]["setId"]);
                if (old == null || old["completed"] == null) {
                    found = [entries[i], sets[j]];
                }
            }
        }
        return found;
    }

    function markCompleted(w, setId, completed) {
        var s = findSet(w, setId);
        if (s == null) {
            return false;
        }
        s["completed"] = completed;
        return true;
    }

    function applyPending(w, queue) {
        for (var i = 0; i < queue.size(); i++) {
            var q = queue[i];
            if (!q["t"].equals("set") || q["st"] != w["startTime"]) {
                continue;
            }
            if (q["append"] == true) {
                // A set added on the watch that the server has not seen yet.
                var ei = entryIndex(w, q["entryId"]);
                if (ei >= 0 && findSet(w, q["setId"]) == null) {
                    addSet(w, ei, q["setId"]);
                }
            } else {
                markCompleted(w, q["setId"], q["completed"]);
            }
        }
    }

    function entryIndex(w, entryId) {
        var entries = w["entries"];
        for (var i = 0; i < entries.size(); i++) {
            if (entryId.equals(entries[i]["entryId"])) {
                return i;
            }
        }
        return -1;
    }

    // Appends a copy of the exercise's last set, not done, under a new id.
    function addSet(w, ei, setId) {
        var sets = w["entries"][ei]["sets"];
        if (sets.size() == 0) {
            return null;
        }
        var last = sets[sets.size() - 1];
        var copy = {};
        var keys = last.keys();
        for (var i = 0; i < keys.size(); i++) {
            copy[keys[i]] = last[keys[i]];
        }
        copy["setId"] = setId;
        copy["completed"] = null;
        copy["index"] = last["index"] == null ? sets.size() : last["index"] + 1;
        sets.add(copy);
        return copy;
    }

    function setCount(w) {
        var n = 0;
        var entries = w["entries"];
        for (var i = 0; i < entries.size(); i++) {
            n += entries[i]["sets"].size();
        }
        return n;
    }

    function counts(entry) {
        var sets = entry["sets"];
        var done = 0;
        for (var j = 0; j < sets.size(); j++) {
            if (sets[j]["completed"] != null) {
                done++;
            }
        }
        return [done, sets.size()];
    }

    // Garmin suggests at most 15 characters for an activity name, and some watches reject longer ones.
    // "Program Day" when it fits; otherwise the day alone (it says what was trained), cut at a word.
    function activityName(w) {
        var program = w["programName"];
        var day = w["dayName"];
        if (program != null && day != null && program.length() + 1 + day.length() <= 15) {
            return program + " " + day;
        }
        var name = day != null ? day : program;
        return name == null || name.length() == 0 ? "Lift Log" : fitWords(name, 15);
    }

    function fitWords(s, max) {
        if (s.length() <= max) {
            return s;
        }
        var cut = max;
        while (cut > 0 && !s.substring(cut, cut + 1).equals(" ")) {
            cut--;
        }
        return cut == 0 ? s.substring(0, max) : s.substring(0, cut);
    }

    function unit(w) {
        var entries = w["entries"];
        for (var i = 0; i < entries.size(); i++) {
            var sets = entries[i]["sets"];
            for (var j = 0; j < sets.size(); j++) {
                var p = Weight.parse(sets[j]["weight"]);
                if (p != null && !p[1].equals("%")) {
                    return p[1];
                }
            }
        }
        return "kg";
    }
}
