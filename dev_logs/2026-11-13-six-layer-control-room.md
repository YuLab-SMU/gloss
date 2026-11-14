# 2026-11-13 — six-layer control room redesign

## Scope

The docs site was restructured around the six semantic layers as the primary route. Overview is now the only visible workspace; substrate inspection, inline proposals, record history, projections, and collaboration all remain in one continuous page.

## Changes

- Replaced the Overview mode rail with a six-layer semantic rail: structure, meaning, relation, claim, narrative, and behavior.
- Reordered the Overview document so the semantic layer stack comes first, followed by the substrate data lens, the semantic path, proposal shell, projections, and supporting status cards.
- Added the substrate data lens with a synchronized scatter plot, 10 stable data rows, status labels, an inspector, and layer-aware proposal actions.
- Routed former Explore and Propose actions to the in-page data lens or proposal shell; the legacy view shells are hidden and deep links normalize to `#overview`.
- Kept the generated penguin asset as an interactive species surface and used it in the top record/project path.
- Added a small substrate fallback model so the static page still renders the data lens when the legacy Explore script is unavailable.

## Verification

- `git diff --check`: clean.
- Extracted all inline scripts and ran `node --check`: passed.
- `curl http://127.0.0.1:4173/`: 200; `assets/penguins-semantic.png`: 200 `image/png`.
- Browser checks on `http://127.0.0.1:4173/#overview`: six-layer rail is the only visible navigation; the data lens renders 10 stable rows and 12 points; selecting `E-10` updates the lens, inspector, asset focus, and current anchor; changing to Meaning keeps `E-10`; the inline Meaning proposal opens with `#overview` unchanged; the former Explore action remains on the Overview workspace.
- `NOT_CRAN=true Rscript -e "devtools::test()"` → 0 failed, 0 skipped, 1422 passed.

## Plan outcome

The redesign plan `plan/2026-11-13-six-layer-control-room.md` is complete. No R package source or benchmark behavior changed.
