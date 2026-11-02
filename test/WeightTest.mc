import Toybox.Lang;
import Toybox.Test;

// Helpers live in a module: the runner treats every global (:test) function as a test.
(:test)
module TestUtil {
    function near(a, b) {
        var d = a - b;
        return d < 0.001 && d > -0.001;
    }
}

(:test)
function weightParsesKgAndLb(logger as Test.Logger) as Boolean {
    var kg = Weight.parse("100kg");
    Test.assert(TestUtil.near(kg[0], 100.0));
    Test.assertEqual(kg[1], "kg");
    var lb = Weight.parse("137.5lb");
    Test.assert(TestUtil.near(lb[0], 137.5));
    Test.assertEqual(lb[1], "lb");
    Test.assert(Weight.parse(null) == null);
    Test.assert(Weight.parse("abc") == null);
    return true;
}

(:test)
function weightFormatsWithoutTrailingZeros(logger as Test.Logger) as Boolean {
    Test.assertEqual(Weight.format(100.0, "kg"), "100kg");
    Test.assertEqual(Weight.format(62.5, "kg"), "62.5kg");
    Test.assertEqual(Weight.format(61.25, "lb"), "61.25lb");
    return true;
}

(:test)
function weightStepIsSmallestIncrement(logger as Test.Logger) as Boolean {
    // A set's plates are what to load, not the plates the gym has; a 20 kg-only set still steps by 2.5 kg.
    Test.assert(TestUtil.near(Weight.step("kg"), 2.5));
    Test.assert(TestUtil.near(Weight.step("lb"), 5.0));
    return true;
}

(:test)
function weightPlatesText(logger as Test.Logger) as Boolean {
    var plates = [{"weight" => "20kg", "num" => 2}, {"weight" => "5kg", "num" => 1}];
    Test.assertEqual(Weight.platesText(plates), "2x20 1x5");
    Test.assertEqual(Weight.platesText(null), "");
    return true;
}

(:test)
function weightConvertsBetweenUnits(logger as Test.Logger) as Boolean {
    Test.assert(TestUtil.near(Weight.convert(100.0, "lb", "kg"), 45.359237));
    Test.assert(TestUtil.near(Weight.convert(45.359237, "kg", "lb"), 100.0));
    Test.assert(TestUtil.near(Weight.convert(60.0, "kg", "kg"), 60.0));
    return true;
}
