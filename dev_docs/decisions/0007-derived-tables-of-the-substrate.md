# ADR-0007: What code works out from the substrate is a derived table, made at capture; bindings are the first

- **Status:** Accepted
- **Date:** 2026-11-12
- **Deciders:** Yonghe Xia settled the principle on 2026-11-11 (M1 plan, decision 2: roles and bindings are derived tables of the substrate, and corrections, agent fills and notes are records laid over them) and on 2026-11-12 that bindings enter the API now ("绑定可以进api ... 其他你来决定就行"). Points 2 to 6 of the decision below were chosen by Claude on that word, from the measurements here; the owner has not read this text.
- **Related:** plan/2026-11-11-m1-roles-and-binding.md (decisions 2 and 5, Task 6a); [ADR-0002](0002-semantic-substrate-with-append-only-records.md); [ADR-0005](0005-bundle-format-v0.md); [ADR-0009](0009-package-behaviour-enters-as-a-checked-proposal.md); dev_logs/2026-11-12-bindings-in-the-api.md; design §绑定假设也要能检查, §实施计划.

## Context

The bind step pairs drawn elements with rows of the engine's tables and checks every pairing against the page. Until this decision it ran only inside the bench: no exported function returned a binding, and a figure read from a bundle had none. The design's Appendix A has rule output written into the `structure` layer as records, which needs the record core of M2, so what code determines would have waited for the machinery meant for what code cannot determine.

Two facts shape where bindings can live. The step reads the engine's state after drawing (the ggplot build, the grob tree, the base display list), and the figure does not keep that state. And principle 2 has code, not a model, determine what follows from the drawing system's contract, so a binding is recomputed from the figure, never asserted.

## Evidence

- **The bind step is a small part of capture on figures of few leaves.** Hand-built scatter plots on the host (`dev_docs/research/bind-dev/d5-bind-cost.R`, output in `d5-bind-cost.out`), 10^3, 10^4 and 10^5 points: the step takes 0.03, 0.05 and 0.43 s beside 0.22, 0.59 and 5.38 s of capture in one panel, and 0.04, 0.13 and 0.39 s beside 0.32, 0.72 and 5.49 s in four. That is 7% to 18% of the capture.
- **It grows with the number of leaves, at about 1.7 ms a leaf.** A base page of `segments()` calls, one leaf each: 0.80, 1.52, 3.23 and 8.63 s for 504, 1004, 2004 and 5004 leaves, beside 0.25, 0.39, 0.79 and 1.92 s of capture (same script). A profile at 5004 leaves has 30% of the step under `data.frame()` and 30% under `%in%`. Looking each claim's elements up once, instead of scanning the scene for every claim, took a profiled run from 9.04 s to 8.68 s and was not kept: most of the cost is the data frames built for every leaf.
- **On the development sets the step is short, with one exception.** An estimate from archived runs, the bind run's time minus the capture run's time for each figure (the capture run sniffs context and the bind run does not, so the difference understates the step): median 0.12 s and 90th percentile 0.68 s on v0's 54 figures (`2026-11-12-1110`, `-1116`), median 0.21 s and maximum 0.70 s on the tree stratum's 29 (`-1105`, `-1107`). One figure is above 5 s: gallery-029, 55.0 s, with 4011 leaves.
- **Stored as plain JSON, the bindings of 10^5 points break the bundle's size criterion; stored as integers they do not.** The element table of the 10^5-point scatter adds about 575 KB to the single file as plain JSON (881 KB with deviations at full precision), which would take a file of 2717 KB to about 3290 KB, over the 3 MiB (3072 KB) the suite checks. With ids stored by position, repeated strings by code and deviations in thousandths of a point it adds 94.4 KB, and the file is 2811 KB. Across the six scatters the bindings add 1.5% to 6.5% (6.5, 14.9, 94.4 KB in one panel; 6.9, 27.6, 204.0 KB in four).
- **The round trip is exact.** `tests/testthat/test-bindings.R`: a figure read back from a directory, an HTML file and an SVG file has `fig$derived` identical to the one written, for a facetted figure, a line chart and a dense leaf of 12000 points.
- **Not measured:** the time of the step on the held-out sets; a figure that is rebuilt after its data changes (no rebuild exists yet); roles, which have no rules yet.

## Decision

What code works out from the substrate and the engine's state is a derived table of the figure: made when the figure is captured, made again whenever it is captured again, and never edited.

1. **Derived tables are not records.** A correction, an agent's proposal that passed its check, or a person's note is a record (ADR-0002) anchored to a leaf or an element, and a query lays records over the derived table. The derived table keeps saying what code found. Records do not exist yet; the plan that builds the first agent path builds the first of them.
2. **They live in `fig$derived`, named by table.** Each has `name`, `by` (the kind, name and version of the plugin whose statements it rests on), `gloss` (the version that computed it), `params` (the scalars it depends on) and `tables` (data frames). Bindings are `fig$derived$bindings`: `by` is the engine, `params$tolerance` is 0.5, and the tables are `elements` (one row per element of a paired leaf), `leaves` (one row per leaf, with the reason when nothing could be checked) and `rows` (for an element that draws a whole group, every row of the group). Roles go in `fig$derived$roles` in the same shape when their rules exist (Task 6b).
3. **Bindings are made at capture, by default.** The engine's state is at hand only then. `gloss(bind = FALSE)` skips the step. A step that raises an error does not fail the capture: the figure has no bindings, `fig$status$withheld` holds the reason, and `print()` and `gl_bindings()` give it. A figure never carries bindings from an earlier capture.
4. **One exported function reads them.** `gl_bindings(fig, by = "element" | "leaf" | "row", where = )`. A figure without bindings is an error that says why, not an empty table.
5. **The bundle keeps them.** One file per table under `substrate/derived/<name>/`, listed in the manifest with `by`, `gloss` and `params`. A table of 10000 rows or more is stored column by column as integers (element and leaf ids by position, other strings by code, doubles that are whole thousandths as thousandths); a compaction is used only if expanding it gives the column back exactly. Smaller tables stay plain JSON. The format version becomes 0.2.0. A 0.1.0 bundle is read as before and has no bindings (tested). A reader of 0.1.0 reads the files it knows and passes over the others, by its code; that was not run.
6. **Deviations are kept to 1/1000 pt.** The check runs on the unrounded value. The tolerance is 0.5 pt and svglite writes coordinates to 1/100 pt, so the stored deviation loses nothing the page holds.

## Alternatives considered

- **Write rule output and bindings as records in the `structure` layer** (Appendix A as written). It needs the record core before anything can be read, and it stores as a claim what code can recompute. A figure captured again would have to rebase its own derived facts (principle 4 asks for verification to rerun when the substrate changes; a derived table does that by being made again).
- **Compute bindings on demand.** The engine's state is gone after capture. Keeping it means keeping the built plot and the grob tree in the figure and in the bundle, and for base figures a display list that only the R that recorded it can replay.
- **Capture again when bindings are asked for.** It needs the original object, which a figure read from a bundle does not have, and a figure that is not deterministic would get bindings of a page other than the one it holds.
- **Off by default.** The first agent tools and every later layer read bindings; a default that leaves them out makes each caller ask. The cost on the figures measured is 7% to 18% of capture, with the many-leaves case as the exception that `bind = FALSE` covers.
- **Store the tables as plain JSON.** The 10^5-point file would go from 2717 KB to about 3290 KB and fail the size check.
- **A binary file per table, like `substrate/index.bin`.** Smaller still, but a second format to describe and read. The codec's integer vectors already give 94 KB.

## Consequences

### Positive

- A user or an agent can ask which rows an element draws, and what it gets was checked against the page. The agent path can start from an exported function.
- A figure read from a bundle answers the same question without the object or the packages that drew it.
- Roles have a place to go that needs no record core.

### Negative / accepted tradeoffs

- `gloss()` is slower by the bind step: 0.03 to 0.43 s on the scatters, 8.6 s on a base page of 5004 leaves, about 55 s on gallery-029. The suite's capture test of 5000 `segments()` calls takes 11 s, where the capture alone takes about 2 s, against a limit of 30 s.
- A figure and its bundle are larger: 1.5% to 6.5% on the scatters measured.
- A figure captured with one version of an engine keeps that engine's bindings until it is captured again. `by` and `gloss` say which.
- `fig$derived$bindings$tables$elements$dev` is rounded; the bench's leaf tables, from `bind_capture()`, are not.
- ADR-0005 gives the bundle format as 0.1.0. It is 0.2.0 from this decision; ADR-0005 is otherwise unchanged.

### Follow-ups

- Appendix A and @tbl-layers of the design still have rules writing `structure` records. A dated note there points here; they are rewritten when Task 6b lands.
- The per-leaf cost of the bind step (data frames built per leaf) is a defect in the implementation, not a property of the design. It is not fixed here.
- The demo tour (`dev_docs/demo/gloss-tour.R`) reads bindings through `gl_bindings()`.
- The agent-path plan defines the first record laid over a derived table: a proposal that passed its check.

### Revisit when

- A figure of a kind people draw often takes more than 5 s in the bind step after the per-leaf cost is fixed, or the step is more than the capture itself on the median development figure: then default-on is reconsidered.
- A rebuild of a figure after its data changed exists and shows that a derived table needs anything carried over from the old figure.
- Bindings push a bundle the owner cares about over a size that matters to them (the 10^5-point figure in four panels is 3115 KB without bindings and 3319 KB with).
