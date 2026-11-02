#!/usr/bin/env bash
# Shows one screen with fake data in the simulator, without a Liftosaur account.
# Usage: scripts/preview.sh <rest|over|norest|hold|done|start|waiting|error|nokey|browse|prompt|edit|rpe|timed|timedwork|menu|overview|bg> [device]
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:?mode}"
device="${2:-fr170}"
SDK="$(scripts/sdk.sh)"
[[ -d /opt/homebrew/opt/openjdk@17/bin ]] && export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
out=bin/preview
rm -rf "$out" && mkdir -p "$out/source" "$out/resources-secret"
cp -R source/. "$out/source/"
cp preview/Preview.mc "$out/source/"
pos=null; [[ "$mode" == "browse" ]] && pos="[0, 1]"
printf 'import Toybox.Lang;\nmodule PreviewMode { const MODE = "%s"; const POS = %s; }\n' "$mode" "$pos" > "$out/source/PreviewMode.mc"
# The simulator opens apps with a glance in glance mode; previews go straight to the app.
python3 -I - "$out/source/LiftosaurApp.mc" <<'PY'
import sys, re
p = sys.argv[1]; t = open(p).read()
t = re.sub(r"    function getGlanceView\(\) \{.*?\n    \}\n", "", t, flags=re.S)
open(p, "w").write(t)
PY
# browse: open the set screen on a logged set
sed -i '' 's/    var _pos = null;/    var _pos = PreviewMode.POS;/' "$out/source/ui/ActiveSetView.mc"
# Boot from fake data; never reach liftosaur.com; separate app id so real app storage stays untouched.
sed -i '' 's/    function boot() {/    function boot() {\n        if (Preview.boot(self)) { return; }/' "$out/source/Controller.mc"
# PREVIEW_URL points the bg preview at a local fake server.
sed -i '' "s#https://www.liftosaur.com/api/v1#${PREVIEW_URL:-https://preview.invalid}#" "$out/source/Config.mc"
sed -e "s/id=\"[0-9a-f]*\" type=\"watch-app\"/id=\"0000000000000000000000000000beef\" type=\"watch-app\"/" -e "/<iq:product id=/d" -e "s#<iq:products>#<iq:products><iq:product id=\"$device\"/>#" manifest.xml > "$out/manifest.xml"
printf '<strings>\n    <string id="ApiKey" scope="background">lftsk_preview</string>\n</strings>\n' > "$out/resources-secret/secrets.xml"
printf 'project.manifest = manifest.xml\nbase.sourcePath = source\nbase.resourcePath = %s/resources;resources-secret\n' "$PWD" > "$out/monkey.jungle"
"$SDK/bin/monkeyc" -l 0 -d "$device" -f "$out/monkey.jungle" -o "$out/preview.prg" -y developer_key.der
pgrep -f "ConnectIQ" >/dev/null || { "$SDK/bin/connectiq" >/dev/null 2>&1 & sleep 6; }
"$SDK/bin/monkeydo" "$out/preview.prg" "$device" > "$out/run.log" 2>&1 &
echo "Running $mode on $device; log in $out/run.log"
