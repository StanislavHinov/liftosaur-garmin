import Toybox.Lang;

(:background)
module Queue {
    function set(st, entryId, setId, completed) {
        return {"t" => "set", "st" => st, "entryId" => entryId, "setId" => setId, "completed" => completed};
    }

    function append(st, entryId, setId) {
        return {"t" => "set", "st" => st, "entryId" => entryId, "setId" => setId, "append" => true};
    }

    function discard(st) {
        return {"t" => "discard", "st" => st};
    }

    function finish(st, endTime, intervals) {
        var e = {"t" => "finish", "st" => st, "endTime" => endTime};
        if (intervals != null) {
            e["intervals"] = intervals;
        }
        return e;
    }

    function isFull(q) {
        return q.size() >= Config.QUEUE_CAP;
    }

    function headRunLength(q) {
        if (q.size() == 0) {
            return 0;
        }
        if (!q[0]["t"].equals("set")) {
            return 1;
        }
        var n = 1;
        while (n < q.size() && q[n]["t"].equals("set") && q[n]["st"] == q[0]["st"]) {
            n++;
        }
        return n;
    }

    function dropFirst(q, n) {
        return q.slice(n, null);
    }

    // Drops run from the head of q only if it is still there: the app may have changed the queue
    // while the background process waited for the reply.
    function dropSent(q, run) {
        if (q.size() < run.size()) {
            return q;
        }
        for (var i = 0; i < run.size(); i++) {
            var a = q[i];
            var b = run[i];
            if (!a["t"].equals(b["t"]) || a["st"] != b["st"] || !same(a["setId"], b["setId"])) {
                return q;
            }
        }
        return q.slice(run.size(), null);
    }

    function same(a, b) {
        return a == null ? b == null : b != null && a.equals(b);
    }
}
