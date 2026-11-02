import Toybox.Lang;

module Rest {
    function remaining(rest, nowSec) {
        if (rest == null) {
            return 0;
        }
        var left = rest["at"] + rest["dur"] - nowSec;
        return left > 0 ? left : 0;
    }

    function overtime(rest, nowSec) {
        if (rest == null) {
            return 0;
        }
        var over = nowSec - rest["at"] - rest["dur"];
        return over > 0 ? over : 0;
    }

    function clock(seconds) {
        return (seconds / 60).toString() + ":" + (seconds % 60).format("%02d");
    }
}
