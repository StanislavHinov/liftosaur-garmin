import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BlockedView extends WatchUi.View {
    var _reason;
    var _message;

    function initialize(reason, message) {
        View.initialize();
        _reason = reason;
        _message = message;
    }

    function title() {
        if (_reason.equals("noKey")) { return "Add your API key"; }
        if (_reason.equals("badKey")) { return "API key invalid"; }
        if (_reason.equals("premium")) { return "Liftosaur Premium required"; }
        if (_reason.equals("tooLarge")) { return "Workout too large for watch"; }
        if (_reason.equals("haltProgram")) { return "Program error"; }
        return "Sync stopped";
    }

    function onUpdate(dc) {
        Theme.clear(dc);
        var rows = [[:badge], [:big, title(), Theme.RED]];
        if (_reason.equals("noKey") || _reason.equals("badKey")) {
            rows.add([:small, "Garmin Connect app:", Theme.GREY]);
            rows.add([:small, "Lift Log > Settings", Theme.TEXT]);
        } else if (_message != null) {
            rows.add([:small, _message, Theme.TEXT]);
        }
        rows.add([:pill, "RETRY", Theme.PILL_GREY]);
        if (BlockedView.canSkip(_reason)) {
            rows.add([:small, Theme.menuHint(), Theme.GREY]);
        }
        Theme.drawRows(dc, rows);
    }

    // A rejected change can be skipped; a key, Premium or size problem can't be fixed by skipping.
    static function canSkip(reason) {
        var fixedElsewhere = ["noKey", "badKey", "premium", "tooLarge"];
        return fixedElsewhere.indexOf(reason) < 0 && Store.queue().size() > 0;
    }
}

class BlockedDelegate extends WatchUi.BehaviorDelegate {
    var _reason;

    function initialize(reason) {
        BehaviorDelegate.initialize();
        _reason = reason;
    }

    function onSelect() {
        getController().clearHalt();
        return true;
    }

    function onMenu() {
        if (!BlockedView.canSkip(_reason)) {
            return false;
        }
        var menu = new WatchUi.Menu2({:title => "Sync stopped"});
        menu.addItem(new WatchUi.MenuItem("Retry", null, :retry, null));
        menu.addItem(new WatchUi.MenuItem("Skip this change", "Resend later from the menu", :skip, null));
        WatchUi.pushView(menu, new BlockedMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onHold(evt) {
        return onMenu();
    }
}

class BlockedMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (item.getId() == :skip) {
            getController().skipStuckChange();
        } else {
            getController().clearHalt();
        }
    }
}
