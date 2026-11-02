import Toybox.Lang;
import Toybox.Math;

module Weight {
    const UNITS = ["kg", "lb", "%"];

    function parse(s) {
        if (s == null) {
            return null;
        }
        var str = s.toString();
        for (var i = 0; i < UNITS.size(); i++) {
            var idx = str.find(UNITS[i]);
            if (idx != null && idx > 0) {
                var value = str.substring(0, idx).toFloat();
                if (value == null) {
                    return null;
                }
                return [value, UNITS[i]];
            }
        }
        return null;
    }

    function formatNumber(value) {
        var rounded = Math.round(value * 100.0) / 100.0;
        if (rounded == rounded.toNumber()) {
            return rounded.toNumber().toString();
        }
        var s = rounded.format("%.2f");
        if (s.substring(s.length() - 1, s.length()).equals("0")) {
            s = s.substring(0, s.length() - 1);
        }
        return s;
    }

    function convert(value, from, to) {
        if (from == null || to == null || from.equals(to)) {
            return value;
        }
        if (from.equals("lb") && to.equals("kg")) {
            return value * 0.45359237;
        }
        if (from.equals("kg") && to.equals("lb")) {
            return value / 0.45359237;
        }
        return value;
    }

    function format(value, unit) {
        return formatNumber(value) + unit;
    }

    // The API's plates are what to load for one set, not the plates the gym has, so the step is fixed.
    function step(unit) {
        return unit.equals("lb") ? 5.0 : 2.5;
    }

    function platesText(plates) {
        if (plates == null) {
            return "";
        }
        var out = "";
        for (var i = 0; i < plates.size(); i++) {
            var p = parse(plates[i]["weight"]);
            if (p == null) {
                continue;
            }
            if (out.length() > 0) {
                out += " ";
            }
            out += plates[i]["num"].toString() + "x" + formatNumber(p[0]);
        }
        return out;
    }
}
