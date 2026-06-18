# Graph Report - .  (2026-06-17)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 26 nodes · 16 edges · 12 communities (3 shown, 9 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `803a3ecf`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]

## God Nodes (most connected - your core abstractions)
1. `validate-patch workflow` - 6 edges
2. `warp.patch` - 3 edges
3. `custom_inference_modal_tests.rs` - 2 edges
4. `validate_url` - 2 edges
5. `How this patch repo works` - 2 edges
6. `cargo test -p warp --lib custom_inference_modal_tests` - 2 edges
7. `apply.sh script` - 1 edges
8. `init-repo.sh script` - 1 edges
9. `regenerate-patch.sh script` - 1 edges
10. `apply.sh` - 1 edges

## Surprising Connections (you probably didn't know these)
- `validate-patch workflow` --calls--> `cargo test -p warp --lib custom_inference_modal_tests`  [EXTRACTED]
  .github/workflows/validate-patch.yml → README.md
- `validate-patch workflow` --calls--> `cargo fmt -p warp --check`  [EXTRACTED]
  .github/workflows/validate-patch.yml → README.md
- `validate-patch workflow` --calls--> `git apply --check`  [EXTRACTED]
  .github/workflows/validate-patch.yml → README.md
- `cargo test -p warp --lib custom_inference_modal_tests` --implements--> `Semantic Drift Check`  [INFERRED]
  README.md → docs/how-it-works.md
- `How this patch repo works` --references--> `warp.patch`  [EXTRACTED]
  docs/how-it-works.md → README.md

## Import Cycles
- None detected.

## Communities (12 total, 9 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.33
Nodes (6): cargo fmt -p warp --check, peter-evans/create-issue-from-file@v5, failure.md, git apply --check, stale-patch issue template, validate-patch workflow

### Community 1 - "Community 1"
Cohesion: 0.50
Nodes (4): How this patch repo works, apply.sh, custom_inference_modal.rs, warp.patch

### Community 2 - "Community 2"
Cohesion: 0.67
Nodes (3): custom_inference_modal_tests.rs, is_loopback_host, validate_url

## Knowledge Gaps
- **17 isolated node(s):** `apply.sh script`, `init-repo.sh script`, `regenerate-patch.sh script`, `warpdotdev/warp`, `Ollama` (+12 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `validate-patch workflow` connect `Community 0` to `Community 4`?**
  _High betweenness centrality (0.067) - this node is a cross-community bridge._
- **Why does `warp.patch` connect `Community 1` to `Community 2`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **Why does `custom_inference_modal_tests.rs` connect `Community 2` to `Community 1`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **What connects `apply.sh script`, `init-repo.sh script`, `regenerate-patch.sh script` to the rest of the system?**
  _17 weakly-connected nodes found - possible documentation gaps or missing edges._