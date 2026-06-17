#!/usr/bin/env bash
# One-shot helper to create the GitHub repo and push the initial commit.
#
# Usage:
#   GH_REPO=<owner>/<name> ./init-repo.sh
#
# Examples:
#   GH_REPO=falcon/warp-local-llm-endpoints ./init-repo.sh
#
# Prerequisites:
#   - gh CLI authenticated
#   - run from the repo root (i.e. the directory containing this script)
#
# The repo is created as public so the daily validation workflow is free
# (private repos on free GitHub plans get 2,000 min/month, public repos
# are unlimited).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ -z "${GH_REPO:-}" ]]; then
  echo "GH_REPO=<owner>/<name> is required, e.g." >&2
  echo "  GH_REPO=falcon/warp-local-llm-endpoints $0" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install from https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Not authenticated with gh. Run 'gh auth login' first." >&2
  exit 1
fi

# Ensure we have a local git repo with an initial commit before invoking
# `gh repo create --source=. --push`, which requires a git working tree.
if [[ ! -d .git ]]; then
  echo "Initializing local git repo on main…"
  git init -q -b main
fi
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add -A
  git commit -q -m "Initial commit: local LLM endpoint patch for warpdotdev/warp"
fi

if gh repo view "$GH_REPO" >/dev/null 2>&1; then
  echo "Repo $GH_REPO already exists. Skipping creation; just pushing." >&2
  CREATED=0
else
  echo "Creating public repo $GH_REPO..."
  gh repo create "$GH_REPO" --public --description "Patch: allow http://localhost in Warp's Custom Endpoint modal" --source=. --remote=origin --push
  CREATED=1
fi

if [[ "$CREATED" == "0" ]]; then
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${GH_REPO}.git"
  git push -u origin main
fi

echo ""
echo "Done. Repo: https://github.com/${GH_REPO}"
echo "Validate the workflow by running 'gh workflow run validate-patch.yml -R ${GH_REPO}' once."
