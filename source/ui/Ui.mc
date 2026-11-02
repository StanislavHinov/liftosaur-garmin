import Toybox.Lang;
import Toybox.WatchUi;

class Ui {
    function initialize() {}

    function show(view, delegate) {
        WatchUi.switchToView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function showLoading() {
        show(new WaitingView("Loading..."), new WaitingDelegate());
    }

    function showWaiting(message) {
        show(new WaitingView(message), new WaitingDelegate());
    }

    function showStart() {
        show(new StartView(), new StartDelegate());
    }

    function showActive() {
        var view = new ActiveSetView();
        show(view, new ActiveSetDelegate(view));
    }

    // dir > 0: the next set comes in from the right; dir < 0: from the left.
    function slideActive(dir) {
        var view = new ActiveSetView();
        WatchUi.switchToView(view, new ActiveSetDelegate(view), dir > 0 ? WatchUi.SLIDE_LEFT : WatchUi.SLIDE_RIGHT);
    }

    function showEnded(saved) {
        show(new EndedView(saved), new EndedDelegate());
    }

    function showBlocked(reason, message) {
        show(new BlockedView(reason, message), new BlockedDelegate(reason));
    }

    function refresh() {
        WatchUi.requestUpdate();
    }
}
