import Toybox.Lang;
import Toybox.Test;

(:test)
module ActiveSetSyncUtil {
    function seed() {
        Store.clearAll();
        Store.setWorkout(SlimWorkout.slim(Fixtures.workoutRaw([])));
        var view = new ActiveSetView();
        view.current();
        return view;
    }

    function update(weight, reps, completed) {
        var raw = Fixtures.workoutRaw([]);
        var set = raw["entries"][0]["warmupSets"][0];
        set["weight"] = weight;
        set["reps"] = reps;
        set["completed"] = completed;
        Store.setWorkout(SlimWorkout.slim(raw));
    }

    function scenario(phoneWeight, phoneReps, watchWeight, watchReps, expectedWeight, expectedReps) {
        var view = seed();
        update("60kg", 8, null);
        // Start a fresh screen at the agreed 60 kg / 8 reps baseline.
        view = new ActiveSetView();
        view.current();
        if (watchWeight != null) {
            view.setValue([Prompt.field("weight", "Weight", watchWeight, 2.5, 0, null, :weight, "kg")]);
        }
        if (watchReps != null) {
            view.setValue([Prompt.field("reps", "Reps", watchReps, 1, 0, null, :reps, null)]);
        }
        var api = new FakeApi();
        var sync = new Sync(api, new FakeListener());
        sync.poll();
        var raw = Fixtures.workoutRaw([]);
        raw["entries"][0]["warmupSets"][0]["weight"] = phoneWeight;
        raw["entries"][0]["warmupSets"][0]["reps"] = phoneReps;
        api.respond(200, Fixtures.response(raw));
        view.current();
        Test.assertEqual(view._weight, expectedWeight);
        Test.assertEqual(view._reps, expectedReps);
        return true;
    }

}

(:test)
function activeSetFollowsPhoneWeightWithoutEdits(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("65kg", 8, null, null, 65.0, 8);
}

(:test)
function activeSetFollowsPhoneRepsWithoutEdits(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("60kg", 10, null, null, 60.0, 10);
}

(:test)
function activeSetFollowsBothPhoneFieldsWithoutEdits(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("65kg", 10, null, null, 65.0, 10);
}

(:test)
function activeSetKeepsWatchWeightOnPhoneConflict(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("65kg", 8, 62.5, null, 62.5, 8);
}

(:test)
function activeSetKeepsWatchRepsOnPhoneConflict(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("60kg", 10, null, 9, 60.0, 9);
}

(:test)
function activeSetFollowsPhoneWeightWithWatchReps(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("65kg", 8, null, 9, 65.0, 9);
}

(:test)
function activeSetFollowsPhoneRepsWithWatchWeight(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("60kg", 10, 62.5, null, 62.5, 10);
}

(:test)
function activeSetKeepsBothWatchFieldsOnPhoneConflict(logger as Test.Logger) as Boolean {
    return ActiveSetSyncUtil.scenario("65kg", 10, 62.5, 9, 62.5, 9);
}

(:test)
function activeSetReturningToWeightBaselineFollowsLatestPhoneValue(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.toggleField();
    view.adjust(1);
    ActiveSetSyncUtil.update("50kg", 8, null);
    view.current();
    ActiveSetSyncUtil.update("55kg", 9, null);
    view.current();
    Test.assertEqual(view._weight, 42.5);
    Test.assertEqual(view._reps, 9);
    Test.assert(view._field == :weight);
    view.adjust(-1);
    view.current();
    Test.assertEqual(view._weight, 55.0);
    return true;
}

(:test)
function activeSetReturningToRepsBaselineFollowsLatestPhoneValue(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.adjust(1);
    ActiveSetSyncUtil.update("50kg", 8, null);
    view.current();
    ActiveSetSyncUtil.update("55kg", 9, null);
    view.current();
    Test.assertEqual(view._reps, 6);
    Test.assertEqual(view._weight, 55.0);
    view.adjust(-1);
    view.current();
    Test.assertEqual(view._reps, 9);
    return true;
}

(:test)
function activeSetTouchConfirmationKeepsEditMadeWhilePhoneUpdates(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    var editor = view.editField(:weight);
    editor.step(1);
    ActiveSetSyncUtil.update("50kg", 8, null);
    editor.next();
    view.current();
    Test.assertEqual(view._weight, 42.5);
    Test.assertEqual(view._reps, 8);
    return true;
}

(:test)
function activeSetTouchCancellationFollowsPhoneUpdates(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    var editor = view.editField(:reps);
    editor.step(1);
    ActiveSetSyncUtil.update("50kg", 8, null);
    editor.back();
    view.current();
    Test.assertEqual(view._weight, 50.0);
    Test.assertEqual(view._reps, 8);
    return true;
}

(:test)
function activeSetTouchUnchangedConfirmationFollowsPhoneUpdates(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    var editor = view.editField(:weight);
    ActiveSetSyncUtil.update("50kg", 8, null);
    editor.next();
    view.current();
    Test.assertEqual(view._weight, 50.0);
    Test.assertEqual(view._reps, 8);
    return true;
}

(:test)
function activeSetTouchUnchangedConfirmationDoesNotUndoRefresh(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    var editor = view.editField(:weight);
    ActiveSetSyncUtil.update("50kg", 8, null);
    view.current();
    editor.next();
    view.current();
    Test.assertEqual(view._weight, 50.0);
    Test.assertEqual(view._reps, 8);
    return true;
}

(:test)
function activeSetTouchUnchangedRepsDoNotUndoRefresh(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    var editor = view.editField(:reps);
    ActiveSetSyncUtil.update("50kg", 8, null);
    view.current();
    editor.next();
    view.current();
    Test.assertEqual(view._reps, 8);
    Test.assertEqual(view._weight, 50.0);
    return true;
}

(:test)
function activeSetTouchWeightUsesEditorUnitAfterRefresh(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    var editor = view.editField(:weight);
    editor.step(1);
    ActiveSetSyncUtil.update("100lb", 8, null);
    view.current();
    editor.next();
    view.current();
    Test.assertEqual(view._unit, "lb");
    Test.assert(TestUtil.near(view._weight, Weight.convert(42.5, "kg", "lb")));
    Test.assertEqual(view._reps, 8);
    return true;
}

(:test)
function activeSetSavedCompletedEditFollowsPhoneBeforeNextDraw(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view._pos = [0, 0];
    ActiveSetSyncUtil.update("40kg", 5, {"reps" => 5, "weight" => "40kg"});
    view.current();
    view.toggleField();
    view.adjust(1);
    var api = new FakeApi();
    var controller = new Controller(api, new FakeRec(), new FakeUi());
    var app = Toybox.Application.getApp();
    var original = app.controller;
    app.controller = controller;
    try {
        view.logSet();
        Test.assertEqual(api.last()["body"]["completed"]["weight"], "42.5kg");
        var raw = Fixtures.workoutRaw(["squatw"]);
        raw["entries"][0]["warmupSets"][0]["completed"]["weight"] = "45kg";
        api.respond(200, Fixtures.response(raw));
        // Inspect that same completed set, before any intermediate redraw.
        view._pos = [0, 0];
        view.current();
        Test.assertEqual(view._weight, 45.0);
    } finally {
        app.controller = original;
    }
    return true;
}

(:test)
function activeSetPromptSaveFollowsLaterPhoneValues(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view._pos = [0, 0];
    ActiveSetSyncUtil.update("40kg", 5, {"reps" => 5, "weight" => "40kg"});
    view.current();
    view.toggleField();
    view.adjust(1);
    var api = new FakeApi();
    var controller = new Controller(api, new FakeRec(), new FakeUi());
    var app = Toybox.Application.getApp();
    var original = app.controller;
    app.controller = controller;
    try {
        var log = new PromptLog(view, [0, 0], {"reps" => 5, "weight" => "42.5kg"}, 5, 42.5, true);
        log.run([]);
        Test.assertEqual(api.last()["body"]["completed"]["weight"], "42.5kg");
        var raw = Fixtures.workoutRaw(["squatw"]);
        raw["entries"][0]["warmupSets"][0]["completed"]["weight"] = "45kg";
        api.respond(200, Fixtures.response(raw));
        view._pos = [0, 0];
        view.current();
        Test.assertEqual(view._weight, 45.0);
    } finally {
        app.controller = original;
    }
    return true;
}

(:test)
function activeSetRefreshesPhoneWeightAndReps(logger as Test.Logger) as Boolean {
    Store.clearAll();
    Store.setWorkout(SlimWorkout.slim(Fixtures.workoutRaw([])));
    var view = new ActiveSetView();
    view.current();
    Test.assertEqual(view._weight, 40.0);
    var api = new FakeApi();
    var sync = new Sync(api, new FakeListener());
    sync.poll();
    var raw = Fixtures.workoutRaw([]);
    raw["entries"][0]["warmupSets"][0]["weight"] = "45kg";
    raw["entries"][0]["warmupSets"][0]["reps"] = 8;
    api.respond(200, Fixtures.response(raw));
    view.current();
    Test.assertEqual(view._weight, 45.0);
    Test.assertEqual(view._reps, 8);
    return true;
}

(:test)
function activeSetKeepsButtonWeightEditButRefreshesReps(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.toggleField();
    view.adjust(1);
    ActiveSetSyncUtil.update("50kg", 8, null);
    view.current();
    Test.assertEqual(view._weight, 42.5);
    Test.assertEqual(view._reps, 8);
    // Repeated redraws must not turn a local edit into an untouched field.
    view.current();
    Test.assertEqual(view._weight, 42.5);
    return true;
}

(:test)
function activeSetKeepsRepsEditButRefreshesWeight(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.adjust(1);
    ActiveSetSyncUtil.update("50kg", 8, null);
    view.current();
    Test.assertEqual(view._reps, 6);
    Test.assertEqual(view._weight, 50.0);
    return true;
}

(:test)
function activeSetKeepsTouchWeightEditButRefreshesReps(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.setValue([Prompt.field("weight", "Weight", 47.5, 2.5, 0, null, :weight, "kg")]);
    ActiveSetSyncUtil.update("50kg", 8, null);
    view.current();
    Test.assertEqual(view._weight, 47.5);
    Test.assertEqual(view._reps, 8);
    return true;
}

(:test)
function activeSetRefreshesCompletedResults(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view._pos = [0, 0];
    ActiveSetSyncUtil.update("40kg", 5, {"reps" => 5, "weight" => "42kg"});
    view.current();
    ActiveSetSyncUtil.update("40kg", 5, {"reps" => 7, "weight" => "45kg"});
    view.current();
    Test.assertEqual(view._reps, 7);
    Test.assertEqual(view._weight, 45.0);
    return true;
}

(:test)
function activeSetRefreshesUnitsAndWeightAvailability(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    ActiveSetSyncUtil.update("100lb", 5, null);
    view.current();
    Test.assertEqual(view._unit, "lb");
    Test.assertEqual(view._step, 5.0);
    Test.assertEqual(view._weight, 100.0);
    ActiveSetSyncUtil.update(null, 5, null);
    view.current();
    Test.assert(view._weight == null);
    return true;
}

(:test)
function activeSetConvertsLocalWeightWhenServerChangesUnit(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.toggleField();
    view.adjust(1);
    ActiveSetSyncUtil.update("100lb", 5, null);
    view.current();
    Test.assertEqual(view._unit, "lb");
    Test.assert(TestUtil.near(view._weight, Weight.convert(42.5, "kg", "lb")));
    return true;
}

(:test)
function activeSetFollowsServerAgainAfterEditsMatch(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.toggleField();
    view.adjust(1);
    ActiveSetSyncUtil.update("42.5kg", 5, null);
    view.current();
    ActiveSetSyncUtil.update("45kg", 5, null);
    view.current();
    Test.assertEqual(view._weight, 45.0);
    return true;
}

(:test)
function activeSetResetsEditsForAnotherSetAndCompletion(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.adjust(1);
    view._pos = [0, 1];
    view.current();
    Test.assertEqual(view._reps, 5);
    Test.assertEqual(view._weight, 100.0);
    view._pos = [0, 0];
    view.current();
    view.adjust(1);
    ActiveSetSyncUtil.update("40kg", 5, {"reps" => 9, "weight" => "45kg"});
    view.current();
    Test.assertEqual(view._reps, 9);
    Test.assertEqual(view._weight, 45.0);
    ActiveSetSyncUtil.update("40kg", 5, null);
    view.current();
    Test.assertEqual(view._reps, 5);
    Test.assertEqual(view._weight, 40.0);
    return true;
}

(:test)
function activeSetResetsEditsForReplacementWorkout(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    view.adjust(1);
    var raw = Fixtures.workoutRaw([]);
    raw["startTime"] = Fixtures.START + 1000l;
    Store.setWorkout(SlimWorkout.slim(raw));
    view.current();
    Test.assertEqual(view._reps, 5);
    return true;
}

(:test)
function activeSetSubmissionUsesRefreshedPhoneValues(logger as Test.Logger) as Boolean {
    var view = ActiveSetSyncUtil.seed();
    var api = new FakeApi();
    var controller = new Controller(api, new FakeRec(), new FakeUi());
    var app = Toybox.Application.getApp();
    var original = app.controller;
    app.controller = controller;
    try {
        controller.sync().poll();
        var raw = Fixtures.workoutRaw([]);
        raw["entries"][0]["warmupSets"][0]["weight"] = "45kg";
        raw["entries"][0]["warmupSets"][0]["reps"] = 8;
        api.respond(200, Fixtures.response(raw));
        view.logSet();
        Test.assertEqual(api.last()["body"]["completed"]["weight"], "45kg");
        Test.assertEqual(api.last()["body"]["completed"]["reps"], 8);
    } finally {
        app.controller = original;
    }
    return true;
}
