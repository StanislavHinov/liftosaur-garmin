import json, sys
# Usage: build.py <work dir>. Writes <work dir>/table.json; copy it to resources/jsonData/fit_exercises.json.
G = sys.argv[1]
d = json.load(open(G + '/data.json')); m = json.load(open(G + '/matches.json'))
fit = d['fit']
def code(s):
    if s is None: return None
    cat, name = s.split('/')
    names = {v: int(k) for k, v in fit[cat]['names'].items()}
    assert name in names, s
    return fit[cat]['num'] * 65536 + names[name]
# Reviewed by hand: base exercise -> Garmin "category/name", or None when Garmin has nothing close.
OVR = {
 'ballSlams':'plyo/medicineBallSlam','battleRopes':'battleRope/doubleArmWave','behindTheNeckPress':'shoulderPress/overheadBarbellPress',
 'chestDip':'tricepsExtension/bodyWeightDip','tricepsDip':'tricepsExtension/bodyWeightDip','negativeDip':'tricepsExtension/bodyWeightDip',
 'chestPress':'benchPress/dumbbellBenchPress','isoLateralChestPress':'benchPress/dumbbellBenchPress',
 'calfPressOnLegPress':'calfRaise/donkeyCalfRaise','standingCalfRaise':'calfRaise/standingCalfRaise','cycling':'indoorBike/stationaryBike','declineBenchPress':'benchPress/declineDumbbellBenchPress',
 'flatKneeRaise':'crunch/reverseCrunch','flatLegRaise':'legRaise/lyingStraightLegRaise','goodMorning':'legCurl/goodMorning',
 'gluteBridge':'hipRaise/hipRaise','gluteBridgeMarch':'hipRaise/marchingHipRaise','gluteKickback':'hipStability/quadrupedHipExtension',
 'highKneeSkips':'warmUp/walkingHighKnees','hipAbductor':'hipStability/standingHipAbduction','hipAdductor':'hipStability/standingAdduction',
 'sideHipAbductor':'hipStability/sideLyingLegRaise','inclineBenchPressWideGrip':'benchPress/inclineBarbellBenchPress',
 'inclineRow':'row/chestSupportedDumbbellRow','jackknifeSitUp':'sitUp/vUp','jumpingJack':'cardio/jumpingJacks',
 'kettlebellTurkishGetUp':'core/turkishGetUp','kneestoElbows':'crunch/kneesToElbow','legExtension':'bandedExercises/legExtension',
 'obliqueCrunch':'crunch/standingSideCrunch','pecDeck':'flye/dumbbellFlye','pullover':'pullUp/ezBarPullover',
 'reverseCurl':'curl/reverseGripBarbellBicepsCurl','reverseGripConcentrationCurl':'curl/reverseGripBarbellBicepsCurl',
 'romanianDeadlift':'deadlift/romanianDeadlift','seatedFrontRaise':'shoulderPress/dumbbellFrontRaise','sideLyingClam':'hipRaise/clams',
 'singleLegBridge':'hipRaise/singleLegHipRaise','singleLegGluteBridgeBench':'hipRaise/singleLegHipRaiseWithFootOnBench',
 'singleLegGluteBridgeStraight':'hipRaise/singleLegHipRaise','singleLegGluteBridgeBentKnee':'hipRaise/singleLegHipRaise',
 'skullcrusher':'tricepsExtension/dumbbellLyingTricepsExtension','snatchPull':'olympicLift/barbellHighPull',
 'deadliftHighPull':'olympicLift/barbellHighPull','standingRowRearDeltWithRope':'row/facePull',
 'standingRowRearHorizontalDeltWithRope':'row/facePull','standingRowVBar':'row/vGripCableRow','standingRowCloseGrip':'row/vGripCableRow',
 'superman':'hyperextension/supermanFromFloor','thruster':'squat/thrusters','tricepsPushdown':'tricepsExtension/tricepsPressdown',
 'tricepsExtension':'tricepsExtension/overheadDumbbellTricepsExtension','deadHang':None,'nordicCurl':'legCurl/legCurl',
 'wallHandstand':'pushUp/handstandPushUp','crowPose':None,'dragonFlag':'crunch/reverseCrunch','copenhagenPlank':'plank/sidePlank',
 'archHang':None,'supportHold':None,'skinTheCat':None,'shoulderPassThrough':None,'pallofPress':'chop/halfKneelingStabilityChop',
 'ringAbRollout':'core/barbellRollout','kneelingRingAbRollout':'core/kneelingAbWheel','hollowBodyHold':'crunch/hollowRock',
 'wristRoller':'curl/barbellWristCurl','torsoRotation':'core/russianTwist','squatRow':'row/row','pressUnder':'olympicLift/snatch',
 'singleLegDeadlift':'deadlift/singleLegRomanianDeadliftWithDumbbell',
}
# Equipment variants reviewed by hand (only where Garmin has a specific one).
EQOVR = {
 'benchPress_dumbbell':'benchPress/dumbbellBenchPress','benchPress_smith':'benchPress/smithMachineBenchPress','benchPress_kettlebell':'benchPress/kettlebellChestPress',
 'inclineBenchPress_dumbbell':'benchPress/inclineDumbbellBenchPress','inclineBenchPress_smith':'benchPress/inclineSmithMachineBenchPress',
 'declineBenchPress_dumbbell':'benchPress/declineDumbbellBenchPress','chestPress_barbell':'benchPress/barbellBenchPress',
 'overheadPress_dumbbell':'shoulderPress/overheadDumbbellPress','overheadPress_smith':'shoulderPress/smithMachineOverheadPress',
 'shoulderPress_barbell':'shoulderPress/overheadBarbellPress','shoulderPress_smith':'shoulderPress/smithMachineOverheadPress',
 'seatedOverheadPress_dumbbell':'shoulderPress/dumbbellShoulderPress',
 'bicepCurl_barbell':'curl/barbellBicepsCurl','bicepCurl_ezbar':'curl/ezBarPreacherCurl','bicepCurl_cable':'curl/cableBicepsCurl',
 'hammerCurl_cable':'curl/cableHammerCurl','preacherCurl_ezbar':'curl/ezBarPreacherCurl','preacherCurl_barbell':'curl/ezBarPreacherCurl',
 'reverseCurl_ezbar':'curl/reverseEzBarCurl','wristCurl_dumbbell':'curl/dumbbellWristCurl',
 'deadlift_dumbbell':'deadlift/dumbbellDeadlift','deadlift_trapbar':'deadlift/trapBarDeadlift','deadlift_kettlebell':'deadlift/kettlebellDeadlift',
 'romanianDeadlift_barbell':'deadlift/romanianDeadlift','straightLegDeadlift_dumbbell':'deadlift/dumbbellStraightLegDeadlift',
 'squat_dumbbell':'squat/dumbbellSquat','squat_kettlebell':'squat/gobletSquat','squat_bodyweight':'squat/airSquat',
 'frontSquat_dumbbell':'squat/dumbbellFrontSquat','lunge_dumbbell':'lunge/dumbbellLunge','lunge_bodyweight':'lunge/lunge',
 'reverseLunge_barbell':'lunge/barbellReverseLunge','splitSquat_barbell':'lunge/barbellSplitSquat','stepUp_barbell':'squat/barbellStepUp',
 'bulgarianSplitSquat_barbell':'lunge/barbellBulgarianSplitSquat',
 'bentOverRow_dumbbell':'row/dumbbellRow','bentOverRow_cable':'row/seatedCableRow','shrug_barbell':'shrug/barbellShrug',
 'uprightRow_barbell':'shrug/barbellUprightRow','uprightRow_cable':'shrug/uprightRow',
 'lateralRaise_cable':'lateralRaise/oneArmCableLateralRaise','frontRaise_cable':'lateralRaise/cableFrontRaise','frontRaise_barbell':'lateralRaise/frontRaise',
 'chestFly_cable':'flye/cableCrossover','chestFly_leverageMachine':'flye/dumbbellFlye',
 'tricepsExtension_cable':'tricepsExtension/cableOverheadTricepsExtension','tricepsExtension_ezbar':'tricepsExtension/ezBarOverheadTricepsExtension',
 'tricepsExtension_barbell':'tricepsExtension/ezBarOverheadTricepsExtension','skullcrusher_ezbar':'tricepsExtension/inclineEzBarLyingTricepsExtension',
 'pushPress_barbell':'shoulderPress/barbellPushPress','snatch_barbell':'olympicLift/barbellSnatch','clean_dumbbell':'olympicLift/dumbbellClean',
 'hipThrust_bodyweight':'hipRaise/hipRaise','pullUp_band':'pullUp/bandedPullUps',
 'standingCalfRaise_barbell':'calfRaise/standingBarbellCalfRaise','standingCalfRaise_dumbbell':'calfRaise/standingDumbbellCalfRaise',
 'reverseWristCurl_dumbbell':'curl/dumbbellReverseWristCurl','kettlebellSwing_dumbbell':'hipRaise/kettlebellSwing',
 'thruster_dumbbell':'squat/dumbbellThrusters','jumpSquat_bodyweight':'plyo/bodyWeightJumpSquat','jumpSquat_dumbbell':'plyo/dumbbellJumpSquat',

}
table = {}; missing = []
for k, v in m.items():
    if k in OVR:
        c = code(OVR[k])
    else:
        best = v['m'][v['eq'] if v['eq'] in v['m'] else 'bodyweight'][0]
        c = code(best[1] + '/' + best[4]) if best[0] > 0 else None
    if c is None: missing.append(k)
    else: table[k] = c
bad = []
for k, s in EQOVR.items():
    base = k.split('_')[0]
    if base not in m: bad.append(k); continue
    try: table[k] = code(s)
    except (AssertionError, KeyError): bad.append(k + ' -> ' + s)
print('bases', len(m), 'mapped', sum(1 for k in table if '_' not in k), 'variants', sum(1 for k in table if '_' in k))
print('no Garmin match:', missing)
print('variant names not in FIT (fix):', bad)
json.dump(table, open(G + '/table.json', 'w'), separators=(',', ':'), sort_keys=True)
