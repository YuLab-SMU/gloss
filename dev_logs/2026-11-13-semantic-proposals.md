# 2026-11-13 — Inline Relation and Claim proposals

- **Related plan:** none; follow-up to the static docs-site semantic-layer slice
- **Related ADRs:** none
- **Worked on by:** Codex

## What changed

- Added an inline semantic proposal workbench to Overview so Relation and Claim records can be created without switching workspaces.
- Relation proposals check a selected element against the local penguin species vocabulary (`belongs_to`, `compares_with`, `annotates`).
- Claim proposals run deterministic group summaries on a local Palmer Penguins fixture, currently supporting bill length, flipper length and body mass means with greater-than / less-than checks.
- Added append-only semantic record history, per-layer record counts/status, and live synchronization into the Overview layer detail and evidence footer.
- Replaced the Explore demo labels/table with penguin-oriented `species`, `island`, `bill` and `flipper` fields. Kept higher-level records explicit about what is checked and what remains unresolved.
- Kept the Chinese page language consistent for the new interface while retaining professional terms such as Relation, Claim, substrate, binding and verified.

## Measured

- `git diff --check`: clean.
- Inline JavaScript extracted from `docs/index.html` and checked with `node --check`: passed (4 scripts, 59,855 bytes).
- `curl -fsS http://127.0.0.1:4173/#overview`: passed.
- `NOT_CRAN=true Rscript -e "devtools::test()"`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1422 ]`.
- Browser checks: inline Relation verified (`E-05 belongs_to Adelie`); Claim verified (`Gentoo flipper mean 217.0 > Adelie 189.0`); inverted Claim rejected with a recorded reason; semantic layer state, record list and evidence footer updated; Explore showed penguin substrate fields; browser console errors/warnings were empty.
- Bench container and R CMD check remain out of scope for this static docs-only slice.

## Surprises

- Keeping proposal forms inline made the layer history visible at the moment of decision and exposed that the old page-level Propose route was too detached from the semantic layer it was meant to update. → site interaction design; no package behavior changed.

## What's next

- Add a Relation/Claim record projection view or a small narrative layer on top of the same history; do not expand point-row matching as the primary research path.
