#!/usr/bin/env bash
# Prints the Connect IQ SDK folder chosen as current in SDK Manager.
set -euo pipefail
base="$HOME/Library/Application Support/Garmin/ConnectIQ"
if [[ -f "$base/current-sdk.cfg" ]]; then
  sdk="$(tr -d '\n' < "$base/current-sdk.cfg")"
else
  sdk="$(ls -d "$base"/Sdks/*/ | sort | tail -1)"
fi
echo "${sdk%/}"
