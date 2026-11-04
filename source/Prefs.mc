import Toybox.Application;
import Toybox.Lang;

// Display settings, set in Garmin Connect or from the workout menu.
module Prefs {
    function showClock() {
        try {
            return Application.Properties.getValue("showClock") != false;
        } catch (e) {
            return true;
        }
    }

    function setShowClock(on) {
        try {
            Application.Properties.setValue("showClock", on);
        } catch (e) {
        }
    }
}
