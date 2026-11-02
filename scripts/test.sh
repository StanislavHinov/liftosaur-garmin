#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f resources-secret/secrets.xml ]] || { echo "Missing resources-secret/secrets.xml" >&2; exit 1; }
SDK="$(scripts/sdk.sh)"
# monkeyc needs Java; Homebrew openjdk@17 is keg-only and not on PATH by default
[[ -d /opt/homebrew/opt/openjdk@17/bin ]] && export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
mkdir -p bin
"$SDK/bin/monkeyc" -l 0 -d fr170 -f monkey.jungle -o bin/test.prg -y developer_key.der -t
pkill -f monkeydo || true  # an app left running in the simulator blocks the test run
pgrep -f "ConnectIQ" >/dev/null || { "$SDK/bin/connectiq" & sleep 6; }
# monkeydo exits 1 even when every test passes, so the result line decides
out="$("$SDK/bin/monkeydo" bin/test.prg fr170 -t "$@" 2>&1 || true)"
echo "$out"
# Tests and the app share one Storage in the simulator; wipe it so test fixtures never reach a real run.
rm -f "$(getconf DARWIN_USER_TEMP_DIR)com.garmin.connectiq/GARMIN/APPS/DATA/TEST."{DAT,IDX,IMT}
grep -q "^PASSED" <<< "$out"
