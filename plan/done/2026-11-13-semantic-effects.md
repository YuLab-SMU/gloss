# Semantic effects board

> Status: closed
> Date opened: 2026-11-13. Owner: Codex.
> Date closed: 2026-11-13.

**Goal:** Make each of the six semantic layers visibly useful in the Palmer Penguins example by comparing the raw substrate with a live semantic projection whose overlays change when records are added.

**Why now:** The six-layer control room removed page switching, but proposals still mostly changed badges and history. The user observed that the interaction adds burden without showing what semantic loss it resolves.

**Architecture:** Add a semantic effects board before the layer rail: a raw substrate plot, a gloss plot with SVG overlays, and a six-layer effect stack. The board reads the existing `semanticRecords` store and current selection, so relation, claim, narrative, meaning, and behavior records become visible marks, callouts, reading order, or collaboration annotations. Existing proposal forms remain the record entry point.

**Out of scope:** R package behavior, benchmark measurements, backend persistence, and changes to the six-layer record schema.

**Starting state:** `NOT_CRAN=true Rscript -e "devtools::test()"` → 1422 passed, 0 failed, 0 skipped; static site at commit `f2ad95b`.

## Tasks

- [x] Task 1: Add the raw-versus-gloss semantic effects board.
- [x] Task 2: Make six layer effects and record submission visibly update the board.
- [x] Task 3: Verify the helpful path, update docs, and close the plan.

## Done when

- The board shows raw substrate and gloss projection together on the Overview screen.
- Selecting each layer changes the visible effect focus without leaving the page.
- Submitting Relation, Claim, Meaning, Narrative, or Behavior changes a board overlay and the effect stack as well as history.
- Inline scripts pass `node --check`, the browser flow has no new console errors, and the full suite remains 0 failed / 0 skipped / 1422 passed.

## Closing notes

- The raw-versus-gloss board is visible before the data lens, so the user can compare the same twelve penguin marks with and without semantic projection in one viewport.
- The six effect buttons now expose a distinct visible consequence: row/structure callout, field meaning card, relation line, evidence card, reading-order card, or collaboration mark. The effect stack remains readable while the selected overlay changes.
- Browser verification on `http://127.0.0.1:4173/#overview`: 12 raw points and 12 gloss points; selecting Meaning kept the URL at `#overview`; submitting the default Meaning proposal produced `M-001`, changed the effect state to `verified`, and changed the board note; submitting Relation produced a verified `R-002`, one visible relation line, and `3 records`. `tab.dev.logs({levels:["error"]})` returned no current errors.
- Verification: `git diff --check`; four extracted inline scripts passed `node --check`; `NOT_CRAN=true Rscript -e "devtools::test()"` → `FAIL 0 | WARN 0 | SKIP 0 | PASS 1422`.
- No R package source, benchmark, or semantic record schema changed; this slice only makes the existing local records legible on the static site.
