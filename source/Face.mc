import Toybox.Lang;
import Toybox.System;

// The watch-face complication: the next or ongoing workout day, for faces that show app complications.
module Face {
    const COMPLICATION_ID = 0;

    function publish(glance) {
        if (!(Toybox has :Complications)) {
            return;
        }
        try {
            Toybox.Complications.updateComplication(COMPLICATION_ID, {:value => GlanceText.value(glance)});
        } catch (e) {
            System.println("complication: " + e.getErrorMessage());
        }
    }
}
