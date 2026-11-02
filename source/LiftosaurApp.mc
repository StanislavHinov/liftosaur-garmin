import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

// Also loaded for the glance and the background service, which run with only (:glance) or
// (:background) code, so the app is built in getInitialView.
(:glance, :background)
class LiftosaurApp extends Application.AppBase {
    var controller = null;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        Math.srand(Time.now().value() + System.getTimer());
        var api = new Api(ApiKey.current(), Store.deviceId());
        BgSchedule.onAppOpened();
        controller = new Controller(api, new Recording(), new Ui());
        controller.setRecording(recordSetting());
        return [new WaitingView("Loading..."), new WaitingDelegate()];
    }

    function getServiceDelegate() {
        return [new BgService()];
    }

    // Only the app itself builds a controller; the glance and the background process stop here too.
    function onStop(state) {
        if (controller != null) {
            BgSchedule.onAppClosed();
        }
    }

    function getGlanceView() {
        return [new GlanceView()];
    }

    // The settings were edited in Garmin Connect: use them and start over from the stored state.
    function onSettingsChanged() {
        if (controller != null) {
            controller.setRecording(recordSetting());
            controller.useKey(ApiKey.current());
        }
    }

    function recordSetting() {
        try {
            return Application.Properties.getValue("recordActivity") != false;
        } catch (e) {
            return true;
        }
    }
}

function getController() {
    return Application.getApp().controller;
}
