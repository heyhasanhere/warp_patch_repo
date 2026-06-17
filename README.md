# warp-local-llm-endpoints

A patch against [warpdotdev/warp](https://github.com/warpdotdev/warp) that lets
Warp's Custom Endpoint settings modal accept `http://localhost` URLs, so you
can point Warp at locally-running OpenAI-compatible servers such as
[Ollama](https://ollama.com) behind a [LiteLLM](https://github.com/BerriAI/litellm)
proxy.


## What the patch does

---
1. warp.patch:
A text file in unified-diff format.
Describes changes to be made in two files inside warp's source:
- app/src/settings_view/custom_inference_modal.rs
        This function decides whether a URL is valid.
        In this, `is_loopback_host` helper is added which chages `validate_url` to allow local urls.
- app/src/settings_view/custom_inference_modal_tests.rs
	New test file 
	To test whether all behaviour is working properly or not.

2. apply.sh	
- given a commit-hash, downloads Warp's source code at that exact commit
- Try to apply the patch with git apply --check first — this is a dry run. 
	- If Warp's code has changed enough that the diff no longer lines up with the surrounding text, then it shows fail message.

---
The Custom Endpoint modal in **Settings → AI** currently rejects any URL
that is not a public HTTPS endpoint. The patch relaxes
`validate_url` in `app/src/settings_view/custom_inference_modal.rs` to
accept `http` **only** when the host is a loopback address
(`localhost`, `127.0.0.0/8`, `::1`).

- Allowed after patching:
  - `http://localhost:11434`
  - `http://127.0.0.1:11434`
  - `http://[::1]:11434`
  - `https://api.openai.com/v1` (unchanged)
- Still blocked (unchanged from upstream):
  - `http://api.example.com` (public host over http)
  - `http://192.168.1.10:11434` (private/LAN host over http)
  - `https://10.0.0.1/v1` (private host over https)
  - `ftp://`, `file://`, `ws://`, malformed URLs

See [`warp.patch`](./warp.patch) for the full diff (~70 lines across two
files).

## How to consume

You need `git`, `cargo`, and (for the full build) the platform toolchain
described in Warp's `WARP.md` — on macOS, that's the Xcode Command Line
Tools; on Linux, the standard build essentials plus `protobuf-compiler`.

```bash
# 1. Clone this repo (which contains warp.patch and apply.sh)
git clone https://github.com/heyhasanhere/warp-local-llm-endpoints.git
cd warp-local-llm-endpoints

# 2. Apply the patch to a fresh warp@master checkout and run the test
./apply.sh
#   Patch applied to warp@<sha>; unit tests passed.

# 3. Build and run Warp
cd warp && ./script/run
```

To pin to a specific upstream commit (recommended for reproducible
builds), set `WARP_SHA`:

```bash
WARP_SHA=466d1856c1bc1824e8680ce77436691d1b4977bf ./apply.sh
```

The pinned SHAs are recorded at the top of [`warp.patch`](./warp.patch).

## Tracking upstream

A daily GitHub Actions workflow (`.github/workflows/validate-patch.yml`)
re-applies the patch against `warp@master` and runs the unit tests. The
workflow badge at the top of this README reflects the most recent run:

- ✅ green → the patch is current and applies cleanly
- ❌ red → upstream has drifted; an issue has been opened with the
  `stale-patch` label. Run `./scripts/regenerate-patch.sh` to rebase.

## When the patch is stale

```bash
# 1. In a clean directory, fetch the latest warp
git clone https://github.com/warpdotdev/warp.git
cd warp && git fetch origin master && git checkout FETCH_HEAD

# 2. Apply the current warp.patch and fix any conflicts
git apply /path/to/warp-local-llm-endpoints/warp.patch

# 3. Re-verify locally
cargo fmt -p warp --check
cargo test -p warp --lib custom_inference_modal_tests

# 4. Refresh warp.patch
/path/to/warp-local-llm-endpoints/scripts/regenerate-patch.sh --write

# 5. Commit and push
git add warp.patch
git commit -m "Rebase onto warp@<new-sha>"
git push
```

The next scheduled workflow run will go green.

## Why a patch file, not a fork or a `[patch.crates-io]` shim?

Warp is a Cargo workspace. The crate being patched (`warp`, in `app/`) is a
workspace *member*, not a published crate, and re-exports a few hundred
`mod` declarations plus platform-specific dependencies (Metal shaders on
macOS, AppKit bindings, etc.). A `path =` override would have to vendor
the entire member — basically a fork with extra steps. Cargo's `[patch]`
table can only point at another crate source (`path` / `git` /
`registry`); it cannot point at a static `.diff` file. A unified-diff
patch + apply script is the simplest shape that gives a **loud, immediate
signal** on upstream drift.

See [`docs/how-it-works.md`](./docs/how-it-works.md) for the full
rationale.

## License

This patch is a derivative work of [warpdotdev/warp](https://github.com/warpdotdev/warp).
The patched code is licensed under the same terms as the upstream files
it modifies:

- The bulk of the Warp codebase is licensed under **AGPL-3.0** — see
  [`LICENSE-AGPL`](./LICENSE-AGPL).
- The `warpui_core` and `warpui` crates are dual-licensed under
  **MIT** — see [`LICENSE-MIT`](./LICENSE-MIT).
- The patch itself (`warp.patch`, `apply.sh`, the workflow YAML, and
  this README) is original to this repository and licensed under
  AGPL-3.0-or-later to match the inherited work.

If you distribute a binary built from the patched Warp tree, the AGPL
obligations on the binary apply — see §5 of [`LICENSE-AGPL`](./LICENSE-AGPL).
