import Toybox.Lang;
import Toybox.Test;

(:test)
function timedSetPhasesAndClock(logger as Test.Logger) as Boolean {
    var run = TimedSet.begin(100, 60);
    Test.assertEqual(TimedSet.phase(run, 102), :ready);
    Test.assertEqual(TimedSet.readyLeft(run, 102), 3);
    Test.assertEqual(TimedSet.text(run, 102), "3");
    Test.assertEqual(TimedSet.phase(run, 105), :work);
    Test.assertEqual(TimedSet.elapsed(run, 105), 0);
    Test.assertEqual(TimedSet.elapsed(run, 135), 30);
    Test.assert(TestUtil.near(TimedSet.fraction(run, 135), 0.5));
    Test.assertEqual(TimedSet.text(run, 117), "0:12");
    Test.assertEqual(TimedSet.isDone(run, 164), false);
    Test.assertEqual(TimedSet.isDone(run, 165), true);
    Test.assert(TestUtil.near(TimedSet.fraction(run, 200), 1.0));
    return true;
}

(:test)
function timedSetSkipsGetReady(logger as Test.Logger) as Boolean {
    var run = TimedSet.begin(100, 60);
    run = TimedSet.skipReady(run, 102);
    Test.assertEqual(TimedSet.phase(run, 102), :work);
    Test.assertEqual(TimedSet.elapsed(run, 112), 10);
    return true;
}

(:test)
function timedSetCompletedBody(logger as Test.Logger) as Boolean {
    var one = TimedSet.completed({"reps" => 1}, [55]);
    Test.assertEqual(one["setTimer"], 55);
    Test.assertEqual(one["reps"], 1);
    Test.assert(!one.hasKey("setTimerLeft"));
    var two = TimedSet.completed({"reps" => 1, "weight" => "10kg"}, [40, 60]);
    Test.assertEqual(two["setTimerLeft"], 40);
    Test.assertEqual(two["setTimer"], 60);
    Test.assertEqual(two["weight"], "10kg");
    return true;
}
