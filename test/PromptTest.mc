import Toybox.Lang;
import Toybox.Test;

(:test)
module PromptUtil {
    function set(extra) {
        var s = {"reps" => 5, "weight" => "60kg", "rpe" => null, "logRpe" => false, "askWeight" => false,
            "isUnilateral" => false, "setTimer" => null, "plates" => null, "completed" => null};
        var keys = extra.keys();
        for (var i = 0; i < keys.size(); i++) {
            s[keys[i]] = extra[keys[i]];
        }
        return s;
    }

    function keys(fields) {
        var out = [];
        for (var i = 0; i < fields.size(); i++) {
            out.add(fields[i]["key"]);
        }
        return out;
    }
}

(:test)
function promptListsFieldsInOrder(logger as Test.Logger) as Boolean {
    var entry = {"promptedVars" => [{"name" => "tm", "value" => "100kg"}, {"name" => "count", "value" => 3}]};
    var set = PromptUtil.set({"isUnilateral" => true, "askWeight" => true, "logRpe" => true});
    var f = Prompt.fields(entry, set, "kg");
    var k = PromptUtil.keys(f);
    Test.assertEqual(k.size(), 5);
    Test.assertEqual(k[0], "repsLeft");
    Test.assertEqual(k[1], "weight");
    Test.assertEqual(k[2], "rpe");
    Test.assertEqual(k[3], "var:tm");
    Test.assertEqual(k[4], "var:count");
    Test.assertEqual(Prompt.fields({"promptedVars" => []}, PromptUtil.set({}), "kg").size(), 0);
    // A timed unilateral set runs per side on the timer instead.
    Test.assertEqual(Prompt.fields({"promptedVars" => []}, PromptUtil.set({"isUnilateral" => true, "setTimer" => 60}), "kg").size(), 0);
    return true;
}

(:test)
function promptStartValuesAndSteps(logger as Test.Logger) as Boolean {
    var entry = {"promptedVars" => [{"name" => "tm", "value" => "100kg"}, {"name" => "pct", "value" => "80%"}, {"name" => "x", "value" => 2.5}]};
    var set = PromptUtil.set({"isUnilateral" => true, "askWeight" => true, "logRpe" => true, "rpe" => 7.5});
    var f = Prompt.fields(entry, set, "kg");
    Test.assertEqual(f[0]["value"], 5);
    Test.assert(TestUtil.near(f[1]["value"], 60.0));
    Test.assert(TestUtil.near(f[2]["value"], 7.5));
    Test.assert(TestUtil.near(f[2]["step"], 0.5));
    Test.assert(TestUtil.near(f[3]["value"], 100.0));
    Test.assert(TestUtil.near(f[3]["step"], 2.5));
    Test.assert(TestUtil.near(f[4]["step"], 1.0));
    Test.assert(TestUtil.near(f[5]["step"], 0.5));
    var noTarget = Prompt.fields({"promptedVars" => []}, PromptUtil.set({"logRpe" => true, "askWeight" => true, "weight" => null}), "lb");
    Test.assert(TestUtil.near(noTarget[0]["value"], 0.0));
    Test.assert(TestUtil.near(noTarget[0]["step"], 5.0));
    Test.assert(TestUtil.near(noTarget[1]["value"], 8.0));
    return true;
}

(:test)
function promptClampsRpe(logger as Test.Logger) as Boolean {
    var f = Prompt.fields({"promptedVars" => []}, PromptUtil.set({"logRpe" => true, "rpe" => 10}), "kg")[0];
    Prompt.adjust(f, 1);
    Test.assert(TestUtil.near(f["value"], 10.0));
    f["value"] = 1.0;
    Prompt.adjust(f, -1);
    Test.assert(TestUtil.near(f["value"], 1.0));
    Prompt.adjust(f, 1);
    Test.assert(TestUtil.near(f["value"], 1.5));
    return true;
}

(:test)
function promptBuildsCompletedBody(logger as Test.Logger) as Boolean {
    var entry = {"promptedVars" => [{"name" => "tm", "value" => "100kg"}, {"name" => "pct", "value" => "80%"}, {"name" => "n", "value" => 3}]};
    var set = PromptUtil.set({"isUnilateral" => true, "askWeight" => true, "logRpe" => true});
    var f = Prompt.fields(entry, set, "kg");
    f[0]["value"] = 4;
    f[1]["value"] = 62.5;
    f[2]["value"] = 8.5;
    var c = Prompt.completed({"reps" => 5}, f);
    Test.assertEqual(c["reps"], 5);
    Test.assertEqual(c["repsLeft"], 4);
    Test.assertEqual(c["weight"], "62.5kg");
    Test.assert(TestUtil.near(c["rpe"], 8.5));
    Test.assertEqual(c["userVars"]["tm"], "100kg");
    Test.assertEqual(c["userVars"]["pct"], "80%");
    Test.assertEqual(c["userVars"]["n"], 3);
    return true;
}

(:test)
function promptPrefillsFromLoggedValues(logger as Test.Logger) as Boolean {
    var set = PromptUtil.set({"logRpe" => true, "isUnilateral" => true,
        "completed" => {"reps" => 5, "repsLeft" => 3, "rpe" => 9}});
    var f = Prompt.fields({"promptedVars" => []}, set, "kg");
    Test.assertEqual(f[0]["value"], 3);
    Test.assert(TestUtil.near(f[1]["value"], 9.0));
    return true;
}
