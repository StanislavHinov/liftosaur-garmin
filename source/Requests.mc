import Toybox.Communications;
import Toybox.Lang;

(:background)
module Requests {
    function current() {
        return {"method" => :get, "path" => "/workout/current", "body" => null};
    }

    function next() {
        return {"method" => :get, "path" => "/workout/next", "body" => null};
    }

    function start(startTimeMs) {
        return {"method" => :post, "path" => "/workout/start", "body" => {"startTime" => startTimeMs}};
    }

    function nextDay(week, dayInWeek) {
        return {"method" => :get, "path" => "/workout/next?week=" + week.toNumber() + "&dayInWeek=" + dayInWeek.toNumber(), "body" => null};
    }

    function startDay(startTimeMs, week, dayInWeek) {
        var r = start(startTimeMs);
        r["body"]["week"] = week;
        r["body"]["dayInWeek"] = dayInWeek;
        return r;
    }

    // An append carries no completed key: null would mean "un-complete".
    function setBody(e) {
        if (e["append"] == true) {
            return {"entryId" => e["entryId"], "setId" => e["setId"], "append" => true};
        }
        return {"entryId" => e["entryId"], "setId" => e["setId"], "completed" => e["completed"]};
    }

    function forRun(run) {
        var head = run[0];
        if (head["t"].equals("discard")) {
            return {"method" => :delete, "path" => "/workout/current", "body" => {"startTime" => head["st"]}};
        }
        if (head["t"].equals("finish")) {
            var body = {"startTime" => head["st"], "endTime" => head["endTime"]};
            if (head.hasKey("intervals")) {
                body["intervals"] = head["intervals"];
            }
            return {"method" => :post, "path" => "/workout/finish", "body" => body};
        }
        if (run.size() == 1) {
            return {"method" => :post, "path" => "/workout/set", "body" => setBody(head)};
        }
        var sets = [];
        for (var i = 0; i < run.size(); i++) {
            sets.add(setBody(run[i]));
        }
        return {"method" => :post, "path" => "/workout/sets", "body" => {"sets" => sets}};
    }

    function headers(apiKey, deviceId, method) {
        var h = {"Authorization" => "Bearer " + apiKey};
        if (method != :get) {
            h["Content-Type"] = Communications.REQUEST_CONTENT_TYPE_JSON;
            h["X-Liftosaur-Device-Id"] = deviceId;
            h["X-Liftosaur-Client"] = Config.CLIENT;
        }
        return h;
    }
}
