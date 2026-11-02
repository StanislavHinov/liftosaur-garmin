import Toybox.Lang;

// Display decisions that the views draw; kept apart so unit tests can check them.
module Look {
    function restText(rest, nowSec) {
        if (rest == null) {
            return null;
        }
        var total = " / " + Rest.clock(rest["dur"]);
        var left = Rest.remaining(rest, nowSec);
        if (left > 0) {
            return Rest.clock(left) + total;
        }
        return "+" + Rest.clock(Rest.overtime(rest, nowSec)) + total;
    }

    function restFraction(rest, nowSec) {
        if (rest == null || rest["dur"] <= 0) {
            return 0.0;
        }
        return Rest.remaining(rest, nowSec).toFloat() / rest["dur"];
    }

    function restOver(rest, nowSec) {
        return rest != null && Rest.remaining(rest, nowSec) == 0;
    }

    // Lengthens or shortens a rest; a rest that would end in the past ends now.
    function adjustRest(rest, delta, nowSec) {
        if (rest == null) {
            return null;
        }
        var dur = rest["dur"] + delta;
        var minDur = nowSec - rest["at"];
        if (dur < minDur) {
            dur = minDur;
        }
        return {"at" => rest["at"], "dur" => dur, "setId" => rest["setId"]};
    }

    function heartRate(bpm) {
        return bpm == null || bpm <= 0 ? "--" : bpm.toString();
    }

    function showPlates(entry, set) {
        return "barbell".equals(entry["equipment"]) && Weight.platesText(set["plates"]).length() > 0;
    }

    // [grey part, white part]: "Warmup · AMRAP · RPE 8 · Plates: " and the plates.
    function infoLine(entry, set) {
        var grey = "";
        if (set["isWarmup"] == true) {
            grey = "Warmup";
        }
        if (set["isAmrap"] == true) {
            grey = grey.length() > 0 ? grey + " · AMRAP" : "AMRAP";
        }
        var done = set["completed"];
        var rpe = done != null && done["rpe"] != null ? done["rpe"] : set["rpe"];
        if (rpe != null) {
            var r = "RPE " + Weight.formatNumber(rpe.toFloat());
            grey = grey.length() > 0 ? grey + " · " + r : r;
        }
        if (set["setTimer"] != null) {
            var hold = "Hold " + Rest.clock(set["setTimer"]);
            grey = grey.length() > 0 ? grey + " · " + hold : hold;
        }
        if (!showPlates(entry, set)) {
            return [grey, ""];
        }
        grey = grey.length() > 0 ? grey + " · Plates: " : "Plates: ";
        return [grey, Weight.platesText(set["plates"])];
    }

    // Sets logged and their volume, counted in the workout's unit even when a set is in the other one.
    function summary(w, nowMs) {
        var sets = 0;
        var volume = 0.0;
        var unit = SlimWorkout.unit(w);
        var entries = w["entries"];
        for (var i = 0; i < entries.size(); i++) {
            var list = entries[i]["sets"];
            for (var j = 0; j < list.size(); j++) {
                var done = list[j]["completed"];
                if (done == null) {
                    continue;
                }
                sets++;
                var p = Weight.parse(done["weight"]);
                if (p != null && !p[1].equals("%") && done["reps"] != null) {
                    volume += done["reps"] * Weight.convert(p[0], p[1], unit);
                }
            }
        }
        var secs = ((nowMs - w["startTime"]) / 1000l).toNumber();
        if (secs < 0) {
            secs = 0;
        }
        return {
            "sets" => sets,
            "volume" => Weight.formatNumber(volume) + " " + unit,
            "volumeNum" => volume,
            "time" => (secs / 3600).toString() + ":" + ((secs % 3600) / 60).format("%02d") + ":" + (secs % 60).format("%02d")
        };
    }

    // The workout overview's line under an exercise: "Now · 1/3 · 5×100kg", or "Done · 3/3".
    function overviewLine(entry, isCurrent) {
        var counts = SlimWorkout.counts(entry);
        var progress = counts[0] + "/" + counts[1];
        if (counts[0] == counts[1]) {
            return "Done · " + progress;
        }
        var next = null;
        var sets = entry["sets"];
        for (var j = 0; j < sets.size() && next == null; j++) {
            if (sets[j]["completed"] == null) {
                next = sets[j];
            }
        }
        var reps = next["reps"] == null ? "" : next["reps"].toString();
        var p = Weight.parse(next["weight"]);
        var target = p == null ? (reps.length() > 0 ? reps + " reps" : "") : reps + "×" + Weight.format(p[0], p[1]);
        if (next["setTimer"] != null) {
            target = p == null ? Rest.clock(next["setTimer"]) : Rest.clock(next["setTimer"]) + " · " + Weight.format(p[0], p[1]);
        }
        var line = target.length() > 0 ? progress + " · " + target : progress;
        return isCurrent ? "Now · " + line : line;
    }

    // What Garmin Connect shows in the activity's Laps table.
    function lapLabel(name, isWarmup) {
        return isWarmup ? name + " (warm-up)" : name;
    }

    function weightText(weight, unit) {
        return weight == null || unit == null ? "Bodyweight" : Weight.formatNumber(weight) + " " + unit;
    }
}
