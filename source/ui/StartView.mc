import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class StartView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    // Shows which day Up and Down picked; without day data, the exercise count.
    function dayLine(p) {
        var d = p["dayData"];
        return d == null ? p["entries"].size() + " exercises" : "Week " + d["week"] + " · Day " + d["dayInWeek"];
    }

    function onUpdate(dc) {
        Theme.clear(dc);
        var p = getController().preview();
        var banner = Theme.bannerText();
        var day = p["dayName"] == null ? "Workout" : p["dayName"];
        Theme.drawRows(dc, [
            banner == null ? [:icon] : [:small, banner, Theme.GREY],
            [:small, "New Workout", Theme.GREY],
            [:card],
            [:big, day, Theme.TEXT],
            [:small, p["programName"] == null ? "" : p["programName"], Theme.GREY],
            [:small, dayLine(p), Theme.TEXT],
            [:end],
            [:pill, "START", Theme.PURPLE]
        ]);
    }
}

class StartDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        getController().startWorkout();
        return true;
    }

    // Up and Down (or swipes) pick another program day.
    function onPreviousPage() {
        getController().pickDay(-1);
        return true;
    }

    function onNextPage() {
        getController().pickDay(1);
        return true;
    }
}
