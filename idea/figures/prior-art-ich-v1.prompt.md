# prior-art-ich-v1

AI-generated schematic for `idea/2026-11-07-semantic-svg-prior-art.md`, §2 InteractiveComplexHeatmap (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `idea/figures/prior-art-routes-v4.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0064. Every string was re-read on the quantized file.
- **Checked on the published `prior-art-ich-v1.png`:**
  - the five strings, letter by letter, each exactly once;
  - two heatmap slices in dashed blue boxes feed one position table; the clicked cell has an orange-red outline;
  - no logo or watermark.
- **Mapping to the text:**
  - dashed boxes = block boxes recorded with `deviceLoc` after `draw()`;
  - "6 rows, 4.5 KB for 80,000 cells" and the cell lookup by fraction × slice size are the measured and read values in §2.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a research note (stylized, not data)
Input images: Image 1: style anchor from the same project. Match its canvas color, fonts, line weights, greys and blue. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold geometric sans-serif, near-black #1F1E1D): "Positions recorded after drawing map a click to the exact cell"
Subject, left to right:
- Left: a heatmap made of small grey-blue shaded square cells, split into two horizontal slices with a small gap between them. Each slice's block of cells is outlined by a dashed blue rectangle (#4C75AD). A blue label above the heatmap with a thin leader line to one dashed outline: "block boxes recorded after draw()".
- Middle: a small white card with a thin grey border, header in dark monospace: "position table". Body: six thin grey rows with short grey placeholder bars, no text. Under the card, muted grey (#87867F): "6 rows, 4.5 KB for 80,000 cells". A thin grey arrow from the dashed boxes to this card.
- Right: on the heatmap, one cell is outlined in orange-red (#C8553D) and a small flat grey mouse-pointer arrow clicks on it. A label on the right side with a thin leader line to that cell: "click → cell by fraction × slice size".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows
Composition/framing: landscape 16:9; title on top; heatmap on the left, table card in the middle, the click label on the right
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD for recorded boxes; orange-red #C8553D for the clicked cell; heatmap cells in muted grey-blues
Text (verbatim, exactly these strings and nothing else): "Positions recorded after drawing map a click to the exact cell", "block boxes recorded after draw()", "position table", "6 rows, 4.5 KB for 80,000 cells", "click → cell by fraction × slice size"
Constraints: render every string exactly once, spelled exactly; no numbers or text inside the heatmap or table; no additional text, logos or watermark
```
