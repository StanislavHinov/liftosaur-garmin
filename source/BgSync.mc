import Toybox.Lang;

// Sends what the app queued after it was closed (phone out of reach, app left mid-sync). Runs in the
// background process, which has 64 KB, so it keeps to the happy path: anything but a success or a
// temporary failure is left in the queue for the app, which knows how to handle it.
(:background)
class BgSync {
    // Runs sent per wake-up; a background process may only run for about 30 seconds.
    const MAX_RUNS = 6;

    var _api;
    var _done;
    var _run = null;
    var _runs = 0;
    var _sets = 0;
    var _finished = false;

    // done is called once with (result, sets sent, whether a finish was sent); result is
    // "synced", "idle" (nothing to send), "offline" (try again later) or "needsApp".
    function initialize(api, done) {
        _api = api;
        _done = done;
    }

    // Worth waking up for: something queued, a key, and no stop the user has to look at.
    static function needed(key) {
        return key != null && Store.halt() == null && Store.queue().size() > 0;
    }

    // The question the watch asks when the user has to look at something; null to stay quiet.
    static function wakeMessage(result) {
        return result.equals("needsApp") ? "Sets not synced. Open Lift Log?" : null;
    }

    function start() {
        if (Store.halt() != null) {
            _done.invoke("needsApp", 0, false);
            return;
        }
        next();
    }

    function next() {
        var q = Store.queue();
        var n = Queue.headRunLength(q);
        if (n == 0 || _runs >= MAX_RUNS) {
            var sent = _sets > 0 || _finished || _runs > 0;
            _done.invoke(n == 0 ? (sent ? "synced" : "idle") : "offline", _sets, _finished);
            return;
        }
        _run = q.slice(0, n);
        _runs++;
        _api.request(Requests.forRun(_run), method(:onResponse));
    }

    function onResponse(status, data) {
        // The app's rules, cut down: success goes on, a temporary failure waits, the rest needs the app.
        // Writes are idempotent (a replayed set or finish changes nothing), and an error reply is small,
        // so a reply too big to read ("tooLarge") is the workout in a success.
        var action = ErrorPolicy.decide(status, data);
        if (action.equals("ok") || action.equals("tooLarge")) {
            for (var i = 0; i < _run.size(); i++) {
                var t = _run[i]["t"];
                if (t.equals("finish")) {
                    _finished = true;
                } else if (t.equals("set") && _run[i]["append"] != true) {
                    _sets++;
                }
            }
            Store.setQueue(Queue.dropSent(Store.queue(), _run));
            next();
        } else if (action.equals("retry")) {
            _done.invoke("offline", _sets, _finished);
        } else {
            _done.invoke("needsApp", _sets, _finished);
        }
    }
}
