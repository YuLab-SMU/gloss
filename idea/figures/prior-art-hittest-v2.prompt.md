# prior-art-hittest-v2

AI-generated schematic for `idea/2026-11-07-semantic-svg-prior-art.md`, §2 Shiny `plotOutput` (figure type F3, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `idea/figures/prior-art-routes-v4.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from an earlier version of the prompt. Two labels pointed at the wrong marks, and the clicked point was not nearest to the other row's raw position. Rejected.
  2. v2 from the prompt below, which fixes each label's target and the geometry. Accepted. Draft v1 was deleted.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0050. Every string was re-read on the quantized file.
- **Checked on the published `prior-art-hittest-v2.png`:**
  - the six strings, letter by letter, each exactly once;
  - hollow grey circles = raw positions, solid dots = drawn (jittered) positions, each pair joined by a thin grey line;
  - "drawn point (jittered)" points at a solid dot, "raw position used by nearPoints()" at a hollow circle, "click" at the clicked solid dot;
  - the clicked dot's own raw circle is far above it; the nearest raw circle (red, dashed red line, red ✗) belongs to another row;
  - no logo or watermark.
- **Mapping to the text:**
  - the mechanism in §2: `nearPoints()` projects the raw columns to pixels and picks the nearest, so jitter moves the drawn point away from its own raw position;
  - the footer = the measured `geom_jitter` result, 1/32.

## Prompt (v2)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a research note (stylized, not data)
Input images: Image 1: style anchor from the same project. Match its canvas color, fonts, line weights, greys and red. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold geometric sans-serif, near-black #1F1E1D): "Hit-testing guesses the row from the raw columns"
Subject: one large white card (thin grey border) on the left two thirds, holding a plot with two thin axes and no labels or numbers. Inside, two vertical columns of points (two discrete x positions).
Notation used in the plot: a HOLLOW grey circle (#87867F outline, no fill) is a raw position; a SOLID dark dot (#3D3D3A) is the drawn, jittered point; each solid dot is joined to its own hollow circle by a short thin grey line.
- Left column: three hollow circles stacked vertically on one vertical line, each with its solid dot displaced a short distance sideways. These are normal pairs.
- Right column: two hollow circles on one vertical line, an upper one U and a lower one L, well apart. The solid dot belonging to U has been jittered far DOWN and to the right, so it sits immediately next to L, much closer to L than to U; a long thin grey line still joins it to U. The solid dot belonging to L is displaced a short distance to the left of L.
- A small flat grey mouse-pointer arrow clicks exactly on U's solid dot (the one that now sits next to L). A short dashed red line (#D65451) joins the click to L. L is ringed in red with a small red ✗ beside it.
Four labels on the right of the card, each with a thin grey leader line that ends exactly on its target:
- "drawn point (jittered)" → ends on one SOLID dot in the left column
- "raw position used by nearPoints()" → ends on one HOLLOW circle in the left column
- "click" → ends on the mouse pointer
- "nearest raw row: a different row" (red text) → ends on the red-ringed hollow circle L
Under the card, centered, muted grey (#87867F): "geom_jitter: 1 of 32 rows recovered"
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; plot card on the left; labels on the right; footer at the bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; red #D65451
Text (verbatim, exactly these strings and nothing else): "Hit-testing guesses the row from the raw columns", "drawn point (jittered)", "raw position used by nearPoints()", "click", "nearest raw row: a different row", "geom_jitter: 1 of 32 rows recovered"
Constraints: render every string exactly once, spelled exactly; the only other symbol is one ✗; no additional text, logos or watermark
```
