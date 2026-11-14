# 2026-11-13 — raw-versus-gloss semantic effects

## Scope

The six-layer control room had an inline proposal path, but adding a record mostly changed badges and history. This slice makes the value of a semantic record visible on the Palmer Penguins example: the same substrate is shown beside a gloss projection, with one concrete visual effect per layer.

## Changes

- Added the `一张图，两个读法` board to Overview, with a raw substrate plot and a gloss projection plot using the generated penguin asset.
- Added a six-item effect stack. Structure shows an element/row callout; Meaning shows a field and domain term; Relation draws a line to a semantic group; Claim shows an evidence card; Narrative shows reading order; Behavior shows focus/review history.
- Connected the board to the existing selected element and append-only local record store. Meaning and Relation submissions update the selected overlay, status, count, and history without changing `#overview`.
- Kept the generated asset in the projection and added the visible effect board to `NEWS.md`.

## Verification

- `git diff --check`: clean.
- Four extracted inline script blocks: `node --check` passed for all four.
- Browser path: 12 raw points and 12 gloss points; all six effect buttons changed the active overlay; the Meaning form submitted `M-001` with `verified` status; the Relation form submitted `R-002`, produced one relation line, and raised the visible count to `3 records`; current browser error logs were empty.
- `NOT_CRAN=true Rscript -e "devtools::test()"` → `FAIL 0 | WARN 0 | SKIP 0 | PASS 1422` in 67.4 seconds.

## Surprise

The missing product signal was not another proposal control. It was the absence of an immediate projection showing why the record exists. The effects board is the smallest surface that turns the six-layer vocabulary into visible consequences while keeping the proposal and history in the same flow.
