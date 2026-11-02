import Toybox.Communications;
import Toybox.Lang;

(:background)
module ErrorPolicy {
    function errorField(data, key) {
        if (data instanceof Dictionary && data["error"] instanceof Dictionary) {
            return data["error"][key];
        }
        return null;
    }

    function message(data) {
        return errorField(data, "message");
    }

    // The workout in a 200 body, null when there is none, or :bad when the body is not the API's
    // (a proxy or captive-portal page can answer 200).
    function workout(data) {
        if (!(data instanceof Dictionary) || !(data["data"] instanceof Dictionary)) {
            return :bad;
        }
        var w = data["data"]["workout"];
        if (w == null) {
            return null;
        }
        return w instanceof Dictionary && w["entries"] instanceof Array ? w : :bad;
    }

    function decide(status, data) {
        if (status == 200) {
            return "ok";
        }
        if (status == Communications.NETWORK_RESPONSE_TOO_LARGE || status == Communications.NETWORK_RESPONSE_OUT_OF_MEMORY) {
            return "tooLarge";
        }
        if (status < 0) {
            return "retry";
        }
        if (status == 401) {
            return "badKey";
        }
        if (status == 403) {
            return "premium";
        }
        var code = errorField(data, "code");
        if (status == 404) {
            if (code == null) {
                // A 404 without a Liftosaur error body comes from a proxy or a bad address, not the API.
                return "retry";
            }
            return "no_active_workout".equals(code) ? "noWorkout" : "refetch";
        }
        if (status == 409) {
            return "workout_already_active".equals(code) ? "adoptCurrent" : "refetch";
        }
        if (status == 422) {
            return "haltProgram";
        }
        if (status >= 500) {
            return "retry";
        }
        return "haltBug";
    }
}
