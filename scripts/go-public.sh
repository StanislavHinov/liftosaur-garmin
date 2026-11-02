#!/usr/bin/env bash
# Maintainer only: makes the repo public, then turns on what GitHub allows only for public repos on a
# free account: branch protection for main and private vulnerability reporting (SECURITY.md relies on it).
set -euo pipefail
repo="${1:-StanislavHinov/liftosaur-garmin}"
read -r -p "Make $repo public? Type yes: " answer
[[ "$answer" == "yes" ]] || { echo "Stopped."; exit 1; }
gh repo edit "$repo" --visibility public --accept-visibility-change-consequences
# main: changes land through pull requests (no review needed, so a solo maintainer isn't blocked),
# linear history, no force pushes or deletion, open review threads must be resolved.
gh api -X PUT "repos/$repo/branches/main/protection" --input - <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
gh api -X PUT "repos/$repo/private-vulnerability-reporting"
gh api -X PUT "repos/$repo/automated-security-fixes" || true
echo "Public, main protected, private vulnerability reporting on."
