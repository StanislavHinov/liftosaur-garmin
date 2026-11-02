import Toybox.Lang;

// The values a set asks for before it can be logged: left reps, an asked weight, RPE and prompted variables.
// A field is {"key", "label", "value", "step", "min", "max", "kind" (:reps, :weight, :number), "unit"}.
module Prompt {
    function fields(entry, set, unit) {
        var done = set["completed"];
        var out = [];
        if (set["isUnilateral"] == true && set["setTimer"] == null) {
            var left = done != null && done["repsLeft"] != null ? done["repsLeft"] : set["reps"];
            out.add(field("repsLeft", "Reps (left)", left == null ? 0 : left, 1, 0, null, :reps, null));
        }
        if (set["askWeight"] == true) {
            var p = Weight.parse(done != null && done["weight"] != null ? done["weight"] : set["weight"]);
            var u = p != null ? p[1] : unit;
            out.add(field("weight", "Weight (" + u + ")", p == null ? 0.0 : p[0], Weight.step(u), 0, null, :weight, u));
        }
        if (set["logRpe"] == true) {
            var rpe = done != null && done["rpe"] != null ? done["rpe"] : (set["rpe"] != null ? set["rpe"] : 8);
            out.add(field("rpe", "RPE", rpe.toFloat(), 0.5, 1, 10, :number, null));
        }
        var vars = entry["promptedVars"];
        if (vars != null) {
            for (var i = 0; i < vars.size(); i++) {
                out.add(varField(vars[i]["name"], vars[i]["value"]));
            }
        }
        return out;
    }

    // Weights and percents come as strings ("100kg", "80%"), numbers as numbers.
    function varField(name, value) {
        if (value instanceof String) {
            var p = Weight.parse(value);
            if (p != null) {
                var step = p[1].equals("%") ? 1.0 : Weight.step(p[1]);
                return field("var:" + name, name, p[0], step, 0, null, :weight, p[1]);
            }
            return field("var:" + name, name, 0, 1, null, null, :number, null);
        }
        if (value instanceof Float || value instanceof Double) {
            var whole = value == value.toNumber();
            return field("var:" + name, name, value, whole ? 1.0 : 0.5, null, null, :number, null);
        }
        return field("var:" + name, name, value, 1, null, null, :number, null);
    }

    function field(key, label, value, step, min, max, kind, unit) {
        return {"key" => key, "label" => label, "value" => value, "step" => step, "min" => min, "max" => max, "kind" => kind, "unit" => unit};
    }

    function adjust(f, dir) {
        var v = f["value"] + dir * f["step"];
        if (f["min"] != null && v < f["min"]) {
            v = f["min"];
        }
        if (f["max"] != null && v > f["max"]) {
            v = f["max"];
        }
        f["value"] = v;
    }

    function text(f) {
        var v = f["value"];
        if (f["kind"] == :reps || v instanceof Number) {
            return v.toString();
        }
        return Weight.formatNumber(v);
    }

    // base holds reps and the box weight; the fields add the rest.
    function completed(base, fields) {
        var c = {};
        var keys = base.keys();
        for (var i = 0; i < keys.size(); i++) {
            c[keys[i]] = base[keys[i]];
        }
        var userVars = {};
        for (var i = 0; i < fields.size(); i++) {
            var f = fields[i];
            var key = f["key"];
            var value = f["kind"] == :weight ? Weight.format(f["value"], f["unit"]) : f["value"];
            if (key.equals("repsLeft") || key.equals("weight") || key.equals("rpe")) {
                c[key] = value;
            } else {
                userVars[key.substring(4, key.length())] = value;
            }
        }
        if (userVars.size() > 0) {
            c["userVars"] = userVars;
        }
        return c;
    }
}
