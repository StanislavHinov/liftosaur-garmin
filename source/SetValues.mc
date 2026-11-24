import Toybox.Lang;

// Reconcile server values with the set card's unsaved edits, independently per field.
module SetValues {
    function editedValue(field, current, unit) {
        // Confirming an untouched editor must not undo a phone update received in the meantime.
        if (field.hasKey("initialValue") && field["value"] == field["initialValue"]) {
            return current;
        }
        return Weight.convert(field["value"], field["unit"], unit);
    }

    function fromSet(set) {
        var done = set["completed"];
        var reps = done != null && done["reps"] != null ? done["reps"] : set["reps"];
        var p = Weight.parse(done != null && done["weight"] != null ? done["weight"] : set["weight"]);
        return {"reps" => reps == null ? 0 : reps,
            "weight" => p == null ? null : p[0], "unit" => p == null ? "kg" : p[1]};
    }

    function merge(previous, incoming, reps, weight, unit) {
        var keepReps = previous != null && reps != previous["reps"] && reps != incoming["reps"];
        var reference = {"reps" => keepReps ? previous["reps"] : incoming["reps"],
            "weight" => incoming["weight"], "unit" => incoming["unit"]};
        var nextWeight = incoming["weight"];
        if (previous != null && weight != null && previous["weight"] != null && nextWeight != null
                && (weight != previous["weight"] || !unit.equals(previous["unit"]))) {
            // Convert the draft and its baseline together, so undo still works after kg/lb changes.
            if (unit.equals(incoming["unit"]) || !unit.equals("%") && !incoming["unit"].equals("%")) {
                nextWeight = Weight.convert(weight, unit, incoming["unit"]);
                if (nextWeight != incoming["weight"]) {
                    reference["weight"] = Weight.convert(previous["weight"], previous["unit"], incoming["unit"]);
                }
            }
        }
        return {"reps" => keepReps ? reps : incoming["reps"],
            "weight" => nextWeight, "unit" => incoming["unit"], "reference" => reference};
    }
}
