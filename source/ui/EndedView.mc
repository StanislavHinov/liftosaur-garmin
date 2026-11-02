import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The workout was finished, discarded or replaced on the phone; a Garmin activity is already saved.
class EndedView extends WatchUi.View {
    var _saved;

    function initialize(saved) {
        View.initialize();
        _saved = saved;
    }

    function onUpdate(dc) {
        Theme.clear(dc);
        Theme.drawRows(dc, [
            [:icon],
            [:big, "Workout ended", Theme.GREEN],
            [:small, "Ended on your phone", Theme.GREY],
            [:small, _saved ? "Garmin activity saved" : "Nothing recorded", Theme.TEXT],
            [:pill, "EXIT", Theme.PURPLE]
        ]);
    }
}

class EndedDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        System.exit();
    }

    function onBack() {
        System.exit();
    }

    // Menu: stay in the app and see what is next.
    function onMenu() {
        getController().boot();
        return true;
    }
}
