import re, json, sys
# Usage: match.py <work dir>. Scores every Garmin exercise name against each Liftosaur exercise and equipment.
G = sys.argv[1]
d = json.load(open(G + '/data.json'))
fit, lifto = d['fit'], d['lifto']
SYN = {'biceps':'bicep','triceps':'tricep','dumbbells':'dumbbell','db':'dumbbell','pulldown':'pull down','pullup':'pull up',
       'pushup':'push up','chinup':'chin up','situp':'sit up','raises':'raise','curls':'curl','rows':'row','squats':'squat',
       'lunges':'lunge','presses':'press','extensions':'extension','flyes':'fly','flye':'fly','flies':'fly','deadlifts':'deadlift',
       'shrugs':'shrug','crunches':'crunch','dips':'dip','kickbacks':'kickback','kickback':'kickback','ez':'ez','overhead':'overhead',
       'rdl':'romanian deadlift','ohp':'overhead press','skullcrusher':'skull crusher','skullcrushers':'skull crusher',
       'lying':'lying','hyperextension':'hyperextension','pecdeck':'pec deck','glute':'glute','glutes':'glute','hamstrings':'hamstring',
       'calves':'calf','legs':'leg','wrists':'wrist','abs':'ab','v':'v'}
EQ = {'barbell':['barbell'],'cable':['cable'],'dumbbell':['dumbbell'],'smith':['smith','machine'],'band':['band'],
      'kettlebell':['kettlebell'],'bodyweight':[],'leverageMachine':['machine'],'medicineball':['medicine','ball'],
      'ezbar':['ez','bar'],'trapbar':['trap','bar']}
EQWORDS = {'barbell','cable','dumbbell','smith','band','kettlebell','machine','medicine','ez','trap','swiss','bosu','weighted','sandbag','plate','landmine','trx','suspension'}
def toks(s):
    s = re.sub(r'([a-z0-9])([A-Z])', r'\1 \2', s)
    out = []
    for w in re.split(r'[^A-Za-z0-9]+', s.lower()):
        if not w: continue
        w = SYN.get(w, w)
        out += w.split()
    return out
cands = []
for cat, v in fit.items():
    ct = set(toks(cat))
    for num, name in v['names'].items():
        if 'heelchair' in name: continue
        cands.append((cat, v['num'], int(num), name, set(toks(name)), ct))
def score(N, E, c):
    cat, cnum, nnum, name, T, ct = c
    core = len(N & T) / max(len(N), 1)
    if core == 0: return -9
    s = core * 2
    s -= 0.15 * len(T - N - set(E))
    if E and set(E) <= T: s += 0.5
    other = (T & EQWORDS) - set(E) - N
    s -= 0.45 * len(other)
    s += 0.25 * len(ct & N)
    if cnum > 32: s -= 0.5
    return s
res = {}
for ex in lifto:
    if ex['eq'] not in EQ: ex['eq'] = 'bodyweight'
    N = set(toks(ex['name']))
    out = {}
    for eq in EQ:
        E = EQ[eq]
        ranked = sorted(cands, key=lambda c: -score(N, E, c))[:3]
        out[eq] = [(round(score(N, E, c), 2), c[0], c[1], c[2], c[3]) for c in ranked]
    res[ex['id']] = {'name': ex['name'], 'eq': ex['eq'], 'm': out}
json.dump(res, open(G + '/matches.json', 'w'))
for k, v in res.items():
    b = v['m'][v['eq']]
    print(f"{k:28} {v['name'][:26]:26} {v['eq'][:8]:8} | {b[0][0]:5} {b[0][1]}/{b[0][4]}   ~ {b[1][4]}")
