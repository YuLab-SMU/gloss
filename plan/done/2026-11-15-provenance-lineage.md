# Semantic provenance lineage

> Status: closed
> Date opened: 2026-11-15. Owner: Codex.
> Date closed: 2026-11-15.

**Goal:** Make every semantic addition in the Penguin storyboard explain its provenance: the data artifact, the plotting code, the statistical method, and the real-world domain vocabulary that support it.

**Problem:** The current storyboard shows overlays and verified records, but a visitor cannot see where the meaning comes from or why the record is more than a label attached to a point.

**Design direction:** Add a compact provenance strip to the same screen. Each story layer highlights one source node and the resulting semantic gain. The source chain stays stable while the semantic records accumulate:

penguins.csv → ggplot code → group mean / comparison → species and flipper-length knowledge

**Out of scope:** R package behavior, benchmark measurements, and changes to the semantic record schema.

## Tasks

- [x] Task 1: Add the provenance source chain and connect it to the active story layer.
- [x] Task 2: Show the source contribution and resulting gain for each layer without adding another proposal workflow.
- [x] Task 3: Verify the full six-layer path, update docs, commit, and redeploy Pages.

## Done when

- The same screen shows data, code, method, and world-knowledge provenance.
- Selecting or adding a semantic layer highlights its source node and explains the resulting gain.
- The primary interaction remains one add/advance action with no duplicate proposal buttons.
- Browser checks, inline script checks, and the full R suite pass.

## Closing notes

- The story now makes provenance visible beneath the figure: penguins.csv → plotting code → statistical method → real-world knowledge.
- The active layer highlights its source node and updates the proof sentence without opening another form.
- git diff --check, four inline node --check runs, and NOT_CRAN=true Rscript -e "devtools::test()" all pass; the suite remains 1422 passed, 0 failed, 0 skipped.
