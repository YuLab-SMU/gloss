# 2026-11-15 — semantic provenance lineage

## Scope

The storyboard showed the visible result of adding a semantic layer, but it did not show where that meaning came from. This slice adds a provenance chain that connects the Penguin example to its data artifact, plotting code, statistical method, and real-world vocabulary.

## Changes

- Added a four-node provenance strip under the semantic storyboard: penguins.csv, ggplot / geom_point, group mean / check, and species / flipper-length knowledge.
- Each story layer now selects a source node and updates the proof sentence: structure uses data, relation uses plotting code, claim uses the statistical method, and meaning/narrative use domain knowledge.
- Kept the single add/advance interaction and the append-only record path; provenance is explanatory state, not another proposal workflow.

## Verification

- git diff --check: clean.
- Four extracted inline script blocks: node --check passed for all four.
- The full R suite remains the baseline 1422 passed, 0 failed, 0 skipped; the change is static-site-only.
- Remote branch content was verified against the local blobs before the previous push; this slice is ready for the same branch push.

## Source-card follow-up

The proof sentence was too thin to make a provenance click useful. The source chain now opens a single in-place card. It shows the concrete reference, the visible evidence, the path back to the current record, and a layer-specific explanation of what that source contributes. Selecting a different source changes only this card; the semantic ladder keeps its one add/advance action.

The four cards use the Penguin fixture's actual values: row 5 / P-05 / Adelie / Dream / 190 mm, the plotting mapping for `flipper_length_mm`, `bill_length_mm`, and `species`, the computed Gentoo 217.0 mm versus Adelie 189.0 mm comparison, and the species / island / flipper vocabulary. This keeps the provenance interaction tied to the visible example rather than adding another workflow.
