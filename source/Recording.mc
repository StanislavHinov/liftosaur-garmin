import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Sensor;

class Recording {
    var _session = null;
    var _f;

    function initialize() {
        _f = {};
    }

    function isActive() {
        return _session != null;
    }

    function start(name, unit) {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        _session = ActivityRecording.createSession({
            :name => name,
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_STRENGTH_TRAINING
        });
        var lap = {:mesgType => FitContributor.MESG_TYPE_LAP};
        var session = {:mesgType => FitContributor.MESG_TYPE_SESSION};
        // Ids match resources/fitcontributions.xml, which tells Garmin Connect which ones to show.
        // Shown in the Laps table: exercise, set, reps, weight. In the summary: program, day, sets, volume.
        _f[:reps] = _session.createField("reps", 0, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "reps"});
        _f[:weightKg] = _session.createField("weight_kg", 1, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "kg"});
        _f[:setNumber] = _session.createField("set", 2, FitContributor.DATA_TYPE_UINT8, lap);
        _f[:warmup] = _session.createField("warmup", 3, FitContributor.DATA_TYPE_UINT8, lap);
        _f[:exercise] = _session.createField("exercise", 4, FitContributor.DATA_TYPE_STRING, {:mesgType => FitContributor.MESG_TYPE_LAP, :count => 32});
        _f[:program] = _session.createField("program", 5, FitContributor.DATA_TYPE_STRING, {:mesgType => FitContributor.MESG_TYPE_SESSION, :count => 32});
        _f[:day] = _session.createField("day", 6, FitContributor.DATA_TYPE_STRING, {:mesgType => FitContributor.MESG_TYPE_SESSION, :count => 32});
        _f[:totalSets] = _session.createField("total_sets", 7, FitContributor.DATA_TYPE_UINT16, session);
        _f[:totalVolume] = _session.createField("total_volume", 8, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => unit});
        // Garmin Connect can't take exercise sets from a Connect IQ app; these let a companion tool add them.
        _f[:fitCategory] = _session.createField("fit_category", 9, FitContributor.DATA_TYPE_UINT16, lap);
        _f[:fitName] = _session.createField("fit_exercise", 10, FitContributor.DATA_TYPE_UINT16, lap);
        _f[:exerciseId] = _session.createField("exercise_id", 11, FitContributor.DATA_TYPE_STRING, {:mesgType => FitContributor.MESG_TYPE_LAP, :count => 48});
        // Text with its unit, so a set in lb next to one in kg reads right.
        _f[:weightText] = _session.createField("weight_text", 12, FitContributor.DATA_TYPE_STRING, {:mesgType => FitContributor.MESG_TYPE_LAP, :count => 16});
        _f[:volumeText] = _session.createField("volume_text", 13, FitContributor.DATA_TYPE_STRING, {:mesgType => FitContributor.MESG_TYPE_SESSION, :count => 16});
        _session.start();
    }

    // weight is in unit ("kg" or "lb"); both are null for a bodyweight set.
    function lap(label, setNumber, isWarmup, reps, weight, unit, fit, exerciseId) {
        if (_session == null) {
            return;
        }
        var parts = FitExercise.split(fit);
        _f[:fitCategory].setData(parts[0]);
        _f[:fitName].setData(parts[1]);
        _f[:exerciseId].setData(exerciseId == null ? "" : truncate(exerciseId, 47));
        _f[:reps].setData(reps);
        _f[:weightKg].setData(weight == null ? 0.0 : Weight.convert(weight, unit, "kg").toFloat());
        _f[:weightText].setData(Look.weightText(weight, unit));
        _f[:setNumber].setData(setNumber);
        _f[:warmup].setData(isWarmup ? 1 : 0);
        _f[:exercise].setData(truncate(label, 31));
        _session.addLap();
    }

    function truncate(s, max) {
        if (s == null) {
            return "";
        }
        return s.length() > max ? s.substring(0, max) : s;
    }

    function pause() {
        if (_session != null && _session.isRecording()) {
            _session.stop();
        }
    }

    function resume() {
        if (_session != null && !_session.isRecording()) {
            _session.start();
        }
    }

    // totals is Look.summary of the final sets, so undone and edited sets count as they ended up.
    function save(program, day, totals) {
        if (_session == null) {
            return;
        }
        pause();
        _f[:program].setData(truncate(program, 31));
        _f[:day].setData(truncate(day, 31));
        _f[:totalSets].setData(totals["sets"]);
        _f[:totalVolume].setData(totals["volumeNum"].toFloat());
        _f[:volumeText].setData(truncate(totals["volume"], 15));
        _session.save();
        _session = null;
    }

    function discard() {
        if (_session == null) {
            return;
        }
        pause();
        _session.discard();
        _session = null;
    }
}
