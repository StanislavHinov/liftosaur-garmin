import Toybox.Lang;

// Stepping the program day on the Start screen; a day is [week, dayInWeek], both from 1.
module DayPick {
    function step(dayData, dir) {
        var week = dayData["week"];
        var day = dayData["dayInWeek"] + dir;
        if (day >= 1) {
            return [week, day];
        }
        // Before the first day of a week: the previous week's first day (its length is unknown).
        return week > 1 ? [week - 1, 1] : null;
    }

    // Days to try when stepping forward lands on a day that does not exist.
    function fallbacks(day) {
        return [[day[0] + 1, 1], [1, 1]];
    }
}
