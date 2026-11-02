#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f resources-secret/secrets.xml ]] || { echo "Missing resources-secret/secrets.xml. Copy secrets.example.xml and add your API key." >&2; exit 1; }
SDK="$(scripts/sdk.sh)"
# monkeyc needs Java; Homebrew openjdk@17 is keg-only and not on PATH by default
[[ -d /opt/homebrew/opt/openjdk@17/bin ]] && export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
mkdir -p bin
# Type checking is off (-l 0): the code is untyped Monkey C.
"$SDK/bin/monkeyc" -l 0 -d fr170 -f monkey.jungle -o bin/LiftosaurGarmin.prg -y developer_key.der "$@"
echo "Built bin/LiftosaurGarmin.prg"
