import Toybox.Communications;
import Toybox.Lang;
import Toybox.Test;

(:test)
module ErrUtil {
    function err(code) {
        return {"error" => {"code" => code, "message" => "m " + code}};
    }
}

(:test)
function errorPolicyMapsStatuses(logger as Test.Logger) as Boolean {
    Test.assertEqual(ErrorPolicy.decide(200, {}), "ok");
    Test.assertEqual(ErrorPolicy.decide(-104, null), "retry");
    Test.assertEqual(ErrorPolicy.decide(Communications.NETWORK_RESPONSE_TOO_LARGE, null), "tooLarge");
    Test.assertEqual(ErrorPolicy.decide(Communications.NETWORK_RESPONSE_OUT_OF_MEMORY, null), "tooLarge");
    Test.assertEqual(ErrorPolicy.decide(401, ErrUtil.err("unauthorized")), "badKey");
    Test.assertEqual(ErrorPolicy.decide(403, null), "premium");
    Test.assertEqual(ErrorPolicy.decide(404, ErrUtil.err("no_active_workout")), "noWorkout");
    Test.assertEqual(ErrorPolicy.decide(404, ErrUtil.err("set_not_found")), "refetch");
    Test.assertEqual(ErrorPolicy.decide(404, null), "retry");
    Test.assertEqual(ErrorPolicy.decide(404, "Not Found"), "retry");
    Test.assertEqual(ErrorPolicy.decide(409, ErrUtil.err("workout_already_active")), "adoptCurrent");
    Test.assertEqual(ErrorPolicy.decide(409, ErrUtil.err("workout_start_time_taken")), "refetch");
    Test.assertEqual(ErrorPolicy.decide(400, ErrUtil.err("missing_set_input")), "haltBug");
    Test.assertEqual(ErrorPolicy.decide(422, ErrUtil.err("program_error")), "haltProgram");
    Test.assertEqual(ErrorPolicy.decide(503, null), "retry");
    Test.assertEqual(ErrorPolicy.message(ErrUtil.err("program_error")), "m program_error");
    Test.assert(ErrorPolicy.message("not json") == null);
    return true;
}

(:test)
function restRemaining(logger as Test.Logger) as Boolean {
    Test.assertEqual(Rest.remaining(null, 100), 0);
    Test.assertEqual(Rest.remaining({"at" => 100, "dur" => 180}, 130), 150);
    Test.assertEqual(Rest.remaining({"at" => 100, "dur" => 180}, 400), 0);
    return true;
}

(:test)
function restOvertimeCountsUpAfterZero(logger as Test.Logger) as Boolean {
    Test.assertEqual(Rest.overtime(null, 100), 0);
    Test.assertEqual(Rest.overtime({"at" => 100, "dur" => 180}, 130), 0);
    Test.assertEqual(Rest.overtime({"at" => 100, "dur" => 180}, 280), 0);
    Test.assertEqual(Rest.overtime({"at" => 100, "dur" => 180}, 345), 65);
    Test.assertEqual(Rest.clock(65), "1:05");
    Test.assertEqual(Rest.clock(9), "0:09");
    return true;
}

(:test)
function errorPolicyWorkoutChecksTheBodyShape(logger as Test.Logger) as Boolean {
    var raw = Fixtures.workoutRaw([]);
    Test.assert(ErrorPolicy.workout(Fixtures.response(raw)) == raw);
    Test.assert(ErrorPolicy.workout({"data" => {"workout" => null}}) == null);
    // A proxy or captive-portal page answering 200 is not the API.
    Test.assert(ErrorPolicy.workout("<html>") == :bad);
    Test.assert(ErrorPolicy.workout(null) == :bad);
    Test.assert(ErrorPolicy.workout({"data" => "x"}) == :bad);
    Test.assert(ErrorPolicy.workout({"data" => {"workout" => {"entries" => "x"}}}) == :bad);
    return true;
}
