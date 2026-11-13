# 2026-11-13 — Reframe the site around semantic layers

- **Related plan:** none; follow-up to the static docs-site slice after the closed agent-path pilot
- **Related ADRs:** none
- **Worked on by:** Codex

## What changed

- Reframed Overview so element-to-row binding is labelled as a substrate fact, not the research problem.
- Added a six-layer semantic stack: role and structure; domain meaning; relations and semantic grouping; claims and evidence; narrative and accessibility; interaction and collaboration.
- Added per-layer detail, source, state, anchor and check fields. The selected element and latest verification still flow through the stack, while higher layers stay visibly pending until their own checker exists.
- Reworded Explore and Propose around substrate facts plus higher-level semantic proposals. Propose now exposes binding, relation, meaning and claim kinds; only binding is checked in this pilot, and the other kinds remain unresolved with an explicit reason.
- Updated site README, NEWS and the static page metadata.

## Measured

- `git diff --check`: clean.
- Inline JavaScript extracted from `docs/index.html` and checked with `node --check`: passed (4 scripts, 44,085 bytes).
- `curl -fsS http://127.0.0.1:4173/#overview`: passed.
- `NOT_CRAN=true Rscript -e "devtools::test()"`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1422 ]`.
- Browser checks: six semantic layer rows are selectable; selecting `claim` shows its own source/state/check and says binding is only the data-entry point; Propose `claim` returns `unresolved` with the higher-layer explanation; Overview syncs that state; console errors/warnings were empty.
- Bench container and R CMD check were not rerun because the slice changes only the static `docs/` presentation layer and documentation.

## Surprises

- The existing flow was technically accurate but visually over-weighted the binding pilot. The correction was to make the distinction an explicit UI boundary (`substrate fact` vs `semantic record`) rather than adding another generic status card. → design language in the site; no package behavior changed.

## What's next

- Keep binding as the tested substrate path, and make the next research slice target one higher-level claim or relation checker rather than improving point-row matching.
