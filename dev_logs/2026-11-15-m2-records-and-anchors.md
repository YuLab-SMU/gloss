# 2026-11-15/16 — M2 records and anchors

- **Related plan:** [2026-11-15-m2-records-and-anchors](../plan/done/2026-11-15-m2-records-and-anchors.md)
- **Related ADR:** [ADR-0002](../dev_docs/decisions/0002-semantic-substrate-with-append-only-records.md)
- **Worked on by:** Codex, following the owner's `/goal 完成M2` request.

## Scope

The prepared visual evidence pilot was complete but had no model comparison. Its route task was closed with the comparative run deferred, and this slice implemented the record and anchor core that the pilot had left out.

## What changed

- Registered the eight core layers through the existing plugin registry.
- Added append-only record materialisation and JSONL events for add, revise, retract, verify, rebase and selector rewrites.
- Added structured anchors for data keys, safe predicates, structure paths, roles, regions and element ids. Stable structural ids are independent of binding computation; bound records also retain a data target so an id that now points at another row is invalidated.
- Added record checking, provenance, status queries, conflict listing and rationale-bearing resolutions. `gl_propose()` keeps its original non-mutating binding form and accepts the documented record-writing form.
- Added bundle persistence, `gl_rebase()`, `gl_status()`, `gl_diff()` and `gl_repair()`; derived roles and bindings remain derived tables.
- `gl_rebase(fig, trust = TRUE)` can reuse a still-live captured expression symbol after the explicit trust gate; an edited figure can always be passed directly.

## Measured

- Starting host suite: 17 files, 1477 expectations, 0 failures and 0 skips (the visual pilot baseline).
- Final host suite: 18 files, 1506 expectations, 0 failures and 0 skips.
- `Rscript bench/m2/rebase.R` on the fixed mtcars fixture: title 3/4 hits (75%), colour 4/4 (100%), data subset 2/4 (50%), add layer 4/4 (100%), delete layer 4/4 (100%). The two subset misses and the title-region miss were explicit `invalid` records; no fallback target was accepted.
- `tests/testthat/test-records.R` covers layer registration, all selector classes, conservative fallback, check rejection, JSONL bundle round trips, revisions, retractions, conflicts, resolution records and rebase invalidation.
- `R CMD build --no-build-vignettes --no-manual .` followed by `R CMD check --no-manual --no-vignettes gloss_0.0.0.9000.tar.gz` completed with `Status: OK`.

## Surprises

- Grob paths contain session-specific numeric suffixes, so using them in stable ids made repeated captures disagree. Stable ids now use the captured leaf id, primitive tag and ordinal; the binding-derived data target supplies the stronger row identity when it exists.
- A title edit moves the panel, so a narrow device-region anchor is expected to invalidate even though data-key and id anchors survive. This is explicit status propagation rather than a silent relocation.

## What's next

The controlled fixture is mechanism evidence only. M5 should measure update coverage on the frozen development/held-out figures and register the threshold before any held-out run. The prepared visual view remains available for a later agent comparison.
