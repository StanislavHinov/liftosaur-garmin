import Toybox.Lang;
import Toybox.Test;

(:test)
module SetValuesUtil {
    function values(reps, weight, unit) {
        return {"reps" => reps, "weight" => weight, "unit" => unit};
    }
}

(:test)
function setValuesKeepsEachEditBaselineAcrossUpdates(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var original = SetValuesUtil.values(8, 60.0, "kg");
    var incoming = SetValuesUtil.values(10, 65.0, "kg");
    var merged = SetValues.merge(original, incoming, 9, 62.5, "kg");
    Test.assertEqual(merged["reps"], 9);
    Test.assertEqual(merged["weight"], 62.5);
    incoming = SetValuesUtil.values(12, 70.0, "kg");
    merged = SetValues.merge(merged["reference"], incoming, 8, 62.5, "kg");
    Test.assertEqual(merged["reps"], 12);
    Test.assertEqual(merged["weight"], 62.5);
    merged = SetValues.merge(merged["reference"], incoming, 12, 60.0, "kg");
    Test.assertEqual(merged["weight"], 70.0);
    // Reconciliation must not mutate either caller-owned snapshot.
    Test.assertEqual(original["reps"], 8);
    Test.assertEqual(original["weight"], 60.0);
    Test.assertEqual(incoming["reps"], 12);
    return true;
}

(:test)
function setValuesUsesLoggedValuesWithTargetFallbacks(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var set = Fixtures.set("aaaaaa", 0, false, 8, "60kg", 90, []);
    set["completed"] = {"reps" => 0, "weight" => null};
    var values = SetValues.fromSet(set);
    Test.assertEqual(values["reps"], 0);
    Test.assertEqual(values["weight"], 60.0);
    set["completed"] = null;
    set["reps"] = null;
    set["weight"] = null;
    values = SetValues.fromSet(set);
    Test.assertEqual(values["reps"], 0);
    Test.assert(values["weight"] == null);
    Test.assertEqual(values["unit"], "kg");
    return true;
}

(:test)
function setValuesConvertsDraftAndBaselineTogether(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var original = SetValuesUtil.values(8, 60.0, "kg");
    var incoming = SetValuesUtil.values(10, 150.0, "lb");
    var merged = SetValues.merge(original, incoming, 9, 62.5, "kg");
    Test.assert(TestUtil.near(merged["weight"], Weight.convert(62.5, "kg", "lb")));
    var reference = merged["reference"];
    Test.assert(reference != null);
    Test.assert(TestUtil.near(reference["weight"], Weight.convert(60.0, "kg", "lb")));
    merged = SetValues.merge(reference, incoming, 9, reference["weight"], "lb");
    Test.assertEqual(merged["weight"], 150.0);
    Test.assertEqual(merged["reps"], 9);
    return true;
}

(:test)
function setValuesResetsIncompatibleWeightButKeepsRepsDraft(logger as Test.Logger) as Boolean {
    Store.clearAll();
    var original = SetValuesUtil.values(8, 60.0, "kg");
    var merged = SetValues.merge(original, SetValuesUtil.values(10, 80.0, "%"), 9, 62.5, "kg");
    Test.assertEqual(merged["weight"], 80.0);
    Test.assertEqual(merged["unit"], "%");
    Test.assertEqual(merged["reps"], 9);
    merged = SetValues.merge(original, SetValuesUtil.values(10, null, "kg"), 9, 62.5, "kg");
    Test.assert(merged["weight"] == null);
    Test.assertEqual(merged["reps"], 9);
    return true;
}
