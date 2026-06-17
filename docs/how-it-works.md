# How this patch repo works

This document explains the moving parts of the patch repo and the design
decisions behind them. If you just want to apply the patch, see the
top-level [`README.md`](../README.md).

## Distribution shape

The repo holds a single unified-diff file (`warp.patch`) and a POSIX
shell script (`apply.sh`) that:

1. Resolves a target upstream SHA (`WARP_SHA` env, or `warp@master` HEAD
   via `git ls-remote`).
2. Clones Warp into `./warp` (or reuses an existing checkout) and checks
   out that SHA.
3. Runs `git apply --check warp.patch` — non-zero exit on textual drift.
4. Applies the patch with `git apply`.
5. Runs `cargo fmt -p warp --check`.
6. Runs `cargo test -p warp --lib custom_inference_modal_tests` — the
   new unit tests that exercise `validate_url` and its form-validity
   helper. **This is the semantic-drift check**: it catches the case
   where the diff applies cleanly but upstream renamed a function the
   patch depends on.
7. Optionally runs `./script/run` (Warp's own build script) when
   `--build` is passed.

## Why not a Cargo `[patch]` shim?

Cargo's `[patch]` table is for redirecting a dependency source. The
key is either `crates-io` or the original source URL of the dep being
overridden; the value is another dep spec (`path` / `git` / `registry`).
There is **no** form that points at a static `.patch` file.

The "tiny patch crate" shape — a `path =` override pointing at a small
crate containing just the patched files — works for libraries that can
be expressed as a single crate, but for Warp it collapses: `warp` is a
workspace *member* with hundreds of `mod` declarations and platform-
specific dependencies (Metal on macOS, AppKit, gRPC codegen via
`prost-build`). A `path =` override would have to vendor the entire
`app/` member, which is just a fork in disguise.

The patch-file + apply-script shape is the only one that:

- Doesn't vendor the whole upstream.
- Fails loudly the moment the diff stops applying (`git apply --check`).
- Fails loudly when the diff applies but symbols have been renamed
  upstream (`cargo test`).

## Why not just a fork?

A fork would mean maintaining a parallel `master` branch, rebasing onto
upstream on a schedule, and resolving every conflict in CI. For a
70-line, one-function change that's overkill: the conflict surface is
the body of `validate_url`, and the new tests. A diff-based repo
captures exactly that.

## Why a custom GitHub Action, not Dependabot?

Dependabot's `cargo` ecosystem tracks dependency versions and the
`Cargo.lock`; it does not re-validate a `[patch]` table against the
upstream source it's replacing. There is no first-class "patch drift"
updater in Dependabot-core.

The cron workflow in `.github/workflows/validate-patch.yml` is the
smallest thing that does what we need: every day, clone `warp@master`,
try to apply the patch, run the test, and on failure open an issue
labeled `stale-patch`. The maintainer is alerted without anyone
needing to babysit a rebase script.

## Failure modes

| Drift type                        | What catches it                              |
| --------------------------------- | -------------------------------------------- |
| Upstream reformats the file       | `git apply --check` (fails loudly)           |
| Upstream renames `validate_url`   | `cargo test` (compile error)                 |
| Upstream adds a new check         | `cargo test` (assertion failure)             |
| Upstream changes the public API   | `git apply --check` (fails loudly)           |
| New test breaks an old assertion  | `cargo test` (assertion failure)             |
| Linux-only build error            | `cargo test` on `ubuntu-latest`              |

`git apply --check` is necessary but not sufficient — that's why the
workflow runs the actual test, not just the apply check.

## Local development loop

To iterate on the patch itself:

```bash
# 1. Work in a local clone of warpdotdev/warp
git clone https://github.com/warpdotdev/warp.git
cd warp

# 2. Edit the two files
$EDITOR app/src/settings_view/custom_inference_modal.rs
$EDITOR app/src/settings_view/custom_inference_modal_tests.rs

# 3. Verify
cargo fmt -p warp --check
cargo test -p warp --lib custom_inference_modal_tests

# 4. Generate a fresh patch against upstream master
git fetch origin master
git diff origin/master -- app/src/settings_view/custom_inference_modal.rs \
                         app/src/settings_view/custom_inference_modal_tests.rs \
  > /path/to/warp-local-llm-endpoints/warp.patch
```

The header at the top of `warp.patch` should be updated to reflect the
new base SHA.
