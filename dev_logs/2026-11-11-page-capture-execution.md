# 2026-11-11 — Page capture executed: grid pages, base pages by entry

- **Related plan:** [plan/2026-11-11-page-capture.md](../plan/2026-11-11-page-capture.md) (active; Tasks 1–7 done; Task 8 waits for the owner's go-ahead, and the plan stays open until then).
- **Related ADRs:** [ADR-0006](../dev_docs/decisions/0006-capture-the-page-the-figure-draws.md) (accepted; unchanged by this session).
- **Worked on by:** Yonghe Xia, Claude
- **Follows:** [2026-11-11-page-capture-adr-plan.md](2026-11-11-page-capture-adr-plan.md)

Covers Tasks 1–7. Task 8 gets its own log when it runs.

## What changed

| Commit | Task | Change |
|---|---|---|
| `19f39d7` | 1 | Grid pages: the input draws itself on gloss's svglite device; leaves wrapped in place on the forced display list; self-check `equal` / `not_deterministic` / abort. Tag `engine-route-final` on `f48c124` keeps the old route for comparison. |
| `55e9b34` | 2 | Engines on the page: ggplot draws its kept build; ComplexHeatmap keeps its drawn list; withheld tables and panels with reasons. |
| `a81cbbc` | 3 | `page_signature()` reads each top-level group once (regex), node by node only where clipping or defs nest. |
| `ebd7e2a`, `51c26d7` | 4 | Bench on the page route; development run `2026-11-11-0627`. |
| `ff0489d` | 5 | Base pages replayed entry by entry on a file svglite device; a leaf per display-list entry; base engine without gridGraphics. |
| `254bd73`, `03abb95` | 6 | Each base entry read through a fresh connection (Linux); the ggExtra test builds on a null device. |
| `9984549` | 6 | Bench judges base pages with no known exception; leaf names per figure; Task 6 predictions, committed before the run. |
| `692c6cc` | 6 | Development run `2026-11-11-0705`, archived. |
| `c20e98b`, `84abf35` | 6 | gridGraphics out of `DESCRIPTION`; `Rplots*.pdf` in `.Rbuildignore`; ggExtra declared; `p6-base-classify`. |
| `8182864` | 6 | Plan: Task 6 result. |
| `aaec8e4` | 7 | Design doc: §元素归属 rewritten for the page route; dated notes in §分类, §评测设计, §风险与未决问题, §已定事项, §与上一版的区别; `fig-capture` corrected; `p7-six-inputs`. |
| _this commit_ | 7 | NEWS, plan Task 7, this log. |

## Measured

- Suite at the start of the session: 7 files / 49 tests / 298 expectations / 0 failed / 0 skipped (`f48c124`). At the end: 7 files / 65 tests / 420 expectations / 0 failed / 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, host; the same in the bench container). The suite leaves no `Rplots.pdf`. Per-task before/after counts are in the plan.
- Fixtures (hand-built; mechanism, not coverage):
  - six inputs, page route against the tag: element tables, panels, tables and clip regions identical; verdict `equal` on six (`p1-fixtures-vs-engine-route.out`).
  - 26 base pages of s2: equal to the code's own page with clip regions, page route 26 of 26, gridGraphics 14 of 26; counted leaves 169 of 169 `ok`; data through `usr` within 0.007 pt (`p5-base-fixtures.out`).
- Time (`p3-time.out`, ggplot scatter, 5 runs): `gloss()` medians on the page route 0.12 / 0.47 / 4.08 s at 10^3 / 10^4 / 10^5 points against 0.08 / 0.29 / 3.11 s on the engine route (1.52x, 1.62x, 1.31x; limit 2x); the self-check is 0.01 / 0.05 / 0.55 s of it. 5000 base entries: 0.79 to 0.98 s.
- Development run `2026-11-11-0627` (grid step only; base still through gridGraphics then): 54 captured, 1 refused; grid 42 equal, 2 not deterministic, 0 different; base 1 equal, 5 known exceptions, 4 different; gloss and the bench agree on 44 of 44 grid pages under the Task 4 reading.
- Development run `2026-11-11-0705` (page route, base by entry; predictions in `9984549`, all held): 52 equal, 2 not deterministic, 1 refused, 0 different, 0 errors. Base 10 of 10 equal, 0 count mismatches (1469 counted leaves), median 0.15 s (`0627`: 0.36 s). gloss and the bench agree on 54 of 54 captured figures (Task 4 reading), identical on 53; 0 failed invariants.
- Classification, base figure of design §分类 (`p6-base-classify.out`): 57 of 60 elements right, 2 wrong, 1 unclassified, as through gridGraphics; 9 leaves instead of 15.
- Suite in the bench container (Linux), after `254bd73`: 7 files / 65 tests / 420 expectations / 0 failed / 0 errors / 0 skipped, as on the host.
- `R CMD check --as-cran --no-manual` (clean export, R 4.5.2, macOS, remote incoming checks off because CRAN did not answer): 1 WARNING (ggExtra undeclared), 2 NOTEs → 2 NOTEs, both from the setting.
- Not run: `R CMD check` on Linux, Windows or R-devel; recorded plots on R versions other than 4.5.2 (none installed; the owner's call); any held-out run (Task 8, needs the owner's go-ahead).

## Surprises

- **gridGraphics passed the new drawing-step contract check** on the base engine's `example()` (Task 1). It draws a function on its own transparent device; the same plot recorded on svglite differs by 1 primitive, `rect(border = 0)` by 2. A contract check on one example cannot see a renderer's differences. → plan Task 1 result; resolved by Task 5, which removed the drawing step.
- **A second ggplot build is not the drawn one when the build draws random numbers**: `position_jitter()` without a seed put 0 of 32 rows on their point in 5 of 5 runs (`p2-jitter-tables.out`). → plan scope change (Task 2): the engine draws its kept build; NEWS.
- **ggbreak's `panels()` returned nothing without a reason** and `built_layer1` was offered on the uncut scale, which M1 would have bound by count (`p2-own-print.out`). → plan scope change (Task 2): withheld with the reason; NEWS.
- **Reading the page signature node by node cost 2.5 s per page at 10^5 points.** → plan Task 3 result (one regex per top-level group). The first version of the fast path turned empty clip groups into `" |clip: ..."` entries (paste recycling); the agreement test between both reads caught it.
- **heatmap-008: gloss says `equal`, the bench says `not_deterministic`** (k-means inside `draw()`, 236 primitives between two drawings). gloss's `equal` certifies its capture against its own drawing, not that the figure draws the same page twice. → plan scope change (Task 4, agreement read accordingly); design doc dated note in Task 7 (open).
- **gallery-053 (gganimate) is refused by the ggplot engine's build check** before any page is drawn; the spike had seen an empty page. → plan Task 4 result; the refusal carries its reason, nothing else to change.
- **Base text with a multibyte character stopped the capture** (Task 5). plotmath writes alpha as U+03B1; the page was cut at byte offsets with `substr()`, which counts characters, so the split page was not well-formed and the integrity check aborted. In front of it, `base_expected()` failed on an expression label. Fixed with a test; the integrity check refused rather than captured a wrong page, as designed. → plan Task 5 result.
- **The first p5 runs measured the page route twice.** p5 got its fixtures by sourcing s2, whose first line is `load_all(".")`, so the tag's package was replaced by this checkout; the giveaway was `rect(border = 0)` equal on the "engine route", against s0's 2 primitives. Its `pairs` check also mapped disp on the mpg scale (`pairs()` fills by column), a 1383.889 pt gap. → fixed in the script; README row of p5 and plan Task 5 result. Nowhere else: a script error, not a claim about gloss. Lesson for research scripts: take fixtures by evaluating their assignment, never by sourcing a script that loads a package.

- **The base route failed on Linux, and only there.** The first bench-container check stopped every base capture on the integrity check: a file connection kept open and seeked again returned bytes from before svglite rewrote the closing tags of its always-valid file (2 of 8 entries of one plot; 0 on macOS, with the same svglite 2.2.2 and R 4.5.2). The host suite cannot see it; the container suite could (5 errors in `test-capture.R` before the fix, 0 after; full suite 65 / 420 / 0 there). → fixed in `254bd73`; plan Task 6 result. Lesson: a new reader of device output runs the suite in the container before it is called done. → nowhere else yet; Task 7 decides whether the container suite becomes a standing step in AGENTS.md.
- **A test left `Rplots.pdf` behind** (ggExtra builds grobs with no device open), and `.Rbuildignore` has no rule for it. → test fixed in `03abb95`; `.Rbuildignore` rule in `c20e98b` (the tarball built from a clean export holds no PDF).
- **The design doc claimed a fallback that never existed**: "a device without groups falls back to colour picking". The code has refused such devices since M0. Found while rewriting §元素归属. → corrected with a dated note in the design doc (§元素归属, §已定事项, §与上一版的区别).
- **The hygiene items expected from `R CMD check` were not findings**: non-ASCII comments in four files pass (the package declares UTF-8), and the `<<-` in M0 code (closures writing their own function's locals: `context-data.R`, `core-bundle.R`, `element_boxes()`) passes "R code for possible problems". AGENTS.md forbids `<<-` all the same. → nowhere yet: a small refactor outside this plan, listed under What's next.

## What's next

- **Task 8, the held-out run, needs the owner's go-ahead.** The development set meets every line of *Done when* as read after the scope changes (52 / 2 / 1 / 0 / 0; agreement 54 of 54). Before the run: predictions in `bench/predictions.md`, committed; both routes on the same held-out figures in the same container (the page route at the plan's final commit, the engine route at the tag `engine-route-final`). The development numbers suggest what to predict, but the held-out set has its own base and grid mix, so the predictions must say how much they rest on 55 figures.
- **For the owner, not done here:** (1) whether running the suite in the bench container becomes a standing step in AGENTS.md for code that reads device output (the Linux defect of Task 6 was invisible on the host); (2) whether to install other R versions to test recorded-plot formats (only R 4.5.2 here).
- **Outside this plan:** replace the M0 `<<-` (closures writing their function's locals in `context-data.R`, `core-bundle.R`, `element_boxes()`) with local environments, as AGENTS.md asks; `R CMD check` passes them, so nothing forces it.
- **M1 can start from these numbers.** The design gated M1 on the package reproducing the probe; it does. The base route gives call names and `usr` scales, so base binding (a §风险与未决问题 item) is now an M1 question about adapters, not about capture.
