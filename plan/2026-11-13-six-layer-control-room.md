# Six-layer control room

> Status: active
> Date opened: 2026-11-13. Owner: Codex.

**Goal:** Rebuild the docs site as one continuous semantic workbench where the six layers are the primary navigation and data inspection, proposals, records, projections, and collaboration stay in the same screen.

**Why now:** The current site has a good semantic record model, but its visible information architecture still presents Overview, Explore, and Propose as separate workspaces. The user asked to follow the six layers as the mainline and remove page jumping.

**Research-card clause:** Infrastructure for the unmeasured M2/M3 record and projection experience; this slice does not claim package accuracy or benchmark coverage.

**Starting state (measured):** `NOT_CRAN=true Rscript -e "devtools::test()"` → 1422 passed, 0 failed, 0 skipped on 2026-11-13. The site is a monolithic `docs/index.html` with three visible workspace views and six semantic-layer records already wired into Overview.

**Architecture:** Keep the existing local record store and proposal handlers, make Overview the only visible workspace, promote the six-layer rail to the primary navigation, embed a compact substrate data lens and inspector, and route former Explore/Propose actions to in-page focus or proposal panels. The static site remains independent of the R package runtime.

**Out of scope:** R package behavior, benchmark measurements, new semantic checkers, backend persistence, and deployment/push.

**Tech stack:** Static HTML/CSS/JS in `docs/index.html`, generated PNG asset in `docs/assets/`.

## Overall progress

- [~] Task 1: Make the six-layer rail and single-screen Overview the primary shell.
- [ ] Task 2: Embed substrate data lens, table, and inspector into the same shell.
- [ ] Task 3: Re-route legacy workspace actions to in-page layer/proposal focus.
- [ ] Task 4: Verify the full layer flow, update documentation, and close the plan.

## Task 1: Single-screen semantic shell

**Status:** `[~]`

**Intent:** Remove the visible page-switching mental model and make layer selection the first action.

**Checklist**

- [ ] Replace Overview rail mode buttons with six layer controls.
- [ ] Put the semantic layer card before the path/projection content.
- [ ] Keep current layer state and proposal history live.

**Verification:** Browser AX tree shows one Overview workspace with six layer controls; no Overview navigation to separate Explore/Propose pages.

## Task 2: Substrate data lens

**Status:** `[ ]`

**Intent:** Make the actual penguin data, scatter marks, selected anchor, and inspector visible without leaving the semantic flow.

**Checklist**

- [ ] Add the in-page data lens with SVG marks and a data table.
- [ ] Reuse `window.glossExplore.select()` so selection updates all existing records and projections.
- [ ] Verify table/plot/inspector selection stays synchronized.

## Task 3: In-page routing

**Status:** `[ ]`

**Intent:** Preserve existing buttons while removing page jumps.

**Checklist**

- [ ] Route old Explore actions to the data lens.
- [ ] Route old Propose actions to the inline proposal shell.
- [ ] Keep deep links usable without presenting separate page shells.

## Task 4: Verification and close

**Status:** `[ ]`

**Checklist**

- [ ] Run `git diff --check`, inline `node --check`, browser flow checks, and the full suite.
- [ ] Update NEWS and a closing dev log.
- [ ] Move this plan to `plan/done/` in the closing commit.

## Scope changes

_(append-only)_
