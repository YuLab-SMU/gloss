# 2026-11-10 — Capture fidelity: silent wrong figures are now refused

- **Related plan:** [plan/2026-11-09-bench-v0.md](../plan/2026-11-09-bench-v0.md) (active; Tasks 1–6 and the fidelity slice done, Task 7 open)
- **Related ADRs:** none. The refusal is a verification rule, cheap to reverse; the corrected definition of success is a design-doc note, not a new mechanism.
- **Worked on by:** Yonghe Xia, WorkBuddy
- **Follows:** [2026-11-10-bench-capture-dev.md](2026-11-10-bench-capture-dev.md)

## What changed

| Commit | Files | Change |
|---|---|---|
| `efe9936` | `R/core-substrate.R`, `tests/testthat/test-capture.R`, `man/gloss.Rd`, `NEWS.md` | `gl_capture()` refuses an object whose `print()` dispatches to a method that is not a standard draw the engines follow. Test fails before the fix (2 failures), passes after. |
| `1b22fe1` | `bench/R/runner.R`, `capture.R`, `score-capture.R`, `check-runner.R` | Strict `faithful` is kept; a new `verdict` (equal / known_exception / different) is proved from the diff. Records differing primitives, which leaves mismatch, rasterized leaf counts; `check-runner.R` Part 1f checks the classifier directly, with two mutation cases. |
| docs commit | `bench/runs/2026-11-10-1424-capture-dev.*`, plan, design doc, this log | Development-set rerun, archived; results routed. |

A known exception has to be proved by the diff: exactly one extra `rect` in the scene and nothing missing (gridGraphics' `graphics-background`), or at least one leaf rasterized by design. Anything else stays `different`. No tolerance was widened and no figure was dropped.

## Measured

- Suite before → after: `NOT_CRAN=true Rscript -e "devtools::test()"`: 7 files / 47 tests / **276 → 280 expectations**, 0 failed, 0 skipped (16.8 s → 16.5 s). `test-capture.R` alone: 75 → 79 expectations; with the fix reverted it fails 2 (`gloss(custom)` and `gloss(ggExtraPlot)` did not throw).
- `Rscript bench/R/check-runner.R`: **runner check: OK**, including new Part 1f. Pure classifier cases: equal → equal; rasterized leaf → known_exception; one background rect → known_exception; **two extra primitives → different**; **extra rect plus one missing → different**. End-to-end: faceted ggplot equal (mismatch leaves named), base known_exception (1 primitive), 12000-point ggplot known_exception (1 rasterized leaf).
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev` (4 m 03 s, commit `1b22fe1`, image digest `359702d4…`, 55 development figures, `bench/runs/2026-11-10-1424-capture-dev.csv/.json`): **51 captured, 3 refused, 1 error, 0 timeouts, 0 rerun failures**. By engine, captured: base 10/10, ggplot 30/32, grid 2/4, heatmap 3/3, patchwork 6/6. The three refusals are all `refused: custom print method`: gallery-052 (`ggExtraPlot`), exts-018 (`ggcut`), gallery-053 (`gganim`). gallery-056 (treemap) is still the `grid.grab()` scene grid cannot draw. This run is **made after looking**; it does not replace the scored run `2026-11-10-1131` and is not a test of predictions 5–8.
- Fidelity verdicts among the 51 captured (`Rscript bench/R/score-capture.R bench/runs/2026-11-10-1424-capture-dev.csv`): **40 equal, 6 known_exception, 5 different**. Per engine, equal/known/different: base 1/5/4, ggplot 28/1/1, grid 2/0/0, heatmap 3/0/0, patchwork 6/0/0. With the corrected definition, 46/51 = 90% of captured figures (46/55 = 84% of all development figures) are accounted for as faithful.
- Known exceptions: five base figures with exactly one extra background rect (gallery-021, -023, -040, -058, bioc-009) and one rasterized dense leaf (exts-022: 12347 primitives in the reference, 94 in the scene).
- Still `different`, with the primitives recorded: gallery-008 (17), gallery-013 (3), gallery-038 (3), gallery-059 (5), bioc-004 (34).
- Which leaves mismatch: **34/51 = 67%** of captured figures have at least one `count_mismatch` leaf, and the run now names them. ggplot mismatches are almost all `panel.grid.major.x/y` polylines (e.g. gallery-001 L004/L005); base ones are `xlab`/`ylab`/`points` leaves of gridGraphics' replay. Prediction 7's "tells us little" is resolved on the development set.
- Not run: the held-out set (rules say it runs only after the success definition is settled); a root-cause fix inside gridGraphics or ggrepel; gloss-side self-verification (drawing `print(x)` and comparing inside `gloss()`); a per-figure rerun to test whether gallery-059's label positions vary on every draw.

## Surprises

- **The wrong-figure bug was not in the ggplot engine.** `ggExtra::ggMarginal()` returns a `ggExtraPlot` that is a **gtable**, so gloss dispatched it to the grid engine; `build_ggplot()` never saw it. → the check had to go in `gl_capture()` (plan Task 8, design §评测设计 note). The container's NAMESPACE files confirmed both real cases: `S3method(print,ggcut)` in ggbreak, `S3method(print,ggExtraPlot)` in ggExtra; gghighlight registers no print method.
- **The refusal reason for gganimate changed.** It is now `refused: custom print method` (`print.gganim`) instead of `refused: not a static ggplot` (its `ggplot_build()` result). Both are honest refusals with a reason; the existing test still covers the synthetic build-only case. → recorded here and in `NEWS.md`; no test was weakened.
- **"Capture rate" did not move: 51/55 before and after.** What moved is the composition: two figures that had been counted as successes (ggbreak, ggExtra) are now explicit refusals, and 46 figures have a proved fidelity verdict. The rate is not a fidelity metric. → design §评测设计 dated note; plan scope change.
- **Two of the four "base figures differing by more than the background" are a style difference, not a moved figure.** gallery-013 and -038 differ by one extra background rect plus one plot-region rect at identical geometry whose `stroke` is `none` in the scene and `#FFFFFF` in the page the code drew. gallery-008 has rotated axis texts at different translate positions and bioc-004 has points ~195 px away (y 124 vs 319). These are recovery-level differences in gridGraphics' replay, diagnosed from the recorded primitives, not fixed. → design §风险与未决问题, plan scope change.
- **gghighlight's label randomness is now observed, not guessed.** gallery-059's differing primitives are a `line`, a `polygon` and a `text` that moved together (from x≈462–470,y≈59 to x≈484–493,y≈40): a label with its leader line laid out again on the second draw. → design §风险与未决问题.
- **The bench, not gloss, is what knows a figure was drawn differently.** `gloss()` has no reference page; it refuses custom print dispatch but cannot detect gridGraphics' replay differences or draw-time randomness. → design §风险与未决问题; owner decision before M1 (see What's next).

## What's next

- Owner decision: treat the 5 `different` figures as recorded recovery limits (exclude them from "faithful success", keep the verdicts), or invest in gloss-side self-verification (draw the object's own `print()` output on a second device and compare) — that would be an architectural change and needs an ADR. M1 waits for this decision.
- Plan Task 7: the remaining design-doc notes (frame actually used, two era environments, data out of git) and M0 Task 9.
- Held-out set: only after the definition of success is settled, with the rules and scorer fixed first.
