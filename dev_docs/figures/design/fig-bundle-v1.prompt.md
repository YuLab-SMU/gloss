# fig-bundle-v1

AI-generated schematic for `dev_docs/design.qmd`, 一个文件就能带走整份图包 → 目录与单文件 (#sec-storage) (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0057. Every string was re-read on the quantized file.
- **Checked on the published `fig-bundle-v1.png`:**
  - the eleven strings, character by character, each exactly once; the file names and function names in monospace;
  - `gl_write()` points from the directory to the single file; `gl_read()` points back;
  - no logo or watermark.
- **Mapping to the text:**
  - left = the directory form (four of its entries; `context.json` is omitted for space); right = the single file, a projection with the whole bundle embedded;
  - "无损互转" is a design goal and an M0 completion criterion, not a measurement.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus file and function names; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "图包有目录和单文件两种形式，可以无损互转"
Subject:
- Left card: header band with monospace bold text "fig.gloss/". Body: a small folder tree drawn with thin grey connector lines, four monospace entries one per line: "manifest.json", "substrate/", "layers/", "projections/".
- Right card: header band with monospace bold text "fig.html". Body: a small grey scatter-plot preview (no text) occupying the upper part; below it a small blue rounded slot (#EEF3FA fill, #4C75AD outline) containing blue text "内嵌整份图包".
- Between the two cards: two horizontal arrows, one pointing right with the monospace label above it "gl_write()", one pointing left with the monospace label below it "gl_read()". Centered between the arrows, a small blue label: "无损互转".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; two cards left and right with the arrows between them
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA
Text (verbatim, exactly these strings and nothing else): "图包有目录和单文件两种形式，可以无损互转", "fig.gloss/", "manifest.json", "substrate/", "layers/", "projections/", "fig.html", "内嵌整份图包", "gl_write()", "gl_read()", "无损互转"
Constraints: render every string exactly once with exactly these characters and punctuation; no additional text, icons, logos or watermark
```
