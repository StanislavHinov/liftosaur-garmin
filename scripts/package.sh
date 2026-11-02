#!/usr/bin/env bash
# Builds bin/LiftosaurGarmin.iq for the Connect IQ Store: every watch in manifest.xml, release mode, no API key inside.
# Sign every version with the same developer_key.der; the store rejects updates signed with another key.
set -euo pipefail
cd "$(dirname "$0")/.."
SDK="$(scripts/sdk.sh)"
[[ -d /opt/homebrew/opt/openjdk@17/bin ]] && export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
mkdir -p bin
"$SDK/bin/monkeyc" -e -r -l 0 -f store.jungle -o bin/LiftosaurGarmin.iq -y developer_key.der "$@"
echo "Built bin/LiftosaurGarmin.iq"
