# 2026-11-14 — semantic storyboard redesign

## Scope

The live demo exposed several equivalent proposal entry points and made the six-layer value difficult to see. This slice turns the Overview into a guided Palmer Penguins story rather than a collection of append buttons.

## Changes

- Added a single semantic storyboard with one shared figure, a six-step ladder, a “before → gained” card, and one add/advance action.
- Each layer now has a concrete projection on the same chart: structure rings a row, meaning colors and labels species fields, relation draws the group connection, claim shows verified mean flipper evidence, narrative adds reading order, and behavior adds focus/review history.
- Hid the duplicate Overview proposal controls and the old raw-versus-gloss board from the primary path. The substrate table and projection/timeline remain visible below the story.
- Kept the append-only semanticRecords store and existing projections; the storyboard writes through the same record path.

## Verification

- git diff --check: clean.
- Four extracted inline script blocks: node --check passed for all four.
- Fresh browser tab on http://127.0.0.1:4173/#overview: the storyboard is the first content card; only one add/advance action is visible; adding Meaning, Relation, Claim, Narrative and Behavior produced 2 through 6 records and the corresponding visible chart overlays; selecting table row E-10 updated the storyboard focus; current browser error logs were empty.
- Local screenshot inspection: the six layer states, claim card, reading order card, focus/review card, and penguin asset are legible at the same viewport.
- Full R suite and deployment checks are recorded when the branch lands.

## Surprise

The useful demo unit is a semantic transition, not a proposal form. Once every layer answered “what did this add to the same figure?”, the page could remove most controls without losing the underlying record model.
