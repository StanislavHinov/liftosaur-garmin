import Toybox.Lang;
import Toybox.WatchUi;

module Menus {
    function confirm(text, callback) {
        WatchUi.pushView(new WatchUi.Confirmation(text), new ConfirmDelegate(callback), WatchUi.SLIDE_UP);
    }

    // One item per exercise with its progress and next set; picking one shows its first set that is not done.
    function overview(view) {
        var w = Store.workout();
        if (w == null) {
            return;
        }
        var menu = new WatchUi.Menu2({:title => "Workout"});
        var entries = w["entries"];
        var cur = Store.cursor();
        for (var i = 0; i < entries.size(); i++) {
            var isCurrent = cur != null && cur[0] == i;
            menu.addItem(new WatchUi.MenuItem(entries[i]["name"], Look.overviewLine(entries[i], isCurrent), i, null));
        }
        // Opens on the exercise being done, so a long workout doesn't start scrolled to the top.
        if (cur != null) {
            menu.setFocus(cur[0]);
        }
        WatchUi.pushView(menu, new OverviewDelegate(view), WatchUi.SLIDE_UP);
    }

    function restMenu() {
        var menu = new WatchUi.Menu2({:title => "Rest"});
        menu.addItem(new WatchUi.MenuItem("-15 s", null, -15, null));
        menu.addItem(new WatchUi.MenuItem("+15 s", null, 15, null));
        menu.addItem(new WatchUi.MenuItem("Skip rest", null, :skip, null));
        WatchUi.pushView(menu, new RestMenuDelegate(), WatchUi.SLIDE_UP);
    }

    function workoutMenu(view) {
        var c = getController();
        var menu = new WatchUi.Menu2({:title => "Workout"});
        menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
        // Touch use has no Back button for these.
        if (view.isBrowsing()) {
            menu.addItem(new WatchUi.MenuItem("Current set", null, :current, null));
        } else if (view.current() != null) {
            menu.addItem(new WatchUi.MenuItem("Skip set", null, :skip, null));
        }
        menu.addItem(new WatchUi.MenuItem("Previous set", null, :prevSet, null));
        menu.addItem(new WatchUi.MenuItem("Next set", null, :nextSet, null));
        if (view.viewedDone()) {
            menu.addItem(new WatchUi.MenuItem("Undo set", null, :undo, null));
        }
        if (Store.rest() != null) {
            menu.addItem(new WatchUi.MenuItem("Rest", null, :rest, null));
        }
        menu.addItem(new WatchUi.MenuItem("Workout overview", null, :overview, null));
        menu.addItem(new WatchUi.MenuItem("Add set", null, :addSet, null));
        menu.addItem(new WatchUi.MenuItem(c.isPaused() ? "Unpause" : "Pause", null, :pause, null));
        menu.addItem(new WatchUi.MenuItem(Prefs.showClock() ? "Hide time" : "Show time", null, :clock, null));
        menu.addItem(new WatchUi.MenuItem("Save & finish", null, :finish, null));
        menu.addItem(new WatchUi.MenuItem("Discard Garmin activity", null, :discardGarmin, null));
        menu.addItem(new WatchUi.MenuItem("Discard workout", "Liftosaur and Garmin", :discardAll, null));
        WatchUi.pushView(menu, new WorkoutMenuDelegate(view), WatchUi.SLIDE_UP);
    }
}

class ConfirmDelegate extends WatchUi.ConfirmationDelegate {
    var _callback;

    function initialize(callback) {
        ConfirmationDelegate.initialize();
        _callback = callback;
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            // The Confirmation pops itself after this returns; a view switch done now would be popped with it.
            Ticker.later(_callback);
        }
        return true;
    }
}

class WorkoutMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var actions = new MenuActions();
        if (id == :current) {
            _view.returnToCurrent();
        } else if (id == :skip) {
            Menus.confirm("Skip set?", actions.method(:skip));
        } else if (id == :prevSet) {
            _view.browse(-1);
        } else if (id == :nextSet) {
            _view.browse(1);
        } else if (id == :undo) {
            _view.undo();
        } else if (id == :rest) {
            Menus.restMenu();
        } else if (id == :overview) {
            Menus.overview(_view);
        } else if (id == :addSet) {
            _view.addSet();
        } else if (id == :discardAll) {
            Menus.confirm("Discard Liftosaur workout?", actions.method(:discardAllAsk));
        } else if (id == :clock) {
            Prefs.setShowClock(!Prefs.showClock());
            WatchUi.requestUpdate();
        } else if (id == :pause) {
            getController().togglePause();
        } else if (id == :finish) {
            Menus.confirm("Save & finish?", actions.method(:finish));
        } else if (id == :discardGarmin) {
            Menus.confirm("Discard Garmin activity?", actions.method(:discardAsk));
        }
    }
}

class MenuActions {
    function initialize() {}

    function finish() {
        getController().finish();
    }

    function discardAsk() {
        Menus.confirm("Really discard?", method(:discard));
    }

    function discard() {
        getController().discardGarmin();
    }

    function discardAllAsk() {
        Menus.confirm("Really discard?", method(:discardAll));
    }

    function discardAll() {
        getController().discardWorkout();
    }

    function skip() {
        getController().skipSet();
    }
}

class RestMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (id == :skip) {
            getController().skipRest();
        } else {
            getController().adjustRest(id);
        }
    }
}

class OverviewDelegate extends WatchUi.Menu2InputDelegate {
    var _view;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item) {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        _view.showEntry(item.getId());
    }
}
