import Toybox.Attention;
import Toybox.Lang;

module Haptics {
    // The rest (by its start time) that already buzzed; shared, because each set slides in as a new screen.
    var restBuzzedAt = null;

    function buzz(ms) {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, ms)]);
        }
    }
}
