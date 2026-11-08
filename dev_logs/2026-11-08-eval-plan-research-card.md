# 2026-11-08 — Evaluation plan from a research card; idea notes rewritten

- **Related plan:** none (documentation patch; M0 is still next)
- **Related ADRs:** none changed
- **Worked on by:** Yonghe Xia, Claude

## What changed

gloss now has a written research card and an evaluation design that follows from it. M5 can no longer finish with "a publishable results table". It finishes when every claim clause is reported as holding, narrowed or failing.

**`dev_docs/design.qmd`, §testing** (heading now 测试守住每项能力，评测拿底座和同样的原始材料比)
- The offline test table is kept unchanged under its own subsection.
- New §research-card. It has five sentences: bottleneck, main claim, strongest rival explanation, decisive comparison, and falsifiers plus legacy. It also gives a Shaw classification and a table of claim clauses (`tbl-claims`), each with its contribution type, scope, validation and milestone.
- New §eval:
  - **Benchmark:** a defined population and a stratified random sample with the seed stored in `bench/`. It reports attempted vs retained counts with a failure taxonomy, and keeps a development set separate from a held-out set. It is frozen before M1. Two annotators label it, and agreement is reported.
  - **Leakage:** main results are reported on a perturbed set. A post-cutoff subset and a no-tools probe are added.
  - **Scoring:** layered (`tbl-eval-metrics`), with miss rate, false-rejection rate and coverage reported together for claim checking.
  - **Conditions** (`tbl-eval-conditions`): A, the same model with the same raw materials and an R sandbox; a 2×2 of structure × verification; C, deterministic only; D, SVG only; an anchor ablation; engineering baselines, which stay in `bench/` only.
  - **Run rules:** newest model plus an open-weight model, the same budget for every condition, at least 5 runs, paired statistics, a log of human interventions, and archived runs.
  - **Masked evaluation:** must be validated against human labels before it can replace them.
  - **Predictions:** committed to `bench/predictions.md` before running.
- New §premortem: reviewer questions, each with its current answer and a status (data / design / open).
- **The VisAnatomy comparison changed.** The published 0.692/0.959 numbers are now context only. VisAnatomy has no plotting code, so gloss cannot build a substrate on it, and the conditions would differ. Condition D re-runs the SVG-only setting on gloss's own figures with the same model.
- Milestones: M0 now includes sampling and freezing the benchmark; M5's content and completion criteria were rewritten.
- Smaller edits:
  - §classify's heading gained the qualifier 三张图上.
  - The stage callout and §risks now point to the evaluation.
  - One new risk: the substrate's advantage may only be more information.
  - Glossary row for 遮蔽评测.
  - Dated note in §changes.
  - Two pre-existing "不是…而是…" sentences (§verify callout and standing-verification paragraph) were reworded; the meaning is unchanged.

**`idea/2026-11-07-semantic-svg-prior-art.md`:**
- Now findings first: four claims, each with its measured boundary.
- Every family section follows the same order: mechanism, what we measured, where it stops.
- The literature is now a table with each work's reported result and limit. The numbers come from the research report's comparison table: ReVision 96%/71%, Poco & Heer ≥ 98%, ChartDetective 0.11%, Mystique > 85%/96%, and the 342 vs 344 penguins from Blanco et al.
- A closing note in §5 records which two lessons the design later changed.

**`idea/2026-11-07-agentic-semantic-svg.md`:**
- Added a "Reading this note" epistemic statement, the idea in one paragraph, and a "What the spikes showed" findings list.
- Risks now open with their conclusions.
- New dated section "What became of it (2026-11-08)". It covers five changes: converter to substrate; three capture candidates to group + probe (ADR-0001); every computable claim checked; verification as a standing constraint; evaluation rebuilt from the research card.

**`idea/README.md`:** index entries describe the rewritten notes.

## Why

The owner wants gloss held to journal standards. The previous evaluation plan had a benchmark, masked evaluation and ablations, but it was missing several things:
- a matched-information baseline;
- leakage control for gallery figures;
- run-to-run variance and rater agreement;
- an attempted vs retained count;
- any way to separate the substrate's contribution from the model's own ability.

Those are the gaps reviewers of comparable system papers (Paper2Agent, Nature 2026) pressed hardest. The research card puts the claims first and derives each experiment from a claim.

## Verification

- `fact_diff.py` old → new for all three changed documents: no missing numbers, code tokens, links, refs or quotes. The only "missing" items were capitalised section-label words.
- `tell_scan.py`: 0 strong tells in all four changed files. Two medium hits in the founding note are the original section name "Showcase" and the word "differentiator", both kept from the 2026-11-07 text.
- `quarto render dev_docs/design.qmd --to html`: renders. The new refs `sec-research-card`, `sec-eval`, `sec-premortem`, `tbl-claims`, `tbl-eval-metrics` and `tbl-eval-conditions` resolve. The only `?@` strings are inside bundled JS.
- Relative links and anchors in the three idea files: 0 broken.
- Removed a stray `Rplots.pdf` from the repo root, left over from an earlier spike re-run (it was untracked).

## What's next

- Open the M0 plan. It now includes sampling the benchmark, writing the sampling frame and seed to `bench/`, and freezing the held-out set.
- Before M5: write `bench/predictions.md`, the annotation rubric, and the per-condition budget caps.
- Decide after M5's main comparison whether to run the candidate domain finding (a claim audit over public R figures).
