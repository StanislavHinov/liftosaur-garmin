import Toybox.Lang;

// Moving the viewed set; a position is [entry index, set index], and null means past an end.
module Nav {
    function step(w, pos, dir) {
        var entries = w["entries"];
        var ei = pos[0];
        var si = pos[1] + dir;
        while (ei >= 0 && ei < entries.size()) {
            if (si >= 0 && si < entries[ei]["sets"].size()) {
                return [ei, si];
            }
            ei += dir;
            if (ei < 0 || ei >= entries.size()) {
                return null;
            }
            si = dir > 0 ? 0 : entries[ei]["sets"].size() - 1;
        }
        return null;
    }

    // The neighbouring exercise's first set that is not done, or its last set when all are done.
    function jumpEntry(w, pos, dir) {
        var entries = w["entries"];
        var ei = pos[0] + dir;
        while (ei >= 0 && ei < entries.size()) {
            var p = firstOpen(w, ei);
            if (p != null) {
                return p;
            }
            ei += dir;
        }
        return null;
    }

    // The next exercise, wrapping to the first after the last; from "All sets done" (null), the first.
    function cycleEntry(w, pos) {
        var entries = w["entries"];
        var start = pos == null ? -1 : pos[0];
        for (var k = 1; k <= entries.size(); k++) {
            var p = firstOpen(w, (start + k) % entries.size());
            if (p != null) {
                return p;
            }
        }
        return null;
    }

    // -1, 0 or 1 as a comes before, at or after b; null ("All sets done") comes after every set.
    function compare(a, b) {
        if (a == null || b == null) {
            return a == null && b == null ? 0 : (a == null ? 1 : -1);
        }
        if (a[0] != b[0]) {
            return a[0] < b[0] ? -1 : 1;
        }
        return a[1] == b[1] ? 0 : (a[1] < b[1] ? -1 : 1);
    }

    function firstOpen(w, ei) {
        var sets = w["entries"][ei]["sets"];
        if (sets.size() == 0) {
            return null;
        }
        for (var j = 0; j < sets.size(); j++) {
            if (sets[j]["completed"] == null) {
                return [ei, j];
            }
        }
        return [ei, sets.size() - 1];
    }
}
