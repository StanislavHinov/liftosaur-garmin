import Toybox.Lang;
import Toybox.Test;

(:test)
function layoutStackCentersRows(logger as Test.Logger) as Boolean {
    Test.assertEqual(Layout.total([40, 30, 70], 6), 152);
    var ys = Layout.stack([40, 30, 70], 6, 20, 372);
    Test.assertEqual(ys[0], 120);
    Test.assertEqual(ys[1], 166);
    Test.assertEqual(ys[2], 202);
    Test.assertEqual(Layout.total([], 6), 0);
    return true;
}

(:test)
function layoutChordOfCircle(logger as Test.Logger) as Boolean {
    Test.assertEqual(Layout.chord(195, 195, 195), 390);
    Test.assertEqual(Layout.chord(195, 195, 78), 312);
    Test.assertEqual(Layout.chord(195, 195, 0), 0);
    Test.assertEqual(Layout.chord(195, 195, -10), 0);
    return true;
}
