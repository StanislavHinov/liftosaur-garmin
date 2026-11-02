import Toybox.Lang;

(:test)
module Fixtures {
    const START = 1738274512000l;

    function set(setId, index, isWarmup, reps, weight, timer, completedIds) {
        var completed = null;
        if (completedIds.indexOf(setId) >= 0) {
            completed = {"reps" => reps, "weight" => weight};
        }
        return {
            "setId" => setId, "index" => index, "isWarmup" => isWarmup, "reps" => reps,
            "minReps" => null, "isAmrap" => false, "weight" => weight, "originalWeight" => "80%",
            "plates" => [{"weight" => "20kg", "num" => 2}], "rpe" => null, "logRpe" => false,
            "askWeight" => false, "isUnilateral" => false, "timer" => timer, "setTimer" => null,
            "completed" => completed
        };
    }

    function workoutRaw(completedIds) {
        var bench = set("benchb", 1, false, 5, "60kg", 120, completedIds);
        bench["logRpe"] = true;
        return {
            "programId" => "abc123", "programName" => "GZCLP", "dayName" => "A1",
            "dayData" => {"day" => 1, "week" => 1, "dayInWeek" => 1},
            "startTime" => START,
            "entries" => [
                {
                    "entryId" => "squat_barbell", "exerciseId" => "squat_barbell", "equipment" => "barbell",
                    "name" => "Squat", "imageUrl" => "/x.png", "superset" => null, "notes" => null,
                    "description" => "T1", "hasUpdateScript" => false, "promptedVars" => [],
                    "warmupSets" => [set("squatw", 0, true, 5, "40kg", 90, completedIds)],
                    "sets" => [
                        set("squata", 0, false, 5, "100kg", 180, completedIds),
                        set("squatb", 1, false, 5, "100kg", 180, completedIds)
                    ]
                },
                {
                    "entryId" => "bench_barbell", "exerciseId" => "benchPress_barbell", "equipment" => "barbell",
                    "name" => "Bench Press", "imageUrl" => null, "superset" => null, "notes" => null,
                    "description" => null, "hasUpdateScript" => false, "promptedVars" => [],
                    "warmupSets" => [],
                    "sets" => [set("bencha", 0, false, 5, "60kg", 120, completedIds), bench]
                }
            ]
        };
    }

    function response(raw) {
        return {"data" => {"workout" => raw}};
    }
}
