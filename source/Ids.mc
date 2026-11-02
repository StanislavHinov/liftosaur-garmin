import Toybox.Lang;
import Toybox.Math;

(:background)
module Ids {
    const LETTERS = "abcdefghijklmnopqrstuvwxyz";

    // The API wants new set ids shaped like the app's: six lowercase letters.
    function newSetId() {
        var chars = LETTERS.toCharArray();
        var out = "";
        for (var i = 0; i < 6; i++) {
            out += chars[Math.rand() % 26].toString();
        }
        return out;
    }

    function newDeviceId() {
        var chars = LETTERS.toCharArray();
        var out = "garmin-";
        for (var i = 0; i < 16; i++) {
            out += chars[Math.rand() % 26].toString();
        }
        return out;
    }
}
