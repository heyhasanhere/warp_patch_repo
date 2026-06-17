#!/usr/bin/env bash
# Regenerate warp.patch from a fresh upstream Warp checkout. Use this when
# the daily validate-patch workflow reports that the patch no longer
# applies.
#
# Workflow:
#   1. Fetch upstream master.
#   2. Check out a clean working tree.
#   3. Manually re-apply (or copy over) the changes from the current
#      warp.patch and resolve any conflicts.
#   4. Run this script to overwrite warp.patch with a fresh diff.
#
# Usage: ./scripts/regenerate-patch.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORK="${WARP_REGEN_DIR:-${REPO_DIR}/.regen-warp}"

if [[ ! -d "${WORK}/.git" ]]; then
  echo "Cloning warpdotdev/warp into ${WORK}…"
  rm -rf "$WORK"
  git clone --quiet https://github.com/warpdotdev/warp.git "$WORK"
fi

(cd "$WORK" && git fetch --quiet origin master && git checkout --quiet FETCH_HEAD)
RESOLVED_SHA="$(git -C "$WORK" rev-parse HEAD)"

echo ""
echo "warp is at ${RESOLVED_SHA}"
echo ""
echo "Next steps:"
echo "  1. cd ${WORK}"
echo "  2. Re-apply the changes from the current warp.patch"
echo "     (or copy the existing patched files over from a known-good tree)"
echo "  3. Resolve any conflicts"
echo "  4. cd ${REPO_DIR} && $0 --write"
echo ""
echo "Or pass --write from inside ${WORK} after the patched files are in place:"
echo "  cd ${WORK} && ${REPO_DIR}/scripts/regenerate-patch.sh --write"

if [[ "${1:-}" == "--write" ]]; then
  cd "$WORK"
  # Only diff the two files we own.
  git add app/src/settings_view/custom_inference_modal.rs \
           app/src/settings_view/custom_inference_modal_tests.rs
  git diff --cached -- app/src/settings_view/custom_inference_modal.rs \
                          app/src/settings_view/custom_inference_modal_tests.rs \
    > "${REPO_DIR}/warp.patch.tmp"

  {
    echo "# Patch to warpdotdev/warp: allow http URLs to loopback hosts in custom AI endpoint settings"
    echo "# Base: ${RESOLVED_SHA} (warp@master)"
    echo "# Patched: regenerated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# License: AGPL-3.0-or-later (inherited from warpdotdev/warp)"
    echo "#"
    cat "${REPO_DIR}/warp.patch.tmp"
  } > "${REPO_DIR}/warp.patch"
  rm -f "${REPO_DIR}/warp.patch.tmp"
  echo "warp.patch rewritten for warp@${RESOLVED_SHA}"
  echo "Verify with: ./apply.sh"
fi
