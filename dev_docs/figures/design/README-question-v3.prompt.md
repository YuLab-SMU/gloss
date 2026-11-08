# README-question-v3

AI-generated schematic for `README.md`, Why (figure type F3, stylized; not data and not a screenshot).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `idea/figures/prior-art-routes-v4.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from an earlier version of the prompt. Strings were exact, but the dots trended upward (mpg falls with weight in mtcars) and a faint ghost dot sat next to the highlighted one. Rejected.
  2. v2 from the prompt below, which asks for a downward trend and identical dot layouts in both panels. Strings were exact; the right panel had one extra dot that the left panel lacks.
  3. v3 = v2 plus an ImageMagick fix: `magick README-question-v2.png -fill "srgb(252,251,248)" -draw "circle 1475,811 1489,811" README-question-v3.png`, with the colour sampled from the card. Both panels now hold the same 25 dots. Drafts v1 and v2 were deleted.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0051. Every string was re-read on the quantized file.
- **Checked on the published `README-question-v3.png`:**
  - the five strings, character by character, each exactly once; the label in monospace;
  - both panels show the same 25 dots with a downward trend; the cursor in the left panel and the blue ring in the right panel are on the same dot;
  - no logo or watermark.
- **Mapping to the text:**
  - "134 shapes, 0 ids" = the svglite export of the faceted mtcars plot in the README (134 drawn primitives, none with an id);
  - "Mazda RX4 · mtcars row 1 · panel am = 1": Mazda RX4 is row 1 of `mtcars` and has `am = 1`; the spike plot uses `facet_wrap(~am)`;
  - the right panel is what gloss is designed to answer; gloss has no code yet.

## Prompt (v2)

```text
Use case: infographic-diagram
Asset type: explanatory before/after schematic for a software README (stylized, not data)
Input images: Image 1: style anchor from the same project. Match its canvas color, fonts, line weights, greys and blue. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Subject: two equal rounded cards side by side (white #FDFCF9, thin grey border #C8C7BF), each with a short header in dark sans-serif. Both cards contain the SAME small scatter plot, drawn identically: two thin axes with no labels or numbers, and about twenty crisp, sharp, perfectly round dark grey dots following a clear DOWNWARD trend from upper left to lower right (heavier cars use more fuel). Every dot is crisp; no faded, blurred or ghost dots.
- Above both cards, centered: a white speech bubble with a thin grey outline, its tail pointing down toward the left card, containing the text "Which car is this?".
- Left card header: "plain SVG export". In its plot, a simple flat grey hand-cursor icon points at one dot in the middle of the cloud. Under the plot, one line in muted grey (#87867F): "134 shapes, 0 ids: no answer".
- Right card header: "with gloss". In its plot, the same dot (same position as in the left card) is ringed in blue (#4C75AD); a thin blue leader line runs from it to a blue-outlined tag with light blue fill (#EEF3FA) and blue monospace text: "Mazda RX4 · mtcars row 1 · panel am = 1". The tag sits in empty space above-right of the cloud and does not cover any dot.
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; the question bubble at the top center; the two cards below with wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA
Text (verbatim, exactly these strings and nothing else): "Which car is this?", "plain SVG export", "134 shapes, 0 ids: no answer", "with gloss", "Mazda RX4 · mtcars row 1 · panel am = 1"
Constraints: render every string exactly once, spelled exactly; the dots trend downward in both cards; no people or faces (only the flat cursor icon); no additional text, logos or watermark
```
