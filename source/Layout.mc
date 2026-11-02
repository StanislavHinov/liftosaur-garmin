import Toybox.Lang;
import Toybox.Math;

// Vertical stacking and round-screen geometry, kept free of Dc so tests can run it.
module Layout {
    function total(heights, gap) {
        var sum = 0;
        for (var i = 0; i < heights.size(); i++) {
            sum += heights[i];
        }
        return heights.size() == 0 ? 0 : sum + gap * (heights.size() - 1);
    }

    // Top y of each row, with the whole stack centered between top and bottom.
    function stack(heights, gap, top, bottom) {
        var y = top + (bottom - top - total(heights, gap)) / 2;
        var ys = [];
        for (var i = 0; i < heights.size(); i++) {
            ys.add(y);
            y += heights[i] + gap;
        }
        return ys;
    }

    // Width of a circle of radius r (centered at cy) along the line at height y.
    function chord(r, cy, y) {
        var d = y - cy;
        if (d * d >= r * r) {
            return 0;
        }
        return (2 * Math.sqrt(r * r - d * d)).toNumber();
    }
}
