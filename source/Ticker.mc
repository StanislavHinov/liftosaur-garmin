import Toybox.Lang;
import Toybox.Timer;

// The one timer the screens share; a watch allows only a few timers at once.
// The shown screen gets tick() every 250 ms, and later() runs a callback on the next tick.
module Ticker {
    var _timer = null;
    var _screen = null;
    var _later = [];

    function watch(screen) {
        _screen = screen;
        run();
    }

    function unwatch(screen) {
        if (_screen == screen) {
            _screen = null;
        }
    }

    function later(callback) {
        _later.add(callback);
        run();
    }

    function run() {
        if (_timer == null) {
            _timer = new Timer.Timer();
            _timer.start(new Lang.Method(Ticker, :tick), 250, true);
        }
    }

    function tick() {
        var due = _later;
        _later = [];
        for (var i = 0; i < due.size(); i++) {
            due[i].invoke();
        }
        if (_screen != null) {
            _screen.tick();
        } else if (_later.size() == 0 && _timer != null) {
            _timer.stop();
            _timer = null;
        }
    }
}
