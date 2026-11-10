# 2026-11-10 — Why captures differ, and a spike that captures the page instead

- **Related plan:** [plan/2026-11-09-bench-v0.md](../plan/2026-11-09-bench-v0.md) (active; Task 7 open; M1 waits for the owner's decision on capture)
- **Related ADRs:** none written. The proposal in [idea/2026-11-10-page-capture.md](../idea/2026-11-10-page-capture.md) would need one (it touches ADR-0001 and ADR-0004).
- **Worked on by:** Yonghe Xia, Claude
- **Follows:** [2026-11-10-capture-fidelity.md](2026-11-10-capture-fidelity.md)

## What changed

| Commit | Files | Change |
|---|---|---|
| `4f8abe4` | `R/core-substrate.R`, `tests/testthat/test-capture.R`, `helper-figures.R`, `NEWS.md` | A `clipGrob` is left in place instead of being wrapped as a leaf; the tests compare clip regions as well as primitives. |
| research commit | `dev_docs/research/capture-fidelity/` (10 scripts with outputs, README), `bench/runs/2026-11-10-{1653,1722,1731}-page-capture-spike-dev.csv` | Root causes of the development-set differences; a spike of page capture on hand-built cases and on the 55 development figures. |
| records commit | `idea/2026-11-10-page-capture.md`, this log, plan scope change, design doc dated notes | Results routed. |

No package behaviour changed except the `clipGrob` fix. The spike is not in `R/`.

## Measured

- Suite at the start (`96f504a`): 7 files, 48 tests, 280 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, counted from the result's data frame; earlier logs say 47 tests for the same suite). After `4f8abe4`: 7 files, 49 tests, **298 expectations**, 0 failed, 0 skipped. `Rscript bench/R/check-runner.R`: runner check OK.
- **The `clipGrob` test fails before the fix:** 4 failures in `test-capture.R` (a disc after a clip window is captured with the whole page as its clip region; the `clipGrob` is listed as a leaf), 0 after. On hand-built grobs only: no development figure has a `clipGrob` leaf (run `2026-11-10-1731`, 0 of 44 grid pages).
- **Root causes, each reproduced** (`s0-root-causes.R`, `d1`, `d2`; details in the research README):
  - gallery-052 (ggExtra): the captured object equals its own `print()`, 83 = 83 primitives. The bench's reference page held two figures, 219 primitives; 219 − 83 = 136, the reported difference.
  - gallery-013, -038: gridGraphics resolves colour 0 against its shadow device, where `par("bg")` is `transparent`; on svglite it is `white`. `rect(border = 0)`: 2 of 2 primitives differ.
  - The five background rects: gridGraphics draws one when `par("bg")` is not transparent, which is the case for a plot recorded on svglite.
  - gallery-008 (`pairs`): 16 primitives on the host, all axis labels: which ones are drawn and where.
  - gallery-056 (treemap): 2 of 14 display-list elements are grobs whose name is a vector. grid draws them; `grid.grab()` returns a tree it cannot index.
  - gallery-059 (gghighlight): `GeomLabelRepel` with `seed = NA`. Two plain `print()` calls differ in 5 primitives; with the same seed before each, 0.
  - bioc-004 (NOISeq): not traced inside gridGraphics.
- **Page capture on the development set** (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript dev_docs/research/capture-fidelity/s3-dev-set.R`, 55 figures, third run `2026-11-10-1731`, made after looking, no prediction scored): 44 grid pages, 10 base pages, 1 empty page, 0 mixed, 0 errors. **54 of 55 captured; 53 equal the page the code drew**, primitive for primitive. Grid pages: captured page equals a plain redraw from the same random state in 44 of 44, with clip regions; the plain redraw equals the first drawing in 43 of 44 (gallery-059). Base pages: 10 of 10 equal, with clip regions. Against the engine route at `1b22fe1` on the same figures: 51 captured, 40 equal, 6 known exceptions, 5 different.
- Objects against pages: of 42 figures recovered as an object, the object printed alone equals the page the code left in 39; not for gallery-052 (two figures on the page) and gallery-059 (random); gallery-053 draws nothing.
- 23 of the 55 figures' code drew more than one page; the last is kept.
- **Hand-built cases** (host): 15 of 16 grid pages identical (`s1`); 26 of 26 base pages identical by entry, and gridGraphics identical on 0 of the same 26 (`s2`). Element tables identical to today's on five test inputs, panels identical, base panel coordinates within 0.005 pt (`s5`).
- Time: median 0.09 s per figure, maximum 37.9 s (gallery-023: 1301 entries, whole page parsed after each). Reading only the new bytes of a file device: 5008 entries in 0.32 s against 53 s, same counts per entry, same page (`s6`).
- Not run: the held-out set. Dense leaves and tables on the page route. Base leaves, expected counts and classification by display-list entry. Nothing of the spike is implemented in `R/`.

## Surprises

- **ggExtra was never captured as another figure.** The verdict came from the bench's reference: the frozen code prints two `ggExtraPlot`s and `print.ggExtraPlot` starts no new page outside an interactive device, so the page held both. The refusal of `efe9936` therefore refuses a figure gloss captures correctly, and the previous dev log, the plan, the design doc, `NEWS.md` and a comment in `R/core-substrate.R` say otherwise. → plan scope change and design doc dated notes (this session); the refusal itself is left as it is until the owner decides on capture.
- **The fidelity comparison could not see clipping.** `scene_signatures()` compares each primitive's tag, attributes and text; the clip region belongs to an ancestor group. A `clipGrob` leaf lost its clip with every signature unchanged. → fixed in `4f8abe4` with clip regions in the tests; the bench's comparator still uses primitives only (idea note, "what it costs").
- **Every base difference is gridGraphics, not gloss.** It is a second implementation of base graphics: it resolves colours, the page background and axis labels itself. On 26 hand-built recorded plots it reproduces the code's drawing in none. → idea note; design §风险与未决问题 dated note.
- **A figure can differ from itself.** gallery-059 is "different" in every run because two drawings of it are different; no capture method can make the second equal the first. Counting it as a capture failure measures the figure. → idea note (a verdict of its own); plan scope change.
- **Restoring the random state is not enough.** For a ggplot whose build also draws random numbers, the state from before `print()` or from the start of the page gives 56 differing primitives; only the state between build and draw works, and gloss has that only where it controls both. → idea note, "what it does not solve".
- **`gloss()` on a function has two unexplained paths.** A function that draws with grid stops with "EXPR must be a length 1 vector", which names no reason; a function that draws four base pages is captured as its last page with a warning. → nowhere yet: both belong to the capture decision.
- **The "scene grid cannot draw" was grid drawing it fine.** treemap's page redraws without error; only the grabbed tree fails. → plan scope change (the class of gallery-056's error is a recovery artefact of `grid.grab()`).

## What's next

- Owner decision, before M1: the three options in the idea note. If page capture is chosen, an ADR, then a plan: grid pages first, base pages second.
- Whatever is chosen: clip regions in the bench's comparison; a verdict for figures that are not deterministic; a reason for the two `gloss(function)` paths.
- Plan Task 7 and the held-out set stay as they were: the held-out set runs only after the definition of success is settled, with predictions committed first.
