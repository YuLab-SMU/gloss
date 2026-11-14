# 2026-11-13 — narrative projection and collaboration timeline

## Scope

The GitHub Pages workbench keeps proposal, record history, and output views in the Overview screen. This slice adds a real Narrative / Accessibility projection and a collaboration timeline driven by the same six-layer record store. It also adds a generated Palmer Penguins illustration as a local site asset.

## Changes

- Added `docs/assets/penguins-semantic.png`, a transparent trio of Adelie, Chinstrap, and Gentoo penguins generated for the projection panel.
- Added a compact projection deck to `docs/index.html` with the image asset, species legend, reading-order flow, accessibility tree, and record chips.
- Added a collaboration timeline that renders semantic records newest first with status, layer, detail, and anchor metadata.
- Wired both outputs to `semanticRecords`; submitting Narrative or Behavior records refreshes the layer state, projection, accessibility tree, history, and timeline without changing workspace pages.
- Kept the existing Explore / Propose controls in the same Overview workspace and removed long inline design notes from the visible UI.

## Verification

- `git diff --check` passed.
- Extracted all inline scripts and ran `node --check` on each; passed.
- Browser check on `http://127.0.0.1:4173/#overview`: generated penguin asset renders; Narrative submission created `N-001` and changed the projection to `verified`; Behavior submission created `W-002` and added it to the timeline; reload restored the initial one-record state; default collaboration target is `Gentoo`.
- Final package suite: `NOT_CRAN=true Rscript -e "devtools::test()"` → 0 failed, 0 skipped, 1422 passed. This slice only changes the static site and documentation; no package source was changed.

## Notes

The projection is a view of recorded semantics, not a second source of truth. The image is decorative context for the Palmer Penguins example; record status and accessibility rows are generated from the local semantic record store.
