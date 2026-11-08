# 2026-11-08 — Project bootstrap: gloss moves out of ggai

- **Related plan:** none yet (M0 is next)
- **Related ADRs:** [ADR-0001](../dev_docs/decisions/0001-capture-by-group-delimiting-and-probes.md), [ADR-0002](../dev_docs/decisions/0002-semantic-substrate-with-append-only-records.md), [ADR-0003](../dev_docs/decisions/0003-plugin-based-core.md); [ggai ADR-0004](https://github.com/YuLab-SMU/ggai/blob/main/dev_docs/decisions/0004-semantic-figure-substrate-as-standalone-package.md) (standalone package)
- **Pre-history (in ggai):** [2026-11-07 log](https://github.com/YuLab-SMU/ggai/blob/main/dev_logs/2026-11-07-semantic-svg-prior-art.md) (idea, prior-art survey, report, capture spikes, first design), [2026-11-08 log](https://github.com/YuLab-SMU/ggai/blob/main/dev_logs/2026-11-08-semsvg-decisions.md) (settled decisions, rename, migration); ggai commits `09809e5`, `30db86d`
- **Worked on by:** Yonghe Xia, Claude

## What happened

**Name.** The working name `semsvg` was dropped: it isn't friendly, and it ties the package to one output format although SVG is now only a projection. The owner chose **gloss**, after medieval manuscript glosses: notes anchored to particular words, added by many readers over time, with the text left untouched. The public API is `gloss()` to build a figure and `gl_*` for everything else. Before choosing, `gloss` was checked: free on CRAN and Bioconductor, never in the CRAN archive, no same-named R repo on GitHub.

**Moved from ggai** (path in ggai → path here):

| ggai | gloss |
|---|---|
| `dev_docs/semsvg-package-design.qmd` | `dev_docs/design.qmd` |
| `dev_docs/semantic-svg-research-report.qmd` | `dev_docs/research-report.qmd` |
| `dev_docs/semantic-svg-research/` (311 files) | `dev_docs/research/` |
| `dev_docs/figures/semantic-svg/` | `dev_docs/figures/` |
| `idea/2026-11-07-agentic-semantic-svg.md`, `idea/2026-11-07-semantic-svg-prior-art.md` | `idea/` |

**Renamed throughout:** `semsvg` → `gloss`, `sem_*` → `gl_*`, `sem_figure()` → `gloss()`, `fig.semsvg` → `fig.gloss`, `data-sem-path` → `data-gloss-path`, `sem-overlay` → `gloss-overlay`. In the capture spikes the probe class and grob names are now `gloss_probe`, `gloss.probe.*` and `gloss.wrap.*`, and the scratch directory is `/tmp/gloss_spike/`.

**History notes, not rewrites.** The idea docs, the research report and the archive README were written while the work was incubated in ggai, so "ggai" there means the host package at the time. Each got a short note saying so; the text otherwise stays as researched. Links to records that stay in ggai (the closed plan, ADR-0004, the dev logs) point to ggai on GitHub.

**Design doc additions:** where the name comes from, the `gloss()` entry point in the capture section, the package-name and repository rows of the decisions table, and links to the new ADRs.

**New project files:** README, AGENTS.md (structure, workflow, the nine design principles, the prior-art rule, `gloss()` / `gl_*` naming, safety), DESCRIPTION (R >= 4.2, no Imports yet), MIT license, NEWS.md, `.Rbuildignore`, `.gitignore`, and indexes for `dev_docs/`, `decisions/`, `plan/` and `idea/`.

**ADRs:**
- 0001: capture by graphics-group delimiting plus probes. This is the capture decision the closed ggai plan had reserved ADR-0004 for.
- 0002: a long-lived substrate with append-only, anchored records.
- 0003: plugin-based core.

## Verification

- Relative links: `python3 -I /tmp/gloss_tools/linkcheck.py ~/Projects/gloss`. 0 broken, plus one false positive inside inline code in `research/reports/translation-canvasxpress-plotly.md`.
- Spikes re-run after the rename, from `/tmp`: `Rscript dev_docs/research/capture-groups/probe.R` (no probe output in the SVG) and `groups.R` (134 drawn primitives, identical drawn sequence: TRUE).
- `quarto render dev_docs/design.qmd --to html` and `quarto render dev_docs/research-report.qmd --to html`: no warnings, no unresolved cross-references, all report figures embedded.
- Leftover names: `grep -rnE 'semsvg|\bsem_|\bsem-' --include='*.md' --include='*.qmd' --include='*.R' .` finds only this log, the history notes and the decisions table, which mention `semsvg` deliberately.

## What's next

- ~~Decide where the repository lives on GitHub, then add the remote.~~ Done: [YuLab-SMU/gloss](https://github.com/YuLab-SMU/gloss), public like ggai.
- Open the M0 plan: plugin registry and contract tests, substrate capture (ADR-0001), row-key inference and `gl_key()`, context sniffing, bundle read/write with the single-file round trip.
- Spike first: context sniffing for code (srcref, knitr chunk, call) and the single-file round trip.
