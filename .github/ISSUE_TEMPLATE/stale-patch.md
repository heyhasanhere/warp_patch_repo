---
name: stale-patch
about: warp.patch no longer applies cleanly to warp@master
title: "[stale-patch] warp.patch needs a rebase"
labels: stale-patch
assignees: ''
---

The daily [`validate-patch` workflow](../../actions/workflows/validate-patch.yml)
failing means this patch drifted from upstream.

## Checklist

- [ ] `git clone https://github.com/warpdotdev/warp.git`
- [ ] `cd warp && git fetch warpdotdev/warp master && git checkout FETCH_HEAD`
- [ ] Apply `warp.patch` from this repo and resolve conflicts
- [ ] `cargo fmt -p warp --check && cargo test -p warp --lib custom_inference_modal_tests`
- [ ] `./scripts/regenerate-patch.sh` to refresh `warp.patch`
- [ ] Commit & push — the next scheduled run re-validates
