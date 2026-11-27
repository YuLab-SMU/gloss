# gloss Project Map (LikeC4 + Live Alignment Probe)

This directory lives on the `site` branch and maintains the live **Architecture & Alignment Map** for `gloss`, automatically built against `main` and published to the `gh-pages` branch on every push to `main` or `site`.

## How It Stays Aligned with Code

| File | Maintained By | Purpose |
| --- | --- | --- |
| `model/00-spec.c4` | Human / PR | LikeC4 element kinds, status colors, and tags (`#implemented`, `#planned`, `#drift`, `#guardrail_pass`, `#guardrail_fail`) |
| `model/10-intent.c4` | Human / PR | Canonical design intent from `AGENTS.md` and `dev_docs/architecture.md` (5 principles, 8 APIs, 7 modules, 5 engines, open contracts, outer ecosystem) |
| `model/20-views.c4` | Human / PR | Interactive drill-down views with dynamic status coloring |
| `model/90-live-status.c4` | **Auto-generated** (`build_map.R`) | `extend` overlay injecting live implementation status, LOC, test results, guardrail verdicts, and GitHub source links |
| `status.json` | **Auto-generated** (`build_map.R`) | Machine-readable alignment snapshot (also published to `gh-pages/status.json`) |

## Local Commands

```bash
# 1. Refresh live status & run unit tests against a checkout of the `main` branch
Rscript project-map/build_map.R --repo-dir /path/to/gloss-main --run-tests

# 2. Launch interactive LikeC4 local dev server
npx --yes likec4@latest start project-map/model

# 3. Build static GitHub Pages bundle locally
npx --yes likec4@latest build --base "/gloss/map/" --use-hash-history --title "gloss Project Map" -o project-map/dist project-map/model
```
