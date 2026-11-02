#!/usr/bin/env bash
# Maintainer only. Usage: scripts/release.sh <version> [commit]
# Builds the Connect IQ Store package at <commit> (default HEAD), tags v<version>, and creates a GitHub
# release with the "What's new (<version>)" section of store/listing.md as its notes and the .iq attached.
set -euo pipefail
cd "$(dirname "$0")/.."
version="${1:?version, e.g. 1.1.0}"
commit="$(git rev-parse "${2:-HEAD}")"
tag="v$version"
git show "$commit:source/Config.mc" | grep -q "liftosaur-garmin/$version\"" \
    || { echo "Config.CLIENT at $commit is not $version"; exit 1; }
notes="$(git show "$commit:store/listing.md" | awk -v h="## What's new ($version)" '$0 == h { f = 1; next } /^## / { f = 0 } f')"
[[ -n "${notes//[[:space:]]/}" ]] || { echo "store/listing.md at $commit has no \"What's new ($version)\""; exit 1; }
[[ -f developer_key.der ]] || { echo "developer_key.der missing: the store package must be signed with it"; exit 1; }
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then echo "$tag already exists"; exit 1; fi

# Build from a clean checkout of that commit, so local changes can't slip into the package.
work="$(mktemp -d)"
trap 'git worktree remove --force "$work" 2>/dev/null || true' EXIT
git worktree add --detach "$work" "$commit" >/dev/null
cp developer_key.der "$work/"
(cd "$work" && scripts/package.sh > "$work/package.log" 2>&1) || { tail -20 "$work/package.log"; exit 1; }
mkdir -p bin
asset="bin/LiftosaurGarmin-$version.iq"
cp "$work/bin/LiftosaurGarmin.iq" "$asset"

git tag -a "$tag" -m "Lift Log for Liftosaur $version" "$commit"
git push -q origin "$tag"
gh release create "$tag" "$asset" --title "Lift Log for Liftosaur $version" --notes "$notes

---
Install the app from the Connect IQ Store. \`LiftosaurGarmin-$version.iq\` is the package uploaded to the store (no API key inside)."
echo "Released $tag"
