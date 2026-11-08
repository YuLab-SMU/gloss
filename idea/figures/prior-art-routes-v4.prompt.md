# prior-art-routes-v4

AI-generated schematic for `idea/2026-11-07-semantic-svg-prior-art.md` (figure type F1, stylized; not data). The numbers behind each barrier are in the note, not in the image.

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Rounds:**
  1. v1 from the prompt below. All 12 strings were exact. Two defects: one blurred dot in the mini scatter plot, and the dashed goal box touched the right edge.
  2. v2 was an edit of v1 that asked for both fixes. The dot was fixed, but the box moved onto two barrier labels. Rejected.
  3. v3 was an edit of v1 that asked for the dot fix only (prompt below). The text was still exact, but the dot was still faintly blurred. That made three rounds, so the remaining fix was done deterministically.
- **Post-processing (v3 → v4), ImageMagick:**
  1. Painted over the blurred dot with the sampled card colour, then drew a crisp dot in the sampled dot colour at the same centre: `-fill "srgb(251,249,245)" -draw "circle 176,597 186,597" -fill "srgb(78,78,80)" -draw "circle 176,597 183,597"`.
  2. Padded the canvas with the sampled canvas colour `srgb(242,238,231)`: 48 px on the right, then 32 px on the left (1904×1024).
  3. Resized to 1600 px wide and quantized to a 128-colour PNG8.
  
  Drafts v1–v3 were deleted.
- **Checked on v4:**
  - every string verbatim, each exactly once: "Every existing route stops at a boundary", the four lane names, the four barrier labels, "same geometry," / "any input," / "checked against data";
  - four ✗ glyphs;
  - no lane reaches the goal box;
  - no logo or watermark.
- **Mapping to the note:**
  - lanes = the four families in the summary table (spec translation, raster hit-testing, device-level tagging, SVG deconstruction);
  - barrier labels = the "where it stops" line of each section;
  - goal box = the three properties no family combines.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a research note comparing prior tools (stylized, not data)
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold geometric sans-serif, near-black #1F1E1D): "Every existing route stops at a boundary"
Subject:
- On the left, vertically centered, a small rounded card (white #FDFCF9, thin grey border #C8C7BF) containing a tiny grey scatter plot: two thin axes and about twelve dark grey dots. It has no label.
- From the right edge of that card, four horizontal parallel lanes run to the right, stacked vertically with even spacing. Each lane is a thin mid-grey arrow line (#87867F).
- Each lane has its name written just above the start of the lane, in dark grey sans-serif (#3D3D3A), left-aligned.
- About 60% of the way across, each lane is blocked by a short, thick vertical red bar (#D65451) with a small red ✗ glyph on top of it. The grey arrow ends at the bar. Directly to the right of each bar, its barrier label in red sans-serif (#D65451).
- On the far right, spanning the height of all four lanes, a tall rounded rectangle with a dashed blue outline (#4C75AD) and very light blue fill (#EEF3FA). Inside it, centered, one blue (#4C75AD) bold label set on three short lines: "same geometry," / "any input," / "checked against data". No lane reaches this box; there is clear empty space between the barrier labels and the box.
Lane names, top to bottom: "Redraw in another engine", "Hit-test a raster image", "Tag elements at the device", "Ask a model to read the SVG"
Barrier labels, top to bottom: "the figure changes", "the row is guessed", "unknown layers get no data", "nothing checks the answer"
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients, no 3D
Composition/framing: landscape 16:9; title on top with wide margins; the four lanes fill the middle; the goal box on the right edge
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; failure red #D65451; goal blue #4C75AD with fill #EEF3FA; nothing else saturated
Text (verbatim, exactly these strings and nothing else): "Every existing route stops at a boundary", "Redraw in another engine", "Hit-test a raster image", "Tag elements at the device", "Ask a model to read the SVG", "the figure changes", "the row is guessed", "unknown layers get no data", "nothing checks the answer", "same geometry,", "any input,", "checked against data"
Constraints: render every string exactly once, spelled exactly; the four ✗ glyphs are the only other symbols; no axis labels or numbers in the small scatter plot; no additional text, icons, logos or watermark
```

## Prompt (v3, edit of v1; reference image v1, role "edit target")

```text
Use case: precise-object-edit
Input images: Image 1: edit target.
Primary request: change only one thing. In the small scatter plot inside the rounded card on the left, one dot slightly left of the middle has a grey smudge next to it; remove the smudge and draw that dot as a crisp, sharp, perfectly round dark grey dot exactly like the other dots.
Constraints: keep everything else exactly unchanged, including the position and size of every element: the title, the four lane names, the four grey arrows, the four red bars with red ✗ glyphs, the four red barrier labels, the dashed blue box on the right and its three lines of blue text, all spelling, fonts, colors and spacing. Text that must remain, exactly once each and spelled exactly: [the 12 strings above]. No additional text, icons, logos or watermark.
```
