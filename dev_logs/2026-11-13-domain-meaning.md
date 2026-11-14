# 2026-11-13 — Data and domain meaning layer

- **Related plan:** none; continuation of the static docs-site semantic proposal slice
- **Related ADRs:** none
- **Worked on by:** Codex

## What changed

- Added Data / Domain Meaning as the fifth inline proposal type alongside Relation, Claim, Narrative and Behavior.
- Meaning proposals map the local penguin fields (`species`, `island`, `bill`, `flipper`, `mass`) to domain terms, units and scope using a compact data dictionary.
- Verified meaning records append to the same history with `M-` ids and update the meaning layer state immediately.
- Kept the UI compact: field groups, domain term chips, units, statuses and history carry the interaction without explanatory design prose.

## Measured

- `git diff --check`: clean.
- Inline JavaScript extracted from `docs/index.html` and checked with `node --check`: passed (4 scripts, 62,809 bytes).
- Browser checks: Meaning opened from the layer row, `species → 物种 · category` verified as `M-001`, `flipper` mapped to `鳍长 · mm`, shared history updated, and console errors/warnings were empty.
- `NOT_CRAN=true Rscript -e "devtools::test()"`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1422 ]`.
- Bench container and R CMD check remain out of scope for this static docs-only slice.

## Surprises

- Domain meaning becomes a concrete interaction when the form exposes field, term, unit and scope as a visual tuple; prose about “meaning” was unnecessary. → site interaction design; no package behavior changed.

## What's next

- Keep the meaning dictionary aligned with the project’s future substrate schema; add a projection preview only if it can stay visual and compact.
