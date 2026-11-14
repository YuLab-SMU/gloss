# Semantic storyboard redesign

> Status: closed
> Date opened: 2026-11-14. Owner: Codex.
> Date closed: 2026-11-14.

**Goal:** Replace the current button-heavy Overview with one guided Palmer Penguins story that makes each semantic layer earn its place through a visible change in the same figure.

**Problem:** The current page exposes several controls that open equivalent proposal forms (`追加 Meaning`, `追加 Relation`, per-layer proposal buttons, and form-specific submit buttons). The six layers are present, but their cumulative benefit is hard to see, so interaction cost is higher than the demonstrated understanding.

**Design direction:** One semantic ladder, one shared action, one projection. The user starts with a plain question about the penguins figure, selects a layer, and uses a single `添加这一层` action. The selected layer changes the same chart, the short “missing → gained” explanation, and the record trail. Advanced forms remain available only as a secondary path and do not compete with the demo.

**Out of scope:** R package behavior, benchmark measurements, and changes to the semantic record schema.

**Starting state:** Local `feat/agent-path` is clean at `df3f84a`; the full suite previously passed with `1422` expectations and the live Pages site is deployed from the same branch.

## Tasks

- [x] Task 1: Replace the raw-versus-gloss board with a guided semantic storyboard and concrete six-step Penguin narrative.
- [x] Task 2: Collapse duplicate proposal actions into one shared add/advance control while preserving append-only records and projections.
- [x] Task 3: Remove or compact redundant Overview controls, polish the visual hierarchy, and validate the full browser path.
- [x] Task 4: Run the required checks, close the plan, commit the branch, and redeploy Pages.

## Done when

- A first-time visitor can understand the example without opening Explore/Propose views or reading implementation copy.
- Each layer changes a visible chart overlay and a concise benefit card; the full sequence can be replayed in place.
- There is one primary semantic action in the demo; redundant per-layer “append” buttons are absent from the visible path.
- Raw substrate, selected penguin data, record history, Narrative / Accessibility, and Collaboration remain linked.
- Inline scripts, browser checks, and the full R suite pass before deployment.

## Closing notes

- The primary Overview path now has one visible semantic storyboard action. Duplicate append buttons, the old effect board, the old proposal shell, and the M0—M5 status grid are removed from the main reading path.
- On a fresh browser tab, the initial state shows structure only. The add/advance action then moves through Meaning, Relation, Claim, Narrative and Behavior; the same plot gains species colors, group relation, verified mean evidence, reading order, and focus/review history.
- Browser verification: six records after the full sequence, table selection of E-10 synchronized the story focus, and the browser error log was empty.
- NOT_CRAN=true Rscript -e "devtools::test()" → FAIL 0 | WARN 0 | SKIP 0 | PASS 1422.
