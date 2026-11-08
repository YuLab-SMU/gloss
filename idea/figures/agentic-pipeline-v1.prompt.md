# agentic-pipeline-v1

AI-generated schematic for `idea/2026-11-07-agentic-semantic-svg.md`, Pipeline (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `idea/figures/prior-art-routes-v4.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0061. Every string was re-read on the quantized file.
- **Checked on the published `agentic-pipeline-v1.png`:**
  - the strings, letter by letter: the title, "code + data", the four stage names, "deterministic" exactly three times (stages 1, 3, 4), "agent" once (stage 2), "figure.svg / figure.html", and the red note under stage 2;
  - stages 1, 3, 4 are blue; stage 2 is orange-red;
  - no logo or watermark.
- **Mapping to the text:**
  - the four stages of the 2026-11-07 pipeline; the red note = stage 2's input is a compressed skeleton, never the full SVG;
  - simplification: stage 3 writes the files and stage 4 checks them and writes a report, which is not drawn.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a research note (stylized, not data)
Input images: Image 1: style anchor from the same project. Match its canvas color, fonts, line weights, greys and blue. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold geometric sans-serif, near-black #1F1E1D): "The 2026-11-07 pipeline: the agent writes semantics, never geometry"
Subject: one horizontal flow across the middle, joined by thin grey arrows, left to right:
- a grey rounded card: "code + data"
- four stage cards of equal size, each with a bold name on top and a smaller subtitle under it:
  stage card 1, blue outline and light blue fill (#4C75AD / #EEF3FA): "1 skeleton" / "deterministic"
  stage card 2, orange-red outline and light warm fill (#C8553D / #FBF1EC): "2 semantics" / "agent"
  stage card 3, blue: "3 compile" / "deterministic"
  stage card 4, blue: "4 verify" / "deterministic"
- a grey rounded card shaped like a document: "figure.svg / figure.html"
Under stage card 2, one line of small orange-red text: "sees a compressed skeleton, never the full SVG".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the flow in one row across the middle with even spacing
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for deterministic stages; orange-red #C8553D / #FBF1EC for the agent stage
Text (verbatim): "The 2026-11-07 pipeline: the agent writes semantics, never geometry", "code + data", "1 skeleton", "2 semantics", "3 compile", "4 verify", "deterministic" (exactly three times, under stages 1, 3 and 4), "agent" (once, under stage 2), "figure.svg / figure.html", "sees a compressed skeleton, never the full SVG". Nothing else.
Constraints: spelled exactly; no additional text, icons, logos or watermark
```
