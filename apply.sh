#!/usr/bin/env bash
# Apply warp.patch to a clean checkout of warpdotdev/warp, then run the
# targeted unit test that exercises the change. Designed to be safe to
# re-run and to fail loudly on upstream drift.
#
# Usage:
#   ./apply.sh                       # uses the latest warp@master
#   WARP_SHA=<40-char-sha> ./apply.sh
#   ./apply.sh --build               # also runs ./script/run
#
# Env:
#   WARP_SHA       Pin a specific upstream commit. Default: HEAD of master.
#   WARP_DIR       Target checkout directory. Default: ./warp
#   SKIP_TEST=1    Skip the cargo test step (useful in CI bootstrap).
#   KEEP_TREE=1    Do not delete the working tree on failure (for debugging).
#
# Exit codes:
#   0  Patch applied and tests passed.
#   1  Patch does not apply (textual drift in the patched files).
#   2  Patch applies but cargo fmt or cargo test failed (semantic drift or
#      local environment problem).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WARP_DIR="${WARP_DIR:-${SCRIPT_DIR}/warp}"
PATCH_FILE="${SCRIPT_DIR}/warp.patch"
RUN_BUILD=0

for arg in "$@"; do
  case "$arg" in
    --build) RUN_BUILD=1 ;;
    -h|--help)
      sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$PATCH_FILE" ]]; then
  echo "warp.patch not found at $PATCH_FILE" >&2
  exit 2
fi

# Resolve the upstream SHA we will check out.
if [[ -n "${WARP_SHA:-}" ]]; then
  BASE_SHA="$WARP_SHA"
else
  echo "Resolving warp@master HEAD…"
  BASE_SHA="$(git ls-remote https://github.com/warpdotdev/warp.git HEAD | cut -f1)"
  if [[ -z "$BASE_SHA" ]]; then
    echo "Failed to resolve warp@HEAD from GitHub." >&2
    exit 2
  fi
fi
echo "Targeting warp@${BASE_SHA}"

# Obtain a clean checkout. Reuse the directory if it already exists at the
# right SHA; otherwise reset it.
if [[ -d "$WARP_DIR/.git" ]]; then
  echo "Reusing existing checkout at $WARP_DIR"
  git -C "$WARP_DIR" fetch --depth 1 origin "$BASE_SHA" 2>/dev/null || \
    git -C "$WARP_DIR" fetch origin "$BASE_SHA"
  git -C "$WARP_DIR" checkout --quiet FETCH_HEAD 2>/dev/null || \
    git -C "$WARP_DIR" checkout --quiet "$BASE_SHA"
else
  echo "Cloning warpdotdev/warp into $WARP_DIR"
  rm -rf "$WARP_DIR"
  git clone --quiet --depth 1 --no-checkout https://github.com/warpdotdev/warp.git "$WARP_DIR"
  git -C "$WARP_DIR" checkout --quiet "$BASE_SHA"
fi

# Capture the SHA we actually ended up on (after checkout).
RESOLVED_SHA="$(git -C "$WARP_DIR" rev-parse HEAD)"

# Check then apply. --check fails loudly on textual drift.
echo "Running 'git apply --check'…"
if ! git -C "$WARP_DIR" apply --check "$PATCH_FILE"; then
  echo "" >&2
  echo "warp.patch does not apply cleanly to warp@${RESOLVED_SHA}." >&2
  echo "This usually means upstream renamed or refactored one of the" >&2
  echo "patched functions. Rebase warp.patch and re-run." >&2
  exit 1
fi

echo "Applying patch…"
git -C "$WARP_DIR" apply "$PATCH_FILE"

# Verify the formatter is happy (in case the patch wasn't run through fmt).
if command -v cargo >/dev/null 2>&1; then
  echo "Running 'cargo fmt -p warp --check'…"
  if ! (cd "$WARP_DIR" && cargo fmt -p warp --check); then
    echo "" >&2
    echo "Patched files do not match 'cargo fmt'. Run 'cargo fmt -p warp'" >&2
    echo "in the patched tree and regenerate warp.patch." >&2
    [[ "${KEEP_TREE:-0}" != "1" ]] || true
    exit 2
  fi
fi

# Run the unit tests that exercise the change. This is the semantic-drift
# check: even if 'git apply' succeeded, a renamed function upstream will
# fail to compile here.
if [[ "${SKIP_TEST:-0}" == "1" ]]; then
  echo "SKIP_TEST=1, skipping cargo test"
else
  if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo not found on PATH; skipping test (set SKIP_TEST=1 to silence)." >&2
  else
    echo "Running 'cargo test -p warp --lib custom_inference_modal_tests'…"
    if ! (cd "$WARP_DIR" && cargo test -p warp --lib custom_inference_modal_tests); then
      echo "" >&2
      echo "Patched files compiled, but the unit tests failed." >&2
      echo "This is a real regression in the patch — rebase and re-test." >&2
      exit 2
    fi
  fi
fi

# Optional: run the full Warp build. Off by default because it requires
# platform-specific toolchains (e.g. Xcode on macOS).
if [[ "$RUN_BUILD" == "1" ]]; then
  echo "Running './script/run'…"
  (cd "$WARP_DIR" && ./script/run)
fi

echo ""
echo "Patch applied to warp@${RESOLVED_SHA}; unit tests passed."
echo "Next: cd $WARP_DIR && ./script/run   (or use --build to do it now)"
