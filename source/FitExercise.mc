import Toybox.Lang;
import Toybox.WatchUi;

// Maps Liftosaur exercises to the FIT exercise category and name that Garmin Connect uses for its
// exercise list and muscle map. A code is category * 65536 + name; the table is in resources/jsonData.
module FitExercise {
    // FIT's exercise_category "unknown".
    const UNKNOWN = 65534;

    // About 6 KB: load it only to resolve a workout's exercises, then let it go.
    function load() {
        return WatchUi.loadResource(Rez.JsonData.FitExercises);
    }

    // Liftosaur ids are "<exercise>_<equipment>". A variant Garmin has its own name for is in the table;
    // otherwise the exercise's mapping applies. Custom exercises (random ids) have none.
    function lookup(table, exerciseId) {
        if (exerciseId == null) {
            return null;
        }
        var code = table[exerciseId];
        if (code != null) {
            return code;
        }
        var cut = exerciseId.find("_");
        return cut == null ? null : table[exerciseId.substring(0, cut)];
    }

    // [category, name]; an exercise with no match is FIT's unknown category.
    function split(code) {
        return code == null ? [UNKNOWN, 0] : [code / 65536, code % 65536];
    }

    // Just this workout's exercises, so the table need not stay in memory.
    function codesFor(table, w) {
        var codes = {};
        var entries = w["entries"];
        for (var i = 0; i < entries.size(); i++) {
            var id = entries[i]["exerciseId"];
            if (id != null) {
                codes[id] = lookup(table, id);
            }
        }
        return codes;
    }
}
