# 2026-11-15 — prepared visual evidence view

- **Related plan:** [plan/2026-11-15-visual-semantic-pilot.md](../plan/2026-11-15-visual-semantic-pilot.md)
- **Related plan closed:** [plan/done/2026-11-15-semantic-pilot.md](../plan/done/2026-11-15-semantic-pilot.md)
- **Worked on by:** Codex.

## What changed

- Added `bench/semantic/vision/make_view.R`, which builds a prompt-side prepared view from the captured substrate.
- The view keeps the original graphics-device scene and adds only deterministic panel guides, element IDs and callouts. It does not show built rows or binding answers.
- Opened the visual semantic pilot as the active plan. The next task compares text-only and visual proposal conditions with the same model, wording and budget.

## Measured

- Host package baseline remains 17 test files, 1477 expectations, 0 failures and 0 skips.
- The prepared view labels 12 circle elements across 2 panels. Source scene hash: `f046477e...c67d`; repeated prepared PNG hash: `92a37f...a114`.
- `metadata.json` records `contains_binding_answers = false`; the source SVG is stored separately from the prepared SVG.
- Local visual inspection: the original points remain visible, both panels are labelled, and the element IDs are legible. No package source or tests changed.

## Surprise

- Labels placed by element order concentrated in one panel and overlapped in dense regions. The generator now balances six labels per panel and uses short leader lines to keep the visual condition usable.

## What's next

- Freeze proposal cases that require locating elements or relations, then run text-only versus visual conditions through the same checked proposal boundary. Keep any real vision-model run separate from the offline artifact test.
