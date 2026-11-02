import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class WaitingView extends WatchUi.View {
    var _message;

    function initialize(message) {
        View.initialize();
        _message = message;
    }

    function onShow() {
        getController().bootOnce();
    }

    function onUpdate(dc) {
        Theme.clear(dc);
        var banner = Theme.bannerText();
        var rows = [
            banner == null ? [:icon] : [:small, banner, Theme.GREY],
            [:big, _message == null ? "No workout" : _message, Theme.TEXT]
        ];
        if (_message == null) {
            rows.add([:small, "Start one on your phone", Theme.GREY]);
        }
        var finishes = 0;
        var q = Store.queue();
        for (var i = 0; i < q.size(); i++) {
            if (q[i]["t"].equals("finish")) {
                finishes++;
            }
        }
        if (finishes > 0) {
            rows.add([:small, finishes + " workout to sync", Theme.YELLOW]);
        }
        var lost = Store.notSynced().size();
        if (lost > 0) {
            rows.add([:small, lost + " sets not synced", Theme.RED]);
        }
        rows.add([:pill, "REFRESH", Theme.PILL_GREY]);
        rows.add([:small, System.getDeviceSettings().phoneConnected ? "Phone connected" : "Phone not connected", Theme.GREY]);
        Theme.drawRows(dc, rows);
    }
}

class WaitingDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        getController().boot();
        return true;
    }

    function onMenu() {
        var menu = new WatchUi.Menu2({:title => "Lift Log"});
        var lost = Store.notSynced().size();
        if (lost > 0) {
            menu.addItem(new WatchUi.MenuItem("Resend " + lost + " sets", null, :resend, null));
        }
        menu.addItem(new WatchUi.MenuItem("Exit", null, :exit, null));
        WatchUi.pushView(menu, new ExitMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    // Touch-only watches: hold the screen for the menu.
    function onHold(evt) {
        return onMenu();
    }
}

class ExitMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        if (item.getId() == :resend) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            getController().resendNotSynced();
            return;
        }
        System.exit();
    }
}
