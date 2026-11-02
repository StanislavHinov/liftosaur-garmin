import re, json, sys
# Usage: extract.py <sources dir with fit-sdk/profile.js and liftosaur-src/exercise.ts> <work dir>
F = sys.argv[1]; G = sys.argv[2]
prof = open(F + '/fit-sdk/profile.js').read()
def enum(name):
    m = re.search(r'\n\s*' + name + r': \{\n(.*?)\n\s*\},?\n', prof, re.S)
    if not m: return None
    return {int(k): v for k, v in re.findall(r'(\d+): "([^"]+)"', m.group(1))}
cats = enum('exerciseCategory')
fit = {}
for num, cat in cats.items():
    names = enum(cat + 'ExerciseName')
    if names: fit[cat] = {'num': num, 'names': names}
print('categories', len(cats), 'with names', len(fit), 'names', sum(len(v['names']) for v in fit.values()))
missing = [c for c in cats.values() if c not in fit]; print('no names:', missing)
ex = open(F + '/liftosaur-src/exercise.ts').read()
body = ex[ex.index('export const allExercisesList'):]
items = re.findall(r'\n  (\w+): \{\n    id: "(\w+)",\n    name: "([^"]+)",\n(?:.*?\n)*?    defaultEquipment: "?(\w+)"?,', body)
lifto = [{'id': i, 'name': n, 'eq': e} for _, i, n, e in items]
print('liftosaur exercises', len(lifto), lifto[:3])
json.dump({'fit': fit, 'cats': cats, 'lifto': lifto}, open(G + '/data.json', 'w'))
