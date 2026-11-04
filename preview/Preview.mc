import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Fake workouts for scripts/preview.sh, so screens can be checked without a Liftosaur account.
module Preview {
    var timer = null;

    // Opens the Timer screen on a one-sided plank, in get-ready or 12 s into the clock.
    function showTimed() {
        var view = new TimedView("Side Plank", 60, true, null, [3, 0], {"reps" => 1}, 1, null);
        view.run = TimedSet.begin(Controller.nowSec() - (PreviewMode.MODE.equals("timed") ? 2 : 17), 60);
        WatchUi.pushView(view, new TimedDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }

    function showMenu() {
        var view = new ActiveSetView();
        if (PreviewMode.MODE.equals("overview")) {
            Menus.overview(view);
        } else {
            Menus.workoutMenu(view);
        }
    }

    // Opens the Input screen on an RPE set with a prompted variable, after the set screen is up.
    function showPrompt() {
        var set = {"reps" => 5, "weight" => "102.5kg", "rpe" => 8, "logRpe" => true, "askWeight" => false,
            "isUnilateral" => false, "setTimer" => null, "plates" => null, "completed" => null};
        var fields = Prompt.fields({"promptedVars" => [{"name" => "Training max", "value" => "110kg"}]}, set, "kg");
        var view = new PromptView("Bench Press", fields, new Lang.Method(Preview, :noop), "LOG");
        WatchUi.pushView(view, new PromptDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }

    // The value screen a tapped weight box opens.
    function showEdit() {
        var f = Prompt.field("weight", "Weight (kg)", 102.5, 2.5, 0, null, :weight, "kg");
        var view = new PromptView("Bench Press", [f], new Lang.Method(Preview, :noop), "DONE");
        WatchUi.pushView(view, new PromptDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }

    function noop(fields) {
    }

    function set(id, isWarmup, reps, weight, plates, done) {
        return {
            "setId" => id, "index" => 0, "isWarmup" => isWarmup, "reps" => reps, "minReps" => null,
            "isAmrap" => false, "weight" => weight, "plates" => plates, "rpe" => null, "logRpe" => false,
            "askWeight" => false, "isUnilateral" => false, "timer" => 90, "setTimer" => null,
            "completed" => done ? {"reps" => reps, "weight" => weight} : null
        };
    }

    function entry(id, name, equipment, sets) {
        return {
            "entryId" => id, "name" => name, "equipment" => equipment, "hasUpdateScript" => false,
            "promptedVars" => [], "warmupSets" => [], "sets" => sets
        };
    }

    // done: how many sets (in order) are completed.
    function raw(done) {
        var bar = [{"weight" => "20kg", "num" => 2}];
        var specs = [
            ["rdl", "Romanian Deadlift", "barbell", [[true, 8, "40kg", [{"weight" => "10kg", "num" => 2}]], [false, 8, "60kg", bar], [false, 8, "60kg", bar], [false, 8, "60kg", bar]]],
            ["bench", "Bench Press", "barbell", [[false, 5, "102.5kg", [{"weight" => "20kg", "num" => 4}, {"weight" => "1.25kg", "num" => 2}]], [false, 5, "102.5kg", null]]],
            ["row", "Dumbbell Row", "dumbbell", [[false, 12, "30kg", null], [false, 12, "30kg", null]]],
            ["plank", "Plank", null, [[false, 1, null, null]]]
        ];
        var entries = [];
        var n = 0;
        for (var i = 0; i < specs.size(); i++) {
            var sets = [];
            var list = specs[i][3];
            for (var j = 0; j < list.size(); j++) {
                var s = set(specs[i][0] + j, list[j][0], list[j][1], list[j][2], list[j][3], n < done);
                if (specs[i][0].equals("bench")) {
                    s["rpe"] = 8;
                }
                if (specs[i][0].equals("rdl") && !list[j][0]) {
                    s["minReps"] = 6;
                }
                if (specs[i][0].equals("plank")) {
                    s["setTimer"] = 60;
                }
                sets.add(s);
                n++;
            }
            entries.add(entry(specs[i][0], specs[i][1], specs[i][2], sets));
        }
        return {
            "programName" => "Demo Program", "dayName" => "Upper A",
            "dayData" => {"day" => 2, "week" => 1, "dayInWeek" => 2},
            "startTime" => Controller.nowMs() - 2410000l, "entries" => entries
        };
    }

    function close() {
        System.exit();
    }

    // Returns true when the preview took over booting.
    function boot(c) {
        var mode = PreviewMode.MODE;
        Store.clearAll();
        if (mode.equals("error")) {
            c.onHalt("badKey", null);
        } else if (mode.equals("nokey")) {
            c.onHalt("noKey", null);
        } else if (mode.equals("waiting")) {
            c._ui.showWaiting(null);
        } else if (mode.equals("bg")) {
            // Sets left unsent, then the app closes: the background service should send them.
            var st = Controller.nowMs() - 3600000l;
            Store.setQueue([
                Queue.set(st, "bench", "aaaaaa", {"reps" => 5, "weight" => "60kg"}),
                Queue.set(st, "bench", "bbbbbb", {"reps" => 5, "weight" => "60kg"}),
                Queue.finish(st, Controller.nowMs(), null)
            ]);
            Store.setGlance(false, "Upper A");
            c._ui.showWaiting(null);
            timer = new Timer.Timer();
            timer.start(new Lang.Method(Preview, :close), 1500, false);
        } else if (mode.equals("start")) {
            c._preview = SlimWorkout.slim(raw(0));
            c._ui.showStart();
        } else {
            var done = {"rest" => 2, "over" => 2, "browse" => 2, "prompt" => 4, "timed" => 4, "timedwork" => 4, "menu" => 2, "overview" => 5, "norest" => 0, "edit" => 4, "rpe" => 4, "hold" => 8, "done" => 9}[mode];
            c.takeOver(raw(done));
            if (mode.equals("rest")) {
                Store.setRest({"at" => Controller.nowSec() - 48, "dur" => 90});
            } else if (mode.equals("over")) {
                Store.setRest({"at" => Controller.nowSec() - 102, "dur" => 90});
            }
            c._notice = null;
            if (mode.equals("prompt") || mode.equals("edit")) {
                timer = new Timer.Timer();
                timer.start(new Lang.Method(Preview, mode.equals("edit") ? :showEdit : :showPrompt), 500, false);
            } else if (mode.equals("menu") || mode.equals("overview")) {
                timer = new Timer.Timer();
                timer.start(new Lang.Method(Preview, :showMenu), 500, false);
            } else if (mode.equals("timed") || mode.equals("timedwork")) {
                timer = new Timer.Timer();
                timer.start(new Lang.Method(Preview, :showTimed), 500, false);
            }
        }
        return true;
    }
}
