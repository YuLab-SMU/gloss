# 2026-11-13 — Narrative and Behavior layers

- **Related plan:** none; continuation of the static docs-site semantic proposal slice
- **Related ADRs:** none
- **Worked on by:** Codex

## What changed

- Extended the same-screen Overview proposal workbench with Narrative and Behavior / Collaboration tabs.
- Narrative proposals capture reading order, key conclusion and accessibility description for the penguin plot; complete fields become a recorded narrative projection entry.
- Behavior proposals capture an operation, actor, target and collaboration note for focus, annotation, review or revision; the result remains in the same append-only record list.
- Layer detail buttons now open the matching proposal type, and layer state plus record history update immediately after submission.
- Reduced explanatory prose in the visible UI; layer rows, compact field groups, status chips, icons, relation lines and record cards now carry the design signal.

## Measured

- `git diff --check`: clean.
- Inline JavaScript extracted from `docs/index.html` and checked with `node --check`: passed (4 scripts, 61,109 bytes).
- Browser checks: Narrative submitted as `verified · N-001`; Behavior submitted as `verified · W-002`; both appeared in the same history alongside the substrate record; console errors/warnings were empty.
- `NOT_CRAN=true Rscript -e "devtools::test()"`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1422 ]`.
- Bench container and R CMD check remain out of scope for this static docs-only slice.

## Surprises

- The same record history made Narrative and Behavior feel like real layers only after their proposals reused the exact Relation/Claim gate and layer-state surface. → site interaction design; no package behavior changed.

## What's next

- Add a narrative projection preview or collaboration timeline if needed; keep it in the same Overview workbench.
