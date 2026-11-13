# 2026-11-13 — Overview control room

- **Related plan:** none; static docs-site implementation after the closed agent-path pilot
- **Related ADRs:** none
- **Worked on by:** Codex

## What changed

- Added a linked Overview workspace to `docs/index.html` with a semantic path drawn from inline SVG: source figure/data, substrate, propose gate, status branches and record/projection.
- Added semantic status colors, particle and relation-line treatment, inline SVG icons, M0—M5 capability map, current-focus card and evidence pulse.
- Shared the selected element and latest verification result between Explore, Propose and Overview. Added deep links for `#overview`, `#explore` and `#propose`.
- Updated `docs/README.md` and `NEWS.md`.

## Measured

- `git diff --check`: clean.
- Inline JavaScript extracted from `docs/index.html` and checked with `node --check`: passed (4 scripts, 39,752 bytes).
- `curl -fsS http://127.0.0.1:4173/#overview`: passed.
- `NOT_CRAN=true Rscript -e "devtools::test()"`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1422 ]`.
- Browser checks on the local Pages entry: Overview opens from `#overview`; Explore selection `E-07` synced to Overview; wrong-row Propose result synced as `rejected`; relation proposal synced as `unresolved`; flow nodes and M0—M5 milestone focus were clickable; browser console had no errors.
- Bench container and R CMD check were not rerun because this slice changes only the static `docs/` presentation layer and NEWS/README.

## Surprises

- The first layered substrate sketch obscured its own heading because SVG skew transformed the layer rectangles upward; replaced it with explicit polygon paths before browser verification. → nowhere yet, a local presentation fix.

## What's next

- Keep the three workspaces as the visual shell while future research-facing pages move from local fixture state to project data and evidence records.
