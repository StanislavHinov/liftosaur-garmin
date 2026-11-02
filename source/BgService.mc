import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// While the app is closed: one wake-up 5 minutes on, and again every 5 minutes while offline.
// One-shot events at a set time, because a repeating one can't be registered within 5 minutes of
// the last wake-up (the call throws), while for a set time that limit is lifted when the app starts.
(:background)
module BgSchedule {
    // A little over the 5-minute minimum between background wake-ups.
    const INTERVAL_SEC = 305;

    // On closing the app.
    function onAppClosed() {
        if (BgSync.needed(ApiKey.current())) {
            later();
        } else {
            cancel();
        }
    }

    // On opening it: the app sends its own queue, and two senders at once could step on each other.
    function onAppOpened() {
        cancel();
    }

    function later() {
        try {
            Background.registerForTemporalEvent(Time.now().add(new Time.Duration(INTERVAL_SEC)));
        } catch (e) {
            System.println("background schedule: " + e.getErrorMessage());
        }
    }

    function cancel() {
        try {
            Background.deleteTemporalEvent();
        } catch (e) {
            System.println("background schedule: " + e.getErrorMessage());
        }
    }
}

(:background)
class BgService extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        var key = ApiKey.current();
        if (!BgSync.needed(key)) {
            Background.exit(null);
            return;
        }
        if (!System.getDeviceSettings().phoneConnected) {
            BgSchedule.later();
            Background.exit(null);
            return;
        }
        new BgSync(new Api(key, Store.deviceId()), method(:onDone)).start();
    }

    function onDone(result, sets, finished) {
        // Offline: try again later. Otherwise the queue is empty or needs the app.
        if (result.equals("offline")) {
            BgSchedule.later();
        }
        var ask = BgSync.wakeMessage(result);
        if (ask != null) {
            // Shown once the background process exits; Yes opens the app on the screen that explains.
            Background.requestApplicationWake(ask);
        }
        Background.exit(null);
    }
}
