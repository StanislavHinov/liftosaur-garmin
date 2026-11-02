import Toybox.Lang;

(:glance)
module GlanceText {
    function text(g) {
        if (g == null) {
            return "Tap to open";
        }
        return (g["ongoing"] == true ? "Ongoing: " : "Up next: ") + g["day"];
    }

    // The watch-face complication: short, the day alone unless it is under way.
    function value(g) {
        if (g == null) {
            return "--";
        }
        return g["ongoing"] == true ? "Now: " + g["day"] : g["day"];
    }
}
